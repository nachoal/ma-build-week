import SwiftUI
import Testing
import UIKit
@testable import MA

/// Renders real screens at the reviewed 368×800 size and measures the ink
/// rail's actual pixel height, proving it hugs the phrase content instead of
/// stretching through flexible whitespace.
@MainActor
@Suite("Ink rails are content-height at 368×800")
struct RailLayoutTests {
    private let canvasWidth = 368
    private let canvasHeight = 800
    /// Rail spans x = 24...28 (side margin + 4pt width); sample its middle.
    private let railColumn = 26

    private func longestAiBlueRun(in view: some View, atColumn column: Int) -> Int {
        // SwiftUI only commits its render tree once hosted in a window.
        let host = UIHostingController(rootView: AnyView(view))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.backgroundColor = .white
        window.layoutIfNeeded()
        host.view.layoutIfNeeded()
        // One bounded main-queue drain so SwiftUI commits pending layout —
        // deterministic, not a wall-clock sleep.
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
        ) else { return -1 }
        host.view.layer.render(in: context)

        var longest = 0
        var current = 0
        for y in 0..<canvasHeight {
            let offset = (y * canvasWidth + column) * 4
            let r = Int(buffer[offset])
            let g = Int(buffer[offset + 1])
            let b = Int(buffer[offset + 2])
            // ai-blue #145CFF with tolerance; excludes mist (#EAF1FF).
            let isAiBlue = abs(r - 20) < 45 && abs(g - 92) < 45 && b > 200
            if isAiBlue {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }

    @Test("Setup phrase rail hugs the phrase block")
    func setupRailIsContentHeight() {
        let run = longestAiBlueRun(in: SetupView(send: { _ in }), atColumn: railColumn)
        // Content (phrase + romaji row + meaning) renders around 130–190pt.
        // A whitespace-stretched rail would exceed 300pt on this canvas.
        #expect(run > 60, "rail missing or not rendered (run \(run))")
        #expect(run < 300, "rail is absorbing flexible whitespace (run \(run))")
    }

    @Test("Coached full-scaffold rail hugs the answer block")
    func coachedRailIsContentHeight() {
        let coached = PracticeReducer.reduce(PracticeState(), .coachedRoundStarted(.full))
        let view = CoachedPracticeView(state: coached, send: { _ in })
        let run = longestAiBlueRun(in: view, atColumn: railColumn)
        #expect(run > 50, "rail missing or not rendered (run \(run))")
        #expect(run < 300, "rail is absorbing flexible whitespace (run \(run))")
    }
}
