# MA implementation plan

Status: approved after final Fable verification — READY for implementation  
Plan date: 2026-07-14 (America/Mexico_City)  
Submission deadline: 2026-07-21 17:00 PDT / 18:00 Mexico City  
Track: Education  
Execution task: Codex `gpt-5.6-sol`, Ultra reasoning, saved local iOS project
scoped to `/Users/ia/code/ios/ma`

## 1. Outcome

Ship one coherent iPhone learning product for a Spanish-speaking absolute
beginner. In the demonstrated restaurant scene, Ignacio must learn to say
`一人です`, enter natural-speed Japanese, recover at the precise moment speech
becomes noise, and complete the same obligation with less help.

The preferred demo distinguishes a low-stakes `はい` backchannel from a
floor-taking `すみません` while tutor audio is active. That overlap claim is
allowed only if the 24-hour physical-iPhone Gate 0 passes. The default delivery
assumption is an honest PARTIAL verdict and a polished Kaiwa Loop; PASS is an
earned upgrade, not a dependency for submitting a strong product.

The implementation task must own the core implementation: Gate 0, the selected
audio topology, transport, local classifier, rendered ledger/ring buffer,
broker, real first-minute audio/capture, repair/resume, GPT-5.6 planner
integration, physical-device validation, and submission evidence. Its
`/feedback` record will enumerate those components and every delegated session
instead of making an unsupported numerical “majority” claim. The existing
fixture UI is a baseline, not the submitted technical core.

## 2. Current baseline

Implemented:

- SwiftUI onboarding, intent-first home, menu, coached ladder, natural-mode
  fixture, repair card, proof view, accessibility behavior, and deterministic
  voice-ink rendering.
- Provider-independent beginnings in `PracticeEvent`, `PracticeState`, and
  `PracticeReducer`.
- Four bundled Japanese `.m4a` assets.
- `MA` and `MAAudioProbe` schemes. On 2026-07-14, the `MA` suite passed 78/78
  and the `MAAudioProbe` suite passed 1/1 on the discovered simulator.
- A paired, developer-mode iPhone 17 Pro running iOS 27.0 is currently visible
  through `devicectl`.
- A redacted non-app preflight minted a `gpt-realtime-2.1` client secret and
  received `session.created` over direct GA WebSocket. See
  `docs/implementation/API_PREFLIGHT.md`.

Not implemented:

- real product audio playback or microphone capture;
- a live or offline speech-evidence path;
- an audio-session owner, interruption/route lifecycle, or teardown;
- Realtime transport, provider normalization, or a deployed client-secret
  broker;
- Gate 0 instrumentation, classifier, rendered-audio ring buffer, acoustic
  alignment, evidence export, or verdict;
- a GPT-5.6 learning planner;
- physical-learner Gates 1-4, video, repository sharing, or submission package.

Repository risk:

- The repository has no commits and every file is currently untracked. Before
  multiple agents or the Gate 0 timer begin, establish a reproducible baseline
  commit without changing behavior. Do not push or publish unless Ignacio asks.

## 3. Non-negotiable gates

### Gate 0 — audio feasibility, exactly 24 clock hours

Question: on one physical iPhone and one observable audio graph, can MA capture
`はい` without stopping tutor output, distinguish `すみません`, silence output
promptly, and recover the exact rendered four-second beat?

- Start by copying `docs/poc/verdict-template.md` to
  `docs/poc/verdict.md` and writing `started_at` plus `hard_stop_at`.
- Start no later than 2026-07-15 Mexico City time.
- Simulator results never count.
- Missing any PASS criterion at the hard stop is automatically PARTIAL.
- An hour-3 failure to expose post-AEC input and actual render position on one
  graph is immediate PARTIAL.
- No product code may represent fixture events as live evidence.

### Gate 1 — useful first minute

From a clean install, Ignacio completes `何名様ですか` -> `一人です` without
answer text after no more than 60 seconds of instruction. Evidence is a screen
recording plus state/event log and an honest learner outcome note.

### Gate 2 — repair changes the next attempt

One breakdown produces a repair, resume at the same obligation, and a second
attempt with less scaffold or fewer repairs. Evidence must be measured or
explicitly self-reported; never turn model confidence into a fake score.

### Gate 3 — dependable demo

The selected physical-iPhone hero path completes at least 9 of 10 consecutive
rehearsals. A labeled deterministic replay survives network failure.

### Gate 4 — immediately legible superpower

At least 4 of 5 cold viewers can say, after ten seconds, that MA teaches a real
conversation and rescues the exact moment the learner stopped understanding.
“ChatGPT for Japanese” is a failed result.

## 4. Decisions frozen before implementation

### D-001 — one owner for capture and playout

One `AudioGraphController` owns `AVAudioSession`, capture, playout, render
position, route changes, interruptions, and teardown. Other components consume
timestamped frames/events but may not create a shadow capture or playback
graph. The implementation owner is organizationally exclusive: no parallel
agent may add another audio topology.

### D-002 — provisional Gate 0 transport: observable WebSocket graph

The provisional first topology is direct Realtime WebSocket media using an
ephemeral client secret, with an app-owned `AVAudioEngine` voice-processing
graph. It is chosen because the existing FitnessOS reference already proves the
basic Swift/WebSocket/PCM path, while app-owned playout makes post-AEC input,
local stop, render position, unplayed-audio exclusion, and ring-buffer evidence
observable on the same graph.

This is a deliberate exception to OpenAI's recommendation to prefer WebRTC for
mobile clients. The redacted non-app preflight closes only client-secret
minting and the direct-WebSocket server handshake: a short-lived client secret
received `session.created` over the current GA endpoint. It does not settle the
iPhone media topology, audio observability, or device behavior.

Inside Gate 0, native WebRTC receives a 30-minute evidence-hook audit during
hours 1-1.5. It may replace the provisional choice only if one readily available
distribution immediately exposes empirically post-AEC input PCM,
device-boundary output frames/render position, and immediate local stop through
one owner. If those hooks exist, they may use at most the next 60 minutes of the
hour-1.5-to-3 proof window; otherwise pivot at hour 1.5 and freeze the
voice-processed WebSocket graph. If neither topology can prove both audio ends
on the physical iPhone by hour 3, record PARTIAL. Do not build a custom WebRTC
audio-device module during Build Week.

### D-003 — floor control is local and deterministic

- The smallest viable local phrase classifier runs on post-AEC frames, owns the
  latency-critical `はい` versus `すみません` decision, and is frozen before
  held-out trials. Provider transcription is secondary evidence only.
- B1 uses server VAD with `create_response=false` and
  `interrupt_response=false`; the server alone owns commit and MA records
  whether a committed backchannel pollutes later context.
- B2 uses `turn_detection=null`; one local onset/end detector owns segmentation,
  clears stale input at onset, discards backchannel input, and commits a
  take-floor repair exactly once.
- `はい`: never cancel or flush tutor output and never create a response.
- `すみません` acts local-first. WebRTC sends `response.cancel` when active and
  `output_audio_buffer.clear`, then awaits `output_audio_buffer.cleared`; clear
  already truncates unplayed output, so no redundant explicit truncate is sent.
  WebSocket captures the local render cursor, stops/flushes the
  `AVAudioPlayerNode`, sends `response.cancel`, and sends exactly one
  `conversation.item.truncate` with render-derived `audio_end_ms`.
- Commit learner audio and create the next response exactly once under the
  predeclared commit owner. Never combine server and app commits.
- Do not add `gpt-realtime-whisper`, a separate transcription connection, or
  semantic VAD during Gate 0.

### D-004 — secrets stay server-side

Deploy the smallest broker under `services/session-broker`:

- `POST /realtime/client-secret` accepts no caller model, prompt, or voice. It
  mints a short-lived secret with server-selected `gpt-realtime-2.1`, voice,
  VAD policy, TTL, and privacy-preserving safety identifier; it returns only
  `value`, `expires_at`, and an expected effective-configuration hash.
- The app compares `session.created/session.updated` with the expected hash.
  Client-secret configuration is overridable and is not described as a
  cryptographic policy pin.
- `POST /learning/next` calls the Responses API with `gpt-5.6-sol` and a strict
  structured schema after a lesson, never inside the latency-critical floor
  loop.
- The standard OpenAI key is a server secret and never enters the app, logs, or
  repository.
- The private MVP uses a pre-provisioned, revocable install token stored in the
  iOS Keychain plus rate limiting. Document that this is not public-beta auth.
- Logs redact authorization, client-secret values, transcripts, and audio.

### D-005 — one scene, two honest operating modes

- PASS mode: measured overlap behavior only on the proven device/route scope.
- PARTIAL mode (expected): explicit non-overlap stop/tap or repair. Transport
  and replay permissions are independent. It may use live Realtime conversation
  only if Experiment 0 proved that exact topology; otherwise tutor audio is
  bundled and local. It may replay an actual rendered window only to the extent
  Experiment D passed; otherwise it uses the last controlled labeled segment
  and never calls that segment exact.
- Replay mode: sanitized events drive the same reducer and is always labeled.
- No additional scenes, languages, accounts, streaks, subscriptions, or GPT-Live
  adapter before submission.

## 5. Target architecture

Keep source local to each app until real duplication justifies a package.

```text
apps/MA
  Domain/
    ScenePlan, Attempt, LearningReport
    ConversationEvent
    RealtimeModelCapabilities
    AudioTopologyCapabilities
    FloorPolicyCapabilities
    existing reducer/state/fixtures
  Audio/
    AudioSessionCoordinator
    OfflinePromptPlayer
    LearnerAttemptRecorder
    RenderedAudioRingBuffer
  Realtime/
    ConversationProvider
    Realtime21Adapter (only when Experiment 0 permits live Realtime)
    ReplayAdapter
    RealtimeEventNormalizer
  Learning/
    LearningPlanner
    DeterministicPedagogyPolicy
    PlannerSchema
  Features/
    FirstMinuteFeature
    NaturalPracticeFeature
    RepairFeature
    EvidenceFeature

apps/MAAudioProbe
  AudioGraphController
  ProbeSession
  FrozenPhraseClassifier
  TrialScheduler
  ProbeEventLog
  EvidenceExporter

services/session-broker
  realtime session endpoint
  learning planner endpoint
  redaction/rate-limit/auth tests

fixtures/realtime
  sanitized raw provider events
  normalized event fixtures
  deterministic complete hero replay

scripts
  device discovery/build/install
  trial randomization
  NDJSON validation and aggregation
  acoustic clock alignment
  tracked-set secret scan
```

Concurrency rules:

- Presentation state remains `@MainActor`.
- Audio, transport, ring-buffer, evidence export, and planner side effects are
  actors or single-executor services behind protocols.
- Audio callbacks do bounded copying only; no JSON, allocation-heavy model
  work, disk I/O, or main-actor hops in the real-time callback.
- Every async operation has cancellation, timeout, and idempotent teardown.
- Raw provider events are retained only in redacted developer diagnostics and
  normalized before product state consumes them.
- Model capabilities (tools, reasoning, manual response control), local audio
  capabilities (post-AEC samples, local stop, rendered cursor/replay), and
  measured floor-policy capabilities (validated phrases, classifier/config
  hash, thresholds, verdict) remain separate. A model slug cannot imply a
  render clock or backchannel distinction.

## 6. Work packages and verifiers

### WP-0 — readiness before the Gate 0 clock

Deliverables:

- create a baseline commit from the current tree;
- regenerate with `xcodegen generate` and prove no unintended project diff;
- rerun all `MA` and `MAAudioProbe` simulator tests;
- dynamically discover, build, install, and launch both schemes on the paired
  physical iPhone;
- fix the stale probe copy that says all product UI is blocked; only live/overlap
  evidence is gated;
- use a minimal Cloudflare Worker as the named broker surface; confirm Wrangler
  account access, signing, microphone permission string, local secrets file,
  recorder charge/storage, and available operator time;
- retain `docs/implementation/API_PREFLIGHT.md` as the redacted proof that the
  current GA client-secret/direct-WebSocket handshake works; no iPhone/probe
  code is allowed in that preflight;
- pin the exact Devpost `/feedback` rule and the implementation task's component
  ledger in `docs/submission/feedback-notes.md`;
- record the exact Devpost deadline and the July 17 12:00 PDT / 13:00 Mexico
  City credit-request deadline;
- prepare gitignored `docs/poc/private-evidence`, randomized trial sheets, sync
  chirps, external recorder, consent/deletion note, and public redacted paths;
- identify a qualified Japanese reviewer, an outreach owner, and a target review
  window for the hero prompts and subtitles. Lack of confirmation must not delay
  Gate 0; completed review remains required in WP-5 before public
  recording/submission.

Verifier:

- clean git status after baseline;
- all tests green;
- both apps visible on the real iPhone;
- Cloudflare Worker account access and local secret injection are proven without
  deploying probe behavior before the clock;
- root implementation task and every delegated task/session have an ID entry in
  `feedback-notes.md`;
- no probe engineering before `started_at`.

### WP-1 — Gate 0 hours 0-3: topology or immediate PARTIAL

Deliverables:

- timestamp `verdict.md` and calculate the hard stop;
- hours 0-1: implement/deploy the Cloudflare Realtime client-secret endpoint;
- hours 1-1.5: audit one native WebRTC distribution's evidence hooks; abandon it
  without a custom build if post-AEC PCM, device-boundary render position, and
  immediate local stop are not all exposed;
- hours 1.5-3: freeze the qualifying WebRTC topology or bring live
  `gpt-realtime-2.1` through the provisional voice-processed WebSocket graph;
- log the immutable audio configuration and selected transport;
- expose timestamped post-AEC input, render position, local stop, and provider
  control from that graph;
- preserve a raw, redacted event stream and a configuration hash.

Verifier:

- external recording shows remote tutor audio while post-AEC learner frames are
  observable;
- advancing render position corresponds to audible output;
- local stop affects that same output path;
- if any is missing at hour 3, write PARTIAL and jump to WP-3.

PARTIAL at hour 3 is the modal planning assumption, not a failed project. It
immediately buys the remaining week for the honest local-audio Kaiwa Loop.

### WP-2 — Gate 0 hours 3-24: earn PASS

Hours 3-5:

- record default automatic-interruption baseline;
- establish a single monotonic event timeline and external sync mapping.

Hours 5-8:

- run B1 server-owned commit and B2 local-owned segmentation without mixing
  their commit policies;
- benchmark the smallest local classifier on real post-AEC frames;
- freeze one four-label policy: echo/noise, backchannel, repair, answer turn;

Hours 8-11:

- implement the selected transport-specific local-first state machine;
- reject duplicate/out-of-order provider events.

Hours 11-15:

- implement a bounded rendered-sample ring buffer;
- test wraparound, unplayed-audio exclusion, four-second extraction, and replay;
- implement the external clock-alignment/aggregate script and synthetic drift
  tests; reject residuals above 20 ms.

Hours 15-18:

- freeze configuration and randomized schedule;
- run route, interruption, echo, resume, and buffer controls.

Hours 18-22:

- run at least 40 first-attempt `はい`, 40 `すみません`, and 40 adversarial
  echo/noise controls across fresh sessions;
- predeclare the 10-trial hero subsets; preserve all failures and first attempts.
- PASS requires the full 40/40/40 sets. If fatigue, recording failure, or the
  hard stop prevents completion, preserve and report the actual smaller n. A
  characterization-only target of at least 10/10/20 reports count, median, and
  maximum only and is automatically PARTIAL. Never rush or replace trials.

Hours 22-24:

- aggregate without retuning;
- have the persistent adversarial reviewer inspect raw/redacted evidence;
- choose exactly PASS, PARTIAL, or FAIL and freeze public wording.

Verifier: every checkbox and threshold in `docs/poc/verdict.md`; no narrative
override of a missing criterion.

### WP-3 — Phase 1 / Gate 1: real offline first minute

This work begins only after the written Gate 0 verdict.
The human learner/operator takes a real sleep block after the 24-hour spike;
Codex may wire deterministic product code meanwhile, but the Gate 1 learner run
does not use an exhausted Ignacio.

Deliverables:

- wire all bundled prompts through a tested `OfflinePromptPlayer`;
- make every play/listen control emit actual audio and visible playback state;
- centralize route/interruption/background lifecycle and idempotent teardown;
- add just-in-time microphone permission and denial recovery;
- capture each coached learner attempt as a bounded local recording associated
  with scene, obligation, scaffold, and timestamps;
- add an honest evidence path: transcript/phonetic hypothesis plus uncertainty
  when available, explicit self-assessment fallback otherwise;
- remove the permanent prototype badge only from genuinely implemented states;
  keep replay/live provenance visible in developer mode;
- run the clean-install 60-second learner test and save evidence.

Verifier:

- all four audio assets play on the real iPhone;
- headphones/speaker route and interruption do not leave stuck audio;
- microphone denial does not crash or dead-end;
- Ignacio completes the exchange without answer text;
- product tests distinguish self-reported, replay-fixture, and measured evidence.

### WP-4 — Phase 2 / Gate 2: breakdown -> repair -> better attempt

Shared deliverables:

- formalize `ConversationProvider`, the three capability groups, normalized
  `ConversationEvent`, and `ReplayAdapter`;
- run a longer natural-speed restaurant turn;
- bind actual audio/render events—not timers—to the heard timeline;
- preserve the same scene obligation through repair and resume;
- compare first and next attempts on completion, onset latency, scaffold, and
  repair count without fake precision;
- build a sanitized, deterministic complete hero replay from normalized events.

PASS branch:

- extract only the measured probe topology into `Realtime21Adapter`;
- implement the proven `はい` continuity and `すみません` yield policy;
- freeze and locally replay the rendered four-second window;
- keep claims scoped to the proven configuration.

PARTIAL branch:

- make Kaiwa Loop the default hero immediately;
- explicit stop/tap always works locally;
- if Experiment D passed, replay the exact rendered window;
- otherwise replay the last complete labeled segment;
- keep experimental overlap behind a developer toggle and never in submission
  claims.

Verifier: physical-device recording and event log show a real breakdown, repair,
same-obligation resume, and successful second attempt. If the live path is not
stable by 2026-07-18 18:00 Mexico City, freeze it and ship Kaiwa Loop.

### WP-5 — Phase 3: controlled pedagogy with GPT-5.6

Deliverables:

- define Codable/schema-backed `ScenePlan`, `Attempt`, `LearningReport`, and
  `NextLearningAction`;
- implement deterministic completion and allowed-action guardrails;
- call `gpt-5.6-sol` through the broker only after an attempt/repair cycle;
- constrain output to repeat, reduce scaffold, isolate beat, advance, or
  abstain, with a short Spanish explanation and evidence-based reason;
- validate the schema, timeout, retry budget, safety identifier, and abstention;
- fall back to deterministic pedagogy or a cached fixture on every failure;
- add contract fixtures and tests for invalid, unsupported, and contradictory
  model output;
- complete Japanese-language and pragmatic review.

Verifier: the model may recommend, but cannot advance an uncompleted obligation,
invent learner evidence, or block the hero path. The replay fixture produces the
same UI state without a network call.

### WP-6 — Phase 4: demo and submission

Deliverables:

- keep one excellent hero screen and freeze further onboarding/menu redesign;
- add English subtitles to the demo video, not the Spanish learner UI;
- create one physical-device build/install/launch script or runbook;
- rehearse live, PARTIAL, forced-network-failure, and labeled replay paths;
- run the five-person comprehension test and repair only comprehension blockers;
- record a public YouTube video under three minutes with audio explaining how
  Codex and GPT-5.6 were used;
- write README setup/sample-data/testing instructions and highlight key Codex
  decisions;
- prepare a private repository share for `testing@devpost.com` and
  `build-week-event@openai.com`, or explicitly approve public release;
- maintain `docs/submission/feedback-notes.md` in the implementation task with
  major decisions, Codex wins/failures, and the final `/feedback` Session ID;
- prepare the Devpost project description, category, video URL, repository URL,
  and testing instructions.

Verifier:

- 9/10 consecutive rehearsals pass on the selected hero path;
- 4/5 cold viewers state the intended superpower;
- video is public, audible, under three minutes, and shows the app working;
- submitted Session ID belongs to the new implementation task where Gate 0 and
  the majority of core functionality were built.

### WP-7 — Phase 5: hardening and code freeze

Deliverables:

- privacy manifest and accurate microphone/data-retention disclosure;
- tracked-set secret scan and explicit allow-list review for public/private repo;
- Wi-Fi/cellular/offline, route, interruption, permission-denial, and provider
  failure matrix;
- ten-minute memory/thermal run and bounded-buffer assertions;
- VoiceOver, Dynamic Type, Reduce Motion, and captions pass;
- final failure copy, recovery, deletion, and diagnostics-off checks;
- rubric evidence table covering implementation, design, impact, and idea;
- archive the exact build, fixtures, redacted logs, and video used.

Verifier: no secrets or raw private audio in the tracked set; no P0/P1 demo-path
defects; code freeze by 2026-07-20 18:00 Mexico City.

## 7. Calendar and automatic scope cuts

| Mexico City time | Milestone |
|---|---|
| Jul 14 | readiness, baseline, adversarial plan closure, new Ultra task |
| Jul 15-16 | Gate 0, hard 24-hour verdict, then learner/operator sleep block |
| Jul 16 evening-Jul 17 | rested offline first-minute learner run and Gate 1 |
| Jul 17-18 | repair/resume vertical slice and Gate 2 |
| Jul 18-19 | GPT-5.6 pedagogy, Japanese review, complete replay |
| Jul 19-20 | rehearsals, cold-viewer test, video, submission copy |
| Jul 20 18:00 | code and hero-path freeze |
| Jul 21 18:00 | Devpost hard deadline; target submission several hours early |

Automatic cuts:

- Gate 0 PARTIAL -> stop overlap tuning; Kaiwa Loop becomes the product.
- Experiment D failure -> labeled segment replay; remove every “exact heard
  four seconds” claim.
- Uncertain recognition -> explicit self-assessment; no pronunciation score.
- Live instability after Jul 18 18:00 -> labeled replay/fallback is the demo.
- Planner instability -> deterministic policy plus cached fixture.
- Japanese review unavailable -> use only lines already approved; do not expand.
- Rehearsal below 9/10 -> record the stable honest path; no risky live flourish.
- Never add new scenes, languages, auth/accounts, social, subscriptions,
  Bluetooth support, generic agent harnesses, or GPT-Live before submission.

## 8. Validation commands

The implementation task must keep these commands current in `README.md` and
replace placeholders with exact destinations/identifiers discovered at runtime.

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

xcrun devicectl list devices

git diff --check
git status --short
```

Add focused commands for broker tests, schema validation, acoustic alignment,
trial aggregation, and secret scanning when those tools exist. Never hardcode a
device identifier in a tracked script.

## 9. New Codex task operating contract

The new task receives this file, `todo.md`, `AGENTS.md`, `CLAUDE.md`, the Fable
review record, and the official-doc snapshot as its source of truth.

It must:

1. Work in the saved local `/Users/ia/code/ios` project, immediately scope every
   command and edit to `/Users/ia/code/ios/ma`, and use the local environment so
   all existing untracked files are visible. Do not start in a clean worktree
   that loses them.
2. Establish a baseline commit before parallel implementation.
3. Keep every core lane in the root task: Gate 0, audio topology, transport,
   classifier, render ledger/ring buffer, broker, product audio/capture,
   repair/resume, planner integration, device verdict, and final claims.
   Subagents may research, adversarially review, design tests, or inspect
   non-overlapping evidence, but may not become the primary implementer of a
   core component. Log every delegated task/session ID.
4. Start Gate 0 only when readiness is complete, then never pause or extend its
   24-hour clock.
5. Continue from PARTIAL automatically rather than treating it as a blocker.
6. Build, test, install, and validate on Ignacio's real iPhone in proportion to
   every milestone; simulator proof never closes audio work.
7. Update checkboxes and evidence as work lands. Never mark a verifier complete
   from code inspection alone when it requires a device or learner.
8. Preserve user-owned changes, avoid destructive Git operations, and do not
   push, publish, submit, or share the repository without explicit permission.
9. Keep an implementation journal suitable for the final `/feedback` command,
   including where GPT-5.6/Codex helped, where it failed, and how evidence
   changed decisions. After every milestone, append the exact components built
   in this root task; never substitute the bare word “majority” for the ledger.
10. Continue through WP-7 unless a genuine external authorization gate requires
    Ignacio. Report blockers with the exact failed command/evidence and proceed
    on every independent lane.

## 10. Definition of done

MA is done for Build Week only when:

- Gate 0 has a written, evidence-audited verdict by its hard stop;
- one honest PASS or PARTIAL physical-iPhone hero path works end to end;
- a zero beginner completes `一人です` without answer text;
- a breakdown produces a useful repair and a better next attempt;
- GPT-5.6 contributes to a bounded, schema-validated pedagogical decision;
- deterministic replay survives network failure without pretending to be live;
- the app passes its targeted unit/UI/device/accessibility/privacy checks;
- Japanese copy is reviewed;
- README, video, repository testing access, Devpost copy, and `/feedback`
  Session ID are ready;
- the submitted claims match the evidence exactly.

## 11. Current official references

- OpenAI Realtime overview: https://developers.openai.com/api/docs/guides/realtime
- WebRTC connection guidance: https://developers.openai.com/api/docs/guides/realtime-webrtc
- VAD controls: https://developers.openai.com/api/docs/guides/realtime-vad
- Interruption/truncation: https://developers.openai.com/api/docs/guides/realtime-conversations#interruption-and-truncation
- Push-to-talk control events: https://developers.openai.com/api/docs/guides/realtime-conversations#push-to-talk
- Realtime transcription: https://developers.openai.com/api/docs/guides/realtime-transcription
- `gpt-realtime-2.1`: https://developers.openai.com/api/docs/models/gpt-realtime-2.1
- GPT-5.6 model guidance: https://developers.openai.com/api/docs/guides/latest-model
- Build Week/Devpost requirements: https://openai.devpost.com/
