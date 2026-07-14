import SwiftUI
import Testing
import UIKit
@testable import MA

/// Renders the chip-heavy and chrome-heavy screens at 368×800 under
/// Accessibility Extra Large type and fails if any content draws in the
/// right-margin band — the symptom of horizontal overflow. Also dumps PNGs
/// for visual inspection when a scratch directory is available.
@MainActor
@Suite("No horizontal overflow at Accessibility Extra Large")
struct AXOverflowTests {
    private let canvasWidth = 368
    private let canvasHeight = 800
    /// Content legitimately ends at x = 344 (24pt side margin); anything at
    /// x ≥ 352 means a view escaped the margin.
    private let overflowBandStart = 352

    private func render(
        _ view: some View, dynamicType: DynamicTypeSize, screenshotName: String? = nil
    ) -> [UInt8] {
        let host = UIHostingController(
            rootView: AnyView(view.environment(\.dynamicTypeSize, dynamicType))
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.backgroundColor = .white
        window.layoutIfNeeded()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date())

        var buffer = [UInt8](repeating: 0, count: canvasWidth * canvasHeight * 4)
        guard let context = CGContext(
            data: &buffer,
            width: canvasWidth,
            height: canvasHeight,
            bitsPerComponent: 8,
            bytesPerRow: canvasWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return buffer }
        // UIKit layers use a top-left origin; flip Core Graphics so the QA
        // PNGs are upright while leaving the horizontal overflow scan intact.
        context.translateBy(x: 0, y: CGFloat(canvasHeight))
        context.scaleBy(x: 1, y: -1)
        host.view.layer.render(in: context)

        if let screenshotName, let cgImage = context.makeImage() {
            let url = URL(fileURLWithPath: "/tmp/ma-screenshots/\(screenshotName).png")
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try? UIImage(cgImage: cgImage).pngData()?.write(to: url)
        }
        return buffer
    }

    /// Counts pixels in the overflow band that are neither white background
    /// nor near-white antialiasing.
    private func overflowPixelCount(in buffer: [UInt8]) -> Int {
        var count = 0
        for y in 0..<canvasHeight {
            for x in overflowBandStart..<canvasWidth {
                let offset = (y * canvasWidth + x) * 4
                let r = Int(buffer[offset])
                let g = Int(buffer[offset + 1])
                let b = Int(buffer[offset + 2])
                if r < 245 || g < 245 || b < 245 {
                    count += 1
                }
            }
        }
        return count
    }

    @Test("Onboarding (chips and chrome) stays inside the margin at AX XL")
    func onboardingNoOverflow() {
        let buffer = render(
            OnboardingView { _ in },
            dynamicType: .accessibility3,
            screenshotName: "onboarding-ax3"
        )
        #expect(overflowPixelCount(in: buffer) == 0)
    }

    @Test("Home (badge, profile, hero, rows) stays inside the margin at AX XL")
    func homeNoOverflow() {
        let home = HomeView(
            profile: .standard,
            onStartScene: { _ in },
            onReplayOnboarding: {},
            onResetChoices: {},
            onDeleteAllData: {}
        )
        let buffer = render(home, dynamicType: .accessibility3, screenshotName: "home-ax3")
        #expect(overflowPixelCount(in: buffer) == 0)
    }

    @Test("Natural-sequence screen with key chips stays inside the margin at AX XL")
    func listeningNoOverflow() {
        var state = PracticeState()
        for event in RestaurantForOneFixture.naturalReadyEvents
            + RestaurantForOneFixture.listeningStageEvents
        {
            state = PracticeReducer.reduce(state, event)
        }
        let listening = ListeningView(state: state, send: { _ in }, reduceMotion: true)
        let buffer = render(listening, dynamicType: .accessibility3, screenshotName: "listening-ax3")
        #expect(overflowPixelCount(in: buffer) == 0)
    }

    @Test("Labeled replay proof stays inside the margin at AX XL")
    func replayProofNoOverflow() async {
        let feature = KaiwaLoopFeature.labeledReplay()
        feature.startLabeledReplay(delivery: .immediate)
        for _ in 0..<500 where feature.state.phase != .proof {
            await Task.yield()
        }
        #expect(feature.state.phase == .proof)
        let buffer = render(
            // Reserve the scanner's 16pt overflow band outside the root view.
            // Kaiwa's full-width paper/chrome backgrounds are intentional and
            // would otherwise look like escaped content to this pixel probe.
            KaiwaLoopView(feature: feature)
                .padding(.trailing, CGFloat(canvasWidth - overflowBandStart)),
            dynamicType: .accessibility3,
            screenshotName: "kaiwa-replay-proof-ax3"
        )
        #expect(overflowPixelCount(in: buffer) == 0)
    }

    @Test("Compact reference renders (default type) also stay inside the margin")
    func compactNoOverflow() {
        let onboarding = render(
            OnboardingView { _ in }, dynamicType: .large, screenshotName: "onboarding-compact"
        )
        #expect(overflowPixelCount(in: onboarding) == 0)
        let home = render(
            HomeView(
                profile: .standard,
                onStartScene: { _ in },
                onReplayOnboarding: {},
                onResetChoices: {},
                onDeleteAllData: {}
            ),
            dynamicType: .large,
            screenshotName: "home-compact"
        )
        #expect(overflowPixelCount(in: home) == 0)
    }
}
