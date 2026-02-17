import Foundation
import SwiftData
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var lectures: [Lecture] = []
    @Published var searchText = ""
    @Published var isLoading = false
    
    // Debounced search text — updated 300ms after user stops typing
    @Published private var debouncedSearchText = ""
    private var searchCancellable: AnyCancellable?
    
    private var modelContext: ModelContext?
    
    init() {
        // Debounce search to avoid filtering on every keystroke
        searchCancellable = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.debouncedSearchText = value
            }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadLectures()
    }
    
    /// Load all lectures from storage
    func loadLectures() {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        let descriptor = FetchDescriptor<Lecture>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            lectures = try context.fetch(descriptor)
        } catch {
            print("Error loading lectures: \(error)")
        }
        
        isLoading = false
    }
    
    @Published var selectedDateFilter: DateFilter = .allTime
    @Published var filterStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @Published var filterEndDate: Date = Date()
    
    enum DateFilter: String, CaseIterable, Identifiable {
        case allTime = "All Time"
        case today = "Today"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case custom = "Custom Range..."
        
        var id: String { rawValue }
    }
    
    /// Filtered lectures based on search text and date filter
    var filteredLectures: [Lecture] {
        var result = lectures
        
        // Date Filtering
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateFilter {
        case .today:
            result = result.filter { calendar.isDateInToday($0.date) }
        case .last7Days:
            if let date = calendar.date(byAdding: .day, value: -7, to: now) {
                result = result.filter { $0.date >= date }
            }
        case .last30Days:
            if let date = calendar.date(byAdding: .day, value: -30, to: now) {
                result = result.filter { $0.date >= date }
            }
        case .custom:
            // Start of start date to end of end date
            let start = calendar.startOfDay(for: filterStartDate)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: filterEndDate) ?? filterEndDate
            
            result = result.filter { $0.date >= start && $0.date <= end }
        case .allTime:
            break
        }
        
        // Search Filtering (uses debounced text to avoid per-keystroke filtering)
        if !debouncedSearchText.isEmpty {
            result = result.filter { lecture in
                lecture.title.localizedCaseInsensitiveContains(debouncedSearchText) ||
                lecture.rawTranscript.localizedCaseInsensitiveContains(debouncedSearchText) ||
                lecture.processedNotes.localizedCaseInsensitiveContains(debouncedSearchText)
            }
        }
        
        return result
    }
    
    /// Delete a lecture
    func deleteLecture(_ lecture: Lecture) {
        guard let context = modelContext else { return }
        context.delete(lecture)
        
        do {
            try context.save()
            loadLectures()
        } catch {
            print("Error deleting lecture: \(error)")
        }
    }
}
