import Foundation

/// What the learner told us at onboarding. Local-only, no account, no
/// analytics — persisted as plain AppStorage primitives.
enum JapaneseLevel: String, CaseIterable, Sendable {
    case zero
    case fewWords

    var spanishLabel: String {
        switch self {
        case .zero: "Cero japonés"
        case .fewWords: "Algunas palabras sueltas"
        }
    }
}

enum TripGoal: String, CaseIterable, Sendable {
    case firstTrip
    case bookedTrip
    case practicalNoTrip

    var spanishLabel: String {
        switch self {
        case .firstTrip: "Preparar mi primer viaje a Japón"
        case .bookedTrip: "Ya tengo viaje reservado"
        case .practicalNoTrip: "Práctica útil, sin viaje todavía"
        }
    }
}

enum DailyPractice: Int, CaseIterable, Sendable {
    case short = 5
    case regular = 10
    case long = 15

    var spanishLabel: String { "\(rawValue) min al día" }
}

struct LearnerProfile: Equatable, Sendable {
    var level: JapaneseLevel = .zero
    var goal: TripGoal = .firstTrip
    /// The restaurant scene is the mandatory, ready first scene and is always
    /// present. Everything else here is an optional *interest* used only to
    /// order the upcoming (PRONTO) roadmap.
    var situations: Set<SceneID> = [.restaurant]
    var dailyMinutes: DailyPractice = .regular

    static let standard = LearnerProfile()

    /// Optional interests only — the mandatory restaurant scene is excluded.
    var interests: Set<SceneID> { situations.subtracting([.restaurant]) }

    /// Toggles an optional interest. The restaurant scene is non-removable
    /// and non-toggleable: it is the product's first scene, not a choice.
    mutating func toggleSituation(_ id: SceneID) {
        guard id != .restaurant else { return }
        if situations.contains(id) {
            situations.remove(id)
        } else {
            situations.insert(id)
        }
    }

    // MARK: Raw persistence (AppStorage primitives)

    var rawLevel: String { level.rawValue }
    var rawGoal: String { goal.rawValue }
    var rawSituations: String {
        SceneID.allCases.filter(situations.contains).map(\.rawValue).joined(separator: ",")
    }
    var rawDailyMinutes: Int { dailyMinutes.rawValue }

    /// Tolerant decoding: any unknown or corrupt raw value falls back to the
    /// standard profile field rather than failing.
    static func fromRaw(
        level: String, goal: String, situations: String, dailyMinutes: Int
    ) -> LearnerProfile {
        var profile = LearnerProfile.standard
        if let decoded = JapaneseLevel(rawValue: level) { profile.level = decoded }
        if let decoded = TripGoal(rawValue: goal) { profile.goal = decoded }
        if let decoded = DailyPractice(rawValue: dailyMinutes) { profile.dailyMinutes = decoded }
        let decodedScenes = situations.split(separator: ",").compactMap {
            SceneID(rawValue: String($0))
        }
        if !decodedScenes.isEmpty { profile.situations = Set(decodedScenes) }
        // The mandatory first scene survives any stored value.
        profile.situations.insert(.restaurant)
        return profile
    }
}
