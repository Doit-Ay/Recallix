import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NotesViewModel
    @State private var showingReminderPicker = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var karaokeEnabled = false
    @State private var showingFlashcards = false
    
    init(lecture: Lecture) {
        _viewModel = StateObject(wrappedValue: NotesViewModel(
            lecture: lecture,
            reminderService: ReminderService()
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                headerSection
                
                // Audio Player
                if viewModel.audioPlayerService.isAudioAvailable {
                    AudioPlayerView(service: viewModel.audioPlayerService,
                                    waveformData: viewModel.lecture.waveformData)
                        .padding(.bottom, DesignSystem.Spacing.sm)
                    
                    // Karaoke transcript (time-synced)
                    if !viewModel.lecture.transcriptSegments.isEmpty {
                        karaokeSection
                    }
                }
                
                // Summary section
                if let summary = viewModel.summary {
                    SummarySection(summary: summary)
                }
                
                // Reminders section
                remindersSection
                
                // Processed notes
                notesSection
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Lecture Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !viewModel.lecture.safeKeyPoints.isEmpty {
                    Button(action: { showingFlashcards = true }) {
                        Label("Study", systemImage: "rectangle.on.rectangle.angled")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        exportLecture()
                    }) {
                        Label("Export to Clipboard", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .sheet(isPresented: $showingFlashcards) {
            FlashcardView(lecture: viewModel.lecture)
        }
        .sheet(isPresented: $showingReminderPicker) {
            reminderPickerSheet
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [buildShareText()])
        }
        .alert("Delete Lecture", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(viewModel.lecture)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this lecture? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(viewModel.lecture.title)
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.label)
            
            HStack {
                Label(viewModel.lecture.formattedDate, systemImage: "calendar")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                
                Spacer()
                
                Label(viewModel.lecture.formattedDuration, systemImage: "clock")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Reminders Section
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Label("Reminders", systemImage: "bell.fill")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.label)
                
                Spacer()
                
                Button(action: {
                    showingReminderPicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            if viewModel.lecture.safeReminders.isEmpty {
                Text("No reminders set")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.tertiaryLabel)
            } else {
                ForEach(viewModel.lecture.safeReminders, id: \.id) { reminder in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reminder.interval.rawValue)
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.label)
                            
                            Text(formatDate(reminder.scheduledDate))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.cancelReminder(reminder)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tertiaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Label("Notes", systemImage: "doc.text.fill")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.label)
            
            let text = viewModel.lecture.processedNotes.isEmpty ? 
                viewModel.lecture.rawTranscript : viewModel.lecture.processedNotes
            
            Text(highlightedText(text))
                .font(DesignSystem.Typography.body)
                .textSelection(.enabled)
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
    
    /// Build an AttributedString with keyword highlights
    private func highlightedText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        
        let processor = NotesProcessor()
        let keywordRanges = processor.getKeywordRanges(in: text)
        
        for match in keywordRanges {
            // Convert String.Index range to AttributedString range
            let startOffset = text.distance(from: text.startIndex, to: match.range.lowerBound)
            let endOffset = text.distance(from: text.startIndex, to: match.range.upperBound)
            
            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            let attrRange = attrStart..<attrEnd
            
            attributed[attrRange].font = .system(.body, design: .default, weight: .bold)
            attributed[attrRange].backgroundColor = DesignSystem.Colors.keywordHighlight
            attributed[attrRange].foregroundColor = DesignSystem.Colors.label
        }
        
        return attributed
    }
    
    // MARK: - Karaoke Mode (Time-Synced Transcript)
    private var karaokeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Toggle header
            Button(action: { 
                withAnimation(DesignSystem.Animation.standard) {
                    karaokeEnabled.toggle()
                }
            }) {
                HStack {
                    Label("Live Transcript", systemImage: karaokeEnabled ? "text.word.spacing" : "text.alignleft")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.label)
                    Spacer()
                    Image(systemName: karaokeEnabled ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                }
            }
            .buttonStyle(.plain)
            
            if karaokeEnabled {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        karaokeText
                            .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                    .onChange(of: viewModel.audioPlayerService.currentTime) { _, newTime in
                        // Auto-scroll to current word
                        let segments = viewModel.lecture.transcriptSegments
                        if let idx = segments.lastIndex(where: { $0.timestamp <= newTime }) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(idx, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
    
    /// Build karaoke text with current word highlighted
    private var karaokeText: some View {
        let segments = viewModel.lecture.transcriptSegments
        let currentTime = viewModel.audioPlayerService.currentTime
        
        return HStack(spacing: 4) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                let isActive = currentTime >= segment.timestamp &&
                    currentTime < segment.timestamp + max(segment.duration, 0.3)
                
                Text(segment.word)
                    .font(isActive ? .system(.body, design: .rounded, weight: .bold) : DesignSystem.Typography.body)
                    .foregroundColor(isActive ? .white : DesignSystem.Colors.label)
                    .padding(.horizontal, isActive ? 6 : 2)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isActive ? DesignSystem.Colors.primary : Color.clear)
                    )
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(DesignSystem.Animation.quick, value: isActive)
                    .id(index)
            }
        }
    }

    
    // MARK: - Reminder Picker Sheet
    private var reminderPickerSheet: some View {
        NavigationStack {
            List {
                ForEach([ReminderInterval.twentyFourHours, .threeDays, .sevenDays], id: \.self) { interval in
                    Button(action: {
                        Task {
                            await viewModel.scheduleReminder(interval: interval)
                            showingReminderPicker = false
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(interval.rawValue)
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.label)
                                
                                Text("Review in \(interval.hours) hours")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingReminderPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func buildShareText() -> String {
        var text = "📝 \(viewModel.lecture.title)\n"
        text += "📅 \(viewModel.lecture.formattedDate) • ⏱ \(viewModel.lecture.formattedDuration)\n\n"
        
        let notes = viewModel.lecture.processedNotes.isEmpty ?
            viewModel.lecture.rawTranscript : viewModel.lecture.processedNotes
        text += notes
        
        if !viewModel.lecture.safeKeyPoints.isEmpty {
            text += "\n\n⭐ Key Points:\n"
            for kp in viewModel.lecture.safeKeyPoints {
                text += "• \(kp.text)\n"
            }
        }
        
        text += "\n— Recorded with Recallix"
        return text
    }
    
    private func exportLecture() {
        UIPasteboard.general.string = buildShareText()
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
