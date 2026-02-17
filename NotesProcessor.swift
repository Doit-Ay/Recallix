import NaturalLanguage

/// Service for processing raw transcripts into structured notes.
/// Struct so it is automatically Sendable for Swift 6 concurrency.
struct NotesProcessor: Sendable {
    
    // Keywords to detect and highlight (Action Items only now needed manually)
    private let actionItemKeywords = [
        "assignment", "homework", "project", "paper",
        "deadline", "due date", "submit", "submission", "due on",
        "exam", "test", "quiz", "midterm", "final", "practice test"
    ]
    
    // Fallback/Emphasis keywords for Narrative importance
    private let narrativeEmphasisKeywords = [
        "important", "crucial", "critical", "key", "essential",
        "remember", "note that", "pay attention",
        "basically", "in short", "conclusion", "definition",
        "concept", "idea", "theme", "point", "takeaway",
        "ensure", "make sure"
    ]
    
    /// Process raw transcript into structured notes
    func processTranscript(_ transcript: String) -> String {
        let cleanTranscript = preprocessTranscript(transcript)
        let sentences = cleanTranscript.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var paragraphs: [String] = []
        var currentParagraph: [String] = []
        
        for (index, sentence) in sentences.enumerated() {
            currentParagraph.append(sentence)
            
            if currentParagraph.count >= 4 || index == sentences.count - 1 {
                let paragraph = currentParagraph.joined(separator: ". ") + "."
                paragraphs.append(paragraph)
                currentParagraph = []
            }
        }
        
        return paragraphs.joined(separator: "\n\n")
    }
    
    /// Pre-process transcript to fix run-on sentences based on transition words
    private func preprocessTranscript(_ text: String) -> String {
        var processed = text
        
        // List of transition words that likely start a new sentence if punctuation is missing
        let transitions = ["Next", "Also", "First", "Secondly", "Finally", "Moreover", "However", "Then"]
        
        for word in transitions {
            // Case 1: "word" (lowercase) followed by Capitalized Transition
            // e.g. "due next month Also we have" -> "due next month. Also we have"
            processed = processed.replacingOccurrences(of: " \(word) ", with: ". \(word) ")
            
            // Case 2: Lowercase transition in middle of run-on (less common with Dictation but possible)
            // e.g. "do this next verify that" -> "do this. Next verify that"
             processed = processed.replacingOccurrences(of: " \(word.lowercased()) ", with: ". \(word) ")
        }
        
        // Double spaces cleanup
        processed = processed.replacingOccurrences(of: "  ", with: " ")
        
        return processed
    }
    
    /// Generate summary from transcript
    func generateSummary(from transcript: String) -> LectureSummary? {
        let cleanTranscript = preprocessTranscript(transcript)
        let sentences = cleanTranscript.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var actionItems: [String] = []
        var narrativeSentences: [String] = []
        
        // 1. Scan all sentences and classify them immediately
        for (index, sentence) in sentences.enumerated() {
            let lowerSentence = sentence.lowercased()
             
            // PRIORITY 1: Detect Action Items (Assignments, Tests, Deadlines)
            if containsActionItemKeyword(lowerSentence) {
                // Add to Action Items list if unique
                if !actionItems.contains(sentence) {
                    actionItems.append(sentence)
                }
                // CRITICAL: Continue to next iteration immediately.
                // Do NOT allow this sentence to fall through to narrative logic.
                continue 
            }
            
            // PRIORITY 2: Context (First Sentence)
            // Only add if it wasn't an action item (handled above)
            if index == 0 && sentence.count > 10 {
                narrativeSentences.append(sentence)
                continue
            }
            
            // PRIORITY 3: Initial Context Extension (Second Sentence)
            // Only add if it wasn't an action item
            if index == 1 && sentence.count > 10 {
                if !narrativeSentences.contains(sentence) {
                    narrativeSentences.append(sentence)
                }
                continue
            }
            
            // PRIORITY 4: Narrative Importance (NLP + Keywords)
            // Skip intro lines (0, 1) as they are handled above
            if index >= 2 {
                if containsNarrativeKeyword(lowerSentence) || isSentenceImportantNLP(sentence) {
                    if !narrativeSentences.contains(sentence) {
                        narrativeSentences.append(sentence)
                    }
                }
            }
        }
        
        let summaryText = narrativeSentences.joined(separator: ". ") + "."
        
        // Return nil if we essentially found nothing new
        if narrativeSentences.isEmpty && actionItems.isEmpty {
           return nil
        }
        
        return LectureSummary(
            text: summaryText,
            actionItems: Array(actionItems.prefix(5))
        )
    }
    
    /// Extract key points from transcript (Legacy/Helper)
    func extractKeyPoints(from transcript: String) -> [String] {
        // Not used heavily anymore, but good for searching
        return []
    }
    
    // MARK: - Helper Methods
    
    private func containsActionItemKeyword(_ text: String) -> Bool {
        return actionItemKeywords.contains { text.contains($0) }
    }
    
    private func containsNarrativeKeyword(_ text: String) -> Bool {
        return narrativeEmphasisKeywords.contains { text.contains($0) }
    }
    
    /// Get highlighted ranges for keywords in text (Used by NotesViewModel)
    func getKeywordRanges(in text: String) -> [(range: Range<String.Index>, keyword: String)] {
        var ranges: [(range: Range<String.Index>, keyword: String)] = []
        let lowercased = text.lowercased()
        
        // Combine all keywords for highlighting
        let allKeywords = actionItemKeywords + narrativeEmphasisKeywords
        
        for keyword in allKeywords {
            var searchStartIndex = lowercased.startIndex
            
            while searchStartIndex < lowercased.endIndex,
                  let range = lowercased.range(of: keyword, range: searchStartIndex..<lowercased.endIndex) {
                ranges.append((range: range, keyword: keyword))
                searchStartIndex = range.upperBound
            }
        }
        
        return ranges
    }
    
    /// Check if text contains important keywords (Used by RecordingViewModel)
    func containsImportantKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let allKeywords = actionItemKeywords + narrativeEmphasisKeywords
        return allKeywords.contains { lowercased.contains($0) }
    }
    
    // MARK: - NLP Integration
    
    /// Uses NaturalLanguage framework to determine if a sentence mentions significant nouns/topics
    private func isSentenceImportantNLP(_ sentence: String) -> Bool {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = sentence
        
        var nounCount = 0
        var hasProperNoun = false
        
        tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
            if let tag = tag {
                if tag == .noun {
                    nounCount += 1
                }
                if tag == .personalName || tag == .placeName || tag == .organizationName {
                    hasProperNoun = true
                }
            }
            return true
        }
        
        // Heuristic: If a sentence has multiple nouns (likely technical terms) or proper names, it's probably important context.
        // Short sentences with 2+ nouns are usually "Topic X is Y."
        return nounCount >= 2 || hasProperNoun
    }
}
