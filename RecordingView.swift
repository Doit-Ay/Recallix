import SwiftUI
import SwiftData
import AVFoundation

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecordingViewModel()
    var onSave: ((Lecture) -> Void)? = nil
    @State private var pulseScale: CGFloat = 1.0
    
    // Save Alert State
    @State private var showingSaveAlert = false
    @State private var recordingName = ""
    @State private var saveAudio = false // Default unchecked as requested
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Breathing animated gradient background
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.primary.opacity(0.18),
                        DesignSystem.Colors.accent.opacity(0.08),
                        DesignSystem.Colors.background
                    ],
                    startPoint: animateGradient ? .topLeading : .top,
                    endPoint: animateGradient ? .bottomTrailing : .bottom
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                        animateGradient = true
                    }
                }
                
                if !viewModel.speechService.isAuthorized {
                    permissionView
                } else {
                    recordingContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cleanup()
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                viewModel.speechService.checkAuthorization()
                // Auto-start recording after a brief delay, only if fully authorized
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let micGranted = AVAudioApplication.shared.recordPermission == .granted
                    if viewModel.speechService.isAuthorized && micGranted && !viewModel.isRecording {
                        viewModel.startRecording()
                    }
                }
            }
            .sheet(isPresented: $showingSaveAlert) {
                NavigationStack {
                    Form {
                        Section {
                            TextField("Recording Name", text: $recordingName)
                        }
                        
                        Section {
                            Toggle(isOn: $saveAudio) {
                                VStack(alignment: .leading) {
                                    Text("Save Audio Recording")
                                    Text(viewModel.formattedAudioSize)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } footer: {
                            Text("Audio recordings take up extra space on your device.")
                        }
                    }
                    .navigationTitle("Save Recording")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                // Just dismiss sheet, keep recording state (paused)
                                showingSaveAlert = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveRecording()
                                showingSaveAlert = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Permission View
    private var permissionView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "mic.slash.circle")
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.warning)
            
            Text("Microphone Access Required")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.label)
            
            Text("Recallix needs access to your microphone to record lectures. Please enable it in Settings.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .primaryButtonStyle()
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Recording Content
    private var recordingContent: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: DesignSystem.Spacing.lg)
            
            // Status indicator
            statusIndicator
                .padding(.bottom, DesignSystem.Spacing.md)
            
            // Timer
            Text(formatTime(viewModel.elapsedTime))
                .font(.system(size: 56, weight: .thin, design: .rounded))
                .foregroundColor(DesignSystem.Colors.label)
                .monospacedDigit()
                .padding(.bottom, DesignSystem.Spacing.lg)
            
            // Waveform area
            waveformSection
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            
            // Transcript area
            transcriptSection
                .padding(.horizontal, DesignSystem.Spacing.md)
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.warning)
                    .padding(.horizontal)
                    .padding(.top, DesignSystem.Spacing.xs)
            }
            
            Spacer()
            
            // Controls
            controlButtons
                .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Status Indicator
    private var statusIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            if viewModel.isRecording {
                Circle()
                    .fill(viewModel.isPaused ? DesignSystem.Colors.warning : Color.red)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseScale = 1.4
                        }
                    }
                
                Text(viewModel.isPaused ? "PAUSED" : "RECORDING")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(viewModel.isPaused ? DesignSystem.Colors.warning : .red)
                    .tracking(1.5)
            } else {
                Text("READY")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .tracking(1.5)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(viewModel.isRecording ?
                      (viewModel.isPaused ? DesignSystem.Colors.warning.opacity(0.12) : Color.red.opacity(0.12)) :
                      DesignSystem.Colors.secondaryBackground)
        )
    }
    
    // MARK: - Waveform Section
    private var waveformSection: some View {
        ZStack {
            if viewModel.isRecording && !viewModel.isPaused {
                WaveformView(audioLevel: viewModel.audioLevel)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
            } else {
                // Flat line when not recording
                HStack(spacing: 2.5) {
                    ForEach(0..<50, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DesignSystem.Colors.tertiaryLabel.opacity(0.3))
                            .frame(width: 3.5, height: 4)
                    }
                }
            }
        }
        .frame(height: 100)
    }
    
    // MARK: - Transcript Section
    private var transcriptSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    if viewModel.transcript.isEmpty {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 28))
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                            
                            Text("Your speech will appear here...")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.xl)
                    } else {
                        Text(viewModel.transcript)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .id("transcript")
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .frame(maxHeight: .infinity)
            .background(DesignSystem.Colors.transcriptBackground)
            .cornerRadius(DesignSystem.CornerRadius.xlarge)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .onChange(of: viewModel.transcript) { _, _ in
                withAnimation {
                    proxy.scrollTo("transcript", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: DesignSystem.Spacing.xxl) {
            if viewModel.isRecording {
                // Pause/Resume button
                Button(action: {
                    if viewModel.isPaused {
                        viewModel.resumeRecording()
                    } else {
                        viewModel.pauseRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.12))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
                // Stop button
                Button(action: {
                    viewModel.pauseRecording()
                    recordingName = ""
                    showingSaveAlert = true
                }) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.recordButton.opacity(0.12))
                            .frame(width: 64, height: 64)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.Colors.recordButton)
                            .frame(width: 22, height: 22)
                    }
                }
            } else {
                // Record button
                Button(action: {
                    viewModel.startRecording()
                }) {
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(DesignSystem.Colors.recordButton.opacity(0.3), lineWidth: 4)
                            .frame(width: 84, height: 84)
                        
                        // Inner circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.recordButton, DesignSystem.Colors.recordButton.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: DesignSystem.Colors.recordButton.opacity(0.4), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .sensoryFeedback(.impact, trigger: viewModel.isRecording)
            }
        }
    }
    
    // MARK: - Save Alert
    private func saveRecording() {
        Task {
            // If name is empty, viewModel will generate one
            if let lecture = await viewModel.stopRecording(title: recordingName.isEmpty ? nil : recordingName, saveAudio: saveAudio) {
                onSave?(lecture)
            }
            dismiss()
        }
    }
    
    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
