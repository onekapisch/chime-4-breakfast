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

/// A soft luminous border drawn inset from the screen edges. Click-through and
/// purely decorative; the hosting window handles event transparency.
struct GlowBorderView: View {
    @ObservedObject var model: GlowOverlayModel
    @State private var pulseUp = false

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) * 0.05

            ZStack {
                border(radius: radius)
                    .stroke(model.color, lineWidth: 28)
                    .blur(radius: 34)

                border(radius: radius)
                    .stroke(model.color, lineWidth: 10)
                    .blur(radius: 9)

                border(radius: radius)
                    .stroke(model.color.opacity(0.95), lineWidth: 2.5)
            }
            .padding(3)
            .opacity(currentOpacity)
            .animation(.easeOut(duration: 0.45), value: model.visible)
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

    private var currentOpacity: Double {
        guard model.visible else { return 0 }
        let base = model.pulsing ? (pulseUp ? 1.0 : 0.45) : 0.92
        return base * model.intensity
    }

    private func updatePulse(_ isPulsing: Bool) {
        if isPulsing {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseUp = true
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                pulseUp = false
            }
        }
    }
}
