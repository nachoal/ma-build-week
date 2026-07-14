# MA agent instructions

## Hard gate

- Read todo.md before changing code.
- Gate 0 is a hard 24-clock-hour spike. After `started_at` is written,
  `MAAudioProbe` may implement and measure the live overlap experiment. Binding
  overlap behavior into the `MA` product target and making any overlap claim
  remain blocked until `docs/poc/verdict.md` records PASS. PARTIAL unlocks
  Kaiwa Loop only and is automatic at the deadline.
- Under PARTIAL, transport and replay permissions are independent. Kaiwa Loop
  may use live Realtime conversation with explicit, non-overlap floor control
  only when Experiment 0 proved that exact topology; otherwise its tutor audio
  is bundled and local. It may claim/replay a rendered window only to the extent
  Experiment D passed; otherwise it replays a controlled labeled segment and
  never calls that segment exact.
- Post-verdict product-direction note: after trying the permitted offline branch,
  Ignacio explicitly rejected it because it did not review his voice and then
  directed MA to use GPT Realtime for an English-default, zero-beginner guided
  lesson. The dated addendum in `docs/poc/verdict.md` authorizes that separate,
  explicit push-to-talk product branch. It does not change Gate 0's PARTIAL
  result or permit overlap, AEC/no-echo, latency, exact-replay, physical-device,
  or learner-outcome claims. The guided branch is governed by
  `docs/submission/claim-evidence-matrix.md` and
  `docs/submission/release-checklist.md`.
- Ignacio explicitly authorized a fixture-driven MA product UI before Gate 0.
  Before the written verdict, the MA target may contain visual design,
  deterministic preview fixtures, animation, navigation, and local interaction
  state, but no live microphone capture, provider transport, credentials, or UI
  that presents a mocked event as live. After the verdict, bind only the mode it
  permits: measured overlap under PASS; proven explicit non-overlap Realtime
  under PARTIAL when Experiment 0 passed; otherwise bundled local audio and
  labeled replay.
- The probe must run on a physical iPhone. Simulator-only evidence never closes
  an audio or echo-cancellation task.
- Count only evidence from one same-topology audio graph with one owner,
  post-AEC mic timing, actual render timing, and synchronized external acoustic
  evidence. Never combine separately passing capture and replay paths.
- Do not describe the current API as full duplex unless the measured behavior
  actually passes the overlap protocol.

## Source of truth

- project.yml is the Xcode project source of truth. Run xcodegen generate after
  changing targets, sources, resources, entitlements, or build settings.
- Use Swift 6, SwiftUI, Observation, structured concurrency, and Swift Testing.
- Keep presentation state on MainActor. Keep transport, audio, timing, and
  persistence side effects behind narrow services or actors.
- Preserve raw provider events in diagnostics and normalize them into app-owned
  domain events before product code consumes them.

## OpenAI and privacy

- A standard OpenAI API key must never ship in the app.
- The session broker mints short-lived Realtime client secrets and supplies a
  privacy-preserving safety identifier.
- Ask for microphone access just in time, explain why, handle denial, and make
  capture/retention visible.
- Default to local-only learner state and no retained raw audio. Any diagnostic
  capture requires an explicit developer toggle and deletion path.

## Verification

- Pure state and event-sequence tests use Swift Testing.
- Async and audio tests must have bounded timeouts; never use arbitrary sleeps.
- Every live trial logs route, model, transport, VAD mode, timestamps, output
  continuity, cancellation events, classification, and result.
- Ten trials support a 9-of-10 functional claim, not p95. Freeze configuration
  and use at least 40 first attempts per class for nearest-rank p95.
- Discover connected devices dynamically. Do not hardcode device identifiers.

## Useful parent skills and references

- /Users/ia/code/ios/.claude/skills/axiom-ios-integration/SKILL.md
- /Users/ia/code/ios/.claude/skills/axiom-avfoundation-ref/SKILL.md
- /Users/ia/code/ios/.claude/skills/axiom-networking/SKILL.md
- /Users/ia/code/ios/.claude/skills/axiom-swiftui-architecture/SKILL.md
- /Users/ia/code/ios/.claude/skills/axiom-privacy-ux/SKILL.md
- /Users/ia/code/ios/.claude/skills/axiom-ios-testing/SKILL.md
