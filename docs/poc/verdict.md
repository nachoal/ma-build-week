# Gate 0 physical-iPhone verdict

Copy this file to verdict.md before starting. Writing started_at starts the hard
24-clock-hour timer. Missing evidence is a failed criterion, not an invitation
to extend the timer.

## Clock and build

- started_at with timezone: 2026-07-14 01:18:10 CST (-0600)
- hard_stop_at with timezone: 2026-07-15 01:18:10 CST (-0600)
- Build Week submission deadline: 2026-07-21
- verdict_written_at:
- commit or dirty-tree snapshot hash: `adadf7a` (clean pre-clock boundary)
- app version: 0.0.1 (build 1)
- tester: Ignacio
- independent evidence reviewer: persistent tmux session `ma-adversary`; audit pending

## Frozen same-topology configuration

- physical device and OS: dynamically discovered iPhone 17 Pro, iOS 27.0 beta
- built-in input/output route: built-in microphone plus built-in speaker required; runtime confirmation pending
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
- post-AEC mic tap: input-node output bus 0 after voice processing is asserted enabled; physical echo-control evidence pending
- playout/render-head tap: main-mixer output tap for rendered samples plus `AVAudioPlayerNode.lastRenderTime` converted with `playerTime(forNodeTime:)` before local stop
- sample rate/channels/I/O buffer: transport PCM16 mono 24 kHz; session preference 48 kHz and 10 ms; negotiated physical values pending
- measured input/output route latency:
- classifier version and labels: not frozen in Experiment 0; frame observability precedes classification
- backchannel playback profile: no-duck / duck, attenuation in dB
- configuration hash: pending runtime route/rate/latency snapshot on the physical iPhone
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

- recorder/device:
- learner-nearfield channel:
- phone-speaker-nearfield channel:
- sync chirp method and measured drift:
- app-to-external clock mapping method:
- maximum alignment residual, must be <= 20 ms:
- raw local evidence path (under gitignored docs/poc/private-evidence): `docs/poc/private-evidence/`
- redacted review artifact:
- consent and deletion status: deletion policy ready; explicit learner consent required before first diagnostic capture

Every counted held-out, hero, and echo-control trial needs a synchronized
external recording. Mark an ambiguous separation of learner and tutor audio as
a failed trial.

## Raw held-out trial table

Add at least 40 first-attempt はい, 40 first-attempt すみません, and 40
adversarial echo/noise controls across two fresh sessions after configuration
freeze. Reruns remain in the log but never replace a first attempt.

| Trial | Session | Cue | Expected | Captured | Onset->duck ms | Onset->decision ms | Decision->local action ms | Decision->cancel ms | Decision->flush/truncate ms | Decision->audible silence ms | Onset->silence ms | Output gap ms / duck dB | Transport controls correct | 4 s beat correct | External marker | First-attempt pass |
|---:|---:|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---|
| 1 | 1 | はい | Backchannel |  |  |  |  | n/a | n/a | n/a | n/a |  |  | n/a |  |  |

Raw structured log:

If the full 40/40/40 sets were not completed before the hard stop:

- reason the block stopped:
- actual first-attempt n for はい / すみません / echo-noise:
- characterization-only 10/10/20 tier met: yes / no
- statistics reported without p95: count / median / maximum
- automatic verdict impact: PARTIAL or FAIL

Never replace, compress, or rush trials to manufacture the full n.

## Integrated hero set

Predeclare ten randomized live trials per human cue as subsets of the frozen
held-out runs. These support the visible 9-of-10 claim; do not select them after
seeing results and do not label a ten-trial statistic p95.

| Cue | n | Correct | Median onset->decision | Max onset->decision | Median decision->silence | Max decision->silence | Continuity/stop passes | Beat passes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| はい | 10 |  |  |  | n/a | n/a |  | n/a |
| すみません | 10 |  |  |  |  |  |  |  |

## Frozen held-out aggregate

Use nearest-rank p95 only when n is at least 40. Include failures and first
attempts. Report median, p95, and maximum so the tail is visible.

- はい n / captured / continuity pass:
- はい onset-to-decision median / p95 / max:
- すみません n / correctly classified:
- すみません onset-to-decision median / p95 / max:
- すみません decision-to-audible-silence median / p95 / max:
- すみません onset-to-audible-silence median / p95 / max:
- すみません utterance-end-to-audible-silence median / p95 / max:
- onset-to-duck max and failures above 150 ms, if enabled:
- selected transport control-channel RTT median / p95 / max (WebRTC data
  channel or WebSocket event channel):
- adversarial echo/noise n / take-floor false positives:
- four-second beat n / waveform-aligned passes:
- transport-appropriate local/provider flush and truncation correctness:
- crashes, stuck sessions, duplicates, buffer or route failures:

## Informative carry-forward probes

These do not rescue or block Gate 0, but must be recorded for Gate 1.

- 一人です answer-turn overlap result:
- resume-after-yield correct obligation, n / pass:
- cleared audio replayed after resume, n / failures:
- moderate-noise result:
- route change/interruption/network recovery:
- ten-minute memory and thermal result:

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

Selected verdict: PENDING until no later than 2026-07-15 01:18:10 CST (-0600);
PASS is disqualified by the recorded ephemeral-secret logging incident, while
Experiment 0 still determines PARTIAL transport eligibility.

Rationale tied to failed/passed criteria:

What this proves:

What this explicitly does not prove:

Public wording permitted by this evidence:

Remaining unknowns:

Approver:
