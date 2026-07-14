import Foundation
import Testing
@testable import MAAudioProbe

@Suite("Probe evidence archive")
struct ProbeEvidenceArchiveTests {
    @Test("Archive writes only the supplied redacted snapshot")
    func protectedSnapshotWrite() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = ProbeEvidenceArchive(directoryURL: directory)
        let diagnostics = ProbeDiagnostics()
        await diagnostics.record(.lifecycle, details: ["state": "ready"])
        let snapshot = try await diagnostics.encodedSnapshot()

        let url = try await archive.writeRedactedSnapshot(snapshot)

        #expect(url.lastPathComponent == "gate0-redacted-evidence.json")
        #expect(try Data(contentsOf: url) == snapshot)
        #expect(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
            .isExcludedFromBackup == true)
    }

    @Test("Archive rejects a compound secret that bypassed upstream redaction")
    func unsafeSnapshotRejected() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = ProbeEvidenceArchive(directoryURL: directory)
        let event = ProbeDiagnosticEvent(
            sequence: 0,
            monotonicNanoseconds: 0,
            wallClock: Date(timeIntervalSince1970: 0),
            kind: .providerEvent,
            details: ["client_secret": "must-not-survive"],
            redactedProviderJSON: nil
        )
        let snapshot = ProbeDiagnosticSnapshot(
            schemaVersion: 1,
            generatedAt: Date(timeIntervalSince1970: 0),
            droppedEventCount: 0,
            events: [event]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)

        await #expect(throws: ProbeEvidenceArchive.ArchiveError.unsafeSnapshot) {
            try await archive.writeRedactedSnapshot(data)
        }
    }
}
