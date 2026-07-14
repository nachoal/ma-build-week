import Foundation

actor ProbeEvidenceArchive {
    enum ArchiveError: Error {
        case applicationSupportUnavailable
    }

    private let directoryURL: URL?

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL
    }

    func writeRedactedSnapshot(_ data: Data) throws -> URL {
        let directory: URL
        if let directoryURL {
            directory = directoryURL
        } else {
            guard let applicationSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw ArchiveError.applicationSupportUnavailable
            }
            directory = applicationSupport.appendingPathComponent(
                "Gate0Evidence",
                isDirectory: true
            )
        }

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        var directoryValues = URLResourceValues()
        directoryValues.isExcludedFromBackup = true
        var mutableDirectory = directory
        try mutableDirectory.setResourceValues(directoryValues)

        let destination = directory.appendingPathComponent(
            "gate0-redacted-evidence.json",
            isDirectory: false
        )
        try data.write(
            to: destination,
            options: [.atomic, .completeFileProtection]
        )
        return destination
    }
}
