import Foundation
import UserNotifications

/// Service for scheduling and managing recall reminders
@MainActor
class ReminderService: ObservableObject {
    
    @Published var isAuthorized = false
    
    init() {
        // Do NOT perform any async work in init.
        // Authorization status will be checked when needed.
    }
    
    /// Check notification authorization status
    func checkAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            self.isAuthorized = false
            return false
        }
    }
    
    /// Schedule a reminder for a lecture
    func scheduleReminder(
        for lecture: Lecture,
        interval: ReminderInterval,
        notificationId: String
    ) async throws {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted {
                throw ReminderError.notAuthorized
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Review"
        content.body = "Time to review your Recallix notes: \(lecture.title)"
        content.sound = .default
        content.badge = 1
        
        let triggerDate = Calendar.current.date(
            byAdding: .hour,
            value: Int(interval.hours),
            to: Date()
        ) ?? Date()
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func cancelReminder(withId id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllReminders(for lecture: Lecture) {
        let ids = lecture.safeReminders.map { $0.notificationId }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    func getPendingReminders() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}

enum ReminderError: LocalizedError {
    case notAuthorized
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifications are not authorized. Please enable them in Settings."
        case .schedulingFailed:
            return "Failed to schedule reminder."
        }
    }
}
