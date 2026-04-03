import Foundation

struct SoundOption: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let filename: String

    static let catalog: [SoundOption] = [
        .init(id: "tick", title: "Tick", filename: "tick.wav"),
        .init(id: "beep", title: "Beep", filename: "beep.wav"),
        .init(id: "horn", title: "Horn", filename: "horn.wav"),
        .init(id: "wave", title: "Wave", filename: "wave.wav"),
        .init(id: "coin", title: "Coin", filename: "coin.wav"),
        .init(id: "glass", title: "Glass", filename: "glass.wav"),
        .init(id: "ping", title: "Ping", filename: "ping.wav"),
        .init(id: "chime", title: "Chime", filename: "chime.wav"),
        .init(id: "pulse", title: "Pulse", filename: "pulse.wav"),
        .init(id: "bloom", title: "Bloom", filename: "bloom.wav"),
        .init(id: "spark", title: "Spark", filename: "spark.wav"),
        .init(id: "knock", title: "Knock", filename: "knock.wav"),
        .init(id: "drift", title: "Drift", filename: "drift.wav"),
        .init(id: "flare", title: "Flare", filename: "flare.wav")
    ]

    static func option(for id: String) -> SoundOption? {
        catalog.first(where: { $0.id == id })
    }
}
