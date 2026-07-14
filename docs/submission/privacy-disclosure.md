# MA privacy and data disclosure

This disclosure describes the current private Build Week build, not a future
public beta.

## On the iPhone

- Onboarding completion, goal, daily-practice choice, and interests are stored
  in app-owned `UserDefaults`/`AppStorage`.
- A revocable private planner credential may be provisioned into iOS Keychain
  with `WhenUnlockedThisDeviceOnly` accessibility.
- Tutor prompts are bundled application assets.
- During an explicit attempt, raw microphone PCM is processed only in bounded
  memory. MA derives capture duration, approximate voice onset, and a coarse
  speech-presence flag. It creates no recording file and retains no raw audio.
- MA does not transcribe or score pronunciation. Completion is the learner's
  explicit self-assessment.
- The local proof and deterministic next action require no network.

## Optional external planner

The proof screen first describes the transfer and requires a separate tap.
Only then may MA send:

- versioned scene/report identifiers and the fixed obligation identifier;
- scaffold/help level and attempt number;
- bounded duration and approximate onset;
- coarse speech-presence and learner completion booleans;
- repair count and controlled-segment metadata.

MA sends no raw audio, waveform, transcript, contact data, account profile,
precise location, advertising identifier, or standard OpenAI key.

The request goes to a private Cloudflare Worker protected by a revocable
install token and endpoint-scoped rate limiting. The Worker builds a bounded
strict-schema request to OpenAI `gpt-5.6-sol` with `store: false` and a stable
privacy-preserving safety identifier. It returns one validated learning action
or the app keeps its deterministic local fallback. Authorization, token,
provider body, transcript, and audio values are redacted from logs.

Cloudflare and OpenAI necessarily process the optional request to provide the
feature. This private MVP does not claim anonymous public access or a public
account/authentication system.

## Tracking, analytics, and retention

- Tracking: none.
- Tracking domains: none.
- Advertising/third-party analytics SDKs: none.
- Account or analytics warehouse: none.
- Raw learner audio retention: none after the bounded in-memory attempt.
- Private Gate 0 evidence is local-only, consent-gated, and excluded from the
  repository/submission archive.
- Developer logs are bounded and must be redacted before any submission use.

`PrivacyInfo.xcprivacy` declares no tracking, app-functionality use of product
interaction/other usage aggregates, and Required Reason API category `CA92.1`
for app-owned `UserDefaults`. The declaration must be re-audited if data flow
or dependencies change.

## Deletion and control

The profile sheet exposes **Borrar todos mis datos** with confirmation. It
clears onboarding/profile choices, returns to the initial flow, resets current
scene state, and deletes the iOS planner Keychain credential. It cannot delete
external diagnostic data that was never retained by MA; any future server-side
retention would require a corresponding deletion mechanism and disclosure.

The learner can deny microphone permission and use the provided Settings action
to recover. External planning is optional; declining it does not block proof or
the local next step.
