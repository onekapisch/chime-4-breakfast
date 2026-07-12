import AppKit
import AVFoundation

@MainActor
protocol SoundPlaying: AnyObject {
    @discardableResult
    func play(soundID: String) -> Bool
}

@MainActor
final class SoundEngine: SoundPlaying {
    private var activePlayer: AVAudioPlayer?
    private let speechSynthesizer = AVSpeechSynthesizer()

    @discardableResult
    func play(soundID: String) -> Bool {
        if let spokenText = spokenText(for: soundID) {
            activePlayer?.stop()
            speechSynthesizer.stopSpeaking(at: .immediate)
            speechSynthesizer.speak(AVSpeechUtterance(string: spokenText))
            chimeDebugLog("SOUND speech id=\(soundID) queued=true")
            return true
        }

        guard let option = SoundOption.option(for: soundID) else {
            chimeDebugLog("SOUND invalid id=\(soundID)")
            return false
        }

        guard let url = bundledSoundURL(named: option.filename) else {
            chimeDebugLog("SOUND missing filename=\(option.filename)")
            NSSound.beep()
            return false
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.prepareToPlay()

            activePlayer?.stop()
            activePlayer = player

            let started = player.play()
            chimeDebugLog(
                "SOUND play id=\(soundID) file=\(url.lastPathComponent) started=\(started) duration=\(player.duration)"
            )

            if !started {
                NSSound.beep()
            }
            return started
        } catch {
            chimeDebugLog("SOUND error id=\(soundID) file=\(url.lastPathComponent) error=\(error.localizedDescription)")
            NSSound.beep()
            return false
        }
    }

    private func bundledSoundURL(named filename: String) -> URL? {
        let fileURL = URL(fileURLWithPath: filename)
        let name = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        guard !name.isEmpty, !ext.isEmpty else { return nil }

        return Bundle.main.url(forResource: name, withExtension: ext)
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Sounds")
    }

    private func spokenText(for soundID: String) -> String? {
        switch soundID {
        case "spoken-codex":
            "Codex"
        case "spoken-claude":
            "Claude"
        default:
            nil
        }
    }
}
