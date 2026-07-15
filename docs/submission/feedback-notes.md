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
| Real offline first-minute playback/capture | Root replaced the fixture-only production route with a zero-beginner local-audio path: all four bundled assets have a validated manifest, one MA audio owner performs audible-completion playback, JIT permission, bounded 8-second capture, aggregate speech-presence/onset extraction, explicit self-assessment, and no retained PCM or file | `cb9d8bd` | Later hardened guided build passed one-tap playback completion plus real physical capture/stop on iPhone 17 Pro/iOS 27.0; human audibility was not observed | physical control/capture path complete; human learner Gate 1 remains unclaimed |
| Repair/resume and next-attempt evidence | Root bound the natural local tutor turn to real playback state, admits pause only while it is active, plays one complete controlled segment labeled `REPLAY · DEMOSTRACIÓN`, resumes the same obligation only after playback completion, captures a new no-text attempt, and gates proof on the full stop/segment/resume chain | `cb9d8bd` | adversarial re-audit PASS; focused strict tests 11/11 and product UI smoke 1/1 | superseded by the guided retry/continue product; historical replay remains labeled and no physical learner repair claim is made |
| GPT-5.6 planner integration/guardrails | Root added versioned `ScenePlan`, `Attempt`, `LearningReport`, and `NextLearningAction` contracts; an immediate deterministic policy; a Keychain-backed broker client; report-generation cancellation; and double validation that binds every action/reason pair to the same observed obligation. The Worker fixes `gpt-5.6-sol`, strict structured output, `store: false`, bounded input/output/timeout/retry, canonical evidence copy, privacy-preserving safety ID, and endpoint-scoped product authentication | `64e8532` | Physical English/Spanish deterministic-input routes provisioned the private product credential and completed non-fallback GPT-5.6 plans; real microphone audio/transcript never enters the planner | code, broker, live contract, and physical deterministic-input planner path complete; human outcome remains unclaimed |
| Physical-device validation and replay fallback | Root added a bounded normalized `ConversationProvider` contract, capability groups that cannot imply one another, a single-use `ReplayAdapter`, fixture-only provenance, a shared product/replay semantic reducer, stale-event and stale-capture rejection, and a permanently labeled replay UI with no microphone, audio, network, learner, or planner claim. One dynamic device script builds, signs, installs, and launches either product or replay without a checked-in device identifier or credential | `c344a67` | Later physical English/Spanish deterministic-input provider routes and a separate real capture/stop path passed; replay remains permanently labeled and isolated | bounded physical provider/control paths complete; route breadth and human evidence remain open |
| Demo/submission evidence | Root added explicit planner opt-in, accurate deletion/privacy flows, captions, Reduce Motion and Dynamic Type hardening, a tested privacy manifest, claim matrix, Devpost draft, demo/testing/privacy runbooks, subtitles, rehearsal/cold-viewer protocols, fail-closed secret scanning, dynamic device automation, and canonical clean-tree archive automation | `c344a67`, `8c9effc` | Current gates: MA 213/213 executions (184 definitions), probe 51/51 (49 definitions), Worker 35/35; `plutil`, script syntax, generated-project stability, current-tree/history/staged-input/compiled-binary secret scans, negative release-tool tests, and independent audits pass | exact `e968354` packet/archive verified with shipping app implementation `f9f7a7f`; human-quality evidence, video, URLs, `/feedback`, and submission remain gated |
| Guided bilingual Realtime product | After the learner rejected the fixture-first flow, root replaced the shipping route with an English-default/Spanish-switchable lesson: explained target, one-tap bundled model, explicit bounded capture, enum-only transcript-grounded Realtime review, canonical bilingual feedback, retry/continue, a briefed captioned waiter turn, second capture/review, and completion without scores or self-rating. One `AudioGraphController` owns every product audio operation | `a9eb988` | Physical English and Spanish provider/review/planner routes passed with deterministic bundled learner input; a separate real physical capture/stop path passed without claiming semantic review | code/service and bounded physical provider/control paths complete; real-microphone semantic review and human quality remain open |
| Guided aggregate planner and hardened product broker | Root added separate v2 aggregate-only guided planning, explicit opt-in, deterministic local fallback, cancellation/generation fencing, a fixed `gpt-5.6-sol` Responses contract, and an independently re-audited product Realtime mint/review policy. Authenticated quota is consumed before bounded body parsing; exact JSON media types and enum-only review arguments fail closed | `a9eb988` | Worker 30/30; security re-audit DEPLOY; live version `e45a3b92-217b-4830-8841-a50a7465a6da` passed health, invalid-media 400, exact-key mint, local policy-hash match, and bilingual guided-plan validation | complete for authorized private single-device demo; not public/TestFlight auth |
| Current guided device/submission evidence | Root generated, signed, and installed the guided build, rewrote the submission story around the actual bilingual two-review product, and made the operator-only replay's not-live badge bilingual | `a9eb988` | Later retained evidence records physical English/Spanish deterministic-input routes plus real capture/stop on iPhone 17 Pro/iOS 27.0 | physical bounded provider/control paths complete; human/Japanese review, broader device matrix, video, `/feedback`, and submission remain gated |
| Production-realistic simulator and policy closure | Root added a DEBUG-only harness that substitutes only deterministic bundled microphone input while retaining the production broker, `gpt-realtime-2.1` WebSocket, effective-policy verifier, structured two-turn review, spoken feedback, waiter audio, shipping playout, and `gpt-5.6-sol` planner. Root fixed cross-runtime hash normalization, pinned `reasoning.effort=low` in the broker-owned policy, and rejects client attempts to weaken it | `bebac3c` | Live smoke 2/2; repeated bilingual journey 10/10 (five English, five Spanish) at `.build/test-results/MA-live-low-reasoning-bilingual-stress5.xcresult`; real simulator permission/capture 1/1; current standard no-secret suite 213/213 executions; Worker 35/35 | simulator/code/service complete; broader physical route/human quality evidence remains gated |
| Physical live automation and final evidence hardening | Root ran the credentialed lesson on the paired iPhone, distinguished a SpringBoard interruption from app behavior, removed every second-tap recovery so one dispatched tap is the invariant, disabled privileged failure diagnostics, widened the existing two planner attempts from 7 to 10 seconds after a reproduced 14.183-second broker 502, narrowed retries to 408/409/500/502/503/504, and made both live runners fail unless the app verifies test-credential deletion | `80c6eee`, `cf96ce0` | Physical English passed in 47.506 seconds and Spanish passed in 53.729 seconds with deterministic bundled learner input. Exact `bd66804` physical real-audio capture/stop passed 1/1 in 17.484 seconds with verified cleanup; current standard MA 213/213; probe 51/51; Worker 35/35; private Worker version `57d49379-af1f-4160-8e88-ec611ab9a1d7` | deterministic physical bilingual provider path and physical capture/stop complete; JIT prompt, route breadth, human audibility/teaching, real-mic semantic review, and broader device matrix remain gated |
| Verified product data deletion | Root replaced best-effort profile reset with a fail-closed transaction: delete and reload the this-device-only Keychain item first, reset local state only after verified absence, and preserve profile/sheet state with fixed English/Spanish recovery copy on any failure | `f9f7a7f`; physical-runner fix `15f6709` | Focused simulator 7/7 plus complete uncontended MA 213/213. Physical iPhone/iOS 27.0: clean transaction/real-Keychain 4/4 and bilingual/success UI 3/3 bundles | simulator and physical code/Keychain/UI complete; archive refreshed |
| Release review-access repair | A physical user report exposed that the frozen archive could launch without a retained private review credential and defer the failure until after capture. Before every explicit microphone action, root now reconciles cached readiness with the transport actor and reconnects only if stale; failure is visible/capture-blocking. The installer verifies Keychain readback and requires a second bearer-free Release launch to load Keychain and policy-verify a real WebSocket session before ordinary relaunch | pending current fix commit | Current simulator MA suite 227/227 (193 definitions), Worker 35/35, focused readiness/provisioning/audio 24/24 and transport preflight 27/27, Release warnings-as-errors build, and revised live smoke 2/2 pass; final 10-journey and replacement physical archive gates are in progress | old `e968354` archive superseded; not complete until exact replacement archive passes on the phone |

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
| `019f610e-74d5-7701-8c67-d7c2f996a9ce` (`/root/realtime_ux_contract_audit`) | Read-only zero-beginner teaching-flow audit | No files; state machine, Spanish copy, recovery rules, claim guards, and acceptance matrix only | no |
| `019f610e-919c-7a22-8954-beeac18090e5` (`/root/realtime_transport_map_audit`) | Read-only product Realtime integration audit | No files; product-local transport, one-owner audio, ordering hazards, and test map only | no |
| `019f610e-a57f-7a02-a526-4f189387bf93` (`/root/realtime_broker_contract_audit`) | Read-only didactic broker/tool/privacy audit | No files; product-only endpoint, session policy, review schema, parser validation, and security tests only | no |
| `019f6138-b6ae-70b2-931b-2ab170460c1f` (`/root/guided_planner_contract_audit`) | Read-only guided post-lesson planner audit | No files; separate v2 aggregate-review contract, privacy boundary, progression guards, and test matrix only | no |
| `019f613d-6256-70b1-af26-b85d8b7ab5c1` (`/root/bilingual_surface_audit`) | Read-only English/Spanish shipping-surface audit | No files; launch, onboarding, home, guided lesson, profile, state-copy, permission-dialog, Realtime feedback, and UI-test inventory only | no |
| `019f615a-7c19-74b2-b7de-ec96a9e8d19e` (`/root/broker_security_audit`) | Read-only post-deploy broker and Realtime review security audit | No files; request-bound/rate-limit ordering, structured review grounding, prompt-safety, token-budget, auth, and guided-planner contract only | no |
| `019f616b-7336-79b2-b5b7-1e903dfe480d` (`/root/submission_claims_audit`) | Read-only guided-product submission consistency audit | No files; line-specific stale-flow, privacy, Realtime, bilingual, demo, subtitle, and public-claim inventory only | no |
| `019f617d-f7d0-7602-876a-288ca6a1e785` (`/root/guided_runtime_race_audit`) | Read-only guided runtime race and turn-isolation audit | No files; found three lifecycle races, then re-audited root fixes and returned PASS | no |
| `/root/final_static_hygiene_audit` (coordination API exposed no opaque ID) | Read-only final claims, evidence-path, secret, and working-tree hygiene audit | No files; reconciled 175/49/30 evidence paths, ignored artifacts, secrets, and claims; returned PASS | no |
| `019f61a4-a9d0-7cc1-873b-28b8070cfb6b` (`/root/release_script_audit`) | Read-only archive and release-command audit | No files; clean-tree, signature, privacy-manifest, export-compliance, and checksum procedure only | no |
| `019f61fa-3f45-7ce1-87d1-f3b0dae1de5e` (`/root/realtime_contract_audit`) | Read-only physical review-failure contract audit | No files; independently checked the live event sequence, audio-session/text-response validity, token accounting, minimal fix, and regression matrix | no |
| `019f6215-5d61-7981-a68e-716caa30661f` (`/root/policy_normalization_audit`) | Read-only cross-runtime effective-policy audit | No files; isolated the JS/Swift `0.92` canonicalization mismatch and specified the exact fail-closed hash/mutation coverage | no |
| `019f6245-5309-7aa1-9038-8eea09eb02eb` (`/root/realtime_reasoning_policy_audit`) | Read-only current OpenAI Realtime reasoning-policy audit | No files; verified official session/response placement, recommended low voice-agent effort, override risk, and required deployment/live verification | no |
| `019f6260-11a2-7650-b1ee-7b4baddc9134` (`/root/simulator_evidence_audit`) | Read-only result-bundle and live-journey evidence audit | No files; independently reconciled 2/2 smoke, 10/10 bilingual stress, 1/1 audio integration, 205 parameterized deterministic executions, assertions, warnings, and physical-evidence qualifications | no |
| `/root/candidate_hygiene_audit` (coordination API exposed no opaque ID) | Read-only current candidate secret, logging, artifact, signing, and release-tool audit | No files; found provider-controlled public logging and compiled-binary scan gaps, both corrected by root; otherwise clean | no |
| `019f6286-a9de-7510-809f-bb634b902599` (`/root/planner_retry_audit`) | Read-only post-502 planner retry and timeout-budget audit | No files; independently accepted the root's two-by-ten-second policy, rejected a third attempt, and identified transient/permanent/status/privacy test gaps that root closed | no |
| `019f6294-e73b-7613-9f26-4584b9eadac1` (`/root/final_delta_audit`) | Read-only final candidate delta and evidence audit | No files; found the potentially masking language-tap retry, unverified test-credential cleanup, overbroad permanent-5xx retries, and two documentation drifts; root removed or corrected each item | no |
| `/root/release_review_failure_audit` (coordination API exposed no opaque ID) | Read-only physical Release review-failure audit | No files; independently traced the exact missing-credential path, proved the frozen archive had no ordinary bootstrap, and identified the PID-only/accept-any-recovery false gates | no |
| `/root/release_provisioning_fix_audit` (coordination API exposed no opaque ID) | Read-only audit of the root's replacement provisioning/readiness diff | No files; credential leakage, marker integrity, races, Release behavior, and false-green checks only | no |
| `/root/live_runner_isolation_audit` (coordination API exposed no opaque ID) | Read-only audit of the repeated live-simulator runner | No files; found stale-marker, unchecked-command, result-count, and repetition-proof gaps; root fixed each and the reviewer returned PASS | no |

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
- Broker boundary: root kept the frozen probe-only `/realtime/client-secret`
  contract unchanged and added product-only
  `/product/realtime/client-secret`, authenticated by the separately revocable
  product install token. The new fixed `gpt-realtime-2.1` session disables VAD,
  enables Japanese transcription, exposes one bounded `report_attempt` tool,
  disables tracing, and forbids numeric/phoneme-level grading. Caller-selected
  configuration remains rejected.
- Verification: Worker contract tests pass 21/21. Private deployment
  `1010289e-16c3-4379-a09f-dc6209649887` minted a bounded product client secret;
  that secret opened the GA WebSocket and returned `session.created` with model
  `gpt-realtime-2.1`, null turn detection, Japanese
  `gpt-4o-mini-transcribe-2025-12-15`, tool choice `none`, the sole
  `report_attempt` tool, and voice `marin`. No standard key, install token, or
  ephemeral secret was printed or retained. This proves the server policy and
  transport handshake only—not device capture, review quality, or audible
  feedback.

### 2026-07-14 — English-default guided product, broker hardening, and simulator closure

- Learner evidence changed the product: after the repaired legacy controls ran,
  Ignacio rejected the flow because it did not review his voice, jumped between
  listening and recording, and played unexplained Japanese to a level-zero
  learner. Root treated that as a failed product branch, not a cosmetic issue.
- Root built the replacement guided state machine directly. Fresh installs use
  English for American judges; an always-visible English/Spanish switch updates
  onboarding, home, profile, OS permission copy, lesson instructions, Realtime
  feedback, completion, and planner explanations without resetting the phase.
- The new lesson explains `一人です`, romaji, meaning, and the response task;
  requires one completed model playback before explicit recording; reviews the
  first learner turn before retry/continue; briefs and captions one bounded
  waiter turn; and reviews the second learner turn before completion. It has no
  self-rating, numeric score, phoneme claim, auto-record, or unexplained
  Japanese monologue.
- Realtime review security was reduced to locally canonical teaching copy from
  exact enum codes. The app independently grounds any positive result in the
  approximate Japanese transcript and downgrades missing or inconsistent
  evidence to unclear. Provider prose cannot enter later model instructions.
- Independent audit `019f615a-7c19-74b2-b7de-ec96a9e8d19e` first returned NO
  DEPLOY for unbounded/pre-rate-limit parsing, model prose, false-match, token
  budget, and `application/jsonp` acceptance. Root fixed each item. The same
  reviewer independently reran Worker 30/30 and returned DEPLOY for the private
  single-device demo; the static product token remains unsuitable for public or
  TestFlight distribution.
- Root deployed fixed Worker version
  `e45a3b92-217b-4830-8841-a50a7465a6da`. Live redacted checks passed health,
  exact JSON rejection, short-lived product Realtime mint, exact local policy
  hash, and an 11-key bilingual `gpt-5.6-sol` guided recommendation. No
  standard key, install token, or ephemeral secret was printed or persisted.
- The first combined simulator run passed all 158 Swift tests and the real
  audio UI check but reported four UI signal-9 failures. Exported xcresult,
  XCTest, host, and simulator logs proved a second concurrent `xcodebuild`
  process was force-quitting this run's test runner on the same simulator;
  `MA` remained healthy until cleanup. Root did not count the partial reruns.
  With the simulator uncontended and microphone permission reset, all 7 UI
  tests passed in 101.8 seconds, including the English Apple disclosure,
  first-tap production playback, real capture/stop, both bilingual reviewed
  turns, planner opt-in, accessibility, and isolated replay.
- Independent audit `019f616b-7336-79b2-b5b7-1e903dfe480d` returned NO-SHIP on
  the submission copy because it still described the retired Spanish-only
  self-assessment/controlled-repair flow and falsely said audio never left the
  phone. Root rewrote Devpost, reviewer instructions, demo, rehearsals, claims,
  cold-viewer protocol, English subtitles, and release checklist around the
  actual guided product and direct-to-OpenAI audio boundary. The historical
  fallback now carries the bilingual permanent badge
  `REPLAY · NOT LIVE / NO EN VIVO`.
- The same read-only claims reviewer re-audited the rewritten packet and returned
  SHIP for submission copy and claim framing. Root accepted its nonblocking
  precision edits: public copy now says speaking-turn review, and subtitles
  distinguish the provider's approximate transcript from MA's local validation
  and canonical teaching adjustment.
- The signed guided product build installed on the paired iPhone from
  `.build/device-evidence/20260714T160140Z-product`, but the device had re-locked
  before launch. This is install evidence only. English/Spanish live review,
  route/interruption/network, Japanese quality, and learner claims remain open.
- Root then froze an uncontended latest-source simulator result at
  `.build/test-results/MA-complete-freeze-20260714.xcresult`: all 175 test cases
  passed (167 Swift and 8 UI). The separate characterization suite passed 49
  tests in 16 suites at
  `.build/test-results/MAAudioProbe-freeze-20260714.xcresult`. The real-audio UI
  test reset microphone permission, verified Apple's English purpose text,
  tapped Allow, and completed first-tap playback plus capture/stop without
  needing manual computer-use intervention. Visual inspection of the exported
  English completion screen found no overlap or missing controls.
- Independent runtime audit `019f617d-f7d0-7602-876a-288ca6a1e785` initially
  found three release-blocking races: optional spoken feedback could delay the
  visible review, canceled response audio could cross into the waiter turn, and
  rapid Retry/Continue taps could start duplicate cleanup. Root moved optional
  audio after the text review, generation-fenced the response mailbox and
  connection invalidation, and synchronously claimed a disabled transition
  state. Deterministic tests now inject late old audio after reconnect and a
  suspended-stop double tap; the same auditor returned PASS.
- Root added an explicit `ITSAppUsesNonExemptEncryption = NO` declaration to
  both generated targets and a regression test alongside the existing privacy
  manifest contract. `xcodegen generate` reproduced the exact project hash
  `ca4bbdaae0157d3e8ebaf9274427b5727283dc6655abd6cd4aa8a96a1e8beba2`.
- After the freeze, Worker 30/30, `git diff --check`, and the current-set plus
  all-reachable-history secret scan passed. The final post-commit scan and
  clean-tree archive remain separate release gates.
- Read-only release audit `019f61a4-a9d0-7cc1-873b-28b8070cfb6b` found that the
  prior ignored archive was stale and that the archive tool verified the
  privacy manifest but not the embedded export-compliance declaration. Root
  made the clean-tree tool fail unless the archived app contains
  `ITSAppUsesNonExemptEncryption=false`; the old candidate will not be reused.
- The final static hygiene reviewer returned PASS after the ledger update: the
  175/175 MA, 49/49 probe, and 30/30 Worker references agree; all exact evidence
  paths exist; generated/private artifacts remain ignored; current claims and
  placeholders are honest; and every implementation/resource file remains
  visible for the intended commit.
- Local freeze commit `a9eb988` (`feat: ship bilingual guided realtime lesson`)
  contains the English-default bilingual product, Realtime and planner clients,
  broker hardening, deterministic race regressions, privacy/export declarations,
  release-tool enforcement, and reconciled submission copy. Nothing was pushed.
- Clean candidate archive: exact commit
  `60b1eabe1f69c5e535de0d7afb6beb3b580f4c7c` produced
  `.build/submission/candidate-60b1eabe1f69c5e535de0d7afb6beb3b580f4c7c/`.
  The archived privacy manifest linted, embedded
  `ITSAppUsesNonExemptEncryption=false`, Apple Development signature verified,
  all manifest entries rehashed successfully, and `MA.xcarchive.zip` SHA-256 is
  `726c13b2fc4a873b5eb3e541c4bd380222b93e184a600f02c1be91663dd6cdff`.
  This is a private local/device Build Week candidate, not an App Store or
  TestFlight distribution package.
- Final `ma-adversary` audit rejected the first candidate packet on three
  evidence-document defects: the preserved PARTIAL verdict did not explain the
  later user-directed guided Realtime branch, two backlog statements remained
  Spanish-first, and Worker 30/30 had no saved log. Root preserved the original
  verdict and added a dated non-overlap product-direction addendum, reconciled
  the English-default requirements, and saved the exact passing TAP output at
  `.build/test-results/MAWorker-freeze-20260714.tap` for re-audit.
- The re-audit found one final stale day-zero statement that still made Spanish
  the sole explanation language. Root reconciled it to English-default with a
  persistent Spanish switch. The persistent `ma-adversary` then returned CLEAN
  for the verdict addendum, AGENTS scope, backlog, Worker artifact, evidence
  references, and current claim set; only the explicit physical/human/external
  release gates remain open.

### 2026-07-14 — First physical guided review failure and live correction

- The unlocked signed build launched from
  `.build/device-evidence/20260714T184649Z-product`. The learner completed a
  real recording without the earlier capture crash, but the first Realtime
  review ended on the recoverable message “I could not review this attempt.”
  This is a failed physical rehearsal, not a successful live-review claim.
- Root replayed the app's exact clear/append/commit/response transaction against
  the deployed private `gpt-realtime-2.1` session using bundled Japanese model
  audio and redacted protocol-only diagnostics. With the shipping 128-token
  response bound, OpenAI emitted `response.function_call_arguments.done` and
  then `response.done` with `status=incomplete` and
  `reason=max_output_tokens`. The app correctly failed closed and discarded the
  otherwise-finished tool arguments, which explains the learner-visible error.
- The same live transaction with a bounded 256-token response completed with
  one valid four-field `report_attempt` call, Japanese input transcription, and
  `response.done status=completed`. The redacted success log is
  `.build/test-results/MA-live-review-fix-20260714.log`; it contains event types
  and Boolean contract results only, with no token, transcript, audio, or tool
  arguments. No Worker policy change or deployment was required.
- Root changed the client cap to 256 and pinned it in the wire-contract test,
  while preserving the existing regression that rejects every non-completed
  response. Focused Realtime suites passed 14/14 at
  `.build/test-results/MA-realtime-review-fix-focused-20260714.xcresult`. The
  complete uncontended iPhone 17 Pro simulator run then passed all 175 test
  cases (167 Swift + 8 UI) at
  `.build/test-results/MA-review-fix-full-20260714.xcresult`.
- During evidence inspection, root discovered that `devicectl --json-output`
  had serialized the product launch environment into an ignored private JSON
  artifact. Root deleted that artifact, terminated the provisioned process,
  rotated the product install token in both Cloudflare's encrypted secret store
  and the local deployment Keychain, and verified the replacement through a
  redacted authenticated mint. The device script now retains only recursively
  key-sanitized launch JSON, compares retained evidence against the exact
  in-memory product token without printing it, scans retained launch files, and
  deletes the raw temporary JSON on every exit. No standard OpenAI key was
  exposed. The prior candidate archive is stale and will be regenerated.
- Independent read-only session
  `019f61fa-3f45-7ce1-87d1-f3b0dae1de5e` confirmed that per-response text is
  valid inside the audio session and that the live-observed token ceiling is the
  failure cause. Root performed the protocol reproduction, code/test/script
  changes, credential rotation, simulator runs, and device work.

### 2026-07-14 — Production-realistic simulator gate after repeated device failure

- The token-cap correction was necessary but did not close the physical failure:
  the next exact device build still showed “I could not review this attempt.”
  Root stopped device handoffs and acknowledged that the prior 175/175 suite was
  fixture-backed and therefore could not validate the production broker/provider
  path. The user is not being used as the QA loop.
- Root added a DEBUG-only realistic simulator harness that substitutes only a
  deterministic bundled microphone waveform while retaining the shipping audio
  conversion, private broker, `gpt-realtime-2.1` WebSocket, response parser,
  structured review validation, response audio, full two-attempt lesson, and
  bounded `gpt-5.6-sol` planner. Its UI test treats any recoverable review error
  as a hard failure and uses accessibility-identified, condition-based waits.
- The first production-realistic runs exposed two defects hidden by fixtures.
  An unsigned simulator app could not read the Keychain credential
  (`errSecMissingEntitlement`); the harness now uses a signed build and waits for
  a value-free credential-readiness sentinel. With that corrected, the private
  broker minted successfully and the real WebSocket received
  `session.created`, but the app failed its configuration check before review.
- A redacted live comparison proved that OpenAI adds six harmless top-level
  effective-session fields, all already excluded by the app's projection. It
  also proved the broker's JS stable JSON hash and Swift Foundation's sorted JSON
  hash differ for the same requested policy. This cross-runtime canonicalization
  defect—not microphone capture—is the current reproduced blocker. No prompt,
  transcript, credential, or raw provider payload was retained or printed.
- Independent read-only audit session
  `019f6215-5d61-7981-a68e-716caa30661f` is reviewing the policy normalization
  boundary and regression coverage. Root owns the diagnostic, verifier fix,
  production-live simulator path, and all subsequent implementation and device
  decisions.

### 2026-07-14 — Low-reasoning policy correction and simulator closure

- Root fixed the cross-runtime policy defect by requiring the exact decimal
  output speed, projecting a canonical `0.92`, requiring explicit null tracing,
  pinning a fixed Worker-derived policy hash, and adding 26 fail-closed policy
  mutations. A live client-secret/session diagnostic then matched the local
  hash; the only six provider-added fields were the already-characterized
  effective-session metadata.
- Increasing response ceilings alone was not accepted as a fix. The interrupted
  cap-only stress result at
  `.build/test-results/MA-live-production-bilingual-spoken-512-stress5.xcresult`
  executed nine journeys: five passed and four failed, with one spoken-feedback
  and three waiter responses ending incomplete at `max_output_tokens`; the
  tenth did not complete. Root stopped that repeated red run when Ignacio
  reported that the app was looping without useful change.
- Current OpenAI [gpt-realtime-2.1 model documentation](https://developers.openai.com/api/docs/models/gpt-realtime-2.1)
  and [Realtime prompting guidance](https://developers.openai.com/api/docs/guides/realtime-models-prompting#set-reasoning-effort),
  plus independent read-only session
  `019f6245-5309-7aa1-9038-8eea09eb02eb` established that
  `gpt-realtime-2.1` is a reasoning model, higher effort consumes additional
  latency/output tokens, and low effort is the recommended production starting
  point for most voice agents. Root added `reasoning.effort=low` to the
  broker-owned session, included it in the exact Swift verifier/hash, rejected
  `session.update`, and rejects any per-response reasoning value other than the
  same exact low policy.
- Worker 30/30 and the focused 16-test Swift policy/transport suite passed. Root
  deployed private Worker version `62c634a7-5a10-4b7a-b755-96b5abe96d96` and
  verified the live effective policy before resuming a complete lesson.
- The corrected production-realistic smoke passed 2/2. The deliberate repeated
  gate then passed 10/10 complete journeys—five English and five Spanish—at
  `.build/test-results/MA-live-low-reasoning-bilingual-stress5.xcresult`. Each
  repetition required two valid reviews, two completed spoken explanations, a
  completed waiter turn, one-tap bundled model playback, and a non-fallback
  `gpt-5.6-sol` plan. The test substitutes only deterministic bundled learner
  input; it does not stand in for physical microphone, route, or human-quality
  evidence.
- The separate shipping-audio integration passed 1/1 at
  `.build/test-results/MA-live-audio-integration.xcresult`: microphone privacy
  was reset, Apple's prompt appeared, Allow was tapped, one-tap playback
  unlocked recording, and real `AVAudioEngine` capture/stop exited without a
  hang. After isolating the credentialed journey in the opt-in `MALive` scheme,
  the exact documented no-secret `MA` command passed 206/206 executions with
  zero skips at `.build/test-results/MA-standard-no-secret.xcresult` (177 test
  definitions including parameterized cases) and contained no `MALiveUITests`
  execution.
- Final pre-commit hardening passed Worker 30/30 at
  `.build/test-results/MAWorker-low-reasoning-20260714.tap`, `git diff --check`,
  current-set plus all-reachable-history secret scanning, the current
  characterization suite at 51/51 executions (49 test definitions), and exact
  XcodeGen reproducibility at project hash
  `457c754c2e16eddc36d2694f687b02e0af151a253788748812c57cf309dd8ae8`.
  No phone install or stronger physical claim was made from these simulator
  results. The scanner now also has a redacted compiled-executable mode, and
  the release archive must pass it before checksums are accepted.
- Read-only `/root/candidate_hygiene_audit` caught two release-hygiene gaps.
  Root stopped logging the raw provider-controlled `status_details.reason` and
  now emits only fixed local codes (`output_limit`, `missing`, or `other`). Root
  also wired the archived Mach-O executable through the scanner's new binary
  mode. A negative fixture proved the mode fails without printing the matched
  value, while the current compiled simulator app passed.
- Root exported all ten retained live completion screenshots to
  `.build/evidence/MA-live-low-reasoning-stress-attachments/` and visually
  inspected English and Spanish repetitions at original resolution. Both
  interfaces show the correct language switch, two reviewed attempts, the
  model-backed next-practice card, and the restart control without clipping,
  missing text, stale loading state, or fallback label.
- Local implementation commit `bebac3c47c4846cbc339ae130978f0384115bbef`
  (`fix: verify guided realtime end to end`) contains the policy, transport,
  harness, tests, runner separation, privacy logging, and release-tool changes.
  Nothing was pushed.
- The exact committed Debug app built, signed, and installed on the dynamically
  discovered iPhone 17 Pro (iOS 27.0) at
  `.build/device-evidence/20260714T210505Z-product`. Launch was denied because
  the phone had re-locked, so this remains install evidence only; no microphone,
  review, route, or learner claim was closed.
- Root added `scripts/test-live-guided-device.sh` so the next physical pass does
  not use Ignacio as the automation driver. It dynamically discovers the
  device, compiles while the phone may sleep, checks lock state immediately
  before install/provision/test, provisions through the value-free DEBUG
  sentinel, retains no credential-bearing launch output, runs a selected
  physical UI suite, scans its evidence, and now requires value-free proof that
  the test credential was deleted before reporting success. Its selector and
  locked-device negative gates pass.
- Clean commit `bebac3c47c4846cbc339ae130978f0384115bbef` produced
  `.build/submission/candidate-bebac3c47c4846cbc339ae130978f0384115bbef/`.
  The signed Release archive, embedded privacy manifest, and
  `ITSAppUsesNonExemptEncryption=false` passed; all 26 manifest entries rehashed,
  the staged packet plus compiled executable scan passed, and
  `MA.xcarchive.zip` SHA-256 is
  `3f14ecf07eaf8e594622df8f9ae43d33d3788f6117c7d7652cffd0352427605c`.

### 2026-07-14 — First automated physical live pass and bounded recovery

- Root's physical runner built, signed, installed, provisioned, and launched the
  exact clean candidate on the dynamically discovered iPhone 17 Pro running
  iOS 27.0. The English production-Realtime lesson passed in 47.506 seconds,
  including one-tap model playback, two valid structured reviews, two completed
  spoken explanations, waiter playback, and a model-backed next plan.
- A real SpringBoard banner then appeared over the Spanish language control.
  XCTest recorded `NotificationShortLookView`; the tap never reached MA, and
  Spanish failed at the unchanged English accessibility label after 4.310
  seconds. This is retained as an automation failure, not counted as a Spanish
  product pass. Xcode's default failure diagnostics then invoked a privileged
  device diagnostic and waited at a password prompt; root entered no password,
  terminated that diagnostic, and preserved the sanitized test log.
- Root changed the Spanish test to clear any existing banner and preserve the
  one-tap product assertion. A second tap is permitted only when a SpringBoard
  banner is positively found and dismissed after the first dispatch; an
  unobstructed ignored tap still fails. Both device and simulator runners now
  use `-collect-test-diagnostics never`, avoiding the privileged post-failure
  prompt and unbounded diagnostic collection.
- The first corrected Spanish simulator journey verified the one-tap language
  switch and completed both live Realtime reviews, spoken feedback, and waiter
  turn, then exposed a separate final-planner 502. Exported simulator logs
  showed one app-to-Worker request lasting 14.183 seconds, matching exhaustion
  of the Worker's two seven-second provider timeouts; the app correctly
  preserved its local safe plan instead of hanging.
- Root kept the two-attempt security/cost ceiling, widened each provider attempt
  to ten seconds, and widened the iOS outer request budget to 27 seconds, still
  below the 35-second learner-visible terminal wait. Immediate upstream 429
  retry was removed because it cannot honor `Retry-After` and could double
  provider work under the install-scoped limiter. Worker tests now cover a
  timeout-shaped `DOMException`, `502` recovery/exhaustion, permanent-status
  no-retry, identical sanitized retry bodies, one limiter charge, and generic
  error collapse without upstream bodies or credentials.
- Worker 34/34 and focused Swift planner 6/6 passed. Root deployed private
  Worker version `59fa3f6f-0ead-421a-bb16-2b64fd8db1ff`; health returned the
  expected secret-free response. The corrected Spanish production-realistic
  simulator journey then passed 1/1 in 51.205 seconds at
  `.build/test-results/MA-live-spanish-timeout-fix-simulator.xcresult`, including
  a non-fallback `gpt-5.6-sol` plan.
- After committing the correction, root reran the entire standard no-secret MA
  scheme from the clean candidate. It passed 206/206 executions with zero skips
  (177 test definitions, including parameterized cases) at
  `.build/test-results/MA-final-planner-timeout-standard.xcresult`; the isolated
  credentialed `MALive` target was absent.
- The iOS shipping preflight then produced a refreshed signed Release archive
  from clean commit `29be3826a816827f3734f486852abedd7e7619a0` at
  `.build/submission/candidate-29be3826a816827f3734f486852abedd7e7619a0/`.
  Its embedded privacy manifest, deep signature, and
  `ITSAppUsesNonExemptEncryption=false` declaration passed. All 26 checksum
  entries rehashed, the staged bundle plus compiled executable secret scan
  passed, and `MA.xcarchive.zip` SHA-256 is
  `64449aa947c886006c1100984eff8cf6bc561934f1ffd0556bbdaa4ff2f29e45`.
- Read-only audit session `019f6286-a9de-7510-809f-bb634b902599`
  independently accepted the two-by-ten-second policy, rejected a third attempt,
  and proposed the adversarial retry matrix that root implemented. The
  Cloudflare deployment skill required an authenticated preflight and shaped
  the private versioned deployment. Root performed every implementation,
  deployment, test, and device action. Local commit `80c6eee` contains the
  correction; nothing was pushed.

### 2026-07-14 — Spanish physical closure and fail-closed credential cleanup

- From exact clean commit `8bf9c942090526ba8e9761962f2357be8daac02a`,
  the Spanish production-Realtime physical route passed 1/1 in 53.729 seconds
  on the paired iPhone 17 Pro running iOS 27.0. The retained test log proves
  the unobstructed language switch succeeded after its first dispatched tap,
  the model unlocked recording after one tap, and both structured reviews,
  both spoken-feedback completions, the briefed waiter turn, and the
  non-fallback GPT-5.6 plan completed. Evidence is
  `.build/test-results/MA-live-spanish-corrected-device.xcresult` and
  `.build/device-evidence/20260714T220420Z-live-ui/`.
- Read-only audit session `019f6294-e73b-7613-9f26-4584b9eadac1` found that
  the test's banner-conditioned second tap could theoretically mask a real
  ignored tap, cleanup was best-effort, and every 5xx was considered transient.
  Root removed the second tap entirely, now proves any pre-existing banner has
  disappeared before one dispatch, narrowed the retry allowlist to
  408/409/500/502/503/504, and added explicit 501/505 no-retry coverage.
  The same reviewer re-audited the root fixes and returned no P0/P1 finding.
- Root changed the DEBUG credential protocol so an old deletion marker is
  removed first, Keychain deletion is reloaded and verified, the readiness
  marker is removed, and only then is a value-free deletion marker written.
  Both runners require deleted-present and ready-absent; a cleanup failure
  turns an otherwise passing run into exit 80. No marker contains a credential.
- The first post-fix Spanish simulator journey passed the actual live lesson
  in 60.966 seconds, but the new runner correctly withheld a passing gate when
  it checked the pre-XCTest app-container path. Root confirmed the current
  container held only the value-free deletion marker, corrected the runner to
  rediscover XCTest's replacement container, and used the shorter real-audio
  test rather than looping the lesson. That 1/1 playback/capture/stop run then
  printed verified credential deletion at
  `.build/test-results/MA-live-audio-cleanup-proof-simulator.xcresult`.
- The hardened no-secret MA suite passed 206/206 executions with zero skips at
  `.build/test-results/MA-final-credential-cleanup-standard.xcresult`. Worker
  tests passed 35/35 at `.build/test-results/MAWorker-final-retry-policy.tap`,
  including every allowed retry status and permanent 501/505 failures. After
  authenticated preflight, root deployed private Worker version
  `57d49379-af1f-4160-8e88-ec611ab9a1d7`; its secret-free health check passed.
- Local hardening commit `cf96ce08f7a8dc5c740d44197c4fa3499f4a2227`
  contains the root implementation. The first real-microphone physical command
  from that clean commit compiled, then stopped at the lock check before
  install, provisioning, or test because the phone had auto-locked. That is
  not counted as device evidence. Nothing was pushed.
- After the phone was unlocked, root reran the bounded physical audio gate from
  exact clean evidence commit `bd668041d00d5ca7334a94da9e15ead409f5630c`.
  `GuidedLiveAudioIntegrationUITests` passed 1/1 in 17.484 seconds on the iPhone
  17 Pro running iOS 27.0: one model tap unlocked recording, the real Apple
  capture graph started only after the explicit record tap, explicit stop left
  recording, and the short take resolved to the visible recoverable path rather
  than fabricated feedback. Microphone permission was already authorized, so
  this does not close the prompt/denial row. The runner then proved the Keychain
  credential absent, scanned retained evidence, and exited 0. Evidence is
  `.build/test-results/MA-live-audio-cleanup-proof-device.xcresult` and
  `.build/device-evidence/20260714T222736Z-live-ui/`.
- The final characterization rerun passed 51/51 executions (49 definitions) at
  `.build/test-results/MAAudioProbe-final-hardening.xcresult`. A signed archive
  preflight from `bd66804` also passed deep signing, privacy/export checks,
  26-entry rehash, and compiled-binary secret scanning; it remains superseded
  until this physical evidence is committed and the canonical archive is
  regenerated.

### 2026-07-14 — Fail-closed product deletion and uncontended final simulator gate

- The final independent delta audit found one remaining release blocker:
  **Delete all my data** used best-effort Keychain deletion and could reset the
  visible profile even when credential deletion failed. Root replaced it with
  a throwing transaction that deletes and reloads the Keychain item before any
  local reset. A delete, reload, or retained-token result leaves the profile and
  sheet intact and shows fixed English/Spanish recovery copy without system
  status or private values. DEBUG-only seams force the failure states; Release
  always uses the real verified deletion path.
- Root added four transaction/Keychain tests for ordering, error propagation,
  retained-token rejection, and an isolated real Keychain round trip, plus
  three UI journeys for English failure, Spanish failure, and verified success.
  The focused gate passed 7/7 at
  `.build/test-results/MA-local-data-deletion-focused.xcresult`. Read-only audit
  session `019f6294-e73b-7613-9f26-4584b9eadac1` rechecked the source boundary
  and returned PASS with no product-deletion blocker.
- A first complete rerun overlapped an auditor's simulator command and recorded
  a signal-killed Dynamic Type process even though the deletion UI tests later
  passed. Root did not count that run; it is retained with a `.contaminated`
  suffix. Root stopped all other test activity, shut down and cold-booted the
  iPhone 17 Pro simulator, and reran the entire scheme uncontended. The final
  result passed 213/213 executions with zero skips (184 test definitions) at
  `.build/test-results/MA-final-verified-deletion-standard.xcresult`, including
  11/11 UI journeys. No signal-kill, failed assertion, or crash appears in the
  accepted run.
- The iOS UI-testing playbook kept all new journeys accessibility-identified
  and condition-waited, including both failure paths. The shipping preflight
  requires a clean exact commit, verified privacy/export declarations, deep
  signature, current/history/staged/bundle/Mach-O secret scans, and a complete
  checksum rehash before the refreshed archive can be accepted.
- A current read-only hygiene recheck confirmed the earlier raw-provider-reason
  logging and compiled-binary scan findings remain closed: logs use only the
  fixed local codes `output_limit`, `missing`, or `other`, and the archive tool
  scans both the app bundle and extracted executable. Root also reconciled the
  stress wording to two test definitions each repeated five times (10 passed
  journeys) and refreshed the top-level evidence ledger rather than treating
  the bundle summary's two definitions as ten definitions.
- The persistent read-only `tmux:ma-adversary` reviewer then re-audited the
  complete current claim set, counts, verified-deletion wording, and still-open
  external gates and returned `CLEAN`. It made no edits and ran no build or
  test. Video/repository URLs, human/device breadth, `/feedback`, approvals,
  publication, and Devpost submission remain explicitly open.
- Root froze the implementation at exact commit
  `f9f7a7f9fdd2ae649ac20bb18392ab14f2b6047c`. The shipping preflight built
  `.build/submission/MA.xcarchive`, recorded that exact commit and the current
  Xcode/Swift/iPhoneOS SDK environment, verified the app's deep signature,
  linted the embedded privacy manifest, required
  `ITSAppUsesNonExemptEncryption=false`, scanned the staged packet/app/Mach-O,
  and rehashed all 26 manifest entries. `MA.xcarchive.zip` SHA-256 is
  `91c251a7d51a58c8375c9ab8bf27d85bccc51a101f3158dd90a1fc07c64d96e9`.
  The repository remains private and has no remote; nothing was pushed or
  published.
- The unchanged Worker source was rerun after the implementation freeze and
  passed 35/35 at `.build/test-results/MAWorker-final-freeze.tap`, preserving
  the fixed Realtime/planner policy, exact retry allowlist, privacy guards, and
  permanent-error no-retry coverage used by the deployed private version.
- Root then ran the seven deletion checks on the unlocked paired iPhone 17 Pro
  running iOS 27.0. The first combined run passed all four hosted
  transaction/real-Keychain tests but XCUITest could not launch the app. A
  separate warm-launch attempt exposed the exact infrastructure cause:
  unqualified Xcode destinations advertised both `arm64e` and `arm64`, selected
  `arm64e`, and failed to inject the generated `arm64` test bundle with
  `Bad CPU type in executable`. Manual launch of the same signed app succeeded,
  so root changed no product code and retained both failed bundles as negative
  infrastructure evidence.
- With `arch=arm64` explicitly selected, all three physical UI journeys passed
  in 40.096 seconds at
  `.build/test-results/MA-local-data-deletion-ui-device-arm64.xcresult`: English
  failure preserved the profile and explained recovery, Spanish failure did the
  same, and verified deletion returned to onboarding. A separate clean physical
  bundle passed the four transaction/real-Keychain tests at
  `.build/test-results/MA-local-data-deletion-unit-device-arm64.xcresult`,
  including an isolated Keychain save/delete/reload round trip. Both summaries
  identify the paired iPhone 17 Pro, iOS 27.0, and `arm64`, with zero failures
  and zero skips.
- Root committed the reproducibility correction as
  `15f67091741024bad903137f6c775b8501988869`: the standard physical runner now
  pins `arch=arm64` for build-for-testing and test-without-building, preventing
  Xcode from choosing the incompatible advertised destination. Shell syntax,
  diff hygiene, and the current/history secret scan passed. This tooling-only
  correction does not alter the exact `f9f7a7f` app/archive binary.
- The persistent `tmux:ma-adversary` reviewer rechecked only this final physical
  delta and returned `CLEAN`: it confirmed the retained unpinned-architecture
  failures are not counted, the two accepted `arm64` bundles support exactly
  4/4 plus 3/3 deletion claims, and no human, audio-quality, teaching, or
  learner-outcome gate was upgraded.
- After committing the physical evidence and architecture runbook, root rebuilt
  the complete packet from exact clean commit
  `e968354b04d5043d65db9c809d02f0ae209a60a1`. The archived app still derives
  from shipping implementation `f9f7a7f`; the later changes are physical-runner
  tooling and evidence documentation only. The refreshed archive again passed
  deep signature, embedded privacy-manifest lint, export declaration, staged
  packet/app/Mach-O secret scan, and all 26 checksum rehashes. The archived
  testing instructions match the committed source byte-for-byte, and
  `MA.xcarchive.zip` SHA-256 is
  `29b0454396797d7483c6306731eae9c309fe8406d45227b61870845e81ba08db`.
- At 2026-07-14 17:13 CST, after an earlier lock-denied launch that is not
  counted, root launched the installed final Release app from that exact
  `e968354` archive on the dynamically discovered iPhone 17 Pro/iOS 27.0 as
  PID 20185; a follow-up device process inventory still found that PID running
  from `MA.app`. This closes final archive install/launch and immediate-stability
  evidence only; it does not upgrade the separately qualified audio, route,
  human-teaching, or learner-outcome claims.

### 2026-07-15 — Physical Release review-access failure and replacement gate

- Ignacio reproduced the archived product failure after submitting real audio.
  Root traced the exact message to `missingCredential`: the prior live runner
  deliberately removed its test credential, while the final archive gate then
  proved only install, PID launch, and immediate liveness. An ordinary icon
  launch could not provision the missing private access. The `e968354` archive
  and its `29b045...` checksum are therefore superseded, not submission-ready.
- Root changed the lesson contract so the model can still be heard, but the
  microphone control is never exposed until the review connection succeeds.
  Missing, expired, or unavailable access is now bilingual and actionable on
  the model screen; retry reconnects without starting capture. This prevents a
  learner from recording an answer the app already knows it cannot review.
- Root added exact Keychain write/readback verification and an authorized
  Release installer. A stored receipt proves the first launch's exact readback;
  a second launch receives no bearer token and writes its unique ready receipt
  only after loading Keychain and completing a real, policy-verified Realtime
  WebSocket session. A final launch receives neither token nor nonce. The
  private token is never retained in evidence. This repairs the authorized
  single-device demo; it does not claim public/TestFlight self-enrollment.
- Standard audio automation now starts/stops the real Apple audio graph, then
  substitutes only the simulator's labeled deterministic learner payload and
  requires visible feedback. A separate silence test requires no transcript or
  review. Missing access, authorization failure, and generic recovery can no
  longer satisfy that gate. Focused tests passed 24/24, MA passed 227/227,
  Worker passed 35/35, the live bilingual smoke passed 2/2, and the Release
  warnings-as-errors build passed. The repeated live journey and exact
  replacement-archive iPhone gates remain open until recorded below.
- The first stale-readiness fix deliberately disconnected and re-minted before
  every capture. A live stress run rejected that design: its first process
  opened three policy-verified sessions, but later simulator processes returned
  Keychain OSStatus `-34018`; root stopped the run instead of retrying blindly,
  retained the fixed-code-only log at
  `.build/test-results/MA-live-forced-reconnect-keychain-failure.log`, and reset
  only the simulator Keychain. The log passed the secret scanner.
- Root replaced that churn with transport-state reconciliation. `connect()` now
  reads the WebSocket transport actor's real state before every microphone
  action, reuses a genuinely connected session, and invalidates/re-mints only a
  failed or idle transport. The focused provider/feature/UI gate passed 27/27;
  a new live English/Spanish smoke then passed 2/2 with verified credential
  deletion. The aborted stress run is negative evidence and is never counted.
- A later all-in-one XCTest repetition hit an Apple simulator AX failure and
  then Keychain `-34018`; root replaced `-test-iterations` with isolated,
  credential-bracketed pairs and exact xcresult validation. Three consecutive
  English/Spanish pairs passed, but Ignacio correctly objected that continued
  repetition was noisy and delayed the physical failure gate. Root stopped the
  fourth pair, verified credential deletion, and moved to the phone. No claim
  depends on the interrupted pair.

## Final feedback preparation

Before running `/feedback` in the root implementation task:

- reconcile this ledger with git history and physical-device evidence;
- identify the highest-value Codex wins and most consequential failures;
- make sure no secrets, raw private audio, or personal identifiers are included;
- record the returned Session ID above and use it in Devpost.
