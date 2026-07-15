import Darwin
import Foundation
import Security

enum PlannerCredentialError: Error, Equatable, Sendable {
    case invalidProvisioningToken
    case provisioningNotVerified
    case keychain(OSStatus)
    case deletionNotVerified
}

protocol PlannerInstallCredentialLoading: Sendable {
    func provisionFromProcessEnvironment() throws
    func loadToken() throws -> String?
}

struct PlannerInstallCredentialStore: PlannerInstallCredentialLoading {
    static let environmentKey = "MA_INSTALL_TOKEN"

    private let service: String
    private let account: String

    init(
        service: String = "com.ia.ma.learning-planner.session-broker",
        account: String = "private-install-token"
    ) {
        self.service = service
        self.account = account
    }

    func provisionFromProcessEnvironment() throws {
        defer { unsetenv(Self.environmentKey) }
        guard let rawValue = ProcessInfo.processInfo.environment[Self.environmentKey] else {
            return
        }
        let token = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValid(token: token) else {
            throw PlannerCredentialError.invalidProvisioningToken
        }
        try Self.verifyProvisioning(
            token: token,
            save: save,
            load: loadToken
        )
    }

    func loadToken() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw PlannerCredentialError.keychain(status)
        }
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8),
              Self.isValid(token: token) else {
            throw PlannerCredentialError.invalidProvisioningToken
        }
        return token
    }

    func deleteToken() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PlannerCredentialError.keychain(status)
        }
    }

    func deleteTokenAndVerify() throws {
        try Self.verifyDeletion(
            delete: { try deleteToken() },
            load: { try loadToken() }
        )
    }

    static func verifyDeletion(
        delete: () throws -> Void,
        load: () throws -> String?
    ) throws {
        try delete()
        guard try load() == nil else {
            throw PlannerCredentialError.deletionNotVerified
        }
    }

    static func verifyProvisioning(
        token: String,
        save: (String) throws -> Void,
        load: () throws -> String?
    ) throws {
        try save(token)
        guard try load() == token else {
            throw PlannerCredentialError.provisioningNotVerified
        }
    }

    #if DEBUG
    func saveTokenForTesting(_ token: String) throws {
        guard Self.isValid(token: token) else {
            throw PlannerCredentialError.invalidProvisioningToken
        }
        try save(token)
    }
    #endif

    static func isValid(token: String) -> Bool {
        (32...512).contains(token.count)
            && token.unicodeScalars.allSatisfy { (0x21...0x7E).contains($0.value) }
    }

    private func save(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw PlannerCredentialError.invalidProvisioningToken
        }

        let updated = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updated == errSecSuccess {
            return
        }
        guard updated == errSecItemNotFound else {
            throw PlannerCredentialError.keychain(updated)
        }

        var item = baseQuery
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let added = SecItemAdd(item as CFDictionary, nil)
        guard added == errSecSuccess else {
            throw PlannerCredentialError.keychain(added)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
