import SwiftUI
import AVFoundation

struct GameOverView: View {
    let score: Int
    let playTime: Int
    var playerName: String = ""   // ニックネーム（リザルトに表示）

    var onRetry: () -> Void
    var onExit: () -> Void

    @State private var gameOverPlayer: AVAudioPlayer?

    private func playGameOverSound() {
        guard let url = Bundle.main.url(forResource: "gameend", withExtension: "mp3") else {
            print("[GameOver] gameend.mp3 not found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()
            gameOverPlayer = player // keep a strong reference while the view is alive
        } catch {
            print("[GameOver] Failed to play game over sound: \(error)")
        }
    }

    var body: some View {
        ZStack {
            ResultBackground()

            VStack(spacing: 32) {
                GlowTitle(text: "GAME OVER", colors: [.red, .purple, .orange])
                ResultTexts(score: score, playTime: playTime, playerName: playerName)

                VStack(spacing: 16) {
                    ResultButton(title: "もう一度遊ぶ", colors: [.orange, .purple], action: onRetry)
                    ResultButton(title: "終了する", colors: [.gray, .indigo], action: onExit)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .onAppear {
            playGameOverSound()
        }
    }
}
