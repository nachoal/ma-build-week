import Foundation
import Security

enum InstallCredentialError: LocalizedError, Equatable {
    case invalidProvisioningToken
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidProvisioningToken:
            "The private probe credential is missing or invalid."
        case .keychain:
            "The private probe credential could not be accessed securely."
        }
    }
}

enum InstallCredentialProvisioningResult: Equatable {
    case alreadyProvisioned
    case provisioned
    case missing
}

struct InstallTokenProvisioning {
    static let environmentKey = "MA_INSTALL_TOKEN"

    static func normalizedToken(in environment: [String: String]) -> String? {
        guard let rawValue = environment[environmentKey] else { return nil }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= 32, value.count <= 512 else { return nil }
        return value
    }
}

struct InstallCredentialStore {
    private let service = "com.ia.ma.audio-probe.session-broker"
    private let account = "private-install-token"

    func provisionFromProcessEnvironment(
        _ environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> InstallCredentialProvisioningResult {
        if let token = InstallTokenProvisioning.normalizedToken(in: environment) {
            try save(token)
            return .provisioned
        }
        return try loadToken() == nil ? .missing : .alreadyProvisioned
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
            throw InstallCredentialError.keychain(status)
        }
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            throw InstallCredentialError.invalidProvisioningToken
        }
        return token
    }

    private func save(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw InstallCredentialError.invalidProvisioningToken
        }

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw InstallCredentialError.keychain(updateStatus)
        }

        var item = baseQuery
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw InstallCredentialError.keychain(addStatus)
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
