import Foundation

@MainActor
final class CoachOutcomeTracker: ObservableObject {
    static let shared = CoachOutcomeTracker()

    private var pendingId: String?
    private var pendingExpiresAt: Date?

    private init() {}

    func startTracking(insightId: String) {
        pendingId = insightId
        pendingExpiresAt = Date().addingTimeInterval(5 * 60)
    }

    func foodLogged() {
        guard let id = activeId() else { return }
        CoachInsightLog.patchOutcome(id: id, outcome: "accepted")
        clear()
    }

    func insightRefreshed() {
        guard let id = activeId() else { return }
        CoachInsightLog.patchOutcome(id: id, outcome: "dismissed")
        clear()
    }

    func insightRegenerated(previousOutput: String, newOutput: String) {
        guard let id = activeId() else { return }
        let a = previousOutput.trimmingCharacters(in: .whitespaces).lowercased()
        let b = newOutput.trimmingCharacters(in: .whitespaces).lowercased()
        CoachInsightLog.patchOutcome(id: id, outcome: a == b ? "regenerated" : "refreshed")
        clear()
    }

    func finalizeIfExpired() {
        guard let expires = pendingExpiresAt, expires < Date(), let id = pendingId else { return }
        CoachInsightLog.patchOutcome(id: id, outcome: "ignored")
        clear()
    }

    private func activeId() -> String? {
        guard let expires = pendingExpiresAt, expires >= Date() else { return nil }
        return pendingId
    }

    private func clear() {
        pendingId = nil
        pendingExpiresAt = nil
    }
}
