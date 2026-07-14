# Fable adversarial implementation review

Reviewer: persistent Claude Code session `ma-adversary` acting as Fable  
Review mode: plan-only, xhigh effort  
Date: 2026-07-14  
Subject: `docs/implementation/BUILD_PLAN.md`

## Round 1 — REJECT

Fable agreed with the product direction and provisional observable WebSocket
topology, but rejected execution until four blockers were repaired.

| Blocker | Failure mode | Resolution |
|---|---|---|
| Grading documents assumed WebRTC | A WebSocket result could not truthfully complete `todo.md`, the verdict template, or the earlier review | `todo.md`, `docs/poc/verdict-template.md`, and `docs/adversarial-review.md` are transport-neutral and define transport-specific controls |
| Ephemeral token over WebSocket was an ownerless open question | A failure at Gate 0 hour zero could force an unplanned transport rewrite | A redacted non-app preflight minted a short-lived client secret and received `session.created`; result is in `API_PREFLIGHT.md` |
| `/feedback` root-session accounting was ambiguous | Core work delegated into other tasks could make the submitted Session ID misleading | `feedback-notes.md` pins the requirement, root task owns every core implementation lane, delegated task IDs are logged, and components are enumerated |
| PARTIAL permissions contradicted the fallback | The plan allowed a live explicit-turn fallback while `AGENTS.md` appeared to forbid all live media | `AGENTS.md` now permits proven live Realtime topology under PARTIAL only for explicit non-overlap control and only to the extent Experiment 0/D evidence supports it |

Required round-1 changes also completed:

- broker surface named as a minimal Cloudflare Worker;
- client-secret policy described as initial configuration, not cryptographic
  pinning;
- WebRTC and WebSocket interruption/truncation sequences separated;
- server-owned and local-owned input-commit experiments separated;
- `gpt-realtime-whisper` removed from the Gate 0 classifier path;
- PASS and characterization-only trial tiers predeclared;
- Gate 1 learner test moved after a sleep block;
- capability types split into model, audio-topology, and measured floor-policy
  groups.

## Accepted major risks

- Hour-3 PARTIAL is the modal outcome from the current static probe shell. The
  project is designed to pivot, not keep debugging overlap.
- The 40/40/40 run has almost no slack. Incomplete sets report actual n and
  automatically prevent PASS.
- Ignacio is both builder and ground-truth speaker. Fatigue cannot be hidden in
  the statistics or carried directly into Gate 1.
- Voice-processing behavior on the iPhone speaker route may suppress a quiet
  `はい`; only physical evidence can answer this.
- The broker and all Gate 0 instrumentation still begin at the timestamp; the
  preflight proved only the auth/transport handshake.

## Round 2 — READY, followed by consistency repairs

Fable re-read the repaired files from disk and marked BL-1 through BL-4 CLOSED,
with no remaining blocker. It confirmed the broker surface, commit-ownership
split, characterization tier, post-spike sleep block, and `/feedback` ledger.

An independent cross-file audit then found four handoff ambiguities that were
not part of Fable's blocker table:

- Gate wording did not explicitly allow live work inside `MAAudioProbe` after
  the clock starts.
- PARTIAL transport eligibility (Experiment 0) and replay eligibility
  (Experiment D) were conflated in `todo.md`.
- WebSocket evidence was still asked to report a WebRTC-only data-channel RTT,
  and the preflight claim was too broad.
- WP-0 required a completed Japanese review before the still-unbooked reviewer
  could be found, despite scheduling that review later.

Those four ambiguities and Fable's non-blocking WebRTC-audit timing nit are now
repaired.

## Final verification — READY

Fable re-read the complete source-of-truth set after the consistency repairs
and closed all eight verification targets:

| Target | Status |
|---|---|
| Gate 0 live-work scope versus MA product binding | CLOSED |
| Independent Experiment 0 transport and Experiment D replay permissions | CLOSED |
| Phase 2 and definition of done under hour-3 PARTIAL | CLOSED |
| WebRTC/WebSocket control-channel RTT evidence | CLOSED |
| Narrow preflight claim | CLOSED |
| Non-gating Japanese-review scheduling | CLOSED |
| 30-minute audit plus optional 60-minute proof window | CLOSED |
| `/feedback` root-task ownership and delegated-session ledger | CLOSED |

Remaining exact repairs: none. Final Fable verdict: **READY**. The dedicated
Codex root task may begin WP-0, create the baseline commit, and start the Gate 0
clock only after operational readiness is complete.
