# Rehearsal and device matrix

The selected product topology is bounded, explicit, non-overlapping GPT
Realtime push-to-talk. Gate 0 permanently prohibits full-duplex overlap,
speech-over-playout classification, AEC/no-echo claims, and exact rendered-
window replay. The historical visual replay is isolated and not the guided
product.

## Automated and service checks

| Path | Expected result | Current evidence | Status |
|---|---|---|---|
| Guided state machine | Model gate → explicit attempt → review → briefed waiter → explicit attempt → review → completion | `.build/test-results/MA-complete-freeze-20260714.xcresult`: 175/175 test cases (167 Swift + 8 UI) | PASS (simulator/code) |
| English/Spanish switch | English fresh default; toggle preserves route, phase, transcript, and feedback semantics | Copy, state, and UI tests | PASS (simulator/code) |
| Real simulator audio | One model tap completes; English permission disclosure; AVAudio capture/stop exits cleanly | `MA-complete-freeze-20260714.xcresult`: all 8 UI tests, including the real-audio integration test | PASS (simulator only) |
| Realtime review contract | Enum-only function, ASR grounding, canonical bilingual copy, no provider prose | Swift + Worker contract tests | PASS (code/service) |
| Guided planner | Local result first; explicit aggregate-only GPT-5.6 request; stale/double-tap fenced | Swift + live Worker verification | PASS (code/service) |
| Labeled historical replay | No microphone, audio, network, learner, or planner side effect | Replay unit + UI test | PASS (simulator/code) |
| Privacy manifest and export compliance | No tracking; declared Realtime audio/aggregate use; CA92.1; non-exempt encryption explicitly `NO` | `plutil`, unit tests, generated Info settings; archive recheck pending | PASS before final archive refresh |
| Secret scan | Current set, staged inputs, and reachable history | `scripts/scan-secrets.sh` after the 175/175 freeze | PASS on current frozen tree; rerun after commit |

## Physical iPhone matrix

Do not mark a row from code inspection or simulator output. Record date, commit,
iOS version, route, network, evidence path, and exact failure.

| Case | Required observation | Result | Evidence |
|---|---|---|---|
| Fresh English install | English objective and controls are immediately clear | PENDING | — |
| Spanish switch | Same lesson phase; all guided review/permission-facing copy coherent | PENDING | — |
| First-tap bundled model | Audible once; completion unlocks record; no second tap | PENDING | — |
| JIT microphone permission | Prompt appears only after record; denial/recovery accurate | PENDING | — |
| First capture/stop | No crash, freeze, duplicate capture, or auto-progress | PENDING | — |
| First live Realtime review (English) | Approximate transcript + grounded canonical feedback | PENDING | — |
| First live Realtime review (Spanish) | Same evidence; Spanish rendering/spoken feedback | PENDING | — |
| Waiter briefing/playback | Meaning/task visible before one audible captioned turn | PENDING | — |
| Second capture/review | Review completes before scene completion | PENDING | — |
| Silence/unclear audio | No fabricated match; visible retry path | PENDING | — |
| Spoken-feedback unavailable | On-screen review remains complete and responsive | PENDING | — |
| Interruption (call/Siri/alarm) | Audio owner tears down and recovers honestly | PENDING | — |
| Route change | Safe stop/recovery; no stale review or playback | PENDING | — |
| Wi-Fi | Full guided hero and optional planner behave as labeled | PENDING | — |
| Cellular | Same explicit non-overlap behavior | PENDING | — |
| Offline | Guided review fails visibly; local post-completion plan persists | PENDING | — |
| Ten-minute run | No unbounded memory/thermal growth; UI remains responsive | PENDING | — |
| VoiceOver / AX type / Reduce Motion | Logical order, no clipping, captions, stable reduced motion | PENDING | — |

## Consecutive guided rehearsals

Acceptance is at least 9/10 on one frozen guided path. Failed takes remain in
the table.

| Take | Commit/archive | Language/path | Duration | Pass/fail | Exact issue/evidence |
|---:|---|---|---:|---|---|
| 1 | — | guided Realtime | — | PENDING | — |
| 2 | — | guided Realtime | — | PENDING | — |
| 3 | — | guided Realtime | — | PENDING | — |
| 4 | — | guided Realtime | — | PENDING | — |
| 5 | — | guided Realtime | — | PENDING | — |
| 6 | — | guided Realtime | — | PENDING | — |
| 7 | — | guided Realtime | — | PENDING | — |
| 8 | — | guided Realtime | — | PENDING | — |
| 9 | — | guided Realtime | — | PENDING | — |
| 10 | — | guided Realtime | — | PENDING | — |
