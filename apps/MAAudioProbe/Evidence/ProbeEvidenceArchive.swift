import Foundation

actor ProbeEvidenceArchive {
    enum ArchiveError: Error, Equatable {
        case applicationSupportUnavailable
        case unsafeSnapshot
    }

    private let directoryURL: URL?

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL
    }

    func writeRedactedSnapshot(_ data: Data) throws -> URL {
        guard ProbeEvidenceExportValidator.isSafe(data) else {
            throw ArchiveError.unsafeSnapshot
        }
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

private enum ProbeEvidenceExportValidator {
    private static let sensitiveExactKeys: Set<String> = [
        "authorization", "secret", "token", "value",
    ]
    private static let sensitiveKeyFragments = [
        "api_key", "apikey", "authorization", "credential", "secret", "token",
    ]
    private static let forbiddenValueFragments = ["bearer ", "ek_", "sk-"]

    static func isSafe(_ data: Data) -> Bool {
        guard !data.isEmpty, data.count <= 16_777_216 else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(ProbeDiagnosticSnapshot.self, from: data),
              snapshot.schemaVersion == 1 else {
            return false
        }
        for event in snapshot.events {
            guard dictionaryIsSafe(event.details) else { return false }
            if let redactedProviderJSON = event.redactedProviderJSON {
                guard let providerData = redactedProviderJSON.data(using: .utf8),
                      let providerObject = try? JSONSerialization.jsonObject(with: providerData),
                      objectIsSafe(providerObject, key: nil) else {
                    return false
                }
            }
        }
        return true
    }

    private static func dictionaryIsSafe(_ dictionary: [String: String]) -> Bool {
        dictionary.allSatisfy { key, value in
            let sensitive = keyIsSensitive(key)
            return (!sensitive || value == "<redacted>") && valueIsSafe(value)
        }
    }

    private static func objectIsSafe(_ value: Any, key: String?) -> Bool {
        if let key, keyIsSensitive(key) {
            return (value as? String) == "<redacted>"
        }
        if let dictionary = value as? [String: Any] {
            return dictionary.allSatisfy { nestedKey, nestedValue in
                objectIsSafe(nestedValue, key: nestedKey)
            }
        }
        if let array = value as? [Any] {
            return array.allSatisfy { objectIsSafe($0, key: nil) }
        }
        if let string = value as? String {
            return valueIsSafe(string)
        }
        return value is NSNumber || value is NSNull
    }

    private static func keyIsSensitive(_ key: String) -> Bool {
        let lowered = key.lowercased()
        return sensitiveExactKeys.contains(lowered)
            || sensitiveKeyFragments.contains(where: lowered.contains)
    }

    private static func valueIsSafe(_ value: String) -> Bool {
        let lowered = value.lowercased()
        return !forbiddenValueFragments.contains(where: lowered.contains)
    }
}
