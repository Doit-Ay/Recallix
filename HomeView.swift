import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var appState = AppState.shared
    @State private var showingRecording = false
    @State private var fabScale: CGFloat = 1.0
    @State private var selectedLecture: Lecture? = nil
    @State private var showingDateFilterSheet = false
    @State private var cardsAppeared = false
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .onChange(of: appState.shouldOpenRecording) { _, shouldOpen in
            if shouldOpen {
                showingRecording = true
                appState.shouldOpenRecording = false
            }
        }
        .onChange(of: appState.searchQuery) { _, query in
            if let query {
                viewModel.searchText = query
                appState.searchQuery = nil
            }
        }
    }
    
    // MARK: - iPad Split View Layout
    private var iPadLayout: some View {
        NavigationSplitView {
            // Sidebar: lecture list
            ZStack {
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.homeGradientStart,
                        DesignSystem.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 1.1)
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchAndFilterBar
                    
                    if viewModel.filteredLectures.isEmpty {
                        emptyState
                    } else {
                        List(viewModel.filteredLectures, id: \.id, selection: $selectedLecture) { lecture in
                            LectureCard(lecture: lecture)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .tag(lecture)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            viewModel.deleteLecture(lecture)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Recallix")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationView()) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.label)
                    }
                    .accessibilityLabel("Notifications")
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { showingRecording = true }) {
                        Label("Record Lecture", systemImage: "mic.fill")
                            .font(.headline)
                    }
                    .accessibilityLabel("Start Recording")
                    .accessibilityHint("Tap to begin recording a new lecture")
                }
            }
        } detail: {
            if let lecture = selectedLecture {
                NotesView(lecture: lecture)
                    .id(lecture.id)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                    Text("Select a Lecture")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    Text("Choose a lecture from the sidebar to view its notes")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                }
            }
        }
        .fullScreenCover(isPresented: $showingRecording) {
            RecordingView(onSave: { lecture in
                selectedLecture = lecture
            })
            .environment(\.modelContext, modelContext)
            .onDisappear {
                viewModel.loadLectures()
            }
        }
        .sheet(isPresented: $showingDateFilterSheet) {
            dateFilterSheet
        }
    }
    
    // MARK: - iPhone Stack Layout
    private var iPhoneLayout: some View {
        NavigationStack {
            ZStack {
                // ... (Gradient remains same)
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.homeGradientStart,
                        DesignSystem.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 1.1)
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ... (Title remains same)
                    HStack {
                        Text("Recallix")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.label)
                        Spacer()
                        NavigationLink(destination: NotificationView()) {
                            ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary.opacity(0.8), lineWidth: 0.8)
                                        )
                                
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.label)
                            }
                            .accessibilityLabel("Notifications")
                            .accessibilityHint("View your reminders and action items")
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.xl)
                    .padding(.bottom, DesignSystem.Spacing.sm)
                    
                    // Search and Filter
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        // ... (Search bar remains same)
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                            
                            TextField("Search lectures...", text: $viewModel.searchText)
                                .font(DesignSystem.Typography.body)
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: { viewModel.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm + 2)
                        .background(DesignSystem.Colors.searchBarBackground)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(DesignSystem.Colors.glassBorder, lineWidth: 0.5)
                        )
                        
                        // Filter Button
                        Menu {
                            Picker("Date Filter", selection: $viewModel.selectedDateFilter) {
                                ForEach(HomeViewModel.DateFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .onChange(of: viewModel.selectedDateFilter) { newValue in
                                if newValue == .custom {
                                    showingDateFilterSheet = true
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.searchBarBackground)
                                    .background(
                                        Circle().fill(.ultraThinMaterial)
                                    )
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(DesignSystem.Colors.glassBorder, lineWidth: 0.5)
                                    )
                                
                                Image(systemName: viewModel.selectedDateFilter == .allTime ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(viewModel.selectedDateFilter == .allTime ? DesignSystem.Colors.secondaryLabel : DesignSystem.Colors.primary)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.md)
                    
                    // ... (Content remains same)
                    // Content
                    if viewModel.filteredLectures.isEmpty {
                        emptyState
                    } else {
                        lecturesList
                    }
                }
                
                // ... (FAB remains same)
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(DesignSystem.Animation.bouncy) {
                                fabScale = 0.85
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(DesignSystem.Animation.bouncy) {
                                    fabScale = 1.0
                                }
                                showingRecording = true
                            }
                        }) {
                            ZStack {
                                // Outer glow
                                Circle()
                                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                                    .frame(width: 72, height: 72)
                                
                                // Main button
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryDark],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .shadow(color: DesignSystem.Colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(fabScale)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                        .accessibilityLabel("Start Recording")
                        .accessibilityHint("Tap to begin recording a new lecture")
                    }
                }
            }
            .navigationBarHidden(true)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .fullScreenCover(isPresented: $showingRecording) {
                RecordingView(onSave: { lecture in
                    selectedLecture = lecture
                })
                .environment(\.modelContext, modelContext)
                .onDisappear {
                    viewModel.loadLectures()
                }
            }
            .sheet(isPresented: $showingDateFilterSheet) {
                NavigationStack {
                    Form {
                        DatePicker("Start Date", selection: $viewModel.filterStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $viewModel.filterEndDate, displayedComponents: .date)
                    }
                    .navigationTitle("Select Date Range")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingDateFilterSheet = false
                                // Reset to all time if cancelled? Or just keep previous?
                                // For now, let's keep it simple and just close
                                if viewModel.selectedDateFilter == .custom {
                                    // If we were just selecting custom, maybe revert if not applied?
                                    // Logic: The picker already set it to .custom.
                                    // If user cancels, we should probably revert to .allTime or previous.
                                    // But tracking previous is complex. Let's just let them be.
                                }
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Apply") {
                                showingDateFilterSheet = false
                                // Ensure .custom is selected (it should be)
                                viewModel.selectedDateFilter = .custom
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
            }

            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    // MARK: - Search and Filter Bar (shared by iPhone + iPad)
    private var searchAndFilterBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                
                TextField("Search lectures...", text: $viewModel.searchText)
                    .font(DesignSystem.Typography.body)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm + 2)
            .background(DesignSystem.Colors.searchBarBackground)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(DesignSystem.Colors.glassBorder, lineWidth: 0.5)
            )
            
            // Filter Button
            Menu {
                Picker("Date Filter", selection: $viewModel.selectedDateFilter) {
                    ForEach(HomeViewModel.DateFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .onChange(of: viewModel.selectedDateFilter) { newValue in
                    if newValue == .custom {
                        showingDateFilterSheet = true
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.searchBarBackground)
                        .background(
                            Circle().fill(.ultraThinMaterial)
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.Colors.glassBorder, lineWidth: 0.5)
                        )
                    
                    Image(systemName: viewModel.selectedDateFilter == .allTime ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(viewModel.selectedDateFilter == .allTime ? DesignSystem.Colors.secondaryLabel : DesignSystem.Colors.primary)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.md)
    }
    
    // MARK: - Date Filter Sheet (shared by iPhone + iPad)
    private var dateFilterSheet: some View {
        NavigationStack {
            Form {
                DatePicker("Start Date", selection: $viewModel.filterStartDate, displayedComponents: .date)
                DatePicker("End Date", selection: $viewModel.filterEndDate, displayedComponents: .date)
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingDateFilterSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        showingDateFilterSheet = false
                        viewModel.selectedDateFilter = .custom
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            // Animated icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary.opacity(0.1), DesignSystem.Colors.accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary.opacity(0.15), DesignSystem.Colors.accent.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Lectures Yet")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.label)
                
                Text("Tap the mic button to start\nrecording your first lecture")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
    }
    
    // MARK: - Lectures List
    private var lecturesList: some View {
        ScrollView(showsIndicators: false) {
            // Stats header
            if viewModel.filteredLectures.count > 0 {
                HStack {
                    Text("\(viewModel.filteredLectures.count) Recording\(viewModel.filteredLectures.count == 1 ? "" : "s")")
                        .font(DesignSystem.Typography.subheadline) // Smaller but still legible
                        .foregroundColor(DesignSystem.Colors.label) // Darker (black in light mode)
                    Spacer()
                }              .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xs)
            }
            
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(Array(viewModel.filteredLectures.enumerated()), id: \.element.id) { index, lecture in
                    NavigationLink(destination: NotesView(lecture: lecture)) {
                        LectureCard(lecture: lecture)
                    }
                    .buttonStyle(.plain)
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 30)
                    .animation(
                        DesignSystem.Animation.spring.delay(Double(index) * 0.06),
                        value: cardsAppeared
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteLecture(lecture)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            // Extra bottom padding so last card isn't hidden behind FAB
            .padding(.bottom, 100)
            .onAppear { cardsAppeared = true }
            .onDisappear { cardsAppeared = false }
        }
    }
}
