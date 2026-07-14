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
        let snapshot = Data(#"{"schemaVersion":1,"events":[]}"#.utf8)

        let url = try await archive.writeRedactedSnapshot(snapshot)

        #expect(url.lastPathComponent == "gate0-redacted-evidence.json")
        #expect(try Data(contentsOf: url) == snapshot)
        #expect(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
            .isExcludedFromBackup == true)
    }
}
