import Foundation
import NaturalLanguage

@MainActor
final class SmartDetector: ObservableObject {
    private let languageRecognizer = NLLanguageRecognizer()
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .language])
    
    // MARK: - Content Analysis
    
    func analyzeContent(_ text: String) -> ContentAnalysis {
        var analysis = ContentAnalysis()
        
        // Basic text statistics
        analysis.wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        analysis.characterCount = text.count
        
        // Language detection
        languageRecognizer.reset()
        languageRecognizer.processString(text)
        analysis.detectedLanguage = languageRecognizer.dominantLanguage?.rawValue ?? "unknown"
        
        // Sentiment analysis
        analysis.sentiment = analyzeSentiment(text)
        
        // Extract key information
        analysis.entities = extractEntities(from: text)
        analysis.keyPhrases = extractKeyPhrases(from: text)
        analysis.actionItems = detectActionItems(in: text)
        
        // Smart categorization
        analysis.suggestedCategory = suggestCategory(for: text)
        analysis.priority = detectPriority(in: text)
        
        // Extract structured data
        analysis.dates = extractDates(from: text)
        analysis.phoneNumbers = extractPhoneNumbers(from: text)
        analysis.emailAddresses = extractEmailAddresses(from: text)
        analysis.urls = extractURLs(from: text)
        
        return analysis
    }
    
    // MARK: - Sentiment Analysis
    
    private func analyzeSentiment(_ text: String) -> SentimentAnalysis {
        // Simple keyword-based sentiment analysis for this demo
        let lowercased = text.lowercased()
        
        let positiveKeywords = ["great", "excellent", "amazing", "wonderful", "fantastic", "good", "happy", "excited", "love", "awesome"]
        let negativeKeywords = ["bad", "terrible", "awful", "horrible", "hate", "angry", "sad", "disappointed", "frustrated", "annoying"]
        
        let positiveCount = positiveKeywords.reduce(0) { count, keyword in
            count + (lowercased.contains(keyword) ? 1 : 0)
        }
        
        let negativeCount = negativeKeywords.reduce(0) { count, keyword in
            count + (lowercased.contains(keyword) ? 1 : 0)
        }
        
        let totalWords = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let positiveScore = Float(positiveCount) / max(Float(totalWords), 1.0)
        let negativeScore = Float(negativeCount) / max(Float(totalWords), 1.0)
        let neutralScore = max(0.0, 1.0 - positiveScore - negativeScore)
        
        let dominantSentiment: SentimentType
        if positiveScore > negativeScore && positiveScore > neutralScore {
            dominantSentiment = .positive
        } else if negativeScore > positiveScore && negativeScore > neutralScore {
            dominantSentiment = .negative
        } else {
            dominantSentiment = .neutral
        }
        
        let confidence = max(positiveScore, negativeScore, neutralScore)
        
        return SentimentAnalysis(
            type: dominantSentiment,
            confidence: confidence,
            positive: positiveScore,
            negative: negativeScore,
            neutral: neutralScore
        )
    }
    
    // MARK: - Entity Extraction
    
    private func extractEntities(from text: String) -> [EntityInfo] {
        tagger.string = text
        var entities: [EntityInfo] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let entity = String(text[tokenRange])
                let entityType = mapNLTagToEntityType(tag)
                entities.append(EntityInfo(text: entity, type: entityType, confidence: 0.8))
            }
            return true
        }
        
        return entities
    }
    
    private func mapNLTagToEntityType(_ tag: NLTag) -> EntityType {
        switch tag {
        case .personalName: return .person
        case .placeName: return .location
        case .organizationName: return .organization
        default: return .other
        }
    }
    
    // MARK: - Key Phrase Extraction
    
    private func extractKeyPhrases(from text: String) -> [String] {
        var keyPhrases: [String] = []
        
        tagger.string = text
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag, tag == .noun || tag == .adjective {
                let phrase = String(text[tokenRange])
                if phrase.count > 3 && !keyPhrases.contains(phrase.lowercased()) {
                    keyPhrases.append(phrase)
                }
            }
            return true
        }
        
        return Array(keyPhrases.prefix(10)) // Limit to top 10
    }
    
    // MARK: - Action Item Detection
    
    private func detectActionItems(in text: String) -> [ActionItem] {
        var actionItems: [ActionItem] = []
        let sentences = text.components(separatedBy: .punctuationCharacters)
        
        for sentence in sentences {
            let lowercased = sentence.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for action verbs and patterns
            let actionPatterns = [
                "todo", "to do", "need to", "should", "must", "have to",
                "remember to", "don't forget", "call", "email", "buy",
                "schedule", "meeting", "appointment", "deadline"
            ]
            
            for pattern in actionPatterns {
                if lowercased.contains(pattern) {
                    let priority = detectActionPriority(in: sentence)
                    actionItems.append(ActionItem(
                        text: sentence.trimmingCharacters(in: .whitespacesAndNewlines),
                        priority: priority,
                        type: .task
                    ))
                    break
                }
            }
        }
        
        return actionItems
    }
    
    private func detectActionPriority(in text: String) -> ActionPriority {
        let lowercased = text.lowercased()
        
        if lowercased.contains("urgent") || lowercased.contains("asap") || lowercased.contains("immediately") {
            return .high
        } else if lowercased.contains("important") || lowercased.contains("soon") {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Smart Categorization
    
    private func suggestCategory(for text: String) -> String? {
        let lowercased = text.lowercased()
        
        let categoryPatterns: [String: [String]] = [
            "Work": ["meeting", "project", "deadline", "client", "office", "work", "business", "professional"],
            "Personal": ["family", "friend", "personal", "home", "self", "hobby", "leisure"],
            "Shopping": ["buy", "purchase", "shop", "store", "grocery", "mall", "order"],
            "Health": ["doctor", "appointment", "medicine", "health", "exercise", "diet", "hospital"],
            "Finance": ["money", "bank", "payment", "budget", "expense", "income", "invest"],
            "Travel": ["trip", "travel", "flight", "hotel", "vacation", "journey", "destination"],
            "Education": ["study", "learn", "course", "school", "university", "book", "exam"],
            "Ideas": ["idea", "thought", "inspiration", "brainstorm", "creative", "innovation"]
        ]
        
        var categoryScores: [String: Int] = [:]
        
        for (category, patterns) in categoryPatterns {
            let score = patterns.reduce(0) { result, pattern in
                return result + (lowercased.contains(pattern) ? 1 : 0)
            }
            categoryScores[category] = score
        }
        
        return categoryScores.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Priority Detection
    
    private func detectPriority(in text: String) -> NotePriority {
        let lowercased = text.lowercased()
        
        let urgentKeywords = ["urgent", "asap", "emergency", "critical", "immediately", "now"]
        let highKeywords = ["important", "priority", "soon", "deadline", "must"]
        let lowKeywords = ["later", "maybe", "someday", "eventually", "when possible"]
        
        if urgentKeywords.contains(where: lowercased.contains) {
            return .urgent
        } else if highKeywords.contains(where: lowercased.contains) {
            return .high
        } else if lowKeywords.contains(where: lowercased.contains) {
            return .low
        } else {
            return .normal
        }
    }
    
    // MARK: - Data Extraction
    
    private func extractDates(from text: String) -> [Date] {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches.compactMap { match in
            match.date
        }
    }
    
    private func extractPhoneNumbers(from text: String) -> [String] {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches.compactMap { match in
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
            return nil
        }
    }
    
    private func extractEmailAddresses(from text: String) -> [String] {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches.compactMap { match in
            if let url = match.url, url.scheme == "mailto" {
                return url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
            }
            return nil
        }
    }
    
    private func extractURLs(from text: String) -> [String] {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches.compactMap { match in
            if let url = match.url, url.scheme != "mailto" {
                return url.absoluteString
            }
            return nil
        }
    }
}

// MARK: - Data Structures

struct ContentAnalysis {
    var wordCount: Int = 0
    var characterCount: Int = 0
    var detectedLanguage: String = "unknown"
    var sentiment: SentimentAnalysis = SentimentAnalysis(type: .neutral, confidence: 0, positive: 0, negative: 0, neutral: 1)
    var entities: [EntityInfo] = []
    var keyPhrases: [String] = []
    var actionItems: [ActionItem] = []
    var suggestedCategory: String?
    var priority: NotePriority = .normal
    var dates: [Date] = []
    var phoneNumbers: [String] = []
    var emailAddresses: [String] = []
    var urls: [String] = []
}

struct SentimentAnalysis {
    let type: SentimentType
    let confidence: Float
    let positive: Float
    let negative: Float
    let neutral: Float
}

enum SentimentType: String, CaseIterable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .negative: return "Negative"
        case .neutral: return "Neutral"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
}

struct EntityInfo {
    let text: String
    let type: EntityType
    let confidence: Float
}

enum EntityType: String, CaseIterable {
    case person = "person"
    case location = "location"
    case organization = "organization"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .person: return "Person"
        case .location: return "Location"
        case .organization: return "Organization"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .person: return "person.fill"
        case .location: return "location.fill"
        case .organization: return "building.2.fill"
        case .other: return "tag.fill"
        }
    }
}

struct ActionItem {
    let text: String
    let priority: ActionPriority
    let type: ActionType
}

enum ActionPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum ActionType: String, CaseIterable {
    case task = "task"
    case reminder = "reminder"
    case appointment = "appointment"
    case call = "call"
    case email = "email"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var iconName: String {
        switch self {
        case .task: return "checkmark.circle"
        case .reminder: return "bell"
        case .appointment: return "calendar"
        case .call: return "phone"
        case .email: return "envelope"
        }
    }
}