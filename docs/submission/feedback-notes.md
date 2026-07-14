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
| Gate 0 probe and written verdict | pending | pending | pending | pending |
| Selected one-owner audio topology | pending | pending | pending | pending |
| Realtime transport/event normalization | pending | pending | pending | pending |
| Local cue classifier/floor policy | pending | pending | pending | pending |
| Render ledger/ring buffer/repair replay | pending | pending | pending | pending |
| Session broker and secret handling | pending | pending | pending | pending |
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

## Final feedback preparation

Before running `/feedback` in the root implementation task:

- reconcile this ledger with git history and physical-device evidence;
- identify the highest-value Codex wins and most consequential failures;
- make sure no secrets, raw private audio, or personal identifiers are included;
- record the returned Session ID above and use it in Devpost.
