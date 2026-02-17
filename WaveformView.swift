import SwiftUI

/// Animated waveform visualization for recording
struct WaveformView: View {
    let audioLevel: CGFloat
    let barCount: Int = 50
    
    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(barGradient(for: index))
                    .frame(width: 3.5)
                    .frame(height: barHeight(for: index))
                    .animation(
                        .interpolatingSpring(stiffness: 300, damping: 15),
                        value: audioLevel
                    )
            }
        }
        .frame(height: 80)
        .drawingGroup() // Optimize rendering
    }
    
    private func barGradient(for index: Int) -> LinearGradient {
        let centerIndex = CGFloat(barCount) / 2
        let distanceFromCenter = abs(CGFloat(index) - centerIndex) / centerIndex
        let opacity = 0.5 + (1 - distanceFromCenter) * 0.5
        
        return LinearGradient(
            colors: [
                DesignSystem.Colors.primary.opacity(opacity),
                DesignSystem.Colors.accent.opacity(opacity * 0.7)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 4
        let maxHeight: CGFloat = 80
        
        // Center-focused bell curve
        let centerIndex = CGFloat(barCount) / 2
        let distanceFromCenter = abs(CGFloat(index) - centerIndex)
        let normalizedDistance = distanceFromCenter / centerIndex
        
        // Deterministic variation to make it look like a frequency analysis
        // Using sin/cos to create a "jagged" but fixed pattern that scales with volume
        let variance = 0.8 + 0.5 * sin(Double(index) * 0.8) * cos(Double(index) * 0.4)
        
        // Calculate dynamic height
        // audioLevel is 0.0-1.0
        // We dampen the edges to 0, peak at center
        let dynamicHeight = (audioLevel * maxHeight * variance) * (1.0 - pow(normalizedDistance, 2))
        
        return max(baseHeight, dynamicHeight)
    }
}
