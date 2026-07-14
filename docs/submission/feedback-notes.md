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
| Gate 0 probe and written verdict | Clock started 2026-07-14 01:18:10 CST; hard stop 2026-07-15 01:18:10 CST | `0432b6f` | physical protocol pending | in progress |
| Selected one-owner audio topology | pending | pending | pending | pending |
| Realtime transport/event normalization | Root added bounded monotonic diagnostics, generic provider redaction, effective-policy verification, typed server events, duplicate rejection, and bounded client commands | `d2e85d3`, `4966eb0`, `38f4686`, `2c95b6f` | probe suite 24/24; live transport pending | in progress |
| Local cue classifier/floor policy | pending | pending | pending | pending |
| Render ledger/ring buffer/repair replay | Root implemented a bounded rendered-only ring with wraparound and explicit future/overwritten-window rejection | `12f3e65` | 4 ring-buffer tests; graph/physical evidence pending | in progress |
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

## Final feedback preparation

Before running `/feedback` in the root implementation task:

- reconcile this ledger with git history and physical-device evidence;
- identify the highest-value Codex wins and most consequential failures;
- make sure no secrets, raw private audio, or personal identifiers are included;
- record the returned Session ID above and use it in Devpost.
