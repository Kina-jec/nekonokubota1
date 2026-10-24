import Foundation
import AVFoundation
import SwiftUI

//アプリ全体で音声を一元管理し、BGMや効果音を重複させずに正しく再生・停止させるための仕組み
final class AudioManager {
    static let shared = AudioManager()
    private init() {}

    // BGM用（ループ再生）。効果音とは別のプレーヤーで管理する
    private var bgmPlayer: AVAudioPlayer?
    private var currentBGMName: String?

    // 効果音用（鳴っている間は保持し、終わったら破棄する）
    private var sfxPlayers: [(name: String, player: AVAudioPlayer)] = []

    // 他のアプリの音と共存できるようにオーディオセッションを設定する
    private func activateSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioManager] Failed to set audio session: \(error)")
        }
    }

    func playBGM(named name: String, withExtension ext: String = "mp3") {
        // すでに同じBGMが再生中なら、頭から流し直さずそのまま続ける
        if currentBGMName == name, bgmPlayer?.isPlaying == true { return }

        activateSession()

        //指定された名前と拡張子の音源ファイルがアプリ内に存在するか確認し、見つからなければ処理を中断する安全装置
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("[AudioManager] Resource not found: \(name).\(ext)")
            return
        }
        do {
            //現在流れているBGMを止め、新しいBGMを読み込んで無限ループで再生し、再生中の情報として記録する切り替え処理
            bgmPlayer?.stop()
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1 // 無限ループ
            newPlayer.prepareToPlay()
            newPlayer.play()
            bgmPlayer = newPlayer
            currentBGMName = name
        } catch {
            print("[AudioManager] Failed to initialize player: \(error)")
        }
    }

    func stopBGM(named name: String) {
        // 指定した名前のBGMが鳴っているときだけ止める（別のBGMを巻き込まない）
        if currentBGMName == name {
            bgmPlayer?.stop()
            bgmPlayer = nil
            currentBGMName = nil
        }
        // 同じ名前の効果音（gameend など）が鳴っていれば止める
        sfxPlayers.removeAll { item in
            guard item.name == name else { return false }
            item.player.stop()
            return true
        }
    }

    //現在再生中のBGMを一時停止し、その後いつでも停止した位置から再生を再開できるようにする機能
    func pauseBGM() {
        bgmPlayer?.pause()
    }

    func resumeBGM() {
        bgmPlayer?.play()
    }

    // 効果音を1回だけ再生する（BGMは止めない）
    func playOnce(named name: String, withExtension ext: String = "mp3") {
        activateSession()
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("[AudioManager] Resource not found: \(name).\(ext)")
            return
        }
        do {
            // 再生が終わった効果音を片付ける
            sfxPlayers.removeAll { !$0.player.isPlaying }

            let sfx = try AVAudioPlayer(contentsOf: url)
            sfx.numberOfLoops = 0
            sfx.prepareToPlay()
            sfx.play()
            sfxPlayers.append((name: name, player: sfx))
        } catch {
            print("[AudioManager] Failed to initialize one-shot player: \(error)")
        }
    }
}
