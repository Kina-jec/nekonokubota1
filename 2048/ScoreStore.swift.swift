import Foundation

// 1回のプレイ記録（ニックネームとスコアをセットで保持）
struct PlayRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    let name: String
    let score: Int
    let date: Date
}

// プレイ記録の保存・読み込みをまとめた窓口
// ※ 図鑑の保存先 "discoveredItems" とは別のキーを使うので、図鑑には影響しない
enum ScoreStore {
    static let recordsKey = "playRecords"         // 新形式（JSON）
    static let legacyKey = "scoreHistory"         // 旧形式（スコアだけの配列）
    static let highScoreKey = "highScore"         // ハイスコア（高速に読むため別保存）
    static let playerCounterKey = "playerCounter" // 名前未入力で始めた人の通し番号

    // 名前が取得できないときの予備の名前（旧データの引き継ぎ用）
    static let defaultName = "Guest"

    // 未入力時の名前（半角英数字とスペースのみ → 文字化けしない）
    private static func defaultName(number: Int) -> String {
        "User \(number)"
    }

    // 次に割り当てる名前を、カウントを進めずに確認する（ポップアップの案内表示用）
    static func peekNextDefaultName() -> String {
        let next = UserDefaults.standard.integer(forKey: playerCounterKey) + 1
        return defaultName(number: next)
    }

    // 名前未入力で始めたときに呼ぶ。「User 1」「User 2」…と番号を進めて返す
    static func nextDefaultName() -> String {
        let next = UserDefaults.standard.integer(forKey: playerCounterKey) + 1
        UserDefaults.standard.set(next, forKey: playerCounterKey)
        return defaultName(number: next)
    }

    // 旧バージョンで保存された日本語の自動名を英語表記に揃える（表示用・保存データは書き換えない）
    private static func normalized(_ name: String) -> String {
        if name == "名無しさん" { return defaultName }
        if name.hasPrefix("ユーザー") {
            let rest = name.dropFirst("ユーザー".count)
            if !rest.isEmpty, rest.allSatisfy({ $0.isNumber }) {
                return "User \(rest)"
            }
        }
        return name
    }

    // 全記録を読み込む（旧形式が残っていれば自動で引き継ぐ）
    static func load() -> [PlayRecord] {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: recordsKey),
           let records = try? JSONDecoder().decode([PlayRecord].self, from: data) {
            return records.map {
                PlayRecord(id: $0.id, name: normalized($0.name), score: $0.score, date: $0.date)
            }
        }

        // 旧形式 [Int] からの引き継ぎ
        if let legacy = defaults.array(forKey: legacyKey) as? [Int], !legacy.isEmpty {
            let migrated = legacy.map { PlayRecord(name: defaultName, score: $0, date: Date()) }
            save(migrated)
            defaults.removeObject(forKey: legacyKey)
            return migrated
        }

        return []
    }

    // 全記録を保存する（ハイスコアも一緒に更新する）
    static func save(_ records: [PlayRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
        UserDefaults.standard.set(records.map(\.score).max() ?? 0, forKey: highScoreKey)
    }

    // 1件追加する
    static func add(name: String, score: Int) {
        var records = load()
        records.append(PlayRecord(name: name, score: score, date: Date()))
        save(records)
    }

    // 端末の最高スコア
    static var highScore: Int {
        if let stored = UserDefaults.standard.object(forKey: highScoreKey) as? Int {
            return stored
        }
        return load().map(\.score).max() ?? 0
    }
}
