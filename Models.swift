import Foundation
import SwiftData

@Model
final class Lecture {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var rawTranscript: String
    var processedNotes: String
    var duration: TimeInterval
    var audioFilename: String? // Optional: Filename of saved audio
    
    @Relationship(deleteRule: .cascade) var keyPoints: [KeyPoint]?
    @Relationship(deleteRule: .cascade) var reminders: [Reminder]?
    
    init(title: String, date: Date = Date(), rawTranscript: String = "", processedNotes: String = "", duration: TimeInterval = 0, audioFilename: String? = nil) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.rawTranscript = rawTranscript
        self.processedNotes = processedNotes
        self.duration = duration
        self.audioFilename = audioFilename
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var preview: String {
        let text = processedNotes.isEmpty ? rawTranscript : processedNotes
        return String(text.prefix(120)) 
    }
    
    var safeKeyPoints: [KeyPoint] {
        keyPoints ?? []
    }
    
    var safeReminders: [Reminder] {
        reminders ?? []
    }
}

@Model
final class KeyPoint {
    @Attribute(.unique) var id: UUID
    var text: String
    var timestamp: TimeInterval
    var isImportant: Bool
    var lecture: Lecture?
    
    init(text: String, timestamp: TimeInterval = 0, isImportant: Bool = false) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.isImportant = isImportant
    }
}

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    var notificationId: String
    var scheduledDate: Date
    var interval: ReminderInterval
    var isCompleted: Bool
    var lecture: Lecture?
    
    init(scheduledDate: Date, interval: ReminderInterval, notificationId: String = UUID().uuidString) {
        self.id = UUID()
        self.notificationId = notificationId
        self.scheduledDate = scheduledDate
        self.interval = interval
        self.isCompleted = false
    }
}

enum ReminderInterval: String, Codable {
    case twentyFourHours = "24 Hours"
    case threeDays = "3 Days"
    case sevenDays = "7 Days"
    
    var hours: Double {
        switch self {
        case .twentyFourHours: return 24
        case .threeDays: return 72
        case .sevenDays: return 168
        }
    }
}

// Summary data structure (not persisted, generated on-the-fly)
// Summary data structure (not persisted, generated on-the-fly)
struct LectureSummary: Sendable {
    var text: String
    var actionItems: [String]
    
    var isEmpty: Bool {
        text.isEmpty && actionItems.isEmpty
    }
}
