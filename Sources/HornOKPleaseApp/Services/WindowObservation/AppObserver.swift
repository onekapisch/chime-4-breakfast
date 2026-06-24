import Foundation

final class AppObserver {
    private let classifier: MessageClassifier

    init(classifier: MessageClassifier = MessageClassifier()) {
        self.classifier = classifier
    }

    func process(_ snapshot: WindowSnapshot, extraPhrases: [String] = []) -> ObservedEvent? {
        return ObservedEvent(
            sourceApp: snapshot.app,
            eventType: classifier.classify(snapshot.message, extraPhrases: extraPhrases),
            message: snapshot.message,
            fingerprint: snapshot.fingerprint
        )
    }
}
