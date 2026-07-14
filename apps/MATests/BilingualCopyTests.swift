import Foundation
import Testing
@testable import MA

@Suite("English and Spanish shipping copy")
struct BilingualCopyTests {
    @Test("Fresh installs default to English and expose a reversible language choice")
    func defaultLanguage() {
        #expect(MAInterfaceLanguage.defaultLanguage == .english)
        #expect(MAInterfaceLanguage.english.toggled == .spanish)
        #expect(MAInterfaceLanguage.spanish.toggled == .english)
    }

    @Test("Profile and scene labels are complete in both interface languages")
    func domainCopy() {
        for language in MAInterfaceLanguage.allCases {
            for level in JapaneseLevel.allCases {
                #expect(!level.label(in: language).isEmpty)
            }
            for goal in TripGoal.allCases {
                #expect(!goal.label(in: language).isEmpty)
            }
            for pace in DailyPractice.allCases {
                #expect(!pace.label(in: language).isEmpty)
            }
            for scene in SceneCatalog.scenes {
                #expect(!scene.title(in: language).isEmpty)
                #expect(!scene.subtitle(in: language).isEmpty)
                #expect(!scene.statusLabel(in: language).isEmpty)
            }
            for failure in [
                GuidedAttemptFailure.microphoneDenied,
                .noSpeech,
                .reviewUnavailable,
                .interrupted,
            ] {
                #expect(!failure.message(in: language).isEmpty)
            }
            for failure in productAudioFailures {
                #expect(!failure.message(in: language).isEmpty)
            }
            for failure in guidedRealtimeFailures {
                #expect(!failure.message(in: language).isEmpty)
            }
        }
        #expect(SceneCatalog.hero.title(in: .english) == "Arrive at a restaurant")
        #expect(SceneCatalog.hero.title(in: .spanish) == "Llegar a un restaurante")
    }

    @Test("A Realtime review contains renderable feedback in both languages")
    func bilingualReview() {
        let review = GuidedAttemptReview.unclear(attemptID: UUID())
        for language in MAInterfaceLanguage.allCases {
            #expect(!review.positive(in: language).isEmpty)
            #expect(review.correction(in: language)?.isEmpty == false)
            #expect(review.retryFocus(in: language)?.isEmpty == false)
        }
    }

    @Test("The app bundle carries localized microphone permission explanations")
    func localizedMicrophonePurposeStrings() throws {
        let english = try permissionString(localization: "en")
        let spanish = try permissionString(localization: "es")
        #expect(english.contains("directly to OpenAI"))
        #expect(english.contains("does not save a recording"))
        #expect(spanish.contains("directamente a OpenAI"))
        #expect(spanish.contains("no guarda una grabación"))
    }

    private func permissionString(localization: String) throws -> String {
        let url = try #require(Bundle.main.url(
            forResource: "InfoPlist",
            withExtension: "strings",
            subdirectory: nil,
            localization: localization
        ))
        let data = try Data(contentsOf: url)
        let object = try PropertyListSerialization.propertyList(from: data, format: nil)
        let dictionary = try #require(object as? [String: String])
        return try #require(dictionary["NSMicrophoneUsageDescription"])
    }

    private var productAudioFailures: [ProductAudioFailure] {
        [
            .missingAsset(.hitoriDesu), .microphoneDenied, .playbackInProgress,
            .captureInProgress, .captureNotRunning, .invalidAudioFormat,
            .invalidProviderAudio, .hardwareUnavailable, .interrupted,
        ]
    }

    private var guidedRealtimeFailures: [GuidedRealtimeError] {
        [
            .missingCredential, .unauthorized, .rateLimited, .serviceUnavailable,
            .invalidBrokerResponse, .invalidClientSecret, .connectionFailed,
            .configurationMismatch, .disconnected, .invalidAudio, .noSpeech,
            .providerRejected, .invalidReview, .responseTimedOut,
            .responseIncomplete, .playbackUnavailable,
        ]
    }
}
