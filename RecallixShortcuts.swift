import AppIntents

/// App Shortcut: Start a lecture recording via Siri or Spotlight
struct StartRecordingIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Start Lecture Recording"
    nonisolated static let description: IntentDescription = IntentDescription("Start recording a new lecture in Recallix")
    nonisolated static let openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.shouldOpenRecording = true
        return .result(dialog: "Opening Recallix to start recording.")
    }
}

/// App Shortcut: Search lectures
struct SearchLecturesIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Search Lectures"
    nonisolated static let description: IntentDescription = IntentDescription("Search your recorded lectures in Recallix")
    nonisolated static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Search Term")
    var searchTerm: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.searchQuery = searchTerm
        return .result(dialog: "Searching for \(searchTerm) in Recallix")
    }
}

/// Register shortcuts with the system
struct RecallixShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "Start a lecture in \(.applicationName)",
                "Record a class in \(.applicationName)",
                "Start recording in \(.applicationName)"
            ],
            shortTitle: "Record Lecture",
            systemImageName: "mic.fill"
        )
        AppShortcut(
            intent: SearchLecturesIntent(),
            phrases: [
                "Search lectures in \(.applicationName)",
                "Find notes in \(.applicationName)"
            ],
            shortTitle: "Search Notes",
            systemImageName: "magnifyingglass"
        )
    }
}
