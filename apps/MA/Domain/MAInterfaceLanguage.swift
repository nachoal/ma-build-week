import SwiftUI

enum MAInterfaceLanguage: String, CaseIterable, Codable, Equatable, Sendable {
    case english = "en"
    case spanish = "es"

    static let defaultLanguage: MAInterfaceLanguage = .english

    var toggled: MAInterfaceLanguage {
        self == .english ? .spanish : .english
    }

    var shortLabel: String {
        rawValue.uppercased()
    }

    func text(english: String, spanish: String) -> String {
        self == .english ? english : spanish
    }
}

private struct MAInterfaceLanguageKey: EnvironmentKey {
    static let defaultValue = MAInterfaceLanguage.defaultLanguage
}

extension EnvironmentValues {
    var maInterfaceLanguage: MAInterfaceLanguage {
        get { self[MAInterfaceLanguageKey.self] }
        set { self[MAInterfaceLanguageKey.self] = newValue }
    }
}
