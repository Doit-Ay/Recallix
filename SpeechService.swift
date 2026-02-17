import Foundation
import Speech
import AVFoundation

/// Speech recognition service.
/// Class is @MainActor for UI state, but audio engine work happens
/// in nonisolated methods so closures don't inherit @MainActor.
@MainActor
class SpeechService: ObservableObject, @unchecked Sendable {
    
    // UI state — always on MainActor
    @Published var isAuthorized = false
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String?
    
    // Audio properties — nonisolated(unsafe) so nonisolated methods can access them
    private nonisolated(unsafe) var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private nonisolated(unsafe) var recognitionTask: SFSpeechRecognitionTask?
    private nonisolated(unsafe) var audioEngine = AVAudioEngine()
    private nonisolated(unsafe) var hasInstalledTap = false
    private nonisolated(unsafe) var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // Audio Persistence
    @Published var recordedAudioURL: URL?
    private nonisolated(unsafe) var audioFile: AVAudioFile?
    
    init() {}
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch currentStatus {
        case .authorized:
            self.isAuthorized = true
            self.errorMessage = nil
        case .denied, .restricted:
            self.isAuthorized = false
            self.errorMessage = "Speech recognition not authorized"
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isAuthorized = (authStatus == .authorized)
                    if authStatus != .authorized {
                        self.errorMessage = "Speech recognition not authorized"
                    } else {
                        self.errorMessage = nil
                    }
                }
            }
        @unknown default:
            self.isAuthorized = false
            self.errorMessage = "Speech recognition authorization unknown"
        }
    }
    
    // MARK: - Recording (MainActor methods for UI state)
    
    func startRecording() throws {
        if !isAuthorized {
            checkAuthorization()
            throw NSError(domain: "SpeechService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Speech recognition not authorized. Please grant permission in Settings."
            ])
        }
        
        // Audio setup in nonisolated context — critical for Swift 6
        // Closures defined in nonisolated methods don't inherit @MainActor
        try setupAndStartAudioEngine()
        
        isRecording = true
        errorMessage = nil
    }
    
    func stopRecording() {
        teardownAudioEngine()
        isRecording = false
        audioLevel = 0
    }
    
    func pauseRecording() {
        if isRecording {
            teardownAudioEngine()
            isRecording = false
            audioLevel = 0
        }
    }
    
    func resumeRecording() throws {
        if !isRecording {
            try startRecording()
        }
    }
    
    func reset() {
        transcript = ""
        errorMessage = nil
        audioLevel = 0
    }
    
    // MARK: - Audio Engine (nonisolated — closures here do NOT inherit @MainActor)
    
    /// Set up audio engine and start recognition.
    /// MUST be nonisolated so installTap/recognitionTask closures
    /// don't inherit @MainActor isolation and crash on audio threads.
    nonisolated private func setupAndStartAudioEngine() throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw NSError(domain: "SpeechService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Audio session setup failed. Please test on a real device.",
                NSLocalizedFailureReasonErrorKey: error.localizedDescription
            ])
        }
        
        // Create recognition request — capture as local variable for tap closure
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // On-device recognition is preferred for privacy/offline, but requires
        // the speech model to be downloaded on-device. If it isn't available,
        // recognition fails silently → empty transcript → save fails.
        // Default to server-side for reliability; set to true for SSC demo
        // on devices where the model is confirmed downloaded.
        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = false
            request.addsPunctuation = true
        }
        
        // Add contextual strings to help with technical terms
        request.contextualStrings = [
            "Recallix", "compiler", "lexical analysis", "syntax parsing", 
            "finite automata", "LL parsing", "LR parsing", "algorithm",
            "data structure", "optimization", "recursion", "database",
            "operating system", "network", "protocol", "interface",
            "polymorphism", "inheritance", "encapsulation", "abstraction",
            "constant folding", "loop unrolling", "control flow analysis",
            "code generation", "register allocation", "peephole optimizations",
            "semantic analysis", "type checking", "attribute grammars", 
            "runtime environments", "practice test", "homework"
        ]
        
        // optimize for dictation
        request.taskHint = .dictation
        
        recognitionRequest = request
        
        // Setup Audio File for Recording
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")
            
        Task { @MainActor [weak self] in
            self?.recordedAudioURL = tempURL
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        do {
            audioFile = try AVAudioFile(forWriting: tempURL, settings: recordingFormat.settings)
        } catch {
            print("Error creating audio file: \(error)")
            // Non-fatal, just won't save audio
        }
        
        // Remove existing tap
        if hasInstalledTap {
            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        
        // Install tap — this closure is NOT @MainActor because we're nonisolated
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            request.append(buffer)
            
            // Write to file
            do {
                try self?.audioFile?.write(from: buffer)
            } catch {
                print("Error writing audio buffer: \(error)")
            }
            
            // Calculate Audio Level (RMS)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let channelDataValue = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
            let rms = sqrt(channelDataValue.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
            let avgPower = 20 * log10(rms)
            
            // Normalize (-60dB to 0dB) -> (0.0 to 1.0)
            // Clamp to avoid -Infinity or OOB values
            let normalizedLevel = max(0.0, min(1.0, (avgPower + 60) / 60))
            
            // Update UI on MainActor (throttled naturally by tap frequency ~100ms)
            Task { @MainActor [weak self] in
                self?.audioLevel = normalizedLevel
            }
        }
        hasInstalledTap = true
        
        // Start engine
        if !audioEngine.isRunning {
            audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                throw NSError(domain: "SpeechService", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Audio engine failed to start. Please test on a real device.",
                    NSLocalizedFailureReasonErrorKey: error.localizedDescription
                ])
            }
        }
        
        // Start recognition — this callback is NOT @MainActor because we're nonisolated
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            // Extract value types on the callback thread (safe)
            let transcriptText = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let errorDesc = error?.localizedDescription
            
            // Hop to MainActor to update UI state
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                if let transcriptText {
                    self.transcript = transcriptText
                }
                
                if errorDesc != nil || isFinal {
                    self.teardownAudioEngine()
                    self.isRecording = false
                    if let errorDesc {
                        self.errorMessage = errorDesc
                    }
                }
            }
        }
    }
    
    /// Tear down audio engine. Nonisolated so it can safely touch
    /// audio engine properties without @MainActor queue assertions.
    nonisolated private func teardownAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        recognitionRequest?.endAudio()
        
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        
        recognitionRequest = nil
        recognitionTask = nil
        
        // Close audio file
        audioFile = nil // effectively closes it
    }
}
