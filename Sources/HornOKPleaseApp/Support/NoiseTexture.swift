import SwiftUI

struct NoiseTexture: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()

            for index in 0..<260 {
                let x = pseudoRandom(index * 13) * size.width
                let y = pseudoRandom(index * 37) * size.height
                let alpha = 0.02 + pseudoRandom(index * 71) * 0.05
                let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                path.addRect(rect)
                context.fill(path, with: .color(.white.opacity(alpha)))
                path = Path()
            }
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    private func pseudoRandom(_ seed: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898) * 43_758.5453
        return CGFloat(value - floor(value))
    }
}
