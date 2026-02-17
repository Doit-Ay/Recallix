import Foundation
import SwiftData

@MainActor
class NotesViewModel: ObservableObject {
    @Published var lecture: Lecture
    @Published var summary: LectureSummary?
    @Published var selectedReminderInterval: ReminderInterval?
    @Published var showingReminderOptions = false
    @Published var errorMessage: String?
    
    private let notesProcessor = NotesProcessor()
    let reminderService: ReminderService
    private var modelContext: ModelContext?
    
    init(lecture: Lecture, reminderService: ReminderService) {
        self.lecture = lecture
        self.reminderService = reminderService
        generateSummary()
        setupAudioPlayer()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// Generate summary from transcript
    func generateSummary() {
        let transcript = lecture.processedNotes.isEmpty ? lecture.rawTranscript : lecture.processedNotes
        // NotesProcessor now returns LectureSummary? which matches our summary property type
        summary = notesProcessor.generateSummary(from: transcript)
    }
    
    /// Schedule a reminder
    func scheduleReminder(interval: ReminderInterval) async {
        let notificationId = UUID().uuidString
        
        do {
            try await reminderService.scheduleReminder(
                for: lecture,
                interval: interval,
                notificationId: notificationId
            )
            
            // Create reminder object
            let scheduledDate = Calendar.current.date(
                byAdding: .hour,
                value: Int(interval.hours),
                to: Date()
            ) ?? Date()
            
            let reminder = Reminder(
                scheduledDate: scheduledDate,
                interval: interval,
                notificationId: notificationId
            )
            reminder.lecture = lecture
            if lecture.reminders == nil {
                lecture.reminders = []
            }
            lecture.reminders?.append(reminder)
            
            // Save to context
            guard let context = modelContext else { return }
            try context.save()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Cancel a reminder
    func cancelReminder(_ reminder: Reminder) {
        reminderService.cancelReminder(withId: reminder.notificationId)
        
        if let index = lecture.safeReminders.firstIndex(where: { $0.id == reminder.id }) {
            lecture.reminders?.remove(at: index)
        }
        
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Get keyword ranges for highlighting
    func getKeywordRanges() -> [(range: Range<String.Index>, keyword: String)] {
        let text = lecture.processedNotes.isEmpty ? lecture.rawTranscript : lecture.processedNotes
        return notesProcessor.getKeywordRanges(in: text)
    }
    
    // MARK: - Audio Player
    
    let audioPlayerService = AudioPlayerService()
    
    func setupAudioPlayer() {
        if let filename = lecture.audioFilename {
            audioPlayerService.setupAudio(filename: filename)
        }
    }
}
