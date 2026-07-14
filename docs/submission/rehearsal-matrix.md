# Rehearsal and device matrix

Realtime live is **N/A and prohibited by the Gate 0 PARTIAL verdict**. The
selected hero is local PARTIAL; “live rehearsal” means the real product running
on the physical iPhone, not a live provider session.

## Codex-complete checks

| Path | Expected result | Current evidence | Status |
|---|---|---|---|
| Selected local PARTIAL, simulator/service seams | Full scaffold → explicit stop → controlled segment → resume → proof | Product/reducer tests | PASS (simulator/code) |
| Forced planner failure | Local deterministic action remains usable | Planner contract/fallback tests | PASS (simulator/code) |
| Labeled replay | Same hero semantic state; no audio, microphone, network, or planner | Replay unit + UI smoke | PASS (simulator/code) |
| Replay restart/cancel | Fresh bounded stream; no duplicate/stale events | Cancellation/restart tests | PASS |
| Capture restart race | Old receipt cannot enter fresh scene | Stale-capture test | PASS |
| Privacy manifest | No tracking; actual aggregate declarations; CA92.1 | `plutil` + unit test | PASS (archive verification pending) |
| Secret scan | Current set plus all reachable history | `scripts/scan-secrets.sh` | PASS at last recorded milestone |

## Physical iPhone matrix

Do not mark a row from simulator output. Record date, commit, iOS version,
route, evidence path, and exact failure.

| Case | Required observation | Result | Evidence |
|---|---|---|---|
| Clean install / first minute | Ignacio completes no-text exchange | PENDING | — |
| Built-in speaker + microphone | All prompts audible; bounded capture/self-assessment works | PENDING | — |
| Explicit local stop | Stops while tutor turn is active; no provider claim | PENDING | — |
| Controlled repair + resume | Segment audible; same obligation returns | PENDING | — |
| Better next attempt | Fresh second attempt reaches proof | PENDING | — |
| Microphone denied | Accurate error and Settings recovery | PENDING | — |
| Interruption (call/Siri/alarm) | Audio owner tears down and recovers honestly | PENDING | — |
| Route change | Safe stop/recovery; no stale attempt or playback | PENDING | — |
| Wi-Fi | Local hero complete; optional planner succeeds only after tap | PENDING | — |
| Cellular | Same as Wi-Fi | PENDING | — |
| Offline | Local hero/proof complete; optional plan falls back | PENDING | — |
| Ten-minute run | No unbounded memory/thermal growth; UI remains responsive | PENDING | — |
| VoiceOver / AX type / Reduce Motion | Logical order, no clipping, captions, no pulse when reduced | PENDING | — |

## Consecutive hero rehearsals

Acceptance is at least 9/10 on one frozen selected path. Failed takes remain in
the table; do not delete or replace them.

| Take | Commit/archive | Path | Duration | Pass/fail | Exact issue/evidence |
|---:|---|---|---:|---|---|
| 1 | — | local PARTIAL | — | PENDING | — |
| 2 | — | local PARTIAL | — | PENDING | — |
| 3 | — | local PARTIAL | — | PENDING | — |
| 4 | — | local PARTIAL | — | PENDING | — |
| 5 | — | local PARTIAL | — | PENDING | — |
| 6 | — | local PARTIAL | — | PENDING | — |
| 7 | — | local PARTIAL | — | PENDING | — |
| 8 | — | local PARTIAL | — | PENDING | — |
| 9 | — | local PARTIAL | — | PENDING | — |
| 10 | — | local PARTIAL | — | PENDING | — |
