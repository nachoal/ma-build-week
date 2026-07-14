# Adversarial review — Gate 0

Date: 2026-07-14  
Status: gate and implementation plans repaired; physical-iPhone evidence not yet collected  
Persistent reviewer session: tmux attach -t ma-adversary

## Verdict

MA is ready to begin one hard 24-clock-hour feasibility spike. It is not yet
cleared for product implementation and it has not earned a full-duplex claim.

The overlap idea stays on the critical path because it is the concept's sharpest
aha and Ignacio explicitly chose to test it first. The adversarial correction is
not to dilute the bet; it is to stop the bet from consuming Build Week. Gate 0
must start by 2026-07-15, use a single observable iPhone audio topology, and
produce PASS or automatic PARTIAL exactly 24 hours later.

## Reviewers

Two independent reviews reached the same core findings:

1. A persistent Claude Code instance, running in plan mode with xhigh effort,
   audited the PRD and was challenged to reconcile its objections with the hard
   24-hour constraint.
2. An independent gate-validity audit tried to game every acceptance criterion
   and checked whether the claimed measurements could exist on the intended iOS
   audio path.

Claude corrected its initial stale model objection after current official docs
were supplied: gpt-realtime-whisper exists as a dedicated transcription path,
and Realtime VAD exposes create_response and interrupt_response controls. It
also withdrew its initial recommendation to skip overlap entirely. A later
review correctly removed gpt-realtime-whisper from the Gate 0 classifier loop
because its turn-detection/commit contract conflicts with that spike.

## Fatal holes found and repaired

| Hole | Why it invalidated the proof | Repair now in todo.md |
|---|---|---|
| Mixed audio topologies | A WebRTC overlap pass plus a separate replay graph would not prove the app can do both | Same-topology invariant and blocking Experiment 0 |
| Self-reported timing | Server or app events do not prove when sound was audible | Post-AEC/render clocks plus synchronized external acoustic evidence |
| Impossible 500 ms claim | The system cannot classify a complete すみません at speech onset | Separate onset-to-decision and decision-to-audible-silence budgets |
| Automatic VAD conflict | Normal interruption cancels the exact backchannel MA wants to preserve | Controlled VAD with automatic response/interruption disabled; MA owns floor policy |
| Echo-only test too easy | The tutor can literally say the trigger words and classify its own output | Adversarial tutor passages with exact cues and close pronunciations |
| Ten-sample p95 | A p95 from ten observations is statistically misleading | 9/10 remains the visible functional claim; frozen n >= 40 sets support p95 |
| Replay judged by transcript | Realtime transcripts are not exact heard-audio alignment | Rendered-sample ring buffer and waveform/acoustic boundary check |
| Tuning grades itself | Retuning after failures makes a 9/10 result gameable | Immutable config hash, disjoint held-out sessions, first attempts always count |
| Zero beginner expected to know controls | Ignacio cannot naturally use Japanese words he has never learned | Explicit はい and すみません micro-lesson before natural mode |
| Overlap work could eat the week | A fascinating systems problem can prevent any product submission | Hour-by-hour spike plan and automatic Kaiwa Loop pivot |
| Two clocks could grade one number | App timestamps and room audio could silently disagree | External acoustic master timebase, chirp-fitted mapping, and <=20 ms residual |
| Early PARTIAL lacks exact replay | Experiment 0 can fail before the ring buffer exists | Pre-segmented local-audio Kaiwa Loop that makes no exact-window claim |
| Transport-shaped grading | A WebSocket result could not satisfy a WebRTC-only template | Transport-neutral topology fields and transport-specific control sequences |
| Ambiguous input commits | Server VAD and the app could both commit one utterance | Separate server-owned and local-owned commit experiments; exactly one owner |
| Broker described as policy enforcement | Client-secret session defaults can be overridden | Server-selected initial config plus on-device effective-config hash verification |

## Final technical stance

- A direct WebSocket connection authenticated with a short-lived client secret
  passed the redacted 2026-07-14 non-app handshake preflight. It is the
  provisional high-probability Gate 0 transport because one app-owned
  voice-processing graph can expose input, playout, render position, and replay.
- Native WebRTC gets a 30-minute hook audit during hours 1-1.5. It remains a
  candidate only if one readily available distribution immediately exposes
  empirically post-AEC input, device-boundary render position, and local stop;
  those hooks may use at most the next 60 minutes for proof before the hour-3
  topology deadline.
- One component must own the AVAudioSession audio device and both media
  directions.
- Gate 0 fails to PASS if that topology cannot expose both post-AEC learner
  frames and the actual local playout render head.
- The baseline keeps server VAD evidence flowing with create_response=false and
  interrupt_response=false while the server alone owns commits. The candidate
  disables turn detection and lets one local segmenter own clear/commit.
- A local post-AEC cue detector owns はい versus すみません; provider
  transcription is secondary evidence.
- はい never cancels or flushes tutor output and never creates a response.
- すみません acts local-first. WebRTC uses response.cancel plus
  output_audio_buffer.clear without a redundant explicit truncate. WebSocket
  stops/flushed local playout, then sends response.cancel plus one
  render-derived conversation.item.truncate.
- PASS proves only two frozen phrases on the named physical device and route. It
  does not prove arbitrary full duplex or answer-turn overlap.

## Residual risks that only the spike can answer

- Whether any selected topology exposes defensible post-AEC and render evidence
  without breaking voice processing.
- Whether the local cue detector can meet the frozen tail-latency and echo
  thresholds.
- Whether server-owned commits pollute later conversation context with harmless
  backchannels, forcing local segmentation.
- Whether local playout control and render-derived truncation remain coherent
  across real network and route events.
- Whether the exact-beat repair feels educational rather than merely technical.

These are now measured unknowns with kill conditions, not assumptions hidden in
the product plan.
