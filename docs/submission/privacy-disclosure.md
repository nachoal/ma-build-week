# MA privacy and data disclosure

This disclosure describes the current private Build Week build, not a future
public beta.

## On the iPhone

- Onboarding completion, goal, daily-practice choice, and interests are stored
  in app-owned `UserDefaults`/`AppStorage`.
- A revocable private product credential is provisioned into iOS Keychain with
  `WhenUnlockedThisDeviceOnly` accessibility.
- The first phrase model is a bundled application asset.
- Microphone permission is requested just in time, only after the learner taps
  the explicit recording control.
- During an explicit attempt, MA holds at most eight seconds of voice-processed
  24 kHz mono PCM in bounded memory. It writes no recording file. After the
  provider turn finishes or fails, the app releases that PCM.
- MA displays the provider transcription only as an approximate hypothesis,
  never as an exact record. It stores neither that hypothesis nor the structured
  review after the lesson process ends.
- MA provides qualitative feedback with one useful retry focus. It does not
  produce pronunciation, fluency, confidence, or mastery scores.

## Guided Realtime review

When the learner stops an explicit recording, the iPhone sends that bounded
audio turn directly to the OpenAI Realtime API over TLS using a short-lived
client secret. The private Cloudflare Worker mints the secret but never receives
the learner audio, transcription, or review.

OpenAI processes the turn to provide:

- an asynchronous Japanese transcription used only as approximate guidance;
- one schema-guided `report_attempt` function call whose enum arguments are
  treated as untrusted and exactly validated by the app;
- at most two short spoken feedback sentences in the selected English or
  Spanish interface language; and
- one brief, captioned restaurant-waiter turn.

The product uses explicit, non-overlapping push-to-talk. It does not claim
full-duplex conversation, speech-over-playout classification, pronunciation
scoring, or exact heard-window replay.

The standard OpenAI API key remains encrypted in the Worker's secret store and
never enters the app or repository. The Worker authorizes the product endpoint
with a revocable installation credential, fixes the model/session/tool policy,
and returns only the short-lived client secret, expiry, and expected policy
hash. Logs exclude authorization values, audio, transcripts, function
arguments, and provider payloads.

OpenAI states that API data is not used to train models unless the account
explicitly opts in. Under the default API data controls, `/v1/realtime` may
retain abuse-monitoring logs containing customer content for up to 30 days and
stores no application state. Realtime is eligible for approved Zero Data
Retention controls, but this build does not claim that such approval is active.

## Optional post-lesson planner

The guided lesson is already complete and shows a deterministic local next
step before any planner transfer. Only after the learner explicitly taps the
GPT-5.6 action may MA send a versioned `/learning/guided-next` report containing:

- the fixed restaurant scene, obligation, level, and phrase identifiers;
- per-stage attempt counts;
- each stage's last qualitative result (`matched`, `close`, `different`, or
  `unclear`); and
- whether the answer was visibly supported.

The report includes explicit false sentinels for raw audio, transcription, and
self-assessment. It contains no PCM, approximate transcript, heard-Japanese
text, free-form feedback, duration, onset, learner name, email, or report UUID
in the model input. The Worker fixes `gpt-5.6-sol`, uses strict structured
output and `store: false`, validates the recommendation against the observed
support/result pair, and supplies canonical English and Spanish explanations.
Invalid or unavailable output leaves the deterministic local step in place.

The older `/learning/next` contract remains only for the frozen historical
replay/audit path; the shipping guided lesson does not synthesize or send that
legacy self-assessment report.

## Tracking, analytics, and retention

- Tracking: none.
- Tracking domains: none.
- Advertising or third-party analytics SDKs: none.
- Account or analytics warehouse: none.
- Raw learner audio stored by the app: none; bounded memory only during the
  explicit Realtime request.
- Transcription stored by the app: none; visible only in the active lesson.
- OpenAI API retention: default abuse-monitoring terms described above.
- Private Gate 0 evidence is local-only, consent-gated, and excluded from the
  repository and submission archive.
- Developer logs are bounded and must be redacted before submission use.

`PrivacyInfo.xcprivacy` declares no tracking; app-functionality use of audio
data, product interaction, and other usage aggregates; and Required Reason API
category `CA92.1` for app-owned `UserDefaults`. The declaration must be
re-audited if the data flow, provider controls, or dependencies change.

## Deletion and control

The profile sheet exposes **Delete all my data / Borrar todos mis datos** with
confirmation. The app first deletes the iOS Keychain credential and reloads
Keychain to verify that it is absent. Only after that verification succeeds
does it clear onboarding/profile choices, return to the initial flow, and reset
the current scene and interface language. If deletion, reload, or verification
fails, the profile remains intact and the sheet shows a fixed bilingual error
without exposing credential values or system error details. The app has no
saved recording or transcript to delete. This local action cannot delete
provider abuse-monitoring logs governed by OpenAI's API data controls.

The learner can deny microphone permission and use the provided Settings action
to recover. No recording begins automatically after tutor playback.
