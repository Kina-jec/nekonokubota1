import SwiftUI


struct CollectionItem: Identifiable {
    let id = UUID()
    // マージしたときの数字
    let value: Int
    // キャラクター名
    let name: String
    // Assetsに登録した画像名
    let imageName: String
    // キャラクターの説明
    let description: String
}
//画面の中心となる定義
struct CollectionView: View {

    //アプリを閉じても図鑑の解放状況を保持し続けるための仕組み
    @AppStorage("discoveredItems")
    private var discoveredItemsString = ""

    // トップ画面へ戻るため
    @Environment(\.dismiss) private var dismiss
    //図鑑管理
    let items = [
        CollectionItem(
            value: 2,
            name: "おばけ",
            imageName: "2",
            description: "城の門前で出会った、ちょっぴり寂しがり屋な魂の迷子。「ねえ、ボクをあそこに連れてって？」"
        ),

        CollectionItem(
            value: 4,
            name: "黒猫",
            imageName: "4",
            description: "おばけたちの魔力に誘われて闇から現れた。その琥珀色の瞳は、城へと続く秘密の小道を映している。"
        ),

        CollectionItem(
            value: 8,
            name: "かぼちゃ",
            imageName: "8",
            description: "ハロウィンの夜に目覚める意志を持ったランタン。不気味に笑いながら、暗い夜道を怪しく照らし出す。"
        ),

        CollectionItem(
            value: 16,
            name: "魔女の帽子",
            imageName: "16",
            description: "かつて大魔女が城に残したとされる遺物。意志を持っており、ふさわしい魔力を持つ主がマージに挑むのを待っている。"
        ),

        CollectionItem(
            value: 32,
            name: "ドクロ",
            imageName: "32",
            description: "城の地下迷宮を守る、陽気でちょっぴりお騒がせな門番。カタカタと骨を鳴らし、お前の覚悟を試しているようだ。"
        ),

        CollectionItem(
            value: 64,
            name: "魔法の薬",
            imageName: "64",
            description: "集まったハロウィンの魔力が結晶化した、怪しく光る秘薬。一口飲めば、城の奥深くに住む魔物たちの声が聞こえ始める。"
        ),

        CollectionItem(
            value: 128,
            name: "キャンディ",
            imageName: "128",
            description: "魔物たちが大好きな、特別な魔力を秘めたお菓子。これが放つ甘い香りが、城の主たちの眠りを呼び覚ます！"
        ),

        CollectionItem(
            value: 256,
            name: "コウモリ猫",
            imageName: "256",
            description: "キャンディの魔力によって、黒猫がさらなる進化を遂げた姿。夜空を静かに舞い、城の玉座の間へと先導してくれる。"
        ),

        CollectionItem(
            value: 512,
            name: "ヴァンパイア",
            imageName: "512",
            description: "「ほう、ここまで辿り着く人間がいるとはな…」古き眠りから目覚めた、気高きハロウィン城の若き貴族。"
        ),

        CollectionItem(
            value: 1024,
            name: "フランケンシュタイン",
            imageName: "1024",
            description: "城の最深部で命を吹き込まれた巨体の怪物。その圧倒的なパワーは、伝説の城の扉をこじ開けるための最後の鍵となる！"
        ),

        CollectionItem(
            value: 2048,
            name: "ハロウィン城",
            imageName: "2048",
            description: "【ゲームクリア！】すべてのマージの果てに現れた伝説の王城。君はすべての住人を引き連れ、見事この城の真の主となった！"
        )
    ]

    //図鑑を２列に変更
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    //キャラクター発見済みか判定
    func isDiscovered(_ value: Int) -> Bool {

        let discovered = discoveredItemsString
            .split(separator: ",")
            .compactMap { Int($0) }

        return discovered.contains(value)
    }
    
     
    var body: some View {

        // トップ画面の NavigationStack に乗るため、ここでは NavigationStack を使わない
        Group {

            ZStack {

                // ========================================
                // 背景画像（はみ出し防止のために maxWidth を画面内に固定）
                // ========================================

                Image("bak")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .ignoresSafeArea()
                Color.black
                    .opacity(0.18)
                    .ignoresSafeArea()

                
                ScrollView {

                    VStack(spacing: 16) {

                        VStack(spacing: 5) {

                            Text("ハロウィン図鑑")
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                                .foregroundStyle(.white)
                                .shadow(
                                    color: .black.opacity(0.8),
                                    radius: 2,
                                    x: 2,
                                    y: 2
                                )


                            Text("HALLOWEEN COLLECTION")
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                                .foregroundStyle(.yellow)
                                .tracking(2)
                        }

                        // タイトルの余白
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        // タイトル背景
                        .background(

                            RoundedRectangle(
                                cornerRadius: 22
                            )
                            .fill(
                                Color.purple.opacity(0.85)
                            )
                        )

                        // オレンジ色の枠
                        .overlay(

                            RoundedRectangle(
                                cornerRadius: 22
                            )
                            .stroke(
                                Color.orange,
                                lineWidth: 3
                            )
                        )

                        // タイトルの影
                        .shadow(
                            color: .black.opacity(0.5),
                            radius: 8,
                            x: 0,
                            y: 5
                        )

                        .padding(.horizontal, 20)
                        .padding(.top, 10)


                        
                        LazyVGrid(
                            columns: columns,
                            spacing: 12
                        ) {

                            ForEach(items) { item in

                                NavigationLink {

                                   
                                    CollectionDetailView(
                                        item: item,
                                        discovered:
                                            isDiscovered(item.value)
                                    )

                                } label: {

                                    
                                    CollectionCard(
                                        item: item,
                                        discovered:
                                            isDiscovered(item.value)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 80) // ホームに戻るボタンとの衝突回避
                    }
                }
            }
        }
        // トップ画面の「戻る」ボタン用に、ナビゲーションバーは非表示にする
        .toolbar(.hidden, for: .navigationBar)

        // 画面下に固定する「ホームへ戻る」ボタン
        .safeAreaInset(edge: .bottom) {

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
            .padding(.bottom, 8)
        }
    }
}

struct CollectionCard: View {

    // キャラクター情報
    let item: CollectionItem

    // 発見済みかどうか
    let discovered: Bool


    var body: some View {

        VStack(spacing: 4) {


            if discovered {

                // キャラクター画像
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 95)


                // 数字
                Text("\(item.value)")
                    .font(.title3)
                    .bold()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)


                // 名前
                Text(item.name)
                    .font(.subheadline)
                    .bold()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)


            } else {

               

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 16
                    )
                    .fill(
                        Color.black.opacity(0.7)
                    )


                    Text("？？？")
                        .font(.title)
                        .bold()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                }
                .frame(maxHeight: 95)


                Text("???")
                    .font(.title3)
                    .bold()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)


                Text("未発見")
                    .font(.subheadline)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }

        // 文字色
        .foregroundStyle(.white)

        // カードの横幅
        .frame(maxWidth: .infinity)

        // カードの高さ
        .frame(height: 175)

        .padding(.horizontal, 8)
        .padding(.vertical, 10)

        // カード背景
        .background(
            Color.black.opacity(0.55)
        )

        // 角を丸くする
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )

        // 枠線
        .overlay {

            RoundedRectangle(
                cornerRadius: 16
            )
            .stroke(
                discovered
                    ? Color.orange
                    : Color.gray,
                lineWidth: 2
            )
        }
    }
}




struct CollectionDetailView: View {

    // キャラクター情報
    let item: CollectionItem

    // 発見済みかどうか
    let discovered: Bool


    var body: some View {

        ZStack {

            

            Image("bak")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .ignoresSafeArea()


            

            Color.black
                .opacity(0.45)
                .ignoresSafeArea()


            ScrollView {
                VStack(spacing: 20) {

                    
                    if discovered {

                        // キャラクター画像
                        Image(item.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxWidth: 220,
                                maxHeight: 220
                            )


                        // キャラクター名
                        Text(item.name)
                            .font(
                                .system(
                                    size: 30,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)


                        // マージした数字
                        Text(
                            "MERGE VALUE : \(item.value)"
                        )
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.orange)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)


                        // 説明
                        Text(item.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)


                    } else {

                        

                        ZStack {

                            Circle()
                                .fill(
                                    Color.black.opacity(0.6)
                                )
                                .frame(
                                    maxWidth: 220,
                                    maxHeight: 220
                                )


                            Text("？")
                                .font(
                                    .system(size: 120)
                                )
                                .bold()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .foregroundStyle(.gray)
                        }


                        Text("？？？")
                            .font(.largeTitle)
                            .bold()


                        Text(
                            "未だ見ぬ闇の住人"
                        )
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)


                        Text(
                            """
                            ゲーム内で魔力を融合し、
                            この住人の封印を解き明かすと、
                            真の姿と物語が解放されます！
                            """
                        )
                        .multilineTextAlignment(.center)
                    }
                }
                .foregroundStyle(.white)
                .padding(20)
                // 詳細情報を読みやすくする
                .background(
                    Color.black.opacity(0.45)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 25
                    )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 30)
            }
        }

        .navigationTitle("図鑑")

        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}




func discoverItem(_ value: Int) {

    var discovered = UserDefaults.standard
        .string(
            forKey: "discoveredItems"
        )?
        .split(separator: ",")
        .compactMap {
            Int($0)
        } ?? []


    if discovered.contains(value) {
        return
    }

    discovered.append(value)

    let text = discovered
        .map {
            String($0)
        }
        .joined(
            separator: ","
        )

    UserDefaults.standard.set(
        text,
        forKey: "discoveredItems"
    )
}


#Preview {

    CollectionView()
}
