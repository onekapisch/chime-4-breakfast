import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.30))
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.98))
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.045),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.11),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.22, y: 0.0),
                                startRadius: 0,
                                endRadius: 210
                            )
                        )
                        .blendMode(.screen)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.24),
                                Color.white.opacity(0.07),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.42), radius: 24, x: 0, y: 18)
            .shadow(color: Color.white.opacity(0.035), radius: 1, x: 0, y: 1)
    }
}
