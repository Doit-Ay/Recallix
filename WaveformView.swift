import SwiftUI

/// High-performance waveform visualization using TimelineView + Canvas
/// Renders at 60fps with smooth frequency-bar animations responsive to audio level
struct WaveformView: View {
    let audioLevel: CGFloat
    let barCount: Int = 50
    
    // Store previous levels for smooth interpolation
    @State private var displayLevel: CGFloat = 0.0
    @State private var barPhases: [Double] = []
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let barWidth: CGFloat = 3.5
                let barSpacing: CGFloat = 2.5
                let totalBarWidth = barWidth + barSpacing
                let centerY = size.height / 2.0
                let maxBarHeight = size.height
                let centerIndex = CGFloat(barCount) / 2.0
                
                // Time-based phase for subtle animation
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<barCount {
                    let x = CGFloat(i) * totalBarWidth
                    
                    // Center-focused bell curve
                    let distanceFromCenter = abs(CGFloat(i) - centerIndex)
                    let normalizedDistance = distanceFromCenter / centerIndex
                    let bellCurve = 1.0 - pow(normalizedDistance, 2)
                    
                    // Multi-frequency variation to simulate spectral analysis
                    let freq1 = sin(Double(i) * 0.8 + time * 3.0) * 0.3
                    let freq2 = cos(Double(i) * 0.4 + time * 2.0) * 0.2
                    let freq3 = sin(Double(i) * 1.5 + time * 5.0) * 0.15
                    let variance = 0.6 + freq1 + freq2 + freq3
                    
                    // Calculate dynamic height
                    let baseHeight: CGFloat = 4.0
                    let dynamicHeight = displayLevel * maxBarHeight * variance * bellCurve
                    let barHeight = max(baseHeight, dynamicHeight)
                    
                    // Bar rect centered vertically
                    let rect = CGRect(
                        x: x,
                        y: centerY - barHeight / 2.0,
                        width: barWidth,
                        height: barHeight
                    )
                    let path = Path(roundedRect: rect, cornerRadius: 2.0)
                    
                    // Gradient opacity based on distance from center
                    let opacity = 0.5 + (1.0 - normalizedDistance) * 0.5
                    let color = Color(
                        hue: 0.58 + normalizedDistance * 0.2, // Blue → Purple gradient
                        saturation: 0.75,
                        brightness: 0.95 * opacity
                    )
                    
                    context.fill(path, with: .color(color))
                }
            }
        }
        .frame(height: 80)
        .onChange(of: audioLevel) { _, newValue in
            // Smooth interpolation to target level
            withAnimation(.easeOut(duration: 0.08)) {
                displayLevel = newValue
            }
        }
    }
}
