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
| Gate 0 probe and written verdict | Clock started 2026-07-14 01:18:10 CST; the fixed native-WebRTC audit completed without rounding its 29m48s root capture; root bound and hardened the provisional graph, then wrote automatic PARTIAL at the mandatory 04:18:10 hour-3 cutoff when no physical topology had launched | `0432b6f`, `ecddafc`, `f8fda5d`, `2c2c3fd`, `d4db899` | 0/0/0 physical trials; every post-freeze launch lock-denied; all physical criteria false | PARTIAL complete |
| Selected one-owner audio topology | Root rejected stock native WebRTC after its public/binary surface exposed none of the three required hooks together; implemented direct GA WebSocket plus one app-owned AVAudioEngine/VoiceProcessingIO graph, JIT permission, processed-input and mixer taps, built-in-route enforcement, route teardown, runtime hash, and revocable playout epochs | `ecddafc`, `f8fda5d`, `2c2c3fd` | strict signed device build only; no runtime route/render proof | developer probe only; not permitted in MA |
| Realtime transport/event normalization | Root added bounded monotonic diagnostics, provider redaction, effective-policy verification, typed/deduplicated events, bounded commands, and a cancellation-safe URLSession WebSocket actor that exposes no event before `session.created` policy verification; one outbound serializer makes cancel-plus-truncate atomic against mic appends and a response gate rejects duplicate/concurrent/stopped output | `d2e85d3`, `4966eb0`, `38f4686`, `2c95b6f`, `8081de1`, `30cb963`, `f8fda5d`, `36e6f3a`, `2c2c3fd` | strict probe suite 47/47; no physical live session | product transport permission false |
| Local cue classifier/floor policy | The mandatory Gate 0 PARTIAL cut left post-AEC phrase classification unproved and therefore unavailable to MA; root removed the overlap path from product scope and uses one explicit local stop control instead | `d4db899`, `cb9d8bd` | no classifier trial; explicit-stop state guards covered in the strict product suite | automatic PARTIAL cut; not a product claim |
| Render ledger/ring buffer/repair replay | Root implemented a bounded rendered-only ring plus a gap-aware player-timeline ledger that rejects future/backward/stale-epoch cursors and derives item-relative truncation milliseconds only from marked-rendered frames; live exact-window exposure is deliberately disabled because the asynchronous mixer handoff is not a device-boundary freeze barrier | `12f3e65`, `9ac69d3`, `f8fda5d`, `4e7855c`, `2c2c3fd` | deterministic mapping/ring tests; Experiment D n=0 | characterization code complete; exact replay permission false |
| Session broker and secret handling | Root implemented the fixed-policy Worker, private install-token boundary, stable safety identifier, rate-limit binding, bounded response, iOS broker client, and this-device-only Keychain provisioning | `9d5cb2e`, `b0d1977` | Worker 7/7; iOS probe 5/5; Wrangler dry run; live health 200, unauthorized 401, caller override 400, authorized mint 200 | complete with recorded Gate limitation |
| Real offline first-minute playback/capture | Root replaced the fixture-only production route with a zero-beginner local-audio path: all four bundled assets have a validated manifest, one MA audio owner performs audible-completion playback, JIT permission, bounded 8-second capture, aggregate speech-presence/onset extraction, explicit self-assessment, and no retained PCM or file | `cb9d8bd` | complete strict scheme 90/90; signed iPhone 17 Pro build and install succeeded, but launch was lock-denied before any runtime/audio claim | code and simulator complete; physical Gate 1 pending |
| Repair/resume and next-attempt evidence | Root bound the natural local tutor turn to real playback state, admits pause only while it is active, plays one complete controlled segment labeled `REPLAY · DEMOSTRACIÓN`, resumes the same obligation only after playback completion, captures a new no-text attempt, and gates proof on the full stop/segment/resume chain | `cb9d8bd` | adversarial re-audit PASS; focused strict tests 11/11 and product UI smoke 1/1; no physical learner run yet | code and simulator complete; physical Gate 2 pending |
| GPT-5.6 planner integration/guardrails | Root added versioned `ScenePlan`, `Attempt`, `LearningReport`, and `NextLearningAction` contracts; an immediate deterministic policy; a Keychain-backed broker client; report-generation cancellation; and double validation that binds every action/reason pair to the same observed obligation. The Worker fixes `gpt-5.6-sol`, strict structured output, `store: false`, bounded input/output/timeout/retry, canonical evidence copy, privacy-preserving safety ID, and endpoint-scoped product authentication | `64e8532` | Worker 18/18; complete strict MA scheme 104/104 test cases (106 parameterized executions); shared Swift/Worker fixtures; live private `gpt-5.6-sol` response validated; product token rejected by Realtime endpoint with 401 | code, broker, and live contract complete; physical product provisioning pending |
| Physical-device validation and replay fallback | Root added a bounded normalized `ConversationProvider` contract, capability groups that cannot imply one another, a single-use `ReplayAdapter`, fixture-only provenance, a shared product/replay semantic reducer, stale-event and stale-capture rejection, and a permanently labeled replay UI with no microphone, audio, network, learner, or planner claim. One dynamic device script builds, signs, installs, and launches either product or replay without a checked-in device identifier or credential | `c344a67` | strict MA 113 Swift + 4 UI tests; independent replay re-audit PASS; exact-commit product and replay builds installed on the dynamically discovered iPhone 17 Pro, then both launches were lock-denied | fallback code, simulator, and signed install complete; unlocked physical runtime matrix pending |
| Demo/submission evidence | Root added explicit planner opt-in, accurate deletion/privacy flows, captions, Reduce Motion and Dynamic Type hardening, a tested privacy manifest, claim matrix, Devpost draft, demo/testing/privacy runbooks, subtitles, rehearsal/cold-viewer protocols, fail-closed secret scanning, dynamic device automation, and canonical clean-tree archive automation | `c344a67`, `8c9effc` | MA 113 + 4, probe 47, Worker 18; `plutil`, script syntax, generated-project diff, current-tree/history/staged-input secret scans, negative release-tool tests, independent WP-6/7 audit PASS, signed Release archive, exact commit/environment files, and verified checksums | private submission packet/archive prepared; physical/human evidence, video, URLs, `/feedback`, and submission remain gated |

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
| `tmux:ma-adversary` | Persistent independent evidence and public-claim reviewer | Read-only verdict/ledger audit; no core edits permitted | no |
| `/root/offline_audio_test_design` | Read-only PARTIAL product audio test-seam audit | No files; injectable offline playback/capture test design only | no |
| `/root/wp3_product_integrity_audit` | Read-only post-implementation and post-fix WP-3 audio/state/claim integrity audit | No files; found four lifecycle/proof risks, then re-audited root fixes and returned PASS with only device checks open | no |
| `/root/wp5_planner_contract_audit` | Read-only WP-5 broker/schema/guardrail adversarial audit | No files; planner security, privacy, progression, and test checklist only | no |
| `/root/wp67_submission_gap_audit` | Read-only WP-6/WP-7 submission and hardening gap audit | No files; documentation, privacy, accessibility, evidence, and external-gate checklist only | no |
| `/root/replay_contract_audit` | Read-only normalized replay architecture and test audit | No files; smallest honest `ConversationProvider`/capabilities/`ReplayAdapter` contract review only | no |
| `019f60ef-42d9-70d1-88de-e50c0e53f6dc` (`/root/physical_audio_defects_audit`) | Read-only physical crash and first-tap playback audit | No files; Swift 6 callback-isolation and playback lifecycle review only | no |
| `019f60fd-740f-7d01-8fd7-05abda774128` (`/root/playback_stall_audit`) | Read-only physical playback-stall audit | No files; output-session, engine lifecycle, asset loudness, watchdog, and device-regression review only | no |

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

### 2026-07-14 — Gate 0 hour-3 automatic PARTIAL

- The mandatory topology deadline was 04:18:10 CST. The verdict became
  effective then and was persisted at 04:18:17, on the first tool return after
  the boundary, against clean snapshot `7585e63`.
- Every post-freeze attempt to launch the signed probe on the dynamically
  discovered iPhone 17 Pro was denied because the phone remained locked. The
  final retry began at 04:17:04. No physical audio graph, microphone permission,
  tutor render, route, local stop, AEC, transport media, or learner trial ran.
- Explicit consent for external diagnostic recording was not received, so no
  acoustic recording was made. Held-out counts are honestly 0/0/0 and the
  characterization tier was not met.
- Root applied the written kill rule rather than extending Gate 0. PASS was
  already disqualified by the ephemeral-secret logging incident; Experiment 0
  additionally left live transport permission false, and Experiment D left
  exact rendered-window replay permission false.
- The product branch is now bundled local tutor audio, explicit tap/stop,
  controlled complete segments labeled `REPLAY · DEMOSTRACIÓN`, same-obligation
  repair/resume, and bounded provider-free local learner capture with explicit
  self-assessment and no retained raw audio. The post-lesson, non-audio
  `/learning/next` call remains permitted. No “live,” “exact,” “validated on
  device,” overlap, or full-duplex claim is permitted.
- The persistent `ma-adversary` independently froze the same four conclusions
  before the boundary. Its post-write audit found and closed two permission
  ambiguities plus one label mismatch, then returned CLEAN for the verdict,
  zero-trial evidence record, permission cuts, provenance taxonomy, and public
  wording.
- GPT-5.6 use at this milestone: `gpt-5.6-sol` with ultra reasoning powered the
  root implementation task. GPT-5.6 was not yet called by the MA product.

### 2026-07-14 — WP-3/WP-4 local Kaiwa Loop product slice

- Intended outcome: turn the fixture baseline into the honest PARTIAL product
  branch without importing any unproved live, overlap, or exact-replay claim.
- Root implementation: commit `cb9d8bd` adds MA's sole product
  `AudioGraphController`, a verified four-asset catalog, audible-completion
  playback, just-in-time microphone permission, mutually exclusive bounded
  learner capture, aggregate presence/onset evidence, explicit self-assessment,
  and unconditional raw-audio non-retention. Production navigation now opens
  the real local Kaiwa Loop while the original fixture reducer remains available
  only to its deterministic tests and replay-oriented screens.
- Beginner path: the learner hears and rehearses `一人です` through full,
  rhythm-only, and no-text scaffolds before entering a natural-speed local tutor
  turn. The product teaches one explicit pause control instead of pretending to
  recognize an overlapped cue.
- Repair integrity: pause is admitted only while `tutor-turn.m4a` is actually
  playing; the repair uses the complete prepared `repair-beat.m4a` segment with
  `REPLAY · DEMOSTRACIÓN`; resume requires that segment's played-back callback,
  preserves `restaurant.party-size.one`, and reaches proof only after the
  resumed audio completes and a post-repair no-text attempt is self-confirmed.
- Test evidence: the full MA scheme passed 90/90 on the iPhone 17 simulator
  (iOS 26.5) with complete Swift concurrency and compiler warnings treated as
  errors. The focused audio/state suite passed 11/11 and the new product smoke
  UI test passed 1/1.
- Adversarial result: the read-only `/root/wp3_product_integrity_audit` first
  found delayed-permission resurrection, self-induced route teardown, lingering
  session ownership, and incomplete proof-gating risks. Root fixed all four;
  its second pass returned PASS with no P0/P1 remaining in code.
- Physical evidence: a fresh signed build for the dynamically discovered paired
  iPhone 17 Pro succeeded and installed as `com.ia.ma`. Launch was denied because
  the phone remained locked, so audibility, microphone indication, route changes,
  session release, learner completion, repair, and better-attempt claims remain
  explicitly open.
- GPT-5.6 use at this milestone: `gpt-5.6-sol` with ultra reasoning powered the
  root implementation task. The MA product still made no GPT-5.6 request; that
  integration begins in WP-5.

### 2026-07-14 — WP-5 bounded GPT-5.6 pedagogy planner

- Intended outcome: let GPT-5.6 recommend one post-lesson action without giving
  it authority over learner evidence, obligation completion, product audio, or
  the hero path.
- Root implementation: commit `64e8532` adds Codable/schema-backed `ScenePlan`,
  `Attempt`, `LearningReport`, and `NextLearningAction`; a deterministic
  pedagogy policy; a resilient planner wrapper; an endpoint-specific broker
  client; and this-device-only Keychain provisioning. The proof screen receives
  a deterministic recommendation synchronously, then accepts a remote result
  only when its report UUID, model, source, obligation, action, reason, and
  evidence semantics all revalidate against the still-current report.
- Broker boundary: `/learning/next` accepts one exact versioned report, strips
  report/attempt UUIDs before model input, sends no transcript or raw audio,
  fixes `gpt-5.6-sol`, uses strict Responses structured output, `store: false`,
  a salted safety identifier, 320 output tokens, seven-second attempts, and a
  single retry. Refusal, incomplete output, unexpected content, invalid JSON,
  extra fields, invented evidence, contradictory progression, or upstream
  failure returns a generic error and therefore the local policy.
- Credential correction: the inherited probe token was unavailable in this
  root shell, so root created a separately revocable product token without
  rotating or invalidating the probe. Its value exists only in Cloudflare's
  encrypted secret store and the local macOS Keychain. The final Worker accepts
  the probe token only on `/realtime/client-secret` and the product token only
  on `/learning/next`; cross-role authorization is rejected.
- Test evidence: the Worker passed 18/18 tests, including all action/reason
  combinations, raw-audio rejection, refusal/incomplete output, one-retry
  budget, and cross-token denial. The full strict MA scheme passed 104/104 test
  cases (106 parameterized executions), including shared Worker/Swift request
  and response fixtures, stale-result cancellation, missing-token fallback,
  broker error mapping, and all UI tests.
- Live evidence: deployed private Worker version
  `e883b190-1a60-4431-ac61-d9a35abbb8f1` returned `source=model`,
  `model=gpt-5.6-sol`, `action=advance`, and
  `reason=completed_after_repair` for the canonical bounded report. The same
  product token received 401 from the Realtime secret endpoint. No token,
  standard API key, raw audio, transcript, provider request ID, or upstream
  error body appeared in output.
- Adversarial result: `/root/wp5_planner_contract_audit` first caught the
  independent action/reason semantic hole, then caught endpoint-role leakage
  and premature GPT pending copy. Root closed all three; the final re-audit
  returned PASS with no P0/P1 remaining.
- Physical evidence: the final signed planner build installed on the paired
  iPhone 17 Pro, but its provisioning launch was lock-denied. Device Keychain
  persistence, model-source UI labeling, tokenless fallback, and live product
  planner behavior remain open physical checks.
- GPT-5.6 use at this milestone: `gpt-5.6-sol` with ultra reasoning powered the
  root implementation task, and MA's private broker made the product's first
  bounded `gpt-5.6-sol` Responses request.

### 2026-07-14 — WP-6/WP-7 replay, privacy, and submission hardening

- Intended outcome: preserve the complete hero semantics in a deterministic
  venue fallback without importing any live, hardware, learner, exact-replay,
  or planner claim, then prepare a reproducible private submission package.
- Root implementation: commit `c344a67` adds bounded normalized conversation
  events, independent model/audio/floor capability groups, a terminal
  single-use `ReplayAdapter`, fixture-only evidence provenance, and one pure
  semantic reducer shared by the shipping local product and labeled replay.
  Product restart/exit invalidates stale capture receipts; replay restart
  invalidates stale adapters and event generations.
- Replay truthfulness: the fallback has a separate visual copy path and a
  permanent `REPLAY · NO EN VIVO` badge. It performs no audio, permission,
  microphone, network, or planner operation; its four attempts and next action
  are explicitly fixed sample data. The binding floor capability now records
  `characterization_only_partial`, matching the zero-trial Gate 0 verdict.
- Privacy and accessibility: the remote `gpt-5.6-sol` plan is now an explicit
  post-proof opt-in after the deterministic local action is already useful.
  Delete-all clears profile/onboarding/scene state and the device credential.
  `PrivacyInfo.xcprivacy` declares no tracking, the optional aggregate product
  interaction/usage data, and the app-only UserDefaults reason. Natural and
  resume audio have captions; motion is gated; primary controls scale; and
  microphone denial exposes Settings recovery.
- Verification: the final serialized strict MA run passed 113 Swift tests in
  20 suites plus 4 UI tests with complete concurrency checking and warnings as
  errors. Its result is
  `Test-MA-2026.07.14_06-21-31--0600.xcresult`. MAAudioProbe passed 47 tests in
  15 suites at `Test-MAAudioProbe-2026.07.14_06-22-40--0600.xcresult`; the
  Worker passed 18/18. The privacy manifest, Bash scripts, generated project,
  whitespace, and current-tree plus all-history secret scan also passed.
- Independent review: `/root/replay_contract_audit` returned PASS after root
  closed replay resume, capability, provenance, cancellation, stale-event, UI,
  and stale-capture gaps. `/root/wp67_submission_gap_audit` reviewed the
  documentation, privacy, accessibility, evidence, and external-gate boundary
  without editing core code.
- Physical evidence: `scripts/device-ma.sh` dynamically found the iPhone 17 Pro
  on iOS 27.0, then built, signed, and installed exact commit `c344a67` in
  product and replay modes. Private evidence directories are
  `20260714T122325Z-product` and `20260714T122345Z-replay`. Both launches were
  denied by SpringBoard because the phone remained locked, so audio, microphone,
  route, interruption, deletion, accessibility, planner provisioning, learner,
  and replay runtime checks remain open.
- Submission preparation: the claim matrix, Devpost draft, demo and reviewer
  runbooks, privacy disclosure, rehearsal/cold-viewer protocols, English
  subtitles, release checklist, dynamic device tool, secret scanner, and clean
  archive/checksum tool are tracked. No repository push/share, video upload,
  `/feedback`, public URL, or Devpost submission was performed.
- Release-boundary re-audit: `/root/wp67_submission_gap_audit` found that the
  first scanner could mask tool errors, the archive output override could make
  `rm -rf` unsafe, untracked XcodeGen inputs were not rejected, and an optional
  redacted log was copied after scanning. It also caught unmeasured
  “immediate” copy, inaccurate token-persistence wording, and unconditional
  pre-verdict requirements. Root fixed every issue in `8c9effc`; the reviewer
  returned PASS with no remaining P0/P1.
- Fail-closed release evidence: missing extra scan input exits 2 without PASS;
  a redacted fake credential exits 1 while printing only its location; an
  output outside `.build/submission` exits 64; tracked/untracked drift exits 65;
  and a temporary untracked Swift source was rejected before archive deletion
  or build. Optional log/video inputs must resolve beneath ignored
  `.build/submission-inputs` and staged text is rescanned.
- Archive evidence: the clean `8c9effc` run produced a signed Release archive,
  verified the embedded privacy manifest and app signature, recorded Xcode
  26.6 / Swift 6.3.3 / iPhoneOS SDK 26.5, and passed all 24 entries in its
  ignored `SHA256SUMS`. The package contains the signed Xcode archive,
  sanitized replay contracts, approved submission copy, exact Git identity,
  build environment, and build log; no optional private log or video was
  supplied.
- GPT-5.6 use at this milestone: `gpt-5.6-sol` with ultra reasoning powered the
  root implementation task. The product calls `gpt-5.6-sol` only after explicit
  learner opt-in and retains its deterministic local fallback.

### 2026-07-14 — Unlocked physical audio defect loop

- First unlocked product run: the signed product launched from
  `.build/device-evidence/20260714T135644Z-product`. The learner then reported
  that beginning an answer closed the app. Device incident
  `F149B847-53EC-44E5-92BC-3E0AAC574D28`, preserved as
  `.build/device-evidence/20260714T140031Z-capture-crash/MA-2026-07-14-075800.ips`,
  is `EXC_BREAKPOINT` on `RealtimeMessenger.mServiceQueue`; its
  `_swift_task_checkIsolatedSwift` stack enters the capture-tap closure created
  inside the main-actor audio owner. Root replaced the inherited actor closure
  with an explicitly sendable callback constructed at a nonisolated boundary,
  applied the same correction to both probe taps, and added background-queue
  regression tests.
- First correction was insufficient for playback. In the signed run at
  `.build/device-evidence/20260714T141507Z-product`, the learner reported that
  one model-audio tap was silent and a second remained stuck. Before debugger
  intervention MA was alive as PID 17891 and the device still contained only
  the earlier 07:58 crash, proving a render/completion stall rather than another
  termination. A remote LLDB attach could not pause the iOS 27 process and
  terminated that instance, so no stack snapshot or success claim is derived
  from it.
- Evidence changed the design: root removed bundled playback from the duplex
  AVAudioEngine path. One `AudioGraphController` still owns all product audio,
  but each local prompt now uses a fresh output-only `AVAudioPlayer` session;
  input-node initialization and 48 kHz capture preferences occur only for
  capture. Delegate completion crosses a nonisolated boundary, and a
  generation-guarded duration-plus-output-latency watchdog converts any future
  stall into a visible recoverable failure instead of permanent
  `Escuchando…` state.
- The shipped assets were also objectively too quiet: the four original means
  were -24.8 to -27.7 dBFS and the 0.732-second model prompt peaked at -13.5
  dBFS. Root normalized each mono 22.05 kHz AAC prompt toward -16 LUFS with a
  -2 dB true-peak ceiling. A strict decoder test now rejects RMS below -22 dBFS
  or clipping risk. The final strict simulator run passed 117 Swift tests in
  20 suites plus 4 UI tests at
  `Test-MA-2026.07.14_08-28-26--0600.xcresult`; MAAudioProbe passed 49 tests
  in 16 suites at `Test-MAAudioProbe-2026.07.14_08-27-36--0600.xcresult`.
  The added non-main playback-delegate contract then passed in the focused
  11/11 suite at `Test-MA-2026.07.14_08-36-39--0600.xcresult`.
- Physical product evidence: the repaired signed build was installed from
  `.build/device-evidence/20260714T142658Z-product`. After the earlier crash,
  silent-first-tap, and stuck-second-tap reports, the learner reported that the
  app was working. This confirms the repaired controls well enough to continue
  product evaluation; route/interruption measurements and any stronger audio
  claims remain open.
- Independent sessions `019f60ef-42d9-70d1-88de-e50c0e53f6dc` and
  `019f60fd-740f-7d01-8fd7-05abda774128` only audited evidence and code. Root
  performed every core audio, state, UI, asset, test, device, and journal edit.

### 2026-07-14 — Learner rejection and guided-Realtime product pivot

- The working physical run exposed a product failure more important than the
  repaired controls. The absolute-beginner learner explicitly rejected the
  sequence because MA did not review recorded audio, jumped between listening
  and recording without feedback, and played a full Japanese situation without
  explaining either its meaning or the learner's next action.
- Root accepts this as disconfirming evidence for the fixture-first hero flow.
  The frozen Gate 0 PARTIAL verdict remains an honest record of the overlap and
  replay experiment; it no longer selects the primary pedagogy. The replacement
  is an explicit non-overlap, push-to-talk Realtime teaching loop: Spanish goal,
  visible Japanese/romaji/meaning, model, deliberate attempt, bounded transcript
  and correction, retry, then a short captioned situation with one explicit
  action. No unexplained Japanese monologue, silent phase transition, self-grade,
  approximate pronunciation score, or fixture presented as live is permitted.
- The new live path will be verified and claimed separately from Gate 0. Until
  the signed product completes the loop on the paired iPhone, this entry records
  direction and acceptance criteria—not completion.

## Final feedback preparation

Before running `/feedback` in the root implementation task:

- reconcile this ledger with git history and physical-device evidence;
- identify the highest-value Codex wins and most consequential failures;
- make sure no secrets, raw private audio, or personal identifiers are included;
- record the returned Session ID above and use it in Devpost.
