import SwiftUI

/// Shared visual state for every screen overlay. One model drives all displays
/// so the glow stays in sync across a multi-monitor setup.
@MainActor
final class GlowOverlayModel: ObservableObject {
    @Published var color: Color = .green
    @Published var visible: Bool = false
    @Published var pulsing: Bool = false
    @Published var configuration = GlowConfiguration(intensity: 1.0)
}

/// A soft ambient glow that hugs the screen edges and fades inward - no hard
/// outline. Click-through and purely decorative; the hosting window handles
/// event transparency.
struct GlowBorderView: View {
    @ObservedObject var model: GlowOverlayModel
    @State private var pulseUp = false

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) * 0.05
            let fullBandWidth = min(max(min(proxy.size.width, proxy.size.height) * 0.10, 92), 150)
            let bandWidth = fullBandWidth * model.configuration.bandWidthScale

            ZStack {
                edgeBands(width: bandWidth)

                border(radius: radius)
                    .stroke(model.color.opacity(model.configuration.haloOpacity), lineWidth: model.configuration.haloWidth)
                    .blur(radius: model.configuration.haloWidth)

                border(radius: radius)
                    .stroke(model.color.opacity(model.configuration.borderOpacity), lineWidth: model.configuration.borderWidth)
                    .blur(radius: 1.5)
            }
            .opacity(currentOpacity)
            // Snap in almost instantly so the ~1 s dwell is spent visible, not
            // fading; ease out gently on dismiss.
            .animation(.easeOut(duration: model.visible ? 0.1 : 0.4), value: model.visible)
            .animation(.easeInOut(duration: 0.4), value: model.color)
            .animation(.easeInOut(duration: 0.16), value: model.configuration)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { updatePulse(model.pulsing) }
        .onChange(of: model.pulsing) { _, isPulsing in updatePulse(isPulsing) }
    }

    private func border(radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    private func edgeBands(width: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [model.color.opacity(model.configuration.haloOpacity), model.color.opacity(model.configuration.haloOpacity * 0.36), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: width)

                Spacer(minLength: 0)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, model.color.opacity(model.configuration.haloOpacity * 0.36), model.color.opacity(model.configuration.haloOpacity)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: width)
            }

            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [model.color.opacity(model.configuration.haloOpacity), model.color.opacity(model.configuration.haloOpacity * 0.36), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)

                Spacer(minLength: 0)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, model.color.opacity(model.configuration.haloOpacity * 0.36), model.color.opacity(model.configuration.haloOpacity)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)
            }
        }
    }

    private var currentOpacity: Double {
        guard model.visible else { return 0 }
        return model.pulsing ? (pulseUp ? 1.0 : 0.5) : 1.0
    }

    private func updatePulse(_ isPulsing: Bool) {
        if isPulsing {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                pulseUp = true
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                pulseUp = false
            }
        }
    }
}
