import Foundation
import Testing
@testable import MA

@Suite("Release install provisioning")
struct InstallCredentialProvisioningTests {
    @Test("A provisioning write must survive an exact Keychain readback")
    func provisioningIsReadBackBeforeSuccess() throws {
        let token = String(repeating: "p", count: 32)
        var stored: String?
        var operations: [String] = []

        try PlannerInstallCredentialStore.verifyProvisioning(
            token: token,
            save: { value in
                operations.append("save")
                stored = value
            },
            load: {
                operations.append("load")
                return stored
            }
        )

        #expect(stored == token)
        #expect(operations == ["save", "load"])
    }

    @Test("A missing or changed readback fails closed")
    func mismatchedReadbackIsRejected() {
        #expect(throws: PlannerCredentialError.provisioningNotVerified) {
            try PlannerInstallCredentialStore.verifyProvisioning(
                token: String(repeating: "p", count: 32),
                save: { _ in },
                load: { String(repeating: "q", count: 32) }
            )
        }
    }

    @Test("Only a bounded lowercase hexadecimal install nonce is accepted", arguments: [
        "",
        String(repeating: "a", count: 31),
        String(repeating: "a", count: 33),
        String(repeating: "A", count: 32),
        String(repeating: "z", count: 32),
        String(repeating: "-", count: 32),
    ])
    func invalidNonceIsRejected(_ nonce: String) {
        #expect(ProductInstallProvisioningMarker.validatedNonce(nonce) == nil)
    }

    @Test("The installer receipt contains no credential and cleanup is prefix-scoped")
    func valueFreeReceiptLifecycle() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let nonce = String(repeating: "a", count: 32)
        let unrelated = directory.appendingPathComponent("keep-me")
        try Data("unrelated".utf8).write(to: unrelated)

        try ProductInstallProvisioningMarker.writeStoredReceipt(
            nonce: nonce,
            in: directory
        )
        let storedReceipt = directory.appendingPathComponent(
            ProductInstallProvisioningMarker.storedFilePrefix + nonce
        )
        #expect(try String(contentsOf: storedReceipt, encoding: .utf8) == "stored")
        try ProductInstallProvisioningMarker.writeReadyReceipt(
            nonce: nonce,
            in: directory
        )
        let readyReceipt = directory.appendingPathComponent(
            ProductInstallProvisioningMarker.readyFilePrefix + nonce
        )
        #expect(try String(contentsOf: readyReceipt, encoding: .utf8) == "ready")

        try ProductInstallProvisioningMarker.removeReceipts(in: directory)
        #expect(!FileManager.default.fileExists(atPath: storedReceipt.path))
        #expect(!FileManager.default.fileExists(atPath: readyReceipt.path))
        #expect(FileManager.default.fileExists(atPath: unrelated.path))
    }
}
