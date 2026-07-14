import Foundation

/// Stable scene identifiers, in curriculum order (todo.md §3 scene catalog).
enum SceneID: String, CaseIterable, Sendable, Hashable {
    case restaurant
    case izakaya
    case konbini
    case train
    case hotel
}

struct SceneInfo: Equatable, Sendable, Identifiable {
    let id: SceneID
    /// 1-based position in the learning path.
    let index: Int
    let title: String
    let subtitle: String
    /// Small Japanese accent shown with the scene — always accompanied by the
    /// Spanish title, never Japanese alone.
    let japaneseAccent: String
    let available: Bool
    /// Estimated minutes for the available slice.
    let minutes: Int?

    var statusLabel: String { available ? "DISPONIBLE" : "PRONTO" }
    var chipLabel: String { title }
}

/// The intent-first menu. Only the restaurant slice exists; the rest are the
/// visible road ahead, clearly labeled as upcoming — never dead buttons.
enum SceneCatalog {
    static let scenes: [SceneInfo] = [
        SceneInfo(
            id: .restaurant,
            index: 1,
            title: "Llegar a un restaurante",
            subtitle: "Pedir mesa para uno",
            japaneseAccent: "一人です",
            available: true,
            minutes: 3
        ),
        SceneInfo(
            id: .izakaya,
            index: 2,
            title: "Pedir en una izakaya",
            subtitle: "Un plato y una pregunta de vuelta",
            japaneseAccent: "注文",
            available: false,
            minutes: nil
        ),
        SceneInfo(
            id: .konbini,
            index: 3,
            title: "Pagar en el konbini",
            subtitle: "Bolsa, pago y recibo",
            japaneseAccent: "会計",
            available: false,
            minutes: nil
        ),
        SceneInfo(
            id: .train,
            index: 4,
            title: "Tomar el tren",
            subtitle: "Encontrar tu andén",
            japaneseAccent: "駅",
            available: false,
            minutes: nil
        ),
        SceneInfo(
            id: .hotel,
            index: 5,
            title: "Llegar al hotel",
            subtitle: "Check-in y una aclaración",
            japaneseAccent: "予約",
            available: false,
            minutes: nil
        ),
    ]

    static var hero: SceneInfo { scenes[0] }

    static func info(for id: SceneID) -> SceneInfo? {
        scenes.first { $0.id == id }
    }

    /// Upcoming (non-hero) scenes, with the learner's interests first — this
    /// is the visible effect of the onboarding choices. Catalog order is
    /// preserved within each group.
    static func upcomingScenes(orderedBy interests: Set<SceneID>) -> [SceneInfo] {
        let upcoming = scenes.filter { $0.id != hero.id }
        return upcoming.filter { interests.contains($0.id) }
            + upcoming.filter { !interests.contains($0.id) }
    }
}
