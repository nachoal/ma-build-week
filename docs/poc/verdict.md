# Gate 0 physical-iPhone verdict

Copy this file to verdict.md before starting. Writing started_at starts the hard
24-clock-hour timer. Missing evidence is a failed criterion, not an invitation
to extend the timer.

## Clock and build

- started_at with timezone: 2026-07-14 01:18:10 CST (-0600)
- hard_stop_at with timezone: 2026-07-15 01:18:10 CST (-0600)
- Build Week submission deadline: 2026-07-21
- verdict_effective_at: 2026-07-14 04:18:10 CST (-0600), the mandatory hour-3 cutoff
- verdict_written_at: 2026-07-14 04:18:17 CST (-0600), persisted on the first tool return after the cutoff
- commit or dirty-tree snapshot hash: `7585e63` (clean immediately before the hour-3 boundary)
- app version: 0.0.1 (build 1)
- tester: Ignacio; no physical trial could start because the phone stayed locked
- independent evidence reviewer: persistent tmux session `ma-adversary`; written verdict and public-claim scope audited CLEAN

## Frozen same-topology configuration

- physical device and OS: dynamically discovered iPhone 17 Pro, iOS 27.0 beta
- built-in input/output route: built-in microphone plus built-in speaker required; not observed at runtime
- transport: direct GA Realtime WebSocket with a broker-minted short-lived client secret; no WebRTC media dependency
- media/audio library and exact version: Apple AVFAudio `AVAudioEngine` / VoiceProcessingIO, Xcode 26.6 with iPhoneOS 26.5 SDK, runtime iOS 27.0 beta
- Realtime model: gpt-realtime-2.1
- transcription model/path: none during Experiment 0; provider transcription is not evidence
- VAD type and settings: `server_vad`, threshold 0.5, prefix padding 300 ms, silence 500 ms
- create_response: false
- interrupt_response: false
- input commit owner and policy: server-owned commit under B1; app appends PCM and never duplicates commit
- transport-appropriate output flush policy: snapshot player render cursor, stop and unschedule `AVAudioPlayerNode` locally, then send one `response.cancel` and exactly one render-derived `conversation.item.truncate`
- audio-device owner: one root-implemented `AudioGraphController`
- AVAudioSession category/mode/options: `playAndRecord` / `voiceChat` / `defaultToSpeaker`
- AEC or voice-processing path: AVAudioEngine VoiceProcessingIO enabled on both I/O nodes; input bypass false and input mute false are required assertions
- post-AEC mic tap: input-node output bus 0 after voice processing is asserted enabled in code; physical echo-control evidence not obtained
- playout/render-head tap: main-mixer output tap for rendered samples plus `AVAudioPlayerNode.lastRenderTime` converted with `playerTime(forNodeTime:)` before local stop
- sample rate/channels/I/O buffer: transport PCM16 mono 24 kHz; session preference 48 kHz and 10 ms; negotiated physical values not observed
- measured input/output route latency: not observed
- classifier version and labels: not frozen in Experiment 0; frame observability precedes classification
- backchannel playback profile: not exercised
- configuration hash: unavailable because the graph never launched on the physical iPhone
- configuration_frozen_at: 2026-07-14 02:48:10 CST (-0600)
- randomized schedule seed: 20260714

Confirm with evidence, not prose:

- [ ] One audio-device owner and one AVAudioSession.
- [ ] Post-AEC mic timing and actual render-head timing are both observable.
- [ ] Capture, classification, local stop, provider control, and heard-beat
      extraction use this exact topology.
- [ ] No separately passing transport and local-audio paths were combined.
- [ ] Provider keys and client secrets are absent from logs and tracked files.

Broker security note: the standard API key and all persistent secrets remained
outside Git and printed output. One 120-second client-secret value was
accidentally printed in private root-task tool output by a rate-limit diagnostic
that expected 429 but received 200. It expired automatically and was not saved
to a repository file. This leaves the log criterion false and disqualifies PASS.

If any of the first four boxes is false, verdict is PARTIAL or FAIL.

## External acoustic evidence

- recorder/device: Studio Display XDR microphone was ready but was not used
- learner-nearfield channel: none
- phone-speaker-nearfield channel: none
- sync chirp method and measured drift: not run
- app-to-external clock mapping method: not run
- maximum alignment residual, must be <= 20 ms: not measured
- raw local evidence path (under gitignored docs/poc/private-evidence): `docs/poc/private-evidence/`
- redacted review artifact: none; no acoustic recording exists
- consent and deletion status: explicit consent was not received, so no diagnostic capture was made and nothing requires deletion

Every counted held-out, hero, and echo-control trial needs a synchronized
external recording. Mark an ambiguous separation of learner and tutor audio as
a failed trial.

## Raw held-out trial table

Add at least 40 first-attempt はい, 40 first-attempt すみません, and 40
adversarial echo/noise controls across two fresh sessions after configuration
freeze. Reruns remain in the log but never replace a first attempt.

| Trial | Session | Cue | Expected | Captured | Onset->duck ms | Onset->decision ms | Decision->local action ms | Decision->cancel ms | Decision->flush/truncate ms | Decision->audible silence ms | Onset->silence ms | Output gap ms / duck dB | Transport controls correct | 4 s beat correct | External marker | First-attempt pass |
|---:|---:|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---|
| — | — | — | — | Not run | — | — | — | — | — | — | — | — | — | — | — | No |

Raw structured log: none; the app did not launch for Experiment 0.

If the full 40/40/40 sets were not completed before the hard stop:

- reason the block stopped: every post-freeze launch attempt was denied by the physical iPhone because it remained locked; no audible or observable topology run began
- actual first-attempt n for はい / すみません / echo-noise: 0 / 0 / 0
- characterization-only 10/10/20 tier met: no
- statistics reported without p95: count 0; median and maximum unavailable
- automatic verdict impact: PARTIAL at hour 3 under the written topology kill rule

Never replace, compress, or rush trials to manufacture the full n.

## Integrated hero set

Predeclare ten randomized live trials per human cue as subsets of the frozen
held-out runs. These support the visible 9-of-10 claim; do not select them after
seeing results and do not label a ten-trial statistic p95.

| Cue | n | Correct | Median onset->decision | Max onset->decision | Median decision->silence | Max decision->silence | Continuity/stop passes | Beat passes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| はい | 0 | 0 | — | — | n/a | n/a | 0 | n/a |
| すみません | 0 | 0 | — | — | — | — | 0 | 0 |

## Frozen held-out aggregate

Use nearest-rank p95 only when n is at least 40. Include failures and first
attempts. Report median, p95, and maximum so the tail is visible.

- はい n / captured / continuity pass: 0 / 0 / 0
- はい onset-to-decision median / p95 / max: not measured
- すみません n / correctly classified: 0 / 0
- すみません onset-to-decision median / p95 / max: not measured
- すみません decision-to-audible-silence median / p95 / max: not measured
- すみません onset-to-audible-silence median / p95 / max: not measured
- すみません utterance-end-to-audible-silence median / p95 / max: not measured
- onset-to-duck max and failures above 150 ms, if enabled: not measured
- selected transport control-channel RTT median / p95 / max (WebRTC data
  channel or WebSocket event channel): not measured
- adversarial echo/noise n / take-floor false positives: 0 / not measured
- four-second beat n / waveform-aligned passes: 0 / 0
- transport-appropriate local/provider flush and truncation correctness: unit-tested only; not physically observed
- crashes, stuck sessions, duplicates, buffer or route failures: no app runtime; launch was lock-denied

## Informative carry-forward probes

These do not rescue or block Gate 0, but must be recorded for Gate 1.

- 一人です answer-turn overlap result: not run
- resume-after-yield correct obligation, n / pass: 0 / 0
- cleared audio replayed after resume, n / failures: 0 / 0
- moderate-noise result: not run
- route change/interruption/network recovery: not run on the physical device
- ten-minute memory and thermal result: not run

## Criterion audit

- [ ] Experiment 0 completed by hour 3 on one observable topology.
- [ ] Integrated はい capture and continuity passed at least 9/10.
- [ ] Held-out はい capture and continuity each passed at least 36/40 first
      attempts.
- [ ] Held-out はい onset-to-decision p95 <= 800 ms, n >= 40.
- [ ] Integrated すみません recognition and local-first stop passed 9/10.
- [ ] Held-out すみません recognition and correct floor action each passed at
      least 36/40 first attempts.
- [ ] Held-out take-floor onset-to-decision median <= 800 ms and p95 <=
      1,000 ms, n >= 40.
- [ ] Held-out decision-to-audible-silence p95 <= 250 ms, n >= 40.
- [ ] Held-out onset-to-audible-silence median <= 1,050 ms and p95 <=
      1,250 ms, n >= 40.
- [ ] Zero backchannel or take-floor decisions in at least 40 adversarial echo
      controls.
- [ ] Exact externally aligned four-second beat passed at least 9/10.
- [ ] Clock-alignment extraction passed synthetic drift tests and reported a
      maximum residual <= 20 ms.
- [ ] Required lifecycle controls had no fatal failure.
- [ ] Adversarial reviewer audited the raw evidence and public claim.

## Verdict

Choose exactly one by hard_stop_at:

- PASS — unlock the measured MA overlap interaction.
- PARTIAL — immediately build Kaiwa Loop; overlap stays developer-only.
- FAIL — stop the overlap claim and retain only independently proven mechanics.

Selected verdict: PARTIAL, effective automatically at the hour-3 cutoff under
WP-1. PASS was already disqualified by the recorded ephemeral-secret logging
incident, and Experiment 0 did not prove any physical-device topology.

Rationale tied to failed/passed criteria: the signed probe, direct-WebSocket
transport, one-owner VoiceProcessingIO graph, redacted event path, response
gate, render ledger, and ring algorithms passed their code-level suites. They
never ran as one observable physical-iPhone topology. The phone remained locked
through the final 04:17 retry, no external acoustic evidence was captured, all
physical criteria are therefore false, and the automatic hour-3 rule requires
PARTIAL rather than further overlap tuning.

What this proves: only that the bounded developer probe and broker build and
pass their recorded unit/contract tests, and that signed artifacts install on
the paired iPhone. It does not upgrade source, simulator, signing, or install
results into runtime audio evidence.

What this explicitly does not prove: microphone permission or processed-input
behavior, route negotiation, audible tutor render, AEC, local-stop latency,
Realtime media correctness, backchannel/floor classification, resume behavior,
learner outcomes, or an exact rendered replay window on the physical iPhone.

Product permissions frozen by this verdict:

- bundled local tutor audio: permitted;
- provider-free local learner-attempt capture: permitted with just-in-time
  microphone permission, a hard duration bound, aggregate timing/presence
  evidence, explicit self-assessment, and no retained raw audio;
- explicit local tap/stop repair: permitted;
- replay of a complete, controlled segment labeled as such: permitted;
- live explicit non-overlap Realtime: not permitted because Experiment 0 did
  not prove the selected topology;
- exact rendered-window replay: not permitted because Experiment D did not run
  and the probe capability is revoked pending a real freeze barrier;
- overlap/full-duplex product behavior: not permitted.

The non-audio `POST /learning/next` planner remains permitted after a completed
attempt/repair cycle. It is a bounded post-lesson broker call to fixed
`gpt-5.6-sol`, not Realtime media transport and not evidence that can override
the learner's recorded/self-reported facts or block the offline hero path.

Public wording permitted by this evidence: “MA’s current hero is an offline
Kaiwa Loop: bundled Japanese tutor audio, an explicit tap to pause, a controlled
labeled-segment replay, a short Spanish repair, and a self-assessed repeat.” Any
implemented local tutor audio is labeled `LOCAL · AUDIO INCLUIDO`; a controlled
product segment is labeled `REPLAY · DEMOSTRACIÓN`; and fixture-only animation
remains labeled `PROTOTIPO` or `REPLAY · NO EN VIVO`.
Do not use “live,” “exact heard window,” “validated on device,” “full duplex,”
or equivalent claims.

Remaining unknowns: every physical audio, lifecycle, acoustic, classifier,
latency, and learner-outcome question above. Those remain future research and
cannot reopen the submission branch without a new written evidence gate.

Approver: automatic WP-1 hour-3 rule; Ignacio review pending. Independent
claim-scope reviewer: persistent `ma-adversary` session.

## Post-verdict product-direction addendum — 2026-07-14

This addendum preserves the Gate 0 PARTIAL result and every false physical
criterion above. It does not retroactively prove Experiment 0, reopen overlap,
or authorize AEC/no-echo, latency, exact rendered-window replay, physical-
device, or learner-outcome claims.

After the permitted offline Kaiwa Loop ran on the physical phone, Ignacio
rejected that product branch because it did not review his recorded answer,
jumped between listening and recording without feedback, and presented
unexplained Japanese to a level-zero learner. He then explicitly directed MA to
use GPT Live/Realtime teaching primitives and requested an English interface so
American judges can understand it.

That later user direction authorizes a separate shipping experiment: bounded,
explicit, non-overlapping push-to-talk Realtime review of two learner turns,
with the task and meaning explained before audio, a bundled one-tap model,
canonical bilingual feedback, a captioned/briefed waiter turn, and no numeric
score or self-rating. It is not the Gate 0 overlap topology and cannot be used as
Gate 0 evidence. One `AudioGraphController` still owns product capture and
playout; standard OpenAI credentials remain server-side.

Claims and release permission for this guided branch are governed by
`docs/submission/claim-evidence-matrix.md` and
`docs/submission/release-checklist.md`. Simulator, service, signing, archive,
and install evidence must remain labeled as such. Until an unlocked physical
run is recorded, the branch may not claim live device validation, route or
interruption correctness, Japanese teaching quality, or learner outcomes.
