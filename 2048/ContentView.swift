import SwiftUI
import AVFoundation

struct ContentView: View {
    //ゲームスタート遷移宣言
    @State private var showPlay = false
    //ニックネーム入力ポップアップの表示
    @State private var showNameInput = false
    //ゲームへ引き継ぐニックネーム
    @State private var playerName = ScoreStore.defaultName
    //コンボなどのポップアップ表示に関する宣言
    @State private var showChild = false
    //実績の画面遷移追加
    @State private var navigateToRanking = false
    //図鑑の画面遷移
    @State private var navigateToPokedex = false
    @State private var didStartBGM = false
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                //トップ画面の背景画像設定
                GeometryReader { geometry in
                    Image("HalloweenBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                }
                .ignoresSafeArea()
                //スタートボタン設定
                VStack {
                    Spacer(minLength: 0)

                    // スタートボタン（下寄せ・余白を確保）
                    Button {
                        // 直接ゲームへ進まず、毎回ニックネーム入力ポップアップを出す
                        withAnimation(.easeOut(duration: 0.2)) {
                            showNameInput = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                            Text("スタート")
                                .font(.system(size: 26, weight: .black))
                        }
                        .contentShape(Capsule())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.95),
                                    Color(red: 1.0, green: 0.7, blue: 0.1).opacity(0.95)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ZStack {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.06)],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                    .blendMode(.screen)
                                    .opacity(0.9)
                                
                                Capsule()
                                    .inset(by: 6)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.8), Color.white.opacity(0.0)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ), lineWidth: 2
                                    )
                                    .blur(radius: 1.2)
                                    .opacity(0.7)
                            }
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.15), lineWidth: 1)
                                .blur(radius: 1)
                                .offset(y: 1)
                                .mask(
                                    Capsule()
                                        .fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3)
                                    ], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 1.5
                                )
                        )
                        
                        .shadow(color: Color.black.opacity(0.45), radius: 14, x: 0, y: 10)
                        
                        .shadow(color: Color.orange.opacity(0.25), radius: 10, x: 0, y: 2)
                        .clipShape(Capsule())
                        
                        .background(.ultraThinMaterial, in: Capsule())
                        
                        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: showPlay)
                    }
                    .padding(.horizontal, 28)
                    .buttonStyle(Pressed3DButtonStyle())

                    // 下部メニューとの間隔（圧迫感を避ける）
                    Spacer().frame(height: 16)

                    // 下部メニュー
                    HStack(spacing: 0) {
                        Button(action: { navigateToPokedex = true }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle().fill(
                                        LinearGradient(
                                            colors: [Color.black.opacity(0.75), Color.black.opacity(0.45)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    Circle()
                                        .fill(
                                            LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)], startPoint: .top, endPoint: .center)
                                        )
                                        .blendMode(.screen)
                                    Circle()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                        .blur(radius: 1)
                                        .offset(y: -1)
                                        .mask(
                                            Circle()
                                                .fill(LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top))
                                        )
                                    Circle()
                                        .stroke(
                                            LinearGradient(colors: [Color.purple.opacity(0.95), Color.purple.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                                            lineWidth: 2
                                        )
                                    Image(systemName: "book.closed.fill")
                                        .font(.system(size: 23, weight: .bold))
                                        .foregroundStyle(.yellow)
                                }
                                .frame(width: 54, height: 54)
                                .contentShape(Circle())

                                Text("図鑑")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PressedCircleMenuStyle())

                        Button(action: { navigateToRanking = true }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle().fill(
                                        LinearGradient(
                                            colors: [Color.black.opacity(0.75), Color.black.opacity(0.45)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    Circle()
                                        .fill(
                                            LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)], startPoint: .top, endPoint: .center)
                                        )
                                        .blendMode(.screen)
                                    Circle()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                        .blur(radius: 1)
                                        .offset(y: -1)
                                        .mask(
                                            Circle()
                                                .fill(LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top))
                                        )
                                    Circle()
                                        .stroke(
                                            LinearGradient(colors: [Color.purple.opacity(0.95), Color.purple.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                                            lineWidth: 2
                                        )
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 23, weight: .bold))
                                        .foregroundStyle(.yellow)
                                }
                                .frame(width: 54, height: 54)
                                .contentShape(Circle())

                                Text("実績")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PressedCircleMenuStyle())
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .ignoresSafeArea(.keyboard)

                // ニックネーム入力ポップアップ（スタートを押すたびに毎回表示）
                if showNameInput {
                    NicknameInputView(
                        onStart: { name in
                            playerName = name
                            withAnimation(.easeOut(duration: 0.2)) {
                                showNameInput = false
                            }
                            showPlay = true
                        },
                        onCancel: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showNameInput = false
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            // ランキング画面へ遷移（NavigationStack の内側に付ける）
            .navigationDestination(isPresented: $navigateToRanking) {
                RankingView()
            }
            // 図鑑画面へ遷移（NavigationStack の内側に付ける）
            .navigationDestination(isPresented: $navigateToPokedex) {
                CollectionView()
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showPlay) {
            PlayView(playerName: playerName, onExitToTop: { showPlay = false })
        }
        .onChange(of: showPlay) { isPresenting in
            if isPresenting {
                // Entering PlayView: stop top BGM
                AudioManager.shared.stopBGM(named: "openmusic")
            } else {
                // Dismissing PlayView: restart top BGM
                AudioManager.shared.stopBGM(named: "gameend")
                AudioManager.shared.playBGM(named: "openmusic")
                didStartBGM = true
            }
        }
        .onAppear {
            guard !didStartBGM else { return }
            didStartBGM = true
            AudioManager.shared.playBGM(named: "openmusic")
        }
    }
    // 下部メニューのボタン
    private func menuItem(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // glossy spherical base
                    Circle().fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.75), Color.black.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    // top highlight
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)], startPoint: .top, endPoint: .center)
                        )
                        .blendMode(.screen)
                    // inner shadow for depth
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .blur(radius: 1)
                        .offset(y: -1)
                        .mask(
                            Circle()
                                .fill(LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top))
                        )
                    // border
                    Circle()
                        .stroke(
                            LinearGradient(colors: [Color.purple.opacity(0.95), Color.purple.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 2
                        )

                    Image(systemName: icon)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(.yellow)
                }
                .frame(width: 54, height: 54)
                .contentShape(Circle())
                
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressedCircleMenuStyle())
    }
}

struct Pressed3DButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // slight compress
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            // push downward when pressed
            .offset(y: configuration.isPressed ? 1.5 : 0)
            // drop shadow collapses when pressed
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.2 : 0.45), radius: configuration.isPressed ? 6 : 14, x: 0, y: configuration.isPressed ? 3 : 10)
            // add an inner shadow when pressed to feel embedded
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(configuration.isPressed ? 0.25 : 0.0), lineWidth: configuration.isPressed ? 2 : 0)
                    .blur(radius: configuration.isPressed ? 1 : 0)
                    .offset(y: configuration.isPressed ? 1 : 0)
                    .mask(
                        Capsule().fill(
                            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        )
                    )
            )
            // animate changes
            .animation(.spring(response: 0.18, dampingFraction: 0.85), value: configuration.isPressed)
            // 👇 iOS 17以降とiOS 16（iPhone 8）の両方に対応した振動処理
            .onChange(of: configuration.isPressed) { newValue in
                if newValue {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }

    }
}

struct PressedCircleMenuStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .offset(y: configuration.isPressed ? 1 : 0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.2 : 0.45), radius: configuration.isPressed ? 3 : 8, x: 0, y: configuration.isPressed ? 1 : 4)
            // inner ring on press
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(configuration.isPressed ? 0.25 : 0.0), lineWidth: configuration.isPressed ? 2 : 0)
                    .blur(radius: configuration.isPressed ? 1 : 0)
                    .offset(y: configuration.isPressed ? 0.5 : 0)
                    .mask(
                        Circle().fill(
                            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        )
                    )
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.85), value: configuration.isPressed)
            // 👇 iOS 17以降なら新しい揺れ方、iOS 16（iPhone 8）なら古い揺れ方で振動させる
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    if #available(iOS 17.0, *) {
                        // iOS 17以降の書き方
                        // ※元のコードの .sensoryFeedback と同じ効果をここで発動させます
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    } else {
                        // iOS 16以前（iPhone 8など）の書き方
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    }
                }
            }
        }
    }

    #Preview {
        ContentView()
    }
