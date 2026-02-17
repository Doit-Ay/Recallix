import SwiftUI

/// Shared app-wide state for cross-component communication.
/// Used by App Shortcuts to trigger navigation actions.
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    /// When set to true, HomeView opens the recording sheet
    @Published var shouldOpenRecording = false
    
    /// When set, HomeView populates the search bar
    @Published var searchQuery: String?
    
    private init() {}
}
