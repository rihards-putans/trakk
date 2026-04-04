import SwiftUI

struct SparklineView: View {
    let dataPoints: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            if dataPoints.count >= 2 {
                let minVal = dataPoints.min() ?? 0
                let maxVal = dataPoints.max() ?? 1
                let range = maxVal - minVal
                let safeRange = range == 0 ? 1.0 : range
                let width = geo.size.width
                let height = geo.size.height
                let dotRadius: CGFloat = 3

                ZStack {
                    // Line path
                    Path { path in
                        for (i, val) in dataPoints.enumerated() {
                            let x = CGFloat(i) / CGFloat(dataPoints.count - 1) * width
                            let y = height - ((val - minVal) / safeRange) * (height - dotRadius * 2) - dotRadius
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                    // Dot on last point
                    if let last = dataPoints.last {
                        let x = width
                        let y = height - ((last - minVal) / safeRange) * (height - dotRadius * 2) - dotRadius
                        Circle()
                            .fill(color)
                            .frame(width: dotRadius * 2, height: dotRadius * 2)
                            .position(x: x, y: y)
                    }
                }
            } else {
                // Flat line for empty/single data
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(color.opacity(0.3), lineWidth: 1.5)
            }
        }
        .frame(height: 24)
    }
}

#Preview {
    VStack(spacing: 16) {
        SparklineView(dataPoints: [82.1, 81.8, 81.5, 81.3, 80.9, 80.7, 80.5], color: Theme.positive)
            .padding()
            .background(Theme.cardSurface)

        SparklineView(dataPoints: [80.5, 81.0, 81.2, 80.8, 81.5], color: Theme.consumed)
            .padding()
            .background(Theme.cardSurface)

        SparklineView(dataPoints: [], color: Theme.textMuted)
            .padding()
            .background(Theme.cardSurface)
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
