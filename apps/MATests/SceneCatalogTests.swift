import Testing
@testable import MA

@Suite("Scene catalog: honest menu, one available slice")
struct SceneCatalogTests {
    @Test("Five scenes in curriculum order with unique ids")
    func orderAndUniqueness() {
        let scenes = SceneCatalog.scenes
        #expect(scenes.count == 5)
        #expect(scenes.map(\.id) == [.restaurant, .izakaya, .konbini, .train, .hotel])
        #expect(scenes.map(\.index) == [1, 2, 3, 4, 5])
        #expect(Set(scenes.map(\.id)).count == scenes.count)
    }

    @Test("Only the restaurant slice is available")
    func onlyRestaurantAvailable() {
        for scene in SceneCatalog.scenes {
            #expect(scene.available == (scene.id == .restaurant))
        }
    }

    @Test("The hero is the restaurant scene with the Paper copy")
    func heroScene() {
        let hero = SceneCatalog.hero
        #expect(hero.id == .restaurant)
        #expect(hero.title == "Llegar a un restaurante")
        #expect(hero.subtitle == "Pedir mesa para uno")
        #expect(hero.japaneseAccent == RestaurantForOneFixture.phraseJapanese)
        #expect(hero.minutes != nil)
    }

    @Test("Upcoming scenes are labeled, never silent dead entries")
    func upcomingScenesLabeled() {
        for scene in SceneCatalog.scenes where !scene.available {
            #expect(scene.statusLabel == "PRONTO")
            #expect(!scene.title.isEmpty)
            #expect(!scene.subtitle.isEmpty)
        }
        #expect(SceneCatalog.hero.statusLabel == "DISPONIBLE")
    }

    @Test("Catalog lookup resolves every id")
    func lookup() {
        for id in SceneID.allCases {
            #expect(SceneCatalog.info(for: id)?.id == id)
        }
    }

    @Test("Interests visibly reorder the upcoming roadmap")
    func interestsOrderUpcoming() {
        // No interests: catalog order, hero excluded.
        #expect(
            SceneCatalog.upcomingScenes(orderedBy: []).map(\.id)
                == [.izakaya, .konbini, .train, .hotel]
        )
        // Interested scenes come first, keeping catalog order in each group.
        #expect(
            SceneCatalog.upcomingScenes(orderedBy: [.train]).map(\.id)
                == [.train, .izakaya, .konbini, .hotel]
        )
        #expect(
            SceneCatalog.upcomingScenes(orderedBy: [.hotel, .konbini]).map(\.id)
                == [.konbini, .hotel, .izakaya, .train]
        )
        // The hero can never appear in the upcoming list.
        #expect(
            !SceneCatalog.upcomingScenes(orderedBy: [.restaurant])
                .contains { $0.id == .restaurant }
        )
    }
}
