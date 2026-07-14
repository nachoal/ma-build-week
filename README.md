# MA

MA is a voice-first iPhone tutor for an English- or Spanish-speaking absolute
beginner who needs one useful Japanese conversation for a trip. English is the
fresh-install default for judges; an always-visible switch changes the complete
guided product interface and Realtime feedback to Spanish without losing lesson progress. The
first lesson teaches one restaurant response, reviews the learner's actual
speaking turn, gives one concrete retry focus, and then uses the phrase in a
captioned waiter exchange.

The binding overlap/AEC Gate 0 verdict remains **PARTIAL**. It permanently
prohibits claims of full-duplex overlap, speech-over-playout classification, or
exact replay of a rendered window. The post-Gate product is a separate,
explicit non-overlapping Realtime path: bundled model audio, learner-controlled
capture, a schema-guided and app-validated GPT Realtime review, an explicit
retry, and one
short captioned situation turn.

Learner audio is held only in bounded memory and sent directly from the iPhone
to OpenAI with a short-lived client secret; the app writes no recording file and
the Worker never receives audio or transcription. The standard OpenAI key stays
server-side. A separate optional `gpt-5.6-sol` planner accepts only structured
lesson aggregates, never audio or transcription.

## Run and verify

Validated with Xcode 26.6, Swift 6.3.3, the iPhoneOS 26.5 SDK, XcodeGen 2.45+,
and an iOS 18+ deployment target.

```sh
xcodegen generate

xcodebuild test \
  -project MA.xcodeproj \
  -scheme MA \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'

xcodebuild test \
  -project MA.xcodeproj \
  -scheme MAAudioProbe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'
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
`REPLAY · NOT LIVE / NO EN VIVO`; it invokes neither microphone, audio hardware, network,
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

1. Read the English or Spanish objective and see `一人です`, `hitori desu`, and
   its meaning before hearing Japanese.
2. Tap once to hear the short bundled model; recording never starts on its own.
3. Explicitly record the phrase and stop when ready.
4. Read what MA understood approximately, one grounded positive, and one useful
   next focus from a schema-guided, app-validated enum function call.
5. Retry the same visible phrase or explicitly continue with support.
6. Before any natural Japanese plays, read the waiter's question, its romaji,
   its English or Spanish meaning, and the exact response task.
7. Hear one captioned Realtime waiter turn, explicitly record the response, and
   receive a second review before completion.

One `AudioGraphController` owns product capture and playout. The historical
replay remains a separate, permanently labeled fallback and cannot carry live,
learner-audio, or exact-heard claims.

## Privacy and evidence boundaries

- Local profile choices use app-owned `UserDefaults`; the privacy manifest
  declares required-reason category `CA92.1`.
- Raw PCM exists only in bounded in-memory processing during one explicit turn,
  is sent directly to OpenAI for Realtime review, and is discarded by the app
  after the request. The app creates no recording file.
- OpenAI's default API data controls may retain Realtime abuse-monitoring logs
  for up to 30 days; this build does not claim Zero Data Retention approval.
- External planning is a separate, explicit learner action. The broker uses
  `store: false`, a strict schema, bounded input/output, and no transcript.
- **Delete all my data / Borrar todos mis datos** clears onboarding/profile
  state and the iOS Keychain credential; the app retains no audio file or
  transcript to delete.
- No tracking SDK, account, analytics warehouse, or raw private probe evidence
  is included.
- Simulator tests are necessary but do not satisfy physical audio, route,
  interruption, microphone, learner-outcome, or thermal claims.

See [privacy-disclosure.md](docs/submission/privacy-disclosure.md) and the
binding [Gate 0 verdict](docs/poc/verdict.md) for the exact claim boundary.

## Repository map

- `apps/MA` — shipping guided Realtime lesson, audio owner, labeled replay,
  privacy, and planner
- `apps/MATests` / `apps/MAUITests` — unit, contract, rendering, and UI checks
- `apps/MAAudioProbe` — isolated Gate 0 characterization code; not product live behavior
- `services/session-broker` — private Cloudflare Worker for product/probe
  Realtime secrets, legacy `/learning/next`, and guided `/learning/guided-next`
- `docs/poc` — immutable protocol, private-evidence rules, and written verdict
- `docs/submission` — Devpost draft, demo/rehearsal plans, claims, privacy, and session ledger
- `scripts` — reproducible device, evidence, and secret-scan helpers

The repository has no public remote. Do not push, publish the video, expose the
Worker, or submit Devpost without Ignacio's explicit approval.
