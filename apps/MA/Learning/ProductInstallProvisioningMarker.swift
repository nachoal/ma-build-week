import Foundation

/// A value-free, per-run receipt used only by the authorized local installer.
/// The random nonce is not a credential. The first phase records exact Keychain
/// readback; the second bearer-free launch records a full, policy-verified
/// Realtime session. A normal launch removes both receipts.
enum ProductInstallProvisioningMarker {
    static let environmentKey = "MA_INSTALL_PROVISION_NONCE"
    static let storedFilePrefix = "ma-release-review-access-stored-"
    static let readyFilePrefix = "ma-release-review-access-ready-"

    static func validatedNonce(_ rawValue: String?) -> String? {
        guard let rawValue, rawValue.count == 32,
              rawValue.utf8.allSatisfy({ byte in
                  (48...57).contains(byte) || (97...102).contains(byte)
              }) else {
            return nil
        }
        return rawValue
    }

    static func removeReceipts(in directory: URL) throws {
        let manager = FileManager.default
        guard manager.fileExists(atPath: directory.path) else { return }
        for url in try manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) where url.lastPathComponent.hasPrefix(storedFilePrefix)
            || url.lastPathComponent.hasPrefix(readyFilePrefix) {
            try manager.removeItem(at: url)
        }
    }

    static func writeStoredReceipt(nonce: String, in directory: URL) throws {
        try writeReceipt(
            value: "stored",
            prefix: storedFilePrefix,
            nonce: nonce,
            in: directory
        )
    }

    static func writeReadyReceipt(nonce: String, in directory: URL) throws {
        try writeReceipt(
            value: "ready",
            prefix: readyFilePrefix,
            nonce: nonce,
            in: directory
        )
    }

    private static func writeReceipt(
        value: String,
        prefix: String,
        nonce: String,
        in directory: URL
    ) throws {
        guard validatedNonce(nonce) != nil else {
            throw PlannerCredentialError.invalidProvisioningToken
        }
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data(value.utf8).write(
            to: directory.appendingPathComponent(prefix + nonce),
            options: .atomic
        )
    }

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
