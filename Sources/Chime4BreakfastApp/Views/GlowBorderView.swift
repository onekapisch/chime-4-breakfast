import SwiftUI

/// Shared visual state for every screen overlay. One model drives all displays
/// so the glow stays in sync across a multi-monitor setup.
@MainActor
final class GlowOverlayModel: ObservableObject {
    @Published var color: Color = .green
    @Published var visible: Bool = false
    @Published var pulsing: Bool = false
    @Published var intensity: Double = 1.0
}

/// A soft ambient glow that hugs the screen edges and fades inward — no hard
/// outline. Click-through and purely decorative; the hosting window handles
/// event transparency.
struct GlowBorderView: View {
    @ObservedObject var model: GlowOverlayModel
    @State private var pulseUp = false

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) * 0.05
            let bandWidth = min(max(min(proxy.size.width, proxy.size.height) * 0.10, 92), 150)

            ZStack {
                edgeBands(width: bandWidth)

                border(radius: radius)
                    .stroke(model.color.opacity(0.7), lineWidth: 16)
                    .blur(radius: 18)

                border(radius: radius)
                    .stroke(model.color.opacity(0.95), lineWidth: 3.5)
                    .blur(radius: 1.5)
            }
            .opacity(currentOpacity)
            // Snap in almost instantly so the ~1 s dwell is spent visible, not
            // fading; ease out gently on dismiss.
            .animation(.easeOut(duration: model.visible ? 0.1 : 0.4), value: model.visible)
            .animation(.easeInOut(duration: 0.4), value: model.color)
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
                            colors: [model.color.opacity(0.9), model.color.opacity(0.32), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: width)

                Spacer(minLength: 0)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, model.color.opacity(0.32), model.color.opacity(0.9)],
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
                            colors: [model.color.opacity(0.9), model.color.opacity(0.32), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)

                Spacer(minLength: 0)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, model.color.opacity(0.32), model.color.opacity(0.9)],
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
        let base = model.pulsing ? (pulseUp ? 1.0 : 0.5) : 1.0
        return base * model.intensity
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
