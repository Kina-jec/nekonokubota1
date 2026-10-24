import SwiftUI
import Combine
import AVFoundation

//プレイヤーが画面をスワイプした「4つの方向（上・下・左・右）」を表す
enum SwipeDirection { case up, down, left, right }
//• ゲームの「3つの状態（プレイ中、クリア、ゲームオーバー）」を表す
enum GameState { case playing, cleared, gameOver }
//タイルのデータ構造（設計図）」の定義
struct Tile: Identifiable, Equatable {
    let id = UUID()
    var value: Int
    var row: Int
    var col: Int
}
//コンボ演出の文字（2連鎖など）を画面に出すためのデータ設計図」の定義
struct ComboItem: Identifiable {
    let id = UUID()
    let text: String
}
//ゲームの「脳みそデータやルール」となる中心的なクラス（GameModel）の開始部分の宣言
@MainActor
final class GameModel: ObservableObject {
    static let size = 4
//ゲームの状況（盤面、スコア、時間、状態、コンボ）をリアルタイムに管理し、変化したら画面を自動で書き換えるための変数宣言
    @Published private(set) var tiles: [Tile] = []
    @Published private(set) var score = 0
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var state: GameState = .playing
    @Published var combos: [ComboItem] = []

    init() { reset() }

    //ゲームを完全に最初からやり直すための、リセット（初期化）処理
    func reset() {
        tiles = []
        score = 0
        elapsedSeconds = 0
        combos = []
        state = .playing
        spawnTile()
        spawnTile()
    }

    //1秒ごとにカウントをする（プレイ中のみ計測開始）
    func tick() {
        guard state == .playing else { return }
        elapsedSeconds += 1
    }

    //画面に表示されたコンボ演出の文字2連鎖！など,表示したあとに消去する処理
    func removeCombo(id: UUID) {
        combos.removeAll { $0.id == id }
    }

    //空いているマスをランダムに1つ選び、そこに新しいタイル90%の確率で「2」、10%の確率で「４」を1枚出現させる処理
    private func spawnTile() {
        let occupied = Set(tiles.map { $0.row * Self.size + $0.col })
        let empties = (0..<(Self.size * Self.size)).filter { !occupied.contains($0) }
        guard let cell = empties.randomElement() else { return }
        let value = Int.random(in: 0..<10) == 0 ? 4 : 2
        tiles.append(Tile(value: value, row: cell / Self.size, col: cell % Self.size))
        // 出現したタイル（2・4）も図鑑に登録する
        unlockPokedex(for: value)
    }

    //スワイプした方向（上・下・左・右）に合わせて、マスの数え方（進む向き）を自動で切り替えるための座標変換処理
    //本来であれば別の書き方を行い４パターンを記入しなければならないがこのワンパターンで全ての方向対応可能になる。
    private func coordinate(_ dir: SwipeDirection, line i: Int, index j: Int) -> (row: Int, col: Int) {
        let last = Self.size - 1
        switch dir {
        case .left:  return (i, j)
        case .right: return (i, last - j)
        case .up:    return (j, i)
        case .down:  return (last - j, i)
        }
    }
    //ゲームプレイ中のみスワイプ操作を受け付け、ゲームクリアやゲームオーバー時にはタイルを動かさないようにする安全機能
    //ない場合正しいスコアの記録キャラのアンロックなどが正常に動かなくなるため
    func move(_ dir: SwipeDirection) {
        guard state == .playing else { return }
        //バラバラに管理されているすべてのタイルの位置を、縦4マス×横4マスの2次元グリッドに整理して配置し直す処理
        //共通化して楽に計算するため
        var grid = Array(repeating: Array(repeating: Tile?.none, count: Self.size), count: Self.size)
        for t in tiles { grid[t.row][t.col] = t }

        var newTiles: [Tile] = []
        var changed = false
        var mergeCount = 0
        var gained = 0
        
        //スワイプされた方向に合わせて、各列のタイルを確認し、同じ数字が連続した場合は合体にし、同時に図鑑の解放とスコア加算を行う、ゲームの核心となる処理
        for i in 0..<Self.size {
            var out: [Tile] = []
            var mergedFlags: [Bool] = []
            for j in 0..<Self.size {
                let pos = coordinate(dir, line: i, index: j)
                guard let t = grid[pos.row][pos.col] else { continue }
                if let last = out.last, last.value == t.value, mergedFlags.last == false {
                    out[out.count - 1].value *= 2
                    unlockPokedex(for: out[out.count - 1].value)
                    mergedFlags[mergedFlags.count - 1] = true
                    gained += out[out.count - 1].value
                    mergeCount += 1
                    changed = true
                } else {
                    out.append(t)
                    mergedFlags.append(false)
                }
            }
            //合体・移動したあとの新しいタイルの位置を確定させ、実際に「タイルが動いたかどうか」を判定する処理
            for (idx, var t) in out.enumerated() {
                let pos = coordinate(dir, line: i, index: idx)
                if t.row != pos.row || t.col != pos.col { changed = true }
                t.row = pos.row
                t.col = pos.col
                newTiles.append(t)
            }
        }
        //スワイプしてもタイルが1マスも動かなかった場合に、それ以降の「新しいタイルの出現」や「スコア計算」をスキップして処理を中断する防衛線
        //ゲームオーバーになってしまう理不尽な現象
        guard changed else { return }

        //ゲームクリアの条件を満たしたかチェック。瞬時に
        let cleared = newTiles.contains { $0.value == 2048 }

        // コンボボーナス：2コンボなら2倍、3コンボなら3倍…（1回以下は等倍）
        let comboMultiplier = max(1, mergeCount)
        let bonusScore = gained * comboMultiplier

        withAnimation(.easeInOut(duration: 0.14)) {
            tiles = newTiles
            score += bonusScore
        }
        //2048タイルがあった場合即座にゲームを終了させてクリア画面へ移行する分岐処理
        if mergeCount >= 2 { showCombo(mergeCount) }

        if cleared {
            stopGame(.cleared)
            return
        }
        //アニメーションありでのタイル生成
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            spawnTile()
        }
        //完全に詰んでいればゲームオーバー画面へ移行する最終判定
        if isStuck() { stopGame(.gameOver) }
    }
    //図鑑開放のアンロック
    private func unlockPokedex(for value: Int) {
        // 図鑑画面（CollectionView）と同じ保存先 "discoveredItems" に登録する
        // すでに登録済みの数字は discoverItem の中で何もせず終了する
        discoverItem(value)
    }

    /// 入力・タイマーは即停止し、画面だけ少し遅れてフェードインさせる
    private func stopGame(_ newState: GameState) {
        withAnimation(.easeIn(duration: 0.5).delay(0.6)) {
            state = newState
        }
    }

    //コンボ
    private func showCombo(_ count: Int) {
        let text: String
        switch count {
        case 2:  text = "2 COMBO!"
        case 3:  text = "3 COMBO!!"
        default: text = "MAX COMBO!!!"
        }
        combos.append(ComboItem(text: text))
        
        AudioManager.shared.playOnce(named: "combomusic")
    }
    

    //詰み判定
    private func isStuck() -> Bool {
        guard tiles.count == Self.size * Self.size else { return false }
        var values = Array(repeating: Array(repeating: 0, count: Self.size), count: Self.size)
        for t in tiles { values[t.row][t.col] = t.value }
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if c + 1 < Self.size, values[r][c] == values[r][c + 1] { return false }
                if r + 1 < Self.size, values[r][c] == values[r + 1][c] { return false }
            }
        }
        return true
    }
}
