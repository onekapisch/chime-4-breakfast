import AppKit

@MainActor
final class SoundEngine {
    private var activeSound: NSSound?

    func play(soundID: String) {
        guard let option = SoundOption.option(for: soundID) else { return }

        if let sound = loadBundledSound(named: option.filename) {
            activeSound?.stop()
            activeSound = sound
            sound.play()
            return
        }

        NSSound.beep()
    }

    private func loadBundledSound(named filename: String) -> NSSound? {
        let path = filename.split(separator: ".")
        guard path.count == 2 else { return nil }

        let name = String(path[0])
        let ext = String(path[1])

        guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Sounds") else {
            return nil
        }

        return NSSound(contentsOf: url, byReference: false)
    }
}
