import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject var service: AudioPlayerService
    
    // Pre-generated waveform bar heights (deterministic per duration)
    @State private var barHeights: [CGFloat] = []
    private let barCount = 50
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Play/Pause button
                Button(action: {
                    service.togglePlayPause()
                }) {
                    Image(systemName: service.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .contentTransition(.symbolEffect(.replace))
                }
                
                // Waveform + scrubber
                VStack(spacing: 4) {
                    waveformVisualizer
                    
                    HStack {
                        Text(formatTime(service.currentTime))
                        Spacer()
                        Text(formatTime(service.duration))
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.separator, lineWidth: 1)
        )
        .onAppear {
            generateBarHeights()
        }
    }
    
    // MARK: - Waveform Visualizer
    private var waveformVisualizer: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Waveform bars
                HStack(spacing: 2) {
                    ForEach(0..<barHeights.count, id: \.self) { i in
                        let progress = service.duration > 0
                            ? service.currentTime / service.duration
                            : 0.0
                        let isFilled = Double(i) / Double(barHeights.count) <= progress
                        
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(isFilled
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.primary.opacity(0.15))
                            .frame(height: barHeights.isEmpty ? 4 : barHeights[i])
                    }
                }
                .frame(height: 32)
                
                // Invisible slider overlay for scrubbing
                Slider(value: Binding(
                    get: { service.currentTime },
                    set: { service.seek(to: $0) }
                ), in: 0...max(service.duration, 0.01))
                .opacity(0.011) // Invisible but interactive
                .frame(height: 32)
            }
        }
        .frame(height: 32)
    }
    
    // MARK: - Helpers
    
    /// Generate deterministic bar heights based on duration
    private func generateBarHeights() {
        var heights: [CGFloat] = []
        // Use a simple deterministic sequence for consistent waveform shape
        let seed = Int(service.duration * 100) &+ 42
        for i in 0..<barCount {
            let hash = (seed &* 31 &+ i &* 17) &* 13
            let normalized = abs(hash % 100)
            // Heights between 6 and 32, with bias toward medium values
            let height = CGFloat(6 + (normalized % 26))
            heights.append(height)
        }
        barHeights = heights
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
