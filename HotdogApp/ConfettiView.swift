import SwiftUI

struct ConfettiView: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<30, id: \.self) { i in
                HotdogParticle(index: i, bounds: geo.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct HotdogParticle: View {
    let index: Int
    let bounds: CGSize

    // Deterministic pseudo-random values derived from index
    private var startX: CGFloat {
        bounds.width * CGFloat((index * 37 + 13) % 100) / 100
    }
    private var xDrift: CGFloat {
        CGFloat((index * 53 + 7) % 201) - 100
    }
    private var fontSize: CGFloat {
        [CGFloat(20), 28, 36, 44, 52][index % 5]
    }
    private var delay: Double {
        Double(index % 20) * 0.08
    }
    private var duration: Double {
        1.6 + Double(index % 6) * 0.2
    }
    private var endRotation: Double {
        Double((index * 61 + 5) % 720) - 360
    }

    @State private var falling = false
    @State private var opacity: Double = 1.0

    var body: some View {
        Text("🌭")
            .font(.system(size: fontSize))
            .rotationEffect(.degrees(falling ? endRotation : 0))
            .opacity(opacity)
            .position(
                x: startX + (falling ? xDrift : 0),
                y: falling ? bounds.height + 80 : -60
            )
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    falling = true
                }
                withAnimation(.linear(duration: 0.5).delay(delay + duration - 0.6)) {
                    opacity = 0
                }
            }
    }
}
