import SwiftUI

struct RankingView: View {
    @Environment(\.dismiss) var dismiss
    // 横スワイプ用（0: ランキング / 1: 戦歴）
    @State private var page = 0
    @GestureState private var dragX: CGFloat = 0
    // ニックネーム付きの記録（スコアと名前をセットで保持）
    @State private var records: [PlayRecord] = []

    // スコアだけの配列（BEST SCORE や空判定に使用）
    var scores: [Int] { records.map(\.score) }

    // 上位5件
    var rankingRecords: [PlayRecord] {
        Array(records.sorted { $0.score > $1.score }.prefix(5))
    }

    var body: some View {

        ZStack {

            
            Image("bak")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            Color.black
                .opacity(0.35)
                .ignoresSafeArea()


            
            GeometryReader { geo in

                HStack(spacing: 0) {

                    // 1ページ目
                    rankingPage
                        .frame(width: geo.size.width, height: geo.size.height)

                    // 2ページ目
                    historyPage
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .offset(x: -CGFloat(page) * geo.size.width + dragX)
                .animation(.easeOut(duration: 0.25), value: page)
                .frame(width: geo.size.width,
                       height: geo.size.height,
                       alignment: .leading)
                .clipped()
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .updating($dragX) { value, state, _ in
                            let w = value.translation.width
                            guard abs(w) > abs(value.translation.height) else { return }
                            // 端のページでは外側へ引っ張れないようにする
                            state = (page == 0) ? min(0, w) : max(0, w)
                        }
                        .onEnded { value in
                            let w = value.translation.width
                            guard abs(w) > abs(value.translation.height) else { return }
                            if w < -50 {
                                page = 1      // 左スワイプ → 戦歴
                            } else if w > 50 {
                                page = 0      // 右スワイプ → ランキング
                            }
                        }
                )
                // ページ位置のドット
                .overlay(alignment: .bottom) {
                    HStack(spacing: 8) {
                        ForEach(0..<2, id: \.self) { i in
                            Circle()
                                .fill(Color.white.opacity(i == page ? 1.0 : 0.4))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 6)
                    .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
           loadScores()
        }
    }


    
    var rankingPage: some View {

        VStack(spacing: 12) {

            // タイトル
            Text("SCORE RANKING")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    Color.purple.opacity(0.85)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.orange,
                            lineWidth: 3
                        )
                )


           
            VStack(spacing: 5) {

                Text("BEST SCORE")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.purple)

                Text("\(scores.max() ?? 0)")
                    .font(
                        .system(
                            size: 50,
                            weight: .black
                        )
                    )
                    .foregroundStyle(.orange)

                Text("POINTS")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.purple)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Color(
                    red: 1.0,
                    green: 0.92,
                    blue: 0.72
                )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 22)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        Color.orange,
                        lineWidth: 3
                    )
            )
            .padding(.horizontal, 25)


            
            VStack(spacing: 10) {

                ForEach(
                    rankingRecords.indices,
                    id: \.self
                ) { index in

                    let record = rankingRecords[index]
                    let score = record.score

                    HStack(spacing: 12) {

                        // 順位
                        Text("\(index + 1)")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.white)
                            .frame(
                                width: 45,
                                height: 45
                            )
                            .background(
                                rankColor(index)
                            )
                            .clipShape(Circle())

                        // 順位とニックネーム
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(index + 1)位")
                                .font(.caption)
                                .bold()
                            Text(record.name)
                                .font(.headline)
                                .bold()
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)

                        Spacer()

                        Text("\(score)")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.yellow)

                        Text("点")
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .background(
                        Color.purple.opacity(0.75)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }


                if scores.isEmpty {

                    Text("まだスコアがありません")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                }
            }
            .padding(15)
            .background(
                Color.black.opacity(0.6)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 25)
            )
            .padding(.horizontal, 20)


            Spacer()


            Text("左にスワイプして戦歴を見る")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))


            // ホームボタン
            Button {
                dismiss()
                // ホーム画面へ戻る処理

            } label: {

                Text("ホームへ戻る")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)
                    .frame(width: 180)
                    .padding(.vertical, 13)
                    .background(Color.orange)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
            }
            .padding(.bottom, 30)
        }
        .padding(.top, 30)
    }


 
    var historyPage: some View {

        VStack(spacing: 20) {

            // タイトル
            Text("SCORE HISTORY")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    Color.orange.opacity(0.9)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.purple,
                            lineWidth: 3
                        )
                )


            Text("今までの戦歴")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)



            if scores.isEmpty {

                Spacer()

                Text("まだ戦歴がありません")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

            } else {

                ScrollView {

                    VStack(spacing: 10) {

                        ForEach(
                            Array(records.enumerated()),
                            id: \.offset
                        ) { index, record in

                            let score = record.score

                            HStack {

                                // プレイ回数とニックネーム
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(index + 1)回目")
                                        .font(.headline)
                                        .bold()
                                        .foregroundStyle(.white)
                                    Text(record.name)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                        .lineLimit(1)
                                }

                                Spacer()

                                // スコア
                                Text("\(score)")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.yellow)

                                Text("点")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            .background(
                                Color.purple.opacity(0.75)
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 15
                                )
                            )
                        }
                    }
                    .padding()
                }
                .background(
                    Color.black.opacity(0.55)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 25)
                )
                .padding(.horizontal, 20)
            }


            Text("右にスワイプしてランキングへ戻る")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))


            Button {

                dismiss()

            } label: {

                Text("ホームへ戻る")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)
                    .frame(width: 180)
                    .padding(.vertical, 13)
                    .background(Color.orange)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
            }
            .padding(.bottom, 30)
        }
        .padding(.top, 30)
        .navigationBarBackButtonHidden(true)
    }


 
    func loadScores() {

        records = ScoreStore.load()
    }



    func rankColor(_ index: Int) -> Color {

        if index == 0 {

            return .orange

        } else if index == 1 {

            return .purple

        } else if index == 2 {

            return .brown

        } else {

            return .gray
        }
    }
}


#Preview {
    RankingView()
}
