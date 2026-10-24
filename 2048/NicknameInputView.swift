import SwiftUI
import UIKit

// ============================================================
//  呪いの名前ブロック（軽量NGワードフィルター）
//  - 辞書ファイルは使わず、コード内の厳選ワードだけで判定（容量ほぼ増えない）
//  - 世界中の文字（ハングル・キリル・アラビア・絵文字など）の入力は許可
// ============================================================
enum NameCurseFilter {

    // MARK: - NGワード辞書
    // 判定前に、辞書側も入力側と同じ正規化（全角半角統一・カタカナ→ひらがな・記号/空白/「っ」「ー」除去・連続文字の圧縮）をかける。
    // なので「くっそ」「クソー」「ｸｿ」「く そ」「くそそそ」は、すべて「くそ」として判定される。

    // 英語：部分一致（"fuck" が入っていれば NG）
    private static let englishWords: [String] = [
        "fuck", "fck", "fvck", "motherfucker", "shit", "bitch", "bastard", "asshole",
        "cunt", "whore", "slut", "pussy", "nigger", "nigga", "faggot", "retard",
        "nazi", "hitler", "porn", "penis", "vagina", "dildo", "blowjob",
        "cumshot", "rapist", "killyou","sine","tinpo","manpo","manko","tinko"
    ]

    // 英語：完全一致のみ（"ass" "dick" などは grass / Dickson を巻き込むため、名前全体がそれと一致した時だけ NG）
    private static let englishExactWords: [String] = [
        "ass", "arse", "dick", "cock", "cum", "sex", "rape", "fag",
        "tits", "anus", "twat", "wank", "kys"
    ]

    // 日本語：部分一致
    private static let japaneseWords: [String] = [
        "しね", "死ね", "氏ね", "ころす", "殺す", "くたばれ",
        "うんこ", "ちんこ", "ちんぽ", "まんこ", "きちがい", "気違い",
        "ちんちん", "ふぁっく", "せっくす", "おっぱい", "ぶっころ",
        "ころしてやる", "しんでしまえ", "糞","ごみ","消えろ","きえろ",
        "うせろ","ちんかす","きもい","ぶちころ","くたばれ","じさつ","ごみかす","あなる","ぱぱかつ","しゃぶ","おまえ"
        ,"きさま","きしょい","きえちまえ","きしょあぷ"
    ]

    // 短くて他の言葉に紛れやすいワード：名前の「先頭」「末尾」「全体」にある時だけ NG
    // 例：「くそ」は「おくそく」「ふくそう」の中に出てくるので部分一致にはしない
    private static let edgeWords: [String] = [
        "くそ", "kuso", "unko", "chinko", "manko", "chinpo"
    ]

    // 韓国語・中国語（部分一致）
    private static let otherWords: [String] = [
        "씨발", "시발", "병신", "개새끼", "좆",
        "傻逼", "操你", "他妈的", "他媽的"
    ]

    // 誤判定の回避（例：「シネマ」→「しねま」が「しね」に引っかからないようにする）
    private static let safeWords: [String] = ["しねま"]

    // 数字・記号による当て字（sh1t → shit, $hit → shit, a$$ → ass）
    private static let leetMap: [Character: Character] = [
        "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t",
        "@": "a", "$": "s", "!": "i"
    ]

    // 判定から取り除く文字（スペース・記号・絵文字・結合文字・制御文字・見えない文字・「ー」「っ」）
    private static let removableChars: CharacterSet = {
        var set = CharacterSet.whitespacesAndNewlines
        set.formUnion(.punctuationCharacters)
        set.formUnion(.symbols)
        set.formUnion(.controlCharacters)
        set.formUnion(.nonBaseCharacters)
        set.formUnion(CharacterSet(charactersIn: "\u{200B}\u{200C}\u{200D}\u{2060}\u{FEFF}"))
        set.formUnion(CharacterSet(charactersIn: "\u{30FC}\u{3063}"))
        return set
    }()

    // MARK: - 正規化

    //  1. 全角→半角などを統一(NFKC)して小文字化   例：ＦＵＣＫ → fuck
    //  2. （leet=true のとき）数字・記号の当て字を戻す   例：sh1t → shit
    //  3. カタカナ → ひらがな                      例：ウンコ → うんこ
    //  4. スペース・記号・結合文字・制御文字・「っ」「ー」を除去して連結  例：「く っ そ ー」 → くそ
    private static func normalized(_ raw: String, leet: Bool) -> String {
        let unified: String = raw.precomposedStringWithCompatibilityMapping
        var lower: String = unified.lowercased()

        if leet {
            var mapped = ""
            for ch in lower {
                mapped.append(leetMap[ch] ?? ch)
            }
            lower = mapped
        }

        let hiragana: String = lower.applyingTransform(.hiraganaToKatakana, reverse: true) ?? lower

        var result = String.UnicodeScalarView()
        for scalar in hiragana.unicodeScalars where !removableChars.contains(scalar) {
            result.append(scalar)
        }
        return String(result)
    }

    // 同じ文字の連続を1つにまとめる   例：くそそそ → くそ / fuuuck → fuck
    private static func squash(_ s: String) -> String {
        var out = ""
        var prev: Character? = nil
        for ch in s {
            if ch != prev { out.append(ch) }
            prev = ch
        }
        return out
    }

    // 辞書ワードを「判定用の形」に変換する
    private static func key(_ word: String) -> String {
        squash(normalized(word, leet: false))
    }

    // 辞書側も最初に1回だけ変換しておく
    private static let substringKeys: [String] = {
        let all: [String] = englishWords + japaneseWords + otherWords
        return all.map { NameCurseFilter.key($0) }
    }()

    private static let edgeKeys: [String] = edgeWords.map { NameCurseFilter.key($0) }

    private static let exactKeys: Set<String> = {
        let keys: [String] = englishExactWords.map { NameCurseFilter.normalized($0, leet: false) }
        return Set(keys)
    }()

    private static let safeKeys: [String] = safeWords.map { NameCurseFilter.normalized($0, leet: false) }

    // MARK: - 各チェック

    // 同じ文字・絵文字が4回以上連続していたら true
    private static func hasRepeat(_ raw: String) -> Bool {
        let chars: [Character] = Array(raw)
        guard chars.count >= 4 else { return false }
        for i in 0...(chars.count - 4) {
            let c = chars[i]
            if c == chars[i + 1] && c == chars[i + 2] && c == chars[i + 3] { return true }
        }
        return false
    }

    // Zalgo文字対策：1文字に結合文字（上下に積まれる記号）が5個以上乗っていたら true
    private static func hasZalgo(_ raw: String) -> Bool {
        for ch in raw {
            var marks = 0
            for scalar in ch.unicodeScalars where CharacterSet.nonBaseCharacters.contains(scalar) {
                marks += 1
            }
            if marks > 4 { return true }
        }
        return false
    }

    // ※ `||` とクロージャを1式に連ねると型チェックが重くなるため、for 文で分けている
    private static func hasBadWord(_ raw: String) -> Bool {
        // 通常の正規化と、当て字（sh1t など）を戻した正規化の2パターンで調べる
        for useLeet in [false, true] {
            var plain: String = normalized(raw, leet: useLeet)
            for safe in safeKeys {
                plain = plain.replacingOccurrences(of: safe, with: "")
            }
            if plain.isEmpty { continue }

            // 1. 完全一致のみのワード
            if exactKeys.contains(plain) { return true }

            let squashed: String = squash(plain)

            // 2. 部分一致のワード
            for w in substringKeys where squashed.contains(w) { return true }

            // 3. 先頭・末尾・全体のみのワード
            for w in edgeKeys {
                if squashed == w || squashed.hasPrefix(w) || squashed.hasSuffix(w) { return true }
            }
        }
        return false
    }

    /// 呪われた名前なら true（NGワード・連打・Zalgo のどれか）
    static func isCursed(_ raw: String) -> Bool {
        if hasRepeat(raw) { return true }
        if hasZalgo(raw) { return true }
        return hasBadWord(raw)
    }
}

// 左右に揺れるエフェクト（値が 1 増えるたびに 4往復する）
private struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 9
    var shakes: CGFloat = 4
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx: CGFloat = travel * sin(animatableData * .pi * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}

// 「城の呪い」エラーメッセージ（古い羊皮紙に inkRed の文字、赤い光が不気味に明滅）
private struct CurseMessageView: View {
    let shake: CGFloat
    @State private var flicker = false

    private let inkRed = Color(red: 0.45, green: 0.05, blue: 0.05)

    private let parchment = LinearGradient(
        colors: [Color(red: 0.97, green: 0.90, blue: 0.72),
                 Color(red: 0.88, green: 0.74, blue: 0.48)],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        content
            .foregroundStyle(inkRed)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(parchment))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(inkRed, lineWidth: 2))
            .shadow(color: Color.red.opacity(flicker ? 0.9 : 0.3), radius: flicker ? 14 : 4)
            .modifier(ShakeEffect(animatableData: shake))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    flicker = true
                }
            }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 1)
            Text("おっと！その名前には城の呪いがかけられているようだ。別の名前を入力してくれ！")
                .font(.system(size: 15, weight: .black, design: .serif))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// スタートボタンを押すたびに毎回表示する、ニックネーム入力ポップアップ
struct NicknameInputView: View {
    /// 開始が決まったときに呼ばれる（決定した名前を渡す）
    var onStart: (String) -> Void
    /// 背景をタップして閉じたときに呼ばれる
    var onCancel: () -> Void

    @State private var name = ""
    @FocusState private var isFocused: Bool
    // 呪いの演出
    @State private var showCurse = false
    @State private var shakeCount: CGFloat = 0

    private let maxLength = 12

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var isEmpty: Bool { trimmed.isEmpty }

    // 未入力のときと入力済みのときでボタンの文字を切り替える
    private var buttonTitle: String {
        isEmpty ? "名前を登録せずにスタート" : "この名前でゲームスタート！"
    }

    // ボタンの色（型を明示して型チェックを軽くする）
    private var buttonColors: [Color] {
        if isEmpty { return [Color.gray, Color.indigo] }
        return [Color.orange, Color.purple]
    }

    private var buttonShadowColor: Color {
        isEmpty ? Color.indigo : Color.orange
    }

    private func start() {
        // 未入力なら「User 1」「User 2」…と番号を進めて割り当てる（自動名はチェック不要）
        if isEmpty {
            onStart(ScoreStore.nextDefaultName())
            return
        }
        // 呪われた名前（NGワード・連打）はゲームを始めさせない
        if NameCurseFilter.isCursed(trimmed) {
            rejectName()
            return
        }
        onStart(trimmed)
    }

    // 城の呪い演出：メッセージを出して、ブルッと揺らす
    private func rejectName() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            showCurse = true
        }
        // 表示した直後に揺らす（初回も揺れるように少しだけ待つ）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.5)) {
                shakeCount += 1
            }
        }
    }

    private func handleNameChange(_ newValue: String) {
        // 文字数の上限を超えた分は切り捨てる
        if newValue.count > maxLength {
            name = String(newValue.prefix(maxLength))
        }
        // 名前を打ち直したら、呪いのメッセージは消す
        if showCurse {
            withAnimation(.easeOut(duration: 0.2)) { showCurse = false }
        }
    }

    // MARK: - パーツ分割（body を軽くするため）

    private var dimBackground: some View {
        Color.black.opacity(0.6)
            .ignoresSafeArea()
            .onTapGesture {
                // キーボードが出ているときは、まずキーボードを閉じる
                if isFocused {
                    isFocused = false
                } else {
                    onCancel()
                }
            }
    }

    private var titleRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundStyle(Color.orange)
            Text("ニックネーム")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
            Image(systemName: "flame.fill")
                .foregroundStyle(Color.orange)
        }
        .font(.system(size: 24, weight: .bold))
        .shadow(color: Color.orange, radius: 6)
    }

    private var nameField: some View {
        let borderColor: Color = showCurse ? Color.red : Color.orange
        return TextField("ニックネーム", text: $name)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: 2) // 呪われている間は枠が赤くなる
            )
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit { isFocused = false }
            .onChange(of: name) { newValue in
                handleNameChange(newValue)
            }
    }

    private var startButton: some View {
        let gradient = LinearGradient(
            colors: buttonColors,
            startPoint: .leading,
            endPoint: .trailing
        )
        return Button {
            start()
        } label: {
            ZStack {
                Text(buttonTitle)
                    .id(buttonTitle)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(gradient))
            .shadow(color: buttonShadowColor.opacity(0.7), radius: 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isEmpty)
        }
    }

    private var cardContent: some View {
        VStack(spacing: 18) {
            titleRow

            Text("あなたの名前を教えてください（\(maxLength)文字まで）")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))

            // 未入力のときに割り当てられる名前の案内
            if isEmpty {
                Text("未入力の場合は「\(ScoreStore.peekNextDefaultName())」として記録されます")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            nameField

            // 城の呪いメッセージ（NGワード・連打を検知したときだけ表示）
            if showCurse {
                CurseMessageView(shake: shakeCount)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            startButton
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.purple.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.orange, lineWidth: 3)
        )
        .padding(.horizontal, 28)
    }

    var body: some View {
        ZStack {
            dimBackground
            cardContent
        }
        .onAppear {
            // ポップアップが出たらすぐ入力できるようにする
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}

#Preview {
    NicknameInputView(onStart: { _ in }, onCancel: {})
}
