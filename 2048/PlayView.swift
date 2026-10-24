import SwiftUI
import Combine
import AVFoundation

struct PlayView: View {
    /// トップ画面のニックネーム入力で決まった名前
    var playerName: String = ScoreStore.defaultName
    /// 「終了する」でトップ画面へ戻す処理（トップ側から渡す）
    var onExitToTop: () -> Void
    
    /// クリア時のみ呼ばれる。ランキング画面へ (スコア, 秒数) を渡す口（任意）
    var onRecordClearScore: ((_ score: Int, _ playTime: Int) -> Void)? = nil

    @StateObject private var model = GameModel()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // 配置の微調整用
    private let boardOffsetX: CGFloat = 0.05   // 画面幅に対する右寄せ量
    private let boardCenterY: CGFloat = 0.62   // 画面高さに対する中心位置
    // スコアを端末に保存する共通関数
    // ニックネームとスコアをセットで保存する
    private func savePlayResult(score: Int) {
        ScoreStore.add(name: playerName, score: score)
        // 保存した結果がハイスコアなら、表示用の値も更新する
        storedHighScore = ScoreStore.highScore
    }

    // 1ゲームにつき1回だけ記録するためのフラグ
    @State private var hasRecorded = false
    // 挑戦状の演出が終わるまではタイマーとスワイプを止める
    @State private var introFinished = false
    // 端末に保存されているハイスコア（プレイ中のリアルタイム表示の基準）
    @State private var storedHighScore = ScoreStore.highScore

    /// 現在のゲームを記録する（クリア・ゲームオーバー・途中退出・リセットのすべてで共通）
    private func recordCurrentGame() {
        guard !hasRecorded else { return }
        // プレイ中は1点でも入っていれば記録（開始直後の0点退出は記録しない）
        guard model.state != .playing || model.score > 0 else { return }
        hasRecorded = true
        savePlayResult(score: model.score)
    }

    /// 記録してから最初からやり直す
    private func restartGame() {
        let wasFinished = model.state != .playing
        recordCurrentGame()
        hasRecorded = false
        model.reset()
        storedHighScore = ScoreStore.highScore
        if wasFinished {
            // リザルト画面から再開するときは、終了の音を止めてゲームBGMを流し直す
            AudioManager.shared.stopBGM(named: "gameend")
            AudioManager.shared.playBGM(named: "gamemusic")
        }
    }


    var body: some View {
        GeometryReader { geo in
            let rawBoard = min(geo.size.width * 0.84, geo.size.height * 0.5)
            let boardSize: CGFloat = rawBoard.isFinite ? max(0, rawBoard) : 0
            let centerX = geo.size.width / 2 + geo.size.width * boardOffsetX
            let centerY = geo.size.height * boardCenterY

            ZStack {
                // 最上部：設定・リセット ＋ スコア
                VStack(spacing: 10) {
                    HStack {
                        exitButton //左端に退出ボタンを設置
                        Spacer()
                        resetButton
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 2) {
                        Text("SCORE")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .tracking(4)
                        Text("\(model.score)")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                        // ハイスコア常時表示（自分のスコアが超えたら一緒に上がる）
                        HStack(spacing: 4) {
                            // 絵文字ではなく SF Symbols を使う（文字化け防止）
                            Image(systemName: model.score > storedHighScore && storedHighScore > 0 ? "flame.fill" : "trophy.fill")
                            Text("HIGH: \(max(storedHighScore, model.score).formatted())")
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                        .monospacedDigit()
                        .shadow(color: .orange, radius: 4)
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .yellow, radius: 5)
                    .shadow(color: .yellow.opacity(0.7), radius: 12)
                    .padding(.top, 4)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ゲームボード
                boardView(size: boardSize)
                    .position(x: centerX, y: centerY)
                    .gesture(swipeGesture)

                // コンボ演出（ボードのすぐ上）
                ForEach(model.combos) { item in
                    ComboPopupView(text: item.text)
                        .position(x: centerX, y: centerY - boardSize / 2 - 24)
                        .task {
                            try? await Task.sleep(nanoseconds: 1_300_000_000)
                            model.removeCombo(id: item.id)
                        }
                        .allowsHitTesting(false)
                }

                // 終了画面
                if model.state == .cleared {
                    GameClearView(
                        score: model.score,
                        playTime: model.elapsedSeconds,
                        playerName: playerName,
                        onRetry: { restartGame() },
                        onExit: onExitToTop,
                        onRecordScore: { score, time in
                                    onRecordClearScore?(score, time)
                                }
                    )
                    .transition(.opacity)
                } else if model.state == .gameOver {
                    GameOverView(
                        score: model.score,
                        playTime: model.elapsedSeconds,
                        playerName: playerName,
                        onRetry: { restartGame() },
                        onExit: onExitToTop
                    )
                    .transition(.opacity)
                }

                // コウモリ＆巻物の挑戦状（タップで消えてゲーム開始）
                if !introFinished {
                    ChallengeIntroView(
                        playerName: playerName,
                        highScore: storedHighScore,
                        onStart: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                introFinished = true
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background {
            Color.black.ignoresSafeArea()
            Color.clear
                .overlay(Image("bak")
                .resizable()
                .scaledToFill())
                .clipped()
                .ignoresSafeArea()
        }
        .onReceive(timer) { _ in
            // 挑戦状の演出中はタイマーを止める
            if introFinished { model.tick() }
        }
        // クリア・ゲームオーバーになった瞬間にスコアを自動保存する
        .onChange(of: model.state) { newState in
            if newState != .playing { recordCurrentGame() }
        }

        .navigationBarBackButtonHidden(true)
        .onAppear {
            AudioManager.shared.playBGM(named: "gamemusic")
        }
    }
    //リセットボタン
    private var resetButton: some View {
        Button {
            restartGame()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.black.opacity(0.45)))
                .contentShape(Circle())
        }
    }
    //途中退出時に安全にBGMの切り替え
    private var exitButton: some View {
           Button {
               recordCurrentGame() // 途中退出でもスコアを記録
               AudioManager.shared.stopBGM(named: "gamemusic")
               AudioManager.shared.playBGM(named: "openmusic")
               onExitToTop() //トップ画面へ戻る処理を呼び出す
           } label: {
               Image(systemName: "chevron.left") // 左向きの「く」の字アイコン
                   .font(.system(size: 24, weight: .semibold))
                   .foregroundStyle(.white)
                   .frame(width: 48, height: 48)
                   .background(Circle().fill(Color.black.opacity(0.45)))
                   .contentShape(Circle())
           }
       }
    //計算が狂うのを防ぎ4×4マスのゲーム盤面と各タイルの正確な1マスの大きさを自動で正確に割り出すための計算処理
    @ViewBuilder
    private func boardView(size rawSize: CGFloat) -> some View {
        let size: CGFloat = rawSize.isFinite ? max(0, rawSize) : 0
        let spacing: CGFloat = 8
        let n = CGFloat(GameModel.size)
        let cell: CGFloat = max(0, (size - spacing * (n + 1)) / n)

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.75))

            // 空きマス
            ForEach(0..<(GameModel.size * GameModel.size), id: \.self) { idx in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: cell, height: cell)
                    .offset(x: spacing + CGFloat(idx % GameModel.size) * (cell + spacing),
                            y: spacing + CGFloat(idx / GameModel.size) * (cell + spacing))
            }

            // タイル
            ForEach(model.tiles) { tile in
                Image("\(tile.value)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cell, height: cell)
                    .offset(x: spacing + CGFloat(tile.col) * (cell + spacing),
                            y: spacing + CGFloat(tile.row) * (cell + spacing))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
    }
    //指のドラッグ移動（20ピクセル以上）を検知しスワイプ操作を
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                // 挑戦状の演出中は操作できない
                guard introFinished else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > abs(dy) {
                    model.move(dx > 0 ? .right : .left)
                } else {
                    model.move(dy > 0 ? .down : .up)
                }
            }
    }
}

//コンボ文字
struct ComboPopupView: View {
    let text: String
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 20

    var body: some View {
        Text(text)
            .font(.system(size: 38, weight: .black, design: .rounded))
            .italic()
            .foregroundStyle(
                LinearGradient(colors: [.purple, .orange],
                               startPoint: .leading, endPoint: .trailing)
            )
            .shadow(color: .yellow, radius: 6)
            .shadow(color: .yellow.opacity(0.8), radius: 14)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: yOffset)
            .onAppear {
                // フワッと湧き出て拡大
                withAnimation(.easeOut(duration: 0.35)) {
                    scale = 1.25
                    opacity = 1
                    yOffset = 0
                }
                // お城（上空）へ昇りながら消える
                withAnimation(.easeIn(duration: 0.85).delay(0.35)) {
                    yOffset = -140
                    opacity = 0
                }
            }
    }
}
