import CoreGraphics

/// Maps the user-facing intensity control to the visible properties of an edge glow.
/// Intensity controls the size and brightness of the emitted light, not merely a
/// final opacity multiplier applied after the glow has already been drawn.
struct GlowConfiguration: Equatable, Sendable {
    let intensity: Double
    let bandWidthScale: CGFloat
    let haloOpacity: Double
    let haloWidth: CGFloat
    let borderOpacity: Double
    let borderWidth: CGFloat

    init(intensity: Double) {
        let clampedIntensity = min(max(intensity, 0.2), 1.0)
        let progress = (clampedIntensity - 0.2) / 0.8

        self.intensity = clampedIntensity
        self.bandWidthScale = 0.38 + (0.62 * progress)
        self.haloOpacity = 0.18 + (0.62 * progress)
        self.haloWidth = 7 + (13 * progress)
        self.borderOpacity = 0.35 + (0.60 * progress)
        self.borderWidth = 1.2 + (3.2 * progress)
    }
}
