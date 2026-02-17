import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject var service: AudioPlayerService
    var waveformData: [Float]? // Real waveform from recording, nil = use deterministic
    
    // Pre-generated waveform bar heights
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
    
    /// Generate bar heights from real waveform data or deterministic fallback
    private func generateBarHeights() {
        if let realData = waveformData, !realData.isEmpty {
            // Downsample real waveform to barCount bars
            barHeights = downsample(realData, to: barCount)
        } else {
            // Deterministic fallback for lectures without recorded waveform
            var heights: [CGFloat] = []
            let seed = Int(service.duration * 100) &+ 42
            for i in 0..<barCount {
                let hash = (seed &* 31 &+ i &* 17) &* 13
                let normalized = abs(hash % 100)
                let height = CGFloat(6 + (normalized % 26))
                heights.append(height)
            }
            barHeights = heights
        }
    }
    
    /// Downsample waveform data to a fixed number of bars
    private func downsample(_ data: [Float], to count: Int) -> [CGFloat] {
        guard !data.isEmpty else { return Array(repeating: 4, count: count) }
        
        let chunkSize = max(1, data.count / count)
        var bars: [CGFloat] = []
        
        for i in 0..<count {
            let start = i * chunkSize
            let end = min(start + chunkSize, data.count)
            if start < data.count {
                let chunk = data[start..<end]
                let avg = chunk.reduce(0, +) / Float(chunk.count)
                // Scale: audioLevel typically 0.0-0.5, map to 4-32px
                let height = CGFloat(max(4, min(32, avg * 64 + 4)))
                bars.append(height)
            } else {
                bars.append(4)
            }
        }
        
        return bars
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
