# Build Week Codex session ledger

Status: root implementation task active  
Source: https://openai.devpost.com/

Live-verified for WP-0: 2026-07-14 01:02 CST

- Codex credit-request deadline: 2026-07-17 12:00 PDT / 13:00
  America/Mexico_City.
- Build Week submission deadline: 2026-07-21 17:00 PDT / 18:00
  America/Mexico_City.
- Required root-task field: run `/feedback` in the Codex task where the core
  functionality was built, then enter that returned Session ID in Devpost.

## Devpost requirement

Verbatim excerpt:

> `/feedback Codex Session ID where the majority of the core functionality where you built your Project, get the /feedback session ID and input it into`

Devpost then instructs the entrant to place that resulting session ID in the
submission form. The MA submission will use the root implementation task and
will enumerate its work below rather than relying on a bare “majority” claim.

## Root implementation task

- Task title: MA Build Week — End-to-End Implementation
- Session/thread ID: `019f5f68-b42c-7bb2-97dc-a1243d495298`
- Project: `/Users/ia/code/ios`, scoped to `/Users/ia/code/ios/ma`
- Model: `gpt-5.6-sol`
- Reasoning: `ultra`
- Started at: 2026-07-14 00:57:03 CST (America/Mexico_City, UTC-06:00)
- Final `/feedback` Session ID: pending

## Existing baseline before the root task

- Fixture-driven onboarding, menu, lesson screens, deterministic practice
  reducer, visual repair/replay states, voice-ink UI, and accessibility tests.
- No real playback, microphone capture, live provider, broker, classifier,
  rendered-audio evidence, learning planner, or physical learner outcome.

## Core components built in the root task

Append exact evidence after each milestone.

| Component | Root-task evidence | Commit | Device/test evidence | Status |
|---|---|---|---|---|
| Gate 0 probe and written verdict | Clock started 2026-07-14 01:18:10 CST; hard stop 2026-07-15 01:18:10 CST; fixed native-WebRTC audit completed without rounding its 29m48s root capture; root bound the frozen graph to the dedicated probe | `0432b6f`, `ecddafc`, `f8fda5d` | physical protocol pending | in progress |
| Selected one-owner audio topology | Root rejected stock native WebRTC after its public/binary surface exposed none of the three required hooks together; implemented direct GA WebSocket plus one app-owned AVAudioEngine/VoiceProcessingIO graph, JIT permission, processed-input and mixer taps, built-in-route enforcement, route teardown, runtime hash, and revocable playout epochs | `ecddafc`, `f8fda5d`, `2c2c3fd` | strict signed device build; physical route/render proof pending | in progress |
| Realtime transport/event normalization | Root added bounded monotonic diagnostics, provider redaction, effective-policy verification, typed/deduplicated events, bounded commands, and a cancellation-safe URLSession WebSocket actor that exposes no event before `session.created` policy verification; one outbound serializer makes cancel-plus-truncate atomic against mic appends and a response gate rejects duplicate/concurrent/stopped output | `d2e85d3`, `4966eb0`, `38f4686`, `2c95b6f`, `8081de1`, `30cb963`, `f8fda5d`, `36e6f3a`, `2c2c3fd` | strict probe suite 47/47; live transport pending | in progress |
| Local cue classifier/floor policy | pending | pending | pending | pending |
| Render ledger/ring buffer/repair replay | Root implemented a bounded rendered-only ring plus a gap-aware player-timeline ledger that rejects future/backward/stale-epoch cursors and derives item-relative truncation milliseconds only from marked-rendered frames; live exact-window exposure is deliberately disabled because the asynchronous mixer handoff is not a device-boundary freeze barrier | `12f3e65`, `9ac69d3`, `f8fda5d`, `4e7855c`, `2c2c3fd` | deterministic mapping/ring tests; exact replay not permitted | in progress |
| Session broker and secret handling | Root implemented the fixed-policy Worker, private install-token boundary, stable safety identifier, rate-limit binding, bounded response, iOS broker client, and this-device-only Keychain provisioning | `9d5cb2e`, `b0d1977` | Worker 7/7; iOS probe 5/5; Wrangler dry run; live health 200, unauthorized 401, caller override 400, authorized mint 200 | complete with recorded Gate limitation |
| Real offline first-minute playback/capture | pending | pending | pending | pending |
| Repair/resume and next-attempt evidence | pending | pending | pending | pending |
| GPT-5.6 planner integration/guardrails | pending | pending | pending | pending |
| Physical-device validation and replay fallback | pending | pending | pending | pending |
| Demo/submission evidence | pending | pending | pending | pending |

## Delegated tasks and sessions

Log every subagent or external reviewer, even when it only researched or
audited. Core implementation remains in the root task.

| Task/session ID | Role | Files or evidence touched | Core implementation? |
|---|---|---|---|
| `/root/wp0_readiness_audit` | Read-only adversarial WP-0 completeness audit | No files; repo/readiness evidence only | no |
| `/root/webrtc_hook_audit` | Read-only, 30-minute native-WebRTC evidence-hook audit | No files; primary-source research only | no |
| `/root/av_audio_evidence_audit` | Read-only Apple audio-evidence API audit | No files; primary-source research only | no |
| `/root/product_gap_audit` | Read-only WP-3 through WP-5 fixture integration audit | No files; product/test gap map only | no |
| `/root/audio_graph_test_audit` | Read-only Swift 6 audio-graph compile/runtime and test-risk audit | No files; implementation risk checklist only | no |
| `/root/gate0_integrity_reaudit` | Read-only post-binding Gate 0 evidence-integrity audit | No files; physical-proof correctness review only | no |
| `/root/wp3_partial_arch_audit` | Read-only automatic-PARTIAL product integration audit | No files; offline Kaiwa Loop file/test sequence only | no |

## Codex implementation journal

For each material decision, capture:

- intended outcome;
- what Codex built or investigated;
- physical/runtime evidence;
- surprising success or failure;
- how the evidence changed the next decision;
- whether GPT-5.6 was used in the product, in Codex, or both.

### 2026-07-14 — WP-0 device and baseline validation

- Codex role: root task is running on `gpt-5.6-sol` with ultra reasoning; no
  subagent or external reviewer has implemented a core component.
- Reproducibility: `xcodegen generate` produced no hash change in the generated
  project.
- Simulator evidence: MA passed 78/78 tests and MAAudioProbe passed 1/1 on the
  dynamically discovered booted iPhone 17 simulator (iOS 26.4.1).
- Device evidence: the dynamically discovered paired iPhone 17 Pro runs iOS
  27.0 with Developer Mode and developer services enabled. Both schemes built
  with team signing, installed, launched, and appeared in the device process
  list.
- Permission evidence: the probe build contains its microphone purpose string;
  the fixture-only MA build intentionally has no microphone declaration yet.
- Readiness evidence: Wrangler 4.108.0 authenticated with the configured user
  API token; required OpenAI and Cloudflare environment variables were present
  without values being logged. A Studio Display microphone produced a local
  48 kHz mono readiness capture; the Mac was on AC power with ample free disk.
- Correction: stale probe wording now gates only live microphone/provider
  binding and overlap claims, not the authorized fixture product UI.
- Baseline commit: `c3498e2` (`chore: establish MA fixture baseline`).
- Pre-clock evidence readiness: generated and validated a private seeded
  40/40/40 trial sheet and deterministic 48 kHz sync chirp; added tracked
  consent/deletion and public-redaction rules. No private capture is tracked.
- Cloudflare readiness: the API token reported active, the Worker subdomain was
  readable, and the persistent `ma-adversary` review session was present. The
  Gate deployment will use Wrangler's encrypted secret store instead of
  duplicating the standard OpenAI key into a plaintext repository-local file.
- A benign temporary `.dev.vars` marker passed through Wrangler's local Worker
  binding and was observed only as present, never disclosed. Fresh test result
  bundles and raw device snapshots are preserved under ignored private evidence
  with a tracked redacted summary.
- Recorder calibration preserved two failed attempts before a controlled
  Studio Display speaker/microphone take recovered the sync marker under
  synthesized speech. This changed the evidence rule from assumed mono
  readiness to explicit per-take ambiguity failure.

### 2026-07-14 — Gate 0 clock start

- Started at: 2026-07-14 01:18:10 CST (UTC-06:00).
- Hard stop: 2026-07-15 01:18:10 CST (UTC-06:00), with no extension.
- Clean pre-clock boundary: `adadf7a`.
- Human held-out-trial availability and the named Japanese reviewer were still
  unconfirmed. The task explicitly accepted automatic characterization-only
  PARTIAL if the full physical protocol cannot run; no missing evidence may be
  upgraded through narrative or replaced trials.

### 2026-07-14 — Gate 0 hour 0 broker

- Root implemented and deployed `ma-session-broker` with a server-owned
  `gpt-realtime-2.1` session policy. The iPhone can request only a short-lived
  client secret; caller-selected model, instructions, voice, and configuration
  are rejected.
- The first deployment returned 503 because the local binding-shape check did
  not match Cloudflare's runtime proxy. Root corrected the fail-closed check,
  redeployed version `d2a6368b-dee5-412e-9fd1-984a8ebd328d`, and reran the
  complete local and live contract checks.
- A 13-request live burst was permitted. Cloudflare documents this binding as
  permissive and eventually consistent, so the implementation treats it only
  as defense-in-depth and makes no accurate-accounting claim.
- A diagnostic that expected a 429 printed one 120-second client secret into
  private root-task tool output. It was never tracked or saved and expired
  automatically, but the Gate's no-client-secret-in-logs criterion is now
  false. PASS is disqualified; Experiment 0 still decides whether PARTIAL may
  retain explicit non-overlap live Realtime.
- The OpenAI documentation skill fixed the GA client-secret contract and
  manual WebSocket interruption sequence; the Cloudflare deployment skill
  shaped encrypted secret handling, Wrangler verification, and the explicit
  rate-limit caveat.
- Broker commit: `9d5cb2e` (`feat: deploy Gate 0 session broker`).
- Root then added the topology-neutral iOS broker client. It sends no caller
  policy, bounds response size/expiry, maps errors without exposing bodies, and
  provisions the revocable token only from a device launch environment into
  this-device-only Keychain storage. Five probe tests passed. Client commit:
  `b0d1977` (`feat: add private probe broker client`).
- The probe now bootstraps the token from a one-time launch environment into
  this-device-only Keychain storage and reports only credential state. The
  signed build installed on the iPhone, but the first provisioning launch was
  correctly denied because the phone was locked; no secret appeared in output.
  Device-shell commit: `a51dbd2`.
- Root added a 20,000-event bounded diagnostic recorder with a relative
  monotonic clock, sanitized metadata, provider JSON redaction, and bounded
  export encoding. It retains event/control identifiers while removing media,
  transcript, prompt, token, and secret values. Commit: `d2e85d3`.
- Root added the rendered-only ring algorithm before graph binding. Its tests
  prove wraparound, exact-duration extraction, non-finite sample neutralization,
  and rejection of decoded/scheduled future frames or overwritten history.
  This is code evidence only until a mixer render tap feeds it on the iPhone.
  Commit: `12f3e65`.
- The iOS client now hashes the exact projected Realtime policy and matches the
  Worker's independently computed canonical hash, normalizes provider control
  events without retaining human-readable error detail, rejects duplicate
  event IDs in a bounded window, and encodes explicit append/clear/commit,
  create/cancel, and render-derived truncate commands. Commits: `4966eb0`,
  `38f4686`, and `2c95b6f`. The complete probe suite reached 24/24 passing.
- Root added the provisional direct-WebSocket transport behind an injected
  socket boundary. It requires a policy-matching `session.created` before
  exposing the connection, bounds every frame, logs only redacted event types,
  fails closed on policy drift, and prevents a cancelled handshake from
  resurrecting a stale actor generation. Commits: `8081de1` and `30cb963`.
- Root added a player-timeline ledger that keeps decoded/scheduled ranges
  separate from the monotonic rendered cursor and derives the one permitted
  WebSocket truncation position in item-relative milliseconds. Commit:
  `9ac69d3`. The complete probe suite reached 32/32 passing; these remain code
  results until the selected iPhone graph supplies the cursor.

### 2026-07-14 — Gate 0 native-WebRTC audit and topology freeze

- The root task kept the prescribed 02:18:10–02:48:10 audit window open to its
  exact boundary. Root source capture began 12 seconds late and is recorded
  honestly as 29 minutes 48 seconds, not rounded up.
- The readily available deprecated GoogleWebRTC binary exposed no post-AEC PCM
  callback, device-boundary output frames/render position, or immediate
  playout-only stop. Modern upstream exposes PCM blocks only when the app
  implements and owns a complete custom `RTCAudioDevice`, which the written
  plan forbids.
- Root also checked AEC dump, aggregate playout stats, track disable, the full
  public header inventory, the framework build manifest, and AppRTCMobile's
  default factory path. AEC dump is a file writer; stats are cumulative; track
  disable asynchronously sets volume to zero; the sample uses the stock ADM.
- Official WebRTC HEAD remained
  `07e2e3bfa9f65d9ad0401dd372253807427b0069` through the boundary watch.
- Commit `ecddafc` freezes direct GA Realtime WebSocket plus one root-owned
  `AudioGraphController` using Apple AVFAudio/VoiceProcessingIO. All physical
  route, negotiated-format, post-AEC, audible-render, local-stop, and runtime
  configuration-hash evidence remains pending; no verdict checkbox was marked
  from source inspection.

### 2026-07-14 — Gate 0 root-owned audio graph binding

- Root implemented the frozen topology in `f8fda5d`: one `AudioGraphController`
  owns `AVAudioSession`, VoiceProcessingIO, capture, and tutor playout. It asks
  for microphone access before minting the 120-second secret, asserts voice
  processing on both I/O nodes, taps processed input and the main-mixer render
  path, and tears the graph down on route, interruption, media-reset, or engine
  configuration changes.
- A serial converter produces bounded PCM16 mono 24 kHz uplink frames. A single
  outbound queue prevents mic appends from interleaving inside the local-first
  cancel-plus-one-render-derived-truncate batch. Tutor chunks require complete
  event, response, item, and content identifiers and are capped at one second.
- The render ledger now maps physical player time across scheduling gaps to
  contiguous content time, so silence or underrun gaps cannot be mislabeled as
  heard tutor audio. Local stop snapshots player time, stops the node first,
  resets the epoch, rejects late output from the stopped response, then sends
  provider control.
- The first atomic-order test run hung because its injected socket incorrectly
  closed immediately after the handshake. Root stopped the run, made the mock
  suspend like an open WebSocket, and reran both suites. MAAudioProbe passed
  38/38 test cases (40 parameterized device passes) and MA remained 78/78 on
  iPhone 17 / iOS 26.5 Simulator; both signed generic-device builds succeeded.
  The probe additionally passed complete Swift concurrency checking with all
  warnings treated as errors. These are code/build results only; no physical
  audio criterion is checked yet.
- The signed `f8fda5d` MA and MAAudioProbe artifacts both installed on the
  dynamically rediscovered iPhone 17 Pro / iOS 27.0 beta. The phone auto-locked
  before either process launch, so this milestone records install success and a
  launch blocker—not runtime, microphone, graph, transport, or learner proof.

### 2026-07-14 — Gate 0 evidence-integrity hardening

- Root added protected redacted evidence export in `fa265c7`, then made exact
  replay fail closed on any mixer drop in `4e7855c`. The archive performs a
  second compound-credential scan before writing and stores no raw audio.
- Root added a one-response admission gate in `36e6f3a`; repeated requests,
  competing response IDs, missing IDs, and chunks from a locally stopped
  response cannot enter playout.
- The read-only `/root/gate0_integrity_reaudit` found that an already admitted
  chunk could still resume after `localStop()` while `schedule()` was suspended
  at the evidence actor. It also found that the asynchronous mixer stream could
  not honestly freeze a device-boundary replay window. Root fixed the first
  defect with matching graph/ledger playout epochs in `2c2c3fd` and made the
  second capability unconditionally unavailable. This intentionally revokes
  exact replay permission unless a later Experiment D implements and proves a
  real freeze barrier.
- The same hardening commit enforces exactly one built-in microphone and one
  built-in speaker, subtracts the player output-presentation latency from the
  truncation cursor, logs normalized tap/stop host times, and rejects stale
  epoch schedules. The automated launch/stop sequence waits for scheduled PCM
  only; it is convenience automation and cannot count as audible-render proof
  without external recording and render-tap correlation.
- MAAudioProbe passed 47/47 under complete Swift concurrency with warnings as
  errors. The signed `2c2c3fd` build installed on the physical iPhone, but every
  launch retry remained blocked by the locked phone. No runtime, audio, live
  transport, learner, or exact-replay checkbox was upgraded from code evidence.

## Final feedback preparation

Before running `/feedback` in the root implementation task:

- reconcile this ledger with git history and physical-device evidence;
- identify the highest-value Codex wins and most consequential failures;
- make sure no secrets, raw private audio, or personal identifiers are included;
- record the returned Session ID above and use it in Devpost.
