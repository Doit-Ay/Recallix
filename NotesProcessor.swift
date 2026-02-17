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
    
    /// Extract key points from transcript using NLP analysis
    func extractKeyPoints(from transcript: String) -> [String] {
        let cleanTranscript = preprocessTranscript(transcript)
        let sentences = cleanTranscript.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
        
        var keyPoints: [String] = []
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        
        for sentence in sentences {
            let lowerSentence = sentence.lowercased()
            
            // Skip action items — those go into summary.actionItems instead
            if containsActionItemKeyword(lowerSentence) { continue }
            
            var score = 0
            
            // 1. Definition patterns ("X is Y", "X means Y", "X refers to Y")
            let definitionPatterns = ["is defined as", "refers to", "is known as", "means that", "is a ", "is an ", "are called"]
            for pattern in definitionPatterns {
                if lowerSentence.contains(pattern) {
                    score += 3
                    break
                }
            }
            
            // 2. Emphasis keywords boost
            if containsNarrativeKeyword(lowerSentence) {
                score += 2
            }
            
            // 3. NLP analysis: noun density and named entities
            tagger.string = sentence
            var nounCount = 0
            var hasNamedEntity = false
            var wordCount = 0
            
            tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
                wordCount += 1
                if let tag = tag, tag == .noun {
                    nounCount += 1
                }
                return true
            }
            
            // Check for named entities (people, places, organizations)
            tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .nameType, options: [.omitPunctuation, .omitWhitespace, .joinNames]) { tag, _ in
                if let tag = tag, tag == .personalName || tag == .placeName || tag == .organizationName {
                    hasNamedEntity = true
                }
                return true
            }
            
            // High noun density → likely technical/informational
            if wordCount > 0 {
                let nounRatio = Double(nounCount) / Double(wordCount)
                if nounRatio > 0.35 { score += 2 }
                else if nounCount >= 3 { score += 1 }
            }
            
            if hasNamedEntity { score += 1 }
            
            // Threshold: score >= 2 qualifies as a key point
            if score >= 2 && !keyPoints.contains(sentence) {
                keyPoints.append(sentence)
            }
        }
        
        // Cap at 10 key points to keep it useful
        return Array(keyPoints.prefix(10))
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
        if allKeywords.contains(where: { lowercased.contains($0) }) {
            return true
        }
        return isSemanticallySimilarToKeyword(lowercased)
    }
    
    // MARK: - NLP Integration
    
    /// Seed concepts for semantic similarity matching
    private static let semanticSeeds = ["exam", "important", "concept", "deadline", "assignment", "definition"]
    
    /// Check semantic similarity using NLEmbedding
    /// Catches words like "midterm", "assessment", "prerequisite" that aren't in keyword lists
    private func isSemanticallySimilarToKeyword(_ text: String) -> Bool {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else { return false }
        
        let words = text.components(separatedBy: .whitespaces).filter { $0.count > 3 }
        for word in words {
            for seed in Self.semanticSeeds {
                let distance = embedding.distance(between: word.lowercased(), and: seed)
                if distance < 0.5 {
                    return true
                }
            }
        }
        return false
    }
    
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
