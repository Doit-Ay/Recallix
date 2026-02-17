import SwiftUI

/// Card component for displaying lecture items
struct LectureCard: View {
    let lecture: Lecture
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Top row: icon + title + duration badge
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                // Colored icon circle
                // Simple Voice Icon
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(lecture.title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.label)
                        .lineLimit(2)
                    
                    Text(lecture.formattedDate)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
                
                Spacer()
                
                // Duration badge
                Text(lecture.formattedDuration)
                    .tagStyle()
            }
            
            // Preview text
            if !lecture.preview.isEmpty {
                Text(lecture.preview)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel) // Darker than tertiary
                    .lineLimit(2)
                    .padding(.leading, 52) // Align with text after icon
            }
            
            // Bottom row: key points + reminders
            if !lecture.safeKeyPoints.isEmpty || !lecture.safeReminders.isEmpty {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if !lecture.safeKeyPoints.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.warning)
                            Text("\(lecture.safeKeyPoints.count) key points")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }
                    
                    if !lecture.safeReminders.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text("\(lecture.safeReminders.count) reminders")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                }
                .padding(.leading, 52)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .premiumCardStyle()
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(DesignSystem.Animation.quick, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
