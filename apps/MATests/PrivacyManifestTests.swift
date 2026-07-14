import Foundation
import Testing
@testable import MA

@Suite("Shipping privacy manifest")
struct PrivacyManifestTests {
    @Test("Manifest is bundled, no-tracking, and declares actual aggregate data")
    func manifestContract() throws {
        let url = try #require(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        )
        let data = try Data(contentsOf: url)
        let root = try #require(
            PropertyListSerialization.propertyList(from: data, format: nil)
                as? [String: Any]
        )

        #expect(root["NSPrivacyTracking"] as? Bool == false)
        #expect((root["NSPrivacyTrackingDomains"] as? [String])?.isEmpty == true)

        let collected = try #require(
            root["NSPrivacyCollectedDataTypes"] as? [[String: Any]]
        )
        #expect(Set(collected.compactMap { $0["NSPrivacyCollectedDataType"] as? String }) == [
            "NSPrivacyCollectedDataTypeProductInteraction",
            "NSPrivacyCollectedDataTypeOtherUsageData",
        ])
        for declaration in collected {
            #expect(declaration["NSPrivacyCollectedDataTypeLinked"] as? Bool == false)
            #expect(declaration["NSPrivacyCollectedDataTypeTracking"] as? Bool == false)
            #expect(
                declaration["NSPrivacyCollectedDataTypePurposes"] as? [String]
                    == ["NSPrivacyCollectedDataTypePurposeAppFunctionality"]
            )
        }

        let accessed = try #require(
            root["NSPrivacyAccessedAPITypes"] as? [[String: Any]]
        )
        #expect(accessed.count == 1)
        #expect(
            accessed[0]["NSPrivacyAccessedAPIType"] as? String
                == "NSPrivacyAccessedAPICategoryUserDefaults"
        )
        #expect(accessed[0]["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"])
    }
}
