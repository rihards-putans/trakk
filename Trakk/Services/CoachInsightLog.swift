import CryptoKit
import Foundation

enum CoachInsightLog {
    private static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Trakk")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("coach-insights.jsonl")
    }()

    static var logFileURL: URL { fileURL }

    @discardableResult
    static func append(prompt: String, inputs: [String: Any], output: String) -> String {
        let id = UUID().uuidString
        let promptHash = SHA256.hash(data: Data(prompt.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
            .prefix(12)
        let entry: [String: Any] = [
            "id": id,
            "ts": ISO8601DateFormatter().string(from: Date()),
            "prompt_hash": String(promptHash),
            "inputs": inputs,
            "output": output,
            "outcome": NSNull(),
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: entry, options: []),
              var line = String(data: data, encoding: .utf8) else { return id }
        line.append("\n")

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try? Data().write(to: fileURL, options: .atomic)
        }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        }
        return id
    }

    static func patchOutcome(id: String, outcome: String) {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8) else { return }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        for (i, line) in lines.enumerated() where line.contains("\"id\":\"\(id)\"") {
            lines[i] = line.replacingOccurrences(
                of: "\"outcome\":null",
                with: "\"outcome\":\"\(outcome)\""
            )
            break
        }
        try? lines.joined(separator: "\n").data(using: .utf8)?.write(to: fileURL, options: .atomic)
    }
}
