import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject var service: AudioPlayerService
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Button(action: {
                    service.togglePlayPause()
                }) {
                    Image(systemName: service.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                VStack(spacing: 4) {
                    Slider(value: Binding(
                        get: { service.currentTime },
                        set: { service.seek(to: $0) }
                    ), in: 0...service.duration)
                    .accentColor(DesignSystem.Colors.primary)
                    
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
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
