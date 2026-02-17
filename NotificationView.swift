import SwiftUI
import SwiftData

struct NotificationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Lecture.date, order: .reverse) private var lectures: [Lecture]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                if allNotifications.isEmpty {
                    emptyState
                } else {
                    ForEach(allNotifications, id: \.id) { notification in
                        notificationCard(notification)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.primary.opacity(0.15),
                    DesignSystem.Colors.background
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.5)
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Notification Data
    private struct NotificationItem: Identifiable {
        let id = UUID()
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
        let time: String
        let type: NotificationType
    }
    
    private enum NotificationType {
        case reminder, assignment, info
    }
    
    private var allNotifications: [NotificationItem] {
        var items: [NotificationItem] = []
        
        // Collect reminders from all lectures
        for lecture in lectures {
            for reminder in lecture.safeReminders {
                let isPast = reminder.scheduledDate < Date()
                items.append(NotificationItem(
                    icon: isPast ? "bell.badge.fill" : "bell.fill",
                    iconColor: isPast ? DesignSystem.Colors.warning : DesignSystem.Colors.primary,
                    title: "Review: \(lecture.title)",
                    subtitle: isPast ? "Time to revise! (\(reminder.interval.rawValue))" : "Upcoming in \(reminder.interval.rawValue)",
                    time: formatRelativeDate(reminder.scheduledDate),
                    type: .reminder
                ))
            }
            
            // Collect assignments from summaries
            if let summary = try? NotesProcessor().generateSummary(from: lecture.processedNotes.isEmpty ? lecture.rawTranscript : lecture.processedNotes) {
                for actionItem in summary.actionItems {
                    items.append(NotificationItem(
                        icon: "doc.text.fill",
                        iconColor: DesignSystem.Colors.accent,
                        title: "Action Item",
                        subtitle: actionItem,
                        time: formatRelativeDate(lecture.date),
                        type: .assignment
                    ))
                }
            }
        }
        
        // Add info about recent lectures
        for lecture in lectures.prefix(3) {
            items.append(NotificationItem(
                icon: "waveform.circle.fill",
                iconColor: DesignSystem.Colors.success,
                title: "Lecture Recorded",
                subtitle: lecture.title,
                time: formatRelativeDate(lecture.date),
                type: .info
            ))
        }
        
        // Sort by most recent
        return items
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()
                .frame(height: 80)
            
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
            
            Text("No Notifications")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.secondaryLabel)
            
            Text("Record your first lecture and set reminders to see notifications here.")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Notification Card
    private func notificationCard(_ item: NotificationItem) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(item.iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(item.iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.label)
                    .fontWeight(.semibold)
                
                Text(item.subtitle)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Time
            Text(item.time)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.glassTint)
        .background(.ultraThinMaterial)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(DesignSystem.Colors.glassBorder, lineWidth: 0.5)
        )
    }
    
    // MARK: - Helpers
    private func formatRelativeDate(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        if diff < 0 {
            // Future
            let futureDiff = -diff
            if futureDiff < 3600 {
                return "in \(Int(futureDiff / 60))m"
            } else if futureDiff < 86400 {
                return "in \(Int(futureDiff / 3600))h"
            } else {
                return "in \(Int(futureDiff / 86400))d"
            }
        } else {
            // Past
            if diff < 60 {
                return "Just now"
            } else if diff < 3600 {
                return "\(Int(diff / 60))m ago"
            } else if diff < 86400 {
                return "\(Int(diff / 3600))h ago"
            } else {
                return "\(Int(diff / 86400))d ago"
            }
        }
    }
}
