import SwiftUI
import AVFoundation

/// 秒数 → 「〇分〇秒」
func formatPlayTime(_ seconds: Int) -> String {
    "\(seconds / 60)分\(seconds % 60)秒"
}

/// bak をうっすら敷き、黒 0.8 のオーバーレイを重ねる
struct ResultBackground: View {
    var body: some View {
        ZStack {
            Color.black
            Color.clear
                .overlay(Image("bak").resizable().scaledToFill())
                .clipped()
            Color.black.opacity(0.8)
        }
        .ignoresSafeArea()
        .onAppear {
            // Stop any ongoing BGM and play the end music once
            AudioManager.shared.stopBGM(named: "gamemusic")
//            AudioManager.shared.playOnce(named: "gameend")
        }
//        .onDisappear {
//            // Optionally stop end music when leaving result screen
//            AudioManager.shared.stopBGM(named: "gameend")
//        }
    }
}

/// ネオン発光グラデーションの大きなタイトル
struct GlowTitle: View {
    let text: String
    let colors: [Color]

    var body: some View {
        Text(text)
            .font(.system(size: 52, weight: .black, design: .rounded))
            .italic()
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .foregroundStyle(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            )
            .shadow(color: .yellow, radius: 6)
            .shadow(color: .yellow.opacity(0.8), radius: 16)
    }
}

/// リザルト（スコア・プレイ時間）
struct ResultTexts: View {
    let score: Int
    let playTime: Int
    /// 空でなければ「〇〇 さんの記録」を表示する（スクショ用）
    var playerName: String = ""

    var body: some View {
        VStack(spacing: 12) {
            if !playerName.isEmpty {
                Text("\(playerName) さんの記録")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text("SCORE  \(score)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("プレイ時間  \(formatPlayTime(playTime))")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .shadow(color: .orange.opacity(0.8), radius: 6)
    }
}

struct ResultButton: View {
    let title: String
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: 260)
                .padding(.vertical, 14)
                .background(
                    Capsule().fill(LinearGradient(colors: colors,
                                                  startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: colors.first!.opacity(0.8), radius: 8)
        }
    }
}
