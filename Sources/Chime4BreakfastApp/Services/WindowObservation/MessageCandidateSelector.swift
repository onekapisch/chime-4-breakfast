import Foundation

struct MessageCandidateSelector {
    private enum Speaker {
        case assistant
        case user
        case unknown
    }

    private let blockedPhrases = [
        "search",
        "new chat",
        "settings",
        "continue",
        "open",
        "share",
        "history",
        "projects",
        "use cmd + i to generate code",
        "command k",
        "chatgpt",
        "claude desktop",
        "codex",
        "send",
        "stop",
        "stop response",
        "regenerate",
        "retry",
        "copy",
        "edit",
        "you",
        "claude",
        "reply to claude",
        "how can i help",
        "good response",
        "bad response"
    ]

    func select(from rawStrings: [String]) -> String? {
        let cleaned = rawStrings
            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, next in
                if result.last != next {
                    result.append(next)
                }
            }

        var currentSpeaker = Speaker.unknown
        var candidates: [(offset: Int, text: String, speaker: Speaker)] = []

        for (offset, text) in cleaned.enumerated() {
            if let speaker = speakerLabel(for: text) {
                currentSpeaker = speaker
                continue
            }

            if isActionLabel(text) {
                continue
            }

            guard isLikelyConversationText(text) else { continue }
            candidates.append((offset: offset, text: text, speaker: currentSpeaker))
        }

        let assistantCandidates = candidates.filter { $0.speaker == .assistant }
        if let latestAssistant = assistantCandidates.last {
            return latestAssistant.text
        }

        let qualifying = candidates.map { (offset: $0.offset, element: $0.text) }
        guard !qualifying.isEmpty else { return nil }

        let midpoint = cleaned.count / 2
        let recent = qualifying.filter { $0.offset >= midpoint }
        let pool = recent.isEmpty ? qualifying : recent

        return pool.max(by: { score(for: $0.element, index: $0.offset, total: cleaned.count) < score(for: $1.element, index: $1.offset, total: cleaned.count) })?.element
    }

    private func speakerLabel(for text: String) -> Speaker? {
        switch text.lowercased() {
        case "you", "user":
            return .user
        case "assistant", "claude", "codex", "chatgpt":
            return .assistant
        default:
            return nil
        }
    }

    private func isActionLabel(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return [
            "copy",
            "edit",
            "good response",
            "bad response",
            "retry",
            "regenerate",
            "reply to claude"
        ].contains(lowered)
    }

    private func isLikelyConversationText(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let words = lowered.split(separator: " ")

        if words.count < 3 || text.count < 18 {
            return false
        }

        if blockedPhrases.contains(where: { lowered == $0 || lowered.hasPrefix($0 + " ") }) {
            return false
        }

        return true
    }

    private func score(for text: String, index: Int, total: Int) -> Double {
        let lowered = text.lowercased()
        let words = text.split(separator: " ").count
        let recency = Double(index + 1) / Double(max(total, 1))
        let punctuationBonus = lowered.contains(".") || lowered.contains("?") || lowered.contains("!") || lowered.contains(":") ? 14.0 : 0.0
        let sentenceBonus = words >= 8 ? 10.0 : Double(words)
        let lengthBonus = min(Double(text.count), 140.0) * 0.14
        let markdownBonus = lowered.contains("```") || lowered.contains("`") ? 6.0 : 0.0
        let recencyBonus = recency * 24.0

        return punctuationBonus + sentenceBonus + lengthBonus + markdownBonus + recencyBonus
    }
}
