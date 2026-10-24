import SwiftUI
import AVFoundation

struct GameClearView: View {
    /// ランキング画面へ渡す値
    let score: Int          // 最終スコア
    let playTime: Int       // プレイ時間（秒）
    var playerName: String = ""   // ニックネーム（リザルトに表示）

    var onRetry: () -> Void
    var onExit: () -> Void
    //スコアとプレイ時間が記録された時に実行したい処理（関数）を、後から外から設定できるようにするための変数（クロージャ）
    var onRecordScore: ((_ score: Int, _ playTime: Int) -> Void)? = nil

    @State private var didRecord = false

    @State private var victoryPlayer: AVAudioPlayer?

    private func playVictorySound() {
        guard let url = Bundle.main.url(forResource: "victorybell", withExtension: "mp3") else {
            print("[GameClear] victorybell.mp3 not found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()
            victoryPlayer = player // keep a strong reference while the view is alive
        } catch {
            print("[GameClear] Failed to play victory sound: \(error)")
        }
    }

    var body: some View {
        ZStack {
            ResultBackground()

            VStack(spacing: 32) {
                GlowTitle(text: "GAME CLEAR", colors: [.yellow, .orange, .purple])
                ResultTexts(score: score, playTime: playTime, playerName: playerName)

                VStack(spacing: 16) {
                    // BGMの切り替えは PlayView / ContentView 側で行う
                    ResultButton(title: "もう一度遊ぶ", colors: [.orange, .purple]) {
                        onRetry()
                    }
                    ResultButton(title: "終了する", colors: [.gray, .indigo]) {
                        onExit()
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        //この画面が表示された瞬間に、1度だけスコアとプレイ時間を記録（通知）する
        .onAppear {
            guard !didRecord else { return }
            didRecord = true
            // Play victory sound once when the view appears
            playVictorySound()
            // Notify score recording once
            onRecordScore?(score, playTime)
        }
    }
}
