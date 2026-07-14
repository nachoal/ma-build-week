# Rehearsal and device matrix

The selected product topology is bounded, explicit, non-overlapping GPT
Realtime push-to-talk. Gate 0 permanently prohibits full-duplex overlap,
speech-over-playout classification, AEC/no-echo claims, and exact rendered-
window replay. The historical visual replay is isolated and not the guided
product.

## Automated and service checks

| Path | Expected result | Current evidence | Status |
|---|---|---|---|
| Guided state machine | Model gate → explicit attempt → review → briefed waiter → explicit attempt → review → completion | Hardened candidate rerun `.build/test-results/MA-final-verified-deletion-standard.xcresult`: 213/213 executions, 0 skipped (184 test definitions, including parameterized cases); the isolated private `MALive` target was absent | PASS (simulator/code) |
| Production-realistic guided route | Complete broker → `gpt-realtime-2.1` → validator → spoken feedback → waiter → second review → `gpt-5.6-sol` planner journey; only microphone input is deterministic | `.build/test-results/MA-live-low-reasoning-bilingual-stress5.xcresult`: two test definitions, each repeated five times with `MA_LIVE_SIM_ITERATIONS=5`; all 10 journeys passed (five English, five Spanish). Physical English and Spanish deterministic-input routes also passed; no review, spoken-audio, waiter, or planner fallback was accepted | PASS (simulator/service/physical provider path); real microphone semantic review pending |
| English/Spanish switch | English fresh default; toggle preserves route, phase, transcript, and feedback semantics | Five English plus five Spanish production-realistic repetitions, plus copy/state/UI regressions in the 213-execution suite | PASS (simulator/code/service) |
| Verified local deletion | Keychain credential is absent before any profile reset; deletion/readback failure preserves the profile and explains recovery in the active language | `.build/test-results/MA-local-data-deletion-focused.xcresult`: 7/7 across four transaction/real-Keychain tests and three English/Spanish/success UI journeys; all seven also passed in the complete 213/213 suite | PASS (simulator/code/Keychain) |
| Real Apple audio integration | One model tap completes; AVAudio capture/stop exits cleanly; review resolves to feedback or an honest recovery | Simulator: `.build/test-results/MA-live-audio-cleanup-proof-simulator.xcresult` 1/1 with verified credential deletion. Physical: `.build/test-results/MA-live-audio-cleanup-proof-device.xcresult` 1/1 in 17.484 seconds on iOS 27.0 with verified credential deletion; permission was already authorized, so no prompt was re-observed | PASS (simulator and physical capture graph); JIT prompt/audibility/semantic review remain separate gates |
| Realtime review contract | Enum-only function, ASR grounding, canonical bilingual copy, no provider prose; broker pins `reasoning.effort=low` and the client rejects session/response policy weakening | `.build/test-results/MA-low-reasoning-focused.xcresult`: 16/16 focused tests with 26 fail-closed policy mutations; live smoke 2/2, stress 10/10, and deterministic-input physical English/Spanish routes passed | PASS (code/service/simulator/physical provider path); real microphone semantic review pending |
| Guided planner | Local result first; explicit aggregate-only GPT-5.6 request; stale/double-tap fenced; two bounded 10-second provider attempts inside a 27-second app budget | All 10 repeated journeys required the model plan. A later 14.183-second two-timeout failure was reproduced and corrected; `.build/test-results/MA-live-spanish-timeout-fix-simulator.xcresult` passed 1/1 with a non-fallback plan | PASS (code/service/simulator) |
| Worker contract suite | Fixed low-reasoning Realtime/planner policies, bounded schemas, auth/rate limits, privacy guards, transient retry identity, permanent-status no-retry | `.build/test-results/MAWorker-final-retry-policy.tap`: 35/35, covering every retryable 408/409/500/502/503/504 and permanent 501/505; private deployment version `57d49379-af1f-4160-8e88-ec611ab9a1d7` | PASS (service) |
| Labeled historical replay | No microphone, audio, network, learner, or planner side effect | Replay unit + UI test | PASS (simulator/code) |
| Privacy manifest and export compliance | No tracking; declared Realtime audio/aggregate use; CA92.1; non-exempt encryption explicitly `NO` | `plutil`, unit tests, generated Info settings; archive recheck pending | PASS before final archive refresh |
| Secret scan | Current set, staged inputs, reachable history, and compiled executable strings | `scripts/scan-secrets.sh` after the 213/213, 10/10, and 1/1 simulator gates | PASS on current candidate; rerun against final archive after commit |

The production-realistic repetitions decode the bundled `hitori-desu.m4a`
through the shipping 24 kHz PCM16 capture converter so that identical learner
input can be repeated. They do not prove the physical microphone, device route,
or human Japanese quality. Those remain explicit rows in the iPhone matrix.

## Physical iPhone matrix

Do not mark a row from code inspection or simulator output. Record date, commit,
iOS version, route, network, evidence path, and exact failure.

| Case | Required observation | Result | Evidence |
|---|---|---|---|
| Fresh English install | English objective and controls are immediately clear | Automated physical route PASS; human clarity observation still pending | `.build/test-results/MA-live-production-device.log`: complete English route passed in 47.506 seconds |
| Spanish switch | Same lesson phase; all guided review/permission-facing copy coherent | PASS for one unobstructed physical tap and the complete Spanish route; human copy/teaching review remains pending | `.build/test-results/MA-live-spanish-corrected-device.xcresult`; `.build/device-evidence/20260714T220420Z-live-ui/test.log` |
| First-tap bundled model | Audible once; completion unlocks record; no second tap | PASS for physical completion/control transition after one tap in English and Spanish; human audibility still pending | `.build/test-results/MA-live-production-device.log`; `.build/device-evidence/20260714T220420Z-live-ui/test.log` |
| JIT microphone permission | Prompt appears only after record; denial/recovery accurate | PARTIAL: capture began only after the explicit record tap, but permission was already authorized and the prompt/denial route was not re-observed | `.build/device-evidence/20260714T222736Z-live-ui/test.log` |
| First capture/stop | No crash, freeze, duplicate capture, or auto-progress | PASS on the hardened build through the real physical capture graph; stop left recording and resolved to a visible recoverable state | `.build/test-results/MA-live-audio-cleanup-proof-device.xcresult`; `.build/device-evidence/20260714T222736Z-live-ui/test.log` |
| First live Realtime review (English) | Approximate transcript + grounded canonical feedback | PASS on the physical device with deterministic bundled learner input; real microphone semantic review remains pending | `.build/test-results/MA-live-production-device.log`: English full route passed |
| First live Realtime review (Spanish) | Same evidence; Spanish rendering/spoken feedback | PASS on the physical device with deterministic bundled learner input; real microphone semantic review remains pending | `.build/test-results/MA-live-spanish-corrected-device.xcresult` |
| Waiter briefing/playback | Meaning/task visible before one audible captioned turn | PASS for the physical visible briefing and playback-completion transition in English and Spanish; human audibility remains pending | `.build/test-results/MA-live-production-device.log`; `.build/test-results/MA-live-spanish-corrected-device.xcresult` |
| Second capture/review | Review completes before scene completion | PASS for the physical device/provider path with deterministic bundled learner input; real microphone review remains pending | `.build/test-results/MA-live-production-device.log`: English full route passed |
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
| 1 | `42b3c57` | English guided Realtime, first review | — | FAIL | `.build/device-evidence/20260714T184649Z-product`: 128-token review ended incomplete/max_output_tokens and showed the recoverable review error |
| 2 | `1f5900f` | English guided Realtime, deterministic bundled learner input | 47.506s | PASS | `.build/test-results/MA-live-production-device.log`: two reviews, two spoken explanations, waiter, and GPT-5.6 planner completed |
| 3 | `1f5900f` | Spanish language entry | 4.310s | FAIL | `.build/test-results/MA-live-production-device.log`: SpringBoard banner `NotificationShortLookView` intercepted the language tap; lesson did not start |
| 4 | `8bf9c94` | Spanish guided Realtime, deterministic bundled learner input | 53.729s | PASS | `.build/test-results/MA-live-spanish-corrected-device.xcresult`: the first unobstructed language tap, model tap, two reviews, spoken feedback turns, waiter, and GPT-5.6 planner completed |
| 5 | — | guided Realtime | — | PENDING | — |
| 6 | — | guided Realtime | — | PENDING | — |
| 7 | — | guided Realtime | — | PENDING | — |
| 8 | — | guided Realtime | — | PENDING | — |
| 9 | — | guided Realtime | — | PENDING | — |
| 10 | — | guided Realtime | — | PENDING | — |
