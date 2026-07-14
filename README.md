# MA

MA is a voice-first iPhone tutor for a Spanish-speaking absolute beginner who
needs one useful Japanese conversation for a trip: ask for a restaurant table
for one, recover when natural Japanese becomes noise, and try the same
obligation again with less hesitation.

The binding Gate 0 verdict is **PARTIAL**. The submission product therefore
uses bundled local tutor audio, bounded non-overlapping learner capture,
explicit self-assessment, one immediate local pause, and a complete labeled
controlled segment for repair. It does **not** claim live Realtime conversation,
speech-over-playout classification, or exact replay of a rendered window.

After the lesson, MA prepares a deterministic local next step. The learner may
explicitly opt in to send only structured attempt aggregates to the private
broker for a bounded `gpt-5.6-sol` recommendation. Raw audio and transcripts
are never sent or retained. The standard OpenAI key remains server-side.

## Run and verify

Requirements: Xcode 17, XcodeGen 2.45+, and an iOS 18+ simulator.

```sh
xcodegen generate

xcodebuild test \
  -project MA.xcodeproj \
  -scheme MA \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'

xcodebuild test \
  -project MA.xcodeproj \
  -scheme MAAudioProbe \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

The physical-device command discovers the paired iPhone 17 Pro on iOS 27 at
runtime; no identifier is checked into the repository.

```sh
scripts/device-ma.sh status
scripts/device-ma.sh build-install
scripts/device-ma.sh product
scripts/device-ma.sh replay
```

`product` reads the revocable private install token from the macOS Keychain and
provisions it into this-device-only iOS Keychain storage without printing it.
`replay` launches a deterministic visual fallback permanently labeled
`REPLAY · NO EN VIVO`; it invokes neither microphone, audio hardware, network,
nor the planner.

Run the reproducible current-tree and Git-history secret check with:

```sh
scripts/scan-secrets.sh
```

Worker contract tests are independent of Xcode:

```sh
cd services/session-broker
npm test
```

Private deployment configuration is intentionally absent. Copy
`.dev.vars.example` only into ignored local configuration and use Wrangler's
encrypted secret store for deployment values.

## Hero path

1. Learn `一人です` with full text, rhythm-only support, then no answer text.
2. Record a bounded attempt and decide yourself whether you completed it.
3. Hear the bundled natural scene and tap **Pausa y ayuda** while it plays.
4. MA stops locally, teaches one complete controlled segment, and clearly says
   it is not the exact last seconds heard.
5. Resume the same restaurant obligation and make a new no-text attempt.
6. Compare before/after aggregates and optionally request a server-validated
   GPT-5.6 learning action.

One `AudioGraphController` owns product capture and playout. Product and replay
drive the same pure Kaiwa semantic reducer; the replay consumes bounded,
monotonic, sanitized normalized events and cannot carry live or exact-heard
capabilities.

## Privacy and evidence boundaries

- Local profile choices use app-owned `UserDefaults`; the privacy manifest
  declares required-reason category `CA92.1`.
- Raw PCM exists only in bounded in-memory processing and is discarded after
  speech-presence/onset aggregates are produced.
- External planning is a separate, explicit learner action. The broker uses
  `store: false`, a strict schema, bounded input/output, and no transcript.
- **Borrar todos mis datos** clears onboarding/profile state and the iOS
  planner credential.
- No tracking SDK, account, analytics warehouse, or raw private probe evidence
  is included.
- Simulator tests are necessary but do not satisfy physical audio, route,
  interruption, microphone, learner-outcome, or thermal claims.

See [privacy-disclosure.md](docs/submission/privacy-disclosure.md) and the
binding [Gate 0 verdict](docs/poc/verdict.md) for the exact claim boundary.

## Repository map

- `apps/MA` — shipping local Kaiwa Loop, normalized replay, privacy, and planner
- `apps/MATests` / `apps/MAUITests` — unit, contract, rendering, and UI checks
- `apps/MAAudioProbe` — isolated Gate 0 characterization code; not product live behavior
- `services/session-broker` — private Cloudflare Worker for Realtime secrets and `/learning/next`
- `docs/poc` — immutable protocol, private-evidence rules, and written verdict
- `docs/submission` — Devpost draft, demo/rehearsal plans, claims, privacy, and session ledger
- `scripts` — reproducible device, evidence, and secret-scan helpers

The repository has no public remote. Do not push, publish the video, expose the
Worker, or submit Devpost without Ignacio's explicit approval.
