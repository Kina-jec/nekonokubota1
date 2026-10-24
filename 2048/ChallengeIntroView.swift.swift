import SwiftUI
import AVFoundation
import Combine
import CoreImage
import UIKit

// ============================================================
//  ジャック・オー・ランタン動画 × 巻物（挑戦状）演出
//
//  使う動画：pumpkin_smoke.mp4
//   - 元動画から「白背景」と「Luma AI ロゴ」を除去済み
//   - 動画の【上半分】がカラー、【下半分】が不透明度マスク（白=不透明 / 黒=透明）
//     （全体 540 x 1212 / 1コマ分は 540 x 606 / 24fps / 約5.04秒 / 音声なし）
//   - アプリ側でこの2つを合成し、本物のアルファ付き画像にする
//     → パンプキン本体は完全に不透明、煙だけが半透明になる
//   ※ Xcode のターゲットに追加し、「Copy Bundle Resources」に入っていること
// ============================================================
private enum IntroVideo {
    static let name = "pumpkin_smoke"
    static let ext = "mp4"
    /// 動画のピクセルサイズ（縦横比の計算用）
    static let size = CGSize(width: 540, height: 606)
    /// 口が大きく開ききり、煙がブワッと噴き出している再生時刻（秒）。巻物はこの瞬間に発射される
    /// （動画では約1.0秒で口が開き始め、約2.0秒で大きく開ききる。早く/遅くしたいときはここを調整）
    static let burstTime: Double = 2.0
    /// 動画の高さに対する口の位置（0 = 上端, 1 = 下端）
    static let mouthY: CGFloat = 0.62
    /// true: 動画が最後まで再生されるまでタップ不可 / false: 巻物が出きったらタップ可
    static let lockUntilVideoEnds = true
    /// 動画の再生が止まった場合の保険（秒）
    static let watchdog: Double = 7.0
}

// ============================================================
//  AVPlayer で動画を1回だけ再生し、フレームを UIImage として配信する
//  （カラー + マスクの2枚を合成してアルファ付きの画像にし、SwiftUI の Image に流す）
// ============================================================
final class PumpkinVideoPlayer: NSObject, ObservableObject {
    @Published private(set) var frame: UIImage?

    private var player: AVPlayer?
    private var output: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    private var boundaryToken: Any?
    private var endObserver: NSObjectProtocol?
    private let context = CIContext()

    private var onBurst: (() -> Void)?
    private var onEnd: (() -> Void)?
    private var burstFired = false
    private var endFired = false

    /// 再生開始。動画が見つからないときは false を返す
    @discardableResult
    func start(onBurst: @escaping () -> Void, onEnd: @escaping () -> Void) -> Bool {
        guard player == nil else { return true }
        guard let url = Bundle.main.url(forResource: IntroVideo.name, withExtension: IntroVideo.ext) else {
            print("[ChallengeIntro] \(IntroVideo.name).\(IntroVideo.ext) not found in bundle")
            return false
        }
        self.onBurst = onBurst
        self.onEnd = onEnd

        let item = AVPlayerItem(url: url)
        let out = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        item.add(out)
        output = out

        let p = AVPlayer(playerItem: item)
        p.isMuted = true
        p.actionAtItemEnd = .pause          // ループなし。最後のコマで止める
        player = p

        // 煙が噴き出す瞬間に巻物を発射するための「時刻の合図」
        let burst = NSValue(time: CMTime(seconds: IntroVideo.burstTime, preferredTimescale: 600))
        boundaryToken = p.addBoundaryTimeObserver(forTimes: [burst], queue: .main) { [weak self] in
            self?.fireBurst()
        }
        // 再生終了の合図
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            self?.fireEnd()
        }

        let link = CADisplayLink(target: self, selector: #selector(step))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .common)
        displayLink = link

        p.play()
        return true
    }

    /// 後片付け（画面が消えたときに呼ぶ）
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        if let token = boundaryToken { player?.removeTimeObserver(token) }
        boundaryToken = nil
        if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }
        endObserver = nil
        player?.pause()
        player = nil
        output = nil
        onBurst = nil
        onEnd = nil
    }

    private func fireBurst() {
        guard !burstFired else { return }
        burstFired = true
        onBurst?()
    }

    private func fireEnd() {
        guard !endFired else { return }
        endFired = true
        step()                       // 最後のコマを確実に反映
        displayLink?.invalidate()
        displayLink = nil
        fireBurst()                  // 万一、境界の合図を取りこぼしても巻物は必ず出す
        onEnd?()
    }

    // 画面の更新タイミングごとに、動画の最新フレームを取り出す
    @objc private func step() {
        guard let out = output else { return }
        let t = out.itemTime(forHostTime: CACurrentMediaTime())
        guard out.hasNewPixelBuffer(forItemTime: t),
              let buffer = out.copyPixelBuffer(forItemTime: t, itemTimeForDisplay: nil) else { return }
        let packed = CIImage(cvPixelBuffer: buffer)
        // Core Image は左下が原点：下側 = 動画の下半分（マスク）、上側 = 動画の上半分（カラー）
        let h = packed.extent.height / 2
        let w = packed.extent.width
        let colorRect = CGRect(x: 0, y: h, width: w, height: h)
        let maskRect = CGRect(x: 0, y: 0, width: w, height: h)

        let color = packed
            .cropped(to: colorRect)
            .transformed(by: CGAffineTransform(translationX: 0, y: -h))
        let gray = packed
            .cropped(to: maskRect)
        // 白黒マスクの明るさ → アルファに変換
        let alphaMask = gray.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])
        let clear = CIImage(color: CIColor.clear).cropped(to: color.extent)
        let result = color.applyingFilter("CIBlendWithAlphaMask", parameters: [
            kCIInputBackgroundImageKey: clear,
            kCIInputMaskImageKey: alphaMask
        ])
        if let cg = context.createCGImage(result, from: color.extent) {
            frame = UIImage(cgImage: cg)
        }
    }
}

// ============================================================
//  ゲーム画面に入った瞬間の「パンプキン動画 → 巻物飛び出し」演出
// ============================================================
struct ChallengeIntroView: View {
    let playerName: String
    let highScore: Int
    /// 画面をタップして挑戦を始めるときに呼ばれる
    var onStart: () -> Void

    @StateObject private var video = PumpkinVideoPlayer()

    // パンプキン動画
    @State private var videoOpacity: Double = 0
    @State private var videoScale: CGFloat = 0.85
    // 巻物
    @State private var showScroll = false
    @State private var scrollScale: CGFloat = 0.0
    // タップ制御
    @State private var scrollFinished = false
    @State private var videoFinished = false
    @State private var canTap = false
    @State private var breathing = false

    private let inkRed = Color(red: 0.45, green: 0.05, blue: 0.05)
    private let ink = Color(red: 0.20, green: 0.10, blue: 0.03)

    var body: some View {
        GeometryReader { geo in
            let videoW = min(geo.size.width, 560)
            let videoH = videoW * IntroVideo.size.height / IntroVideo.size.width
            let videoCenterY = geo.size.height * 0.46
            // 画面中心から見た「口」の位置。巻物はここから飛び出す
            let mouthDY = (videoCenterY - geo.size.height / 2) + videoH * (IntroVideo.mouthY - 0.5)

            ZStack {
                // 暗幕。どこをタップしても開始できる（canTap が true になるまで無効）
                Color.black
                    .opacity(showScroll ? 0.82 : 0.60)
                    .ignoresSafeArea()
                    .animation(.easeIn(duration: 0.4), value: showScroll)
                    .onTapGesture { startIfPossible() }

                // パンプキン動画（アルファ付き：本体は不透明、煙だけ半透明）
                Group {
                    if let image = video.frame {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.clear
                    }
                }
                .frame(width: videoW, height: videoH)
                .scaleEffect(videoScale)
                .opacity(videoOpacity)
                .position(x: geo.size.width / 2, y: videoCenterY)
                .allowsHitTesting(false)

                // 巻物（口の奥から手前に向かって飛び出す）
                if showScroll {
                    scrollCard(size: geo.size)
                        .scaleEffect(max(scrollScale, 0.001))
                        .offset(y: (1 - min(scrollScale, 1)) * mouthDY)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .contentShape(Rectangle())
        .onTapGesture { startIfPossible() }
        .onAppear { startSequence() }
        .onDisappear { video.stop() }
        .task { await watchdog() }
    }

    // MARK: - 演出の進行

    private func startSequence() {
        // 0.0秒：動画の再生開始と同時に、パンプキンがググッとズームアップ
        withAnimation(.easeOut(duration: 0.5)) {
            videoOpacity = 1
            videoScale = 1.0
        }

        let found = video.start(
            onBurst: { launchScroll() },        // 煙が噴き出した瞬間に巻物発射
            onEnd: {                            // 動画の再生が終わった
                videoFinished = true
                refreshTapLock()
            }
        )

        // 動画が見つからない場合でもゲームが止まらないようにする
        if !found {
            videoFinished = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { launchScroll() }
        }
    }

    // 巻物の発射（0.0 → 1.05 → 1.0）。煙の噴出に合わせて1回だけ実行される
    private func launchScroll() {
        guard !showScroll else { return }
        showScroll = true
        scrollScale = 0.0

        // パンプキンは動かさず、巻物だけが口の奥から飛び出す
        withAnimation(.easeOut(duration: 0.45)) { scrollScale = 1.05 }

        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            withAnimation(.easeInOut(duration: 0.15)) { scrollScale = 1.0 }

            try? await Task.sleep(nanoseconds: 150_000_000)
            // 巻物が出きった（パンプキンは透けさせないので、不透明度はそのまま）
            scrollFinished = true
            refreshTapLock()
        }
    }

    // タップ解禁の条件：巻物が出きっている ＋（設定により）動画の再生が終わっている
    private func refreshTapLock() {
        guard !canTap else { return }
        guard scrollFinished, videoFinished || !IntroVideo.lockUntilVideoEnds else { return }
        canTap = true
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            breathing = true
        }
    }

    // 動画の終了通知が来ないときの保険（ゲームが永久に始まらない事故を防ぐ）
    private func watchdog() async {
        try? await Task.sleep(nanoseconds: UInt64(IntroVideo.watchdog * 1_000_000_000))
        guard !Task.isCancelled else { return }
        if !videoFinished { videoFinished = true }
        if !showScroll { launchScroll() }
        refreshTapLock()
    }

    // 演出中の誤タップを無視する防衛線
    private func startIfPossible() {
        if canTap { onStart() }
    }

    // MARK: - 巻物

    private func scrollCard(size: CGSize) -> some View {
        let cardWidth = min(size.width * 0.88, 420)
        let cardHeight = min(size.height * 0.70, 580)

        return VStack(spacing: 0) {
            scrollRoll(width: cardWidth)

            VStack(spacing: 0) {
                // スクロールできる挑戦状の本文
                ScrollView(showsIndicators: false) {
                    challengeContent
                }

                Rectangle()
                    .fill(inkRed.opacity(0.35))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                // 最下部に固定：タップで開始（解禁されるまで非表示 → ゆっくり明滅）
                Text("【画面をタップして挑戦開始！】")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(inkRed)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .opacity(canTap ? (breathing ? 1.0 : 0.35) : 0.0)
                    .scaleEffect(breathing ? 1.04 : 0.97)
                    .animation(.easeIn(duration: 0.3), value: canTap)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
            }
            .frame(width: cardWidth - 16)
            .frame(maxHeight: .infinity)
            .background(parchment)

            scrollRoll(width: cardWidth)
        }
        .frame(width: cardWidth, height: cardHeight)
        .shadow(color: .black.opacity(0.6), radius: 14, x: 0, y: 8)
    }

    // 古びた羊皮紙
    private var parchment: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.90, blue: 0.72),
                         Color(red: 0.88, green: 0.74, blue: 0.48)],
                startPoint: .top,
                endPoint: .bottom
            )
            // 四隅を焦げたように暗くする
            RadialGradient(
                colors: [.clear, Color(red: 0.35, green: 0.20, blue: 0.05).opacity(0.35)],
                center: .center,
                startRadius: 60,
                endRadius: 340
            )
        }
    }

    // 巻物の上下の丸まった部分
    private func scrollRoll(width: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.55, green: 0.35, blue: 0.15),
                             Color(red: 0.30, green: 0.17, blue: 0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Capsule().stroke(Color(red: 0.20, green: 0.10, blue: 0.03), lineWidth: 2)
            )
            .overlay(
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(height: 5)
                    .padding(.horizontal, 14)
                    .offset(y: -5)
            )
            .frame(width: width, height: 26)
    }

    // MARK: - 本文

    private var challengeContent: some View {
        VStack(spacing: 14) {
            // タイトル（絵文字は使わず SF Symbols で飾る）
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("DEMON'S CHALLENGE")
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(inkRed)

            // 挑戦状（飾り線つき）
            HStack(spacing: 10) {
                Rectangle().fill(inkRed.opacity(0.5)).frame(height: 2)
                Text("挑 戦 状")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(inkRed.opacity(0.9))
                    .fixedSize()
                Rectangle().fill(inkRed.opacity(0.5)).frame(height: 2)
            }

            challengeMessage
                .padding(.top, 4)

            HStack(spacing: 6) {
                Image(systemName: "chevron.down")
                Text("下にスクロールするとルールが見えるぞ")
                Image(systemName: "chevron.down")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(inkRed.opacity(0.7))
            .padding(.top, 6)

            guideSection
                .padding(.top, 24)
        }
        .padding(20)
    }

    // ニックネーム（User 1 など）と最高スコアを連動させた熱いメッセージ
    @ViewBuilder
    private var challengeMessage: some View {
        VStack(spacing: 12) {
            Text("異界へ迷い込みし者\n\(playerName) よ")
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(Color(red: 0.30, green: 0.10, blue: 0.45))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            VStack(spacing: 8) {
                Text("1年に1度、すべての魔力が交差するハロウィンの夜。")
                    .font(.system(size: 13, weight: .bold))
                Text("目の前に現れたのは、奇妙なマージのパズル…")
                    .font(.system(size: 13, weight: .bold))
                Text("同じ姿の闇の住人を重ね、進化の連鎖を起こせ！")
                    .font(.system(size: 13, weight: .bold))
                Text("ヴァンパイアや怪物の封印を解き明かし、")
                    .font(.system(size: 13, weight: .bold))
                Text("伝説の『ハロウィン城』を呼び覚ますのだ！")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(inkRed)
            }
            .foregroundStyle(ink)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)

            if highScore > 0 {
                Text("現在の最高到達魔力")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ink)

                Text("【 \(highScore.formatted())点 】")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(inkRed)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("この記録を超え、城の真の主となれ！")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(ink)
            } else {
                Text("お前が初代の王となり、\n歴史を刻むのだ！")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(inkRed)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // ストーリーに合わせたミニゲームガイド
    private var guideSection: some View {
        VStack(spacing: 12) {
            Text("―― 魔力融合の法則 ――")
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(inkRed.opacity(0.85))

            HStack(spacing: 8) {
                Image(systemName: "hand.point.right.fill")
                Text("同じ住人を重ねて上位の異形へ進化！")
            }
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(ink)

            HStack(spacing: 8) {
                tileIcon("2")
                Image(systemName: "plus")
                tileIcon("2")
                Image(systemName: "arrow.right")
                tileIcon("4")
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(inkRed)

            HStack(spacing: 8) {
                tileIcon("4")
                Image(systemName: "plus")
                tileIcon("4")
                Image(systemName: "arrow.right")
                tileIcon("8")
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(inkRed)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("警告：スワイプすると、\nすべての住人が同時に動いてしまうぞ！")
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(Color(red: 0.65, green: 0.20, blue: 0.05))
            .font(.system(size: 16, weight: .black, design: .rounded))
            .padding(.top, 6)
        }
        .padding(.bottom, 12)
    }


    private func tileIcon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
    }
}

#Preview {
    ChallengeIntroView(playerName: "User 1", highScore: 12800, onStart: {})
}
