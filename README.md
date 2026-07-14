# MA

MA is a voice-first iPhone tutor for a Spanish-speaking absolute beginner who
needs to function in Japan. The working thesis is that learning should feel like
entering a real conversation: acknowledge the speaker without stealing the
floor, interrupt when genuinely lost, rewind the exact moment that broke
comprehension, learn it, and resume.

The repository is deliberately at Gate 0 for live audio. It now also contains a
fixture-driven `MA` product target so the learning flow, visual language, and
demo interaction can be designed before the physical-iPhone feasibility verdict.
Every fixture-backed state is labeled `PROTOTIPO` or `REPLAY · NO EN VIVO`; the
current target has no microphone capture, provider transport, credentials, or
simulated-live claims. After the written verdict, those labels may be removed
only from states backed by the permitted real implementation and evidence.

The OpenAI Build Week submission deadline is July 21, 2026. Once
docs/poc/verdict.md receives its started_at timestamp, Gate 0 has exactly 24
clock hours. PASS unlocks the measured overlap interaction; any missing
criterion at the deadline records PARTIAL and immediately pivots to Kaiwa Loop.
Start the clock no later than July 15; the probe's engineering counts inside the
24 hours, while this scaffold and readiness work do not.

## First commands

1. Generate the Xcode project with: `xcodegen generate`.
2. Build and run the `MA` scheme to exercise the offline fixture UI.
3. Run its tests with: `xcodebuild test -project MA.xcodeproj -scheme MA -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`.
4. Build and test the `MAAudioProbe` scheme before touching device audio.
5. When ready to start the uninterrupted spike, copy
   docs/poc/verdict-template.md to docs/poc/verdict.md and timestamp it.
6. Run MAAudioProbe on a paired physical iPhone and preserve both structured
   logs and synchronized external acoustic evidence.
7. Attach to the adversarial planning session with: `tmux attach -t ma-adversary`.

The original [Paper design](https://app.paper.design/file/01KXF2S5M0T6YNPBRS2S1A66Y3/1-0)
is now a historical visual reference. SwiftUI is the interaction source of
truth. Exact Paper tokens and the constraints carried forward from that pass are
preserved in `docs/design/paper-ui-handoff.md`.

## Fixture UI status

The current code-first flow includes three short onboarding decisions, an
intent-first home and compact profile menu, then a coached first minute before
natural mode. The learner says one useful line with full support, rhythm-only
support, and no answer text; sees explicit evidence of that first success;
learns the conversation controls; and only then enters the deterministic
natural-speed fixture. That fixture demonstrates a non-interrupting はい wake,
すみません floor transfer, a provenance-tagged visual repair window, and the
shape of future before/after proof without claiming that audio rendered.

Manual interaction, previews, unit tests, rendering tests, and UI tests all use
the same canonical fixture stages. The current Simulator run passes 78 tests,
including the full self-assessed coached progression, compact 368x800 rail
geometry, every onboarding step at Accessibility Extra Large, and a running-app
accessibility check that keeps the hero scene as one semantic button. The
light-only prototype scrolls when content outgrows the reference viewport.
Silent fixture actions are labeled as visual simulations and use no play/listen
affordances; no live microphone, provider transport, or real audio playback is
wired into this product target yet. Synthetic timing comparisons are presented
only as sample data, never as personal learner evidence.

## Repository map

- apps/MA — fixture-driven product UI and deterministic voice-ink renderer
- apps/MATests — reducer, replay, repair-window, proof, and geometry tests
- apps/MAUITests — running-app navigation and accessibility assertions
- apps/MAAudioProbe — isolated physical-device feasibility probe
- apps/MAAudioProbeTests — structural and later deterministic probe tests
- docs/design — historical Paper handoff and retained visual constraints
- docs/research — evidence and product decisions from comparable learning apps
- docs/poc — experiment protocol, evidence, and verdict
- docs/decisions — architecture decision records after the gate
- services/session-broker — server-only OpenAI credential broker
- fixtures/realtime — sanitized event/audio replay fixtures
- scripts — repeatable build, device, and evidence helpers
- todo.md — PRD, gates, acceptance criteria, and execution order

## Reuse, not coupling

The hardened audio/session mechanics in the sibling FitnessOS project are useful
reference material, especially its AVAudioSession lifecycle, PCM conversion,
route handling, teardown, event loop, and ephemeral-secret broker. Extract those
mechanics; do not copy its workout domain, Supabase assumptions, old model slug,
or WebSocket architecture into MA.
