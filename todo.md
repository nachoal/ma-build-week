# MA — PRD, validation gate, and execution plan

Last revised: 2026-07-14  
Owner and first learner: Ignacio  
Hackathon track: Education  
Working title: MA  
Build Week deadline: 2026-07-21 17:00 PDT / 18:00 Mexico City  
Current state: Gate 0 recorded PARTIAL at the mandatory hour-3 topology cutoff;
Kaiwa Loop is the product branch, using bundled local tutor audio and controlled
labeled-segment repair. Live Realtime and exact rendered-window replay are not
permitted in MA.
Gate 0 clock: started 2026-07-14 01:18:10 CST; PARTIAL became effective at
2026-07-14 04:18:10 CST under the hour-3 kill rule, so overlap tuning stopped

## 0. The decision

Build MA only if the physical-iPhone probe proves the interaction that makes it
different.

MA is not another chat screen with a voice model. It is a tutor for an absolute
beginner entering a real Japanese conversation. The tutor should keep speaking
through a low-stakes acknowledgement such as はい, yield promptly when the
learner actually takes the floor with すみません, and let the learner replay the
last heard beat that caused confusion.

The app must still be useful if the current API cannot support that overlap. The
honest fallback is Kaiwa Loop: listen without overlap, stop or tap when lost,
rewind the exact last heard beat, learn it, and resume. The fallback remains a
real learning product; it must never be presented as full duplex.

### Gate matrix

| Gate | Question | Unlocks | Evidence |
|---|---|---|---|
| 0 | Can the physical iPhone distinguish backchannel from floor-taking during tutor output? | Live overlap integration and public claim | docs/poc/verdict.md |
| 1 | Can a zero-Japanese learner complete one useful exchange in 60 seconds? | Scene expansion | Recorded learner run plus state log |
| 2 | Does exact-beat repair improve the next attempt? | Adaptive curriculum | Before/after attempt evidence |
| 3 | Is the live path reliable enough for a three-minute demo? | Submission polish | Rehearsal matrix and replay fallback |
| 4 | Does a cold viewer understand the superpower in ten seconds? | Final submission | Five-person comprehension test |

## 1. Executive product brief

### One sentence

MA teaches a zero-Japanese traveler one useful conversation at a time, then
places them inside natural-speed speech where they can acknowledge, interrupt,
rewind, learn, and resume without losing the social rhythm.

### Personal origin

Ignacio is a Spanish-speaking absolute beginner. Traditional lessons front-load
vocabulary and grammar but do not solve the frightening moment when a real
speaker answers at natural speed. MA exists because he wants to go from knowing
nothing to completing the exchanges he will actually need in Japan.

If a Japan trip is already booked, the exact trip date becomes the first line of
the submission. If it is not booked, do not fabricate one; say that MA was built
to prepare for the first trip.

### Problem

An absolute beginner has three simultaneous problems:

1. They do not yet know what to say.
2. They cannot segment a natural reply into learnable pieces.
3. They do not know how to participate in the rhythm of Japanese conversation:
   acknowledgement is not necessarily interruption, while a polite repair phrase
   must take the floor.

Most language apps train recall outside the conversation. Generic AI tutors
converse, but often assume enough language to start, stop whenever they hear a
sound, and provide feedback after the moment has passed.

### Product promise

Within the first 60 seconds, a person who selected I know zero Japanese should
complete one practical exchange with the visible scaffolding removed.

Within the first full session, the learner should:

- hear a natural prompt;
- understand the intent rather than every word;
- answer one useful line;
- experience one breakdown;
- replay and learn the precise last heard beat;
- answer again with less help;
- leave with audible proof of improvement.

### The aha moment

The tutor is speaking naturally. Ignacio says はい. MA visibly captures the
acknowledgement, but the tutor does not stop. Ignacio then says すみません. The
tutor yields immediately. MA rewinds the four seconds he actually heard before
the interruption, explains that beat in Spanish, and resumes from there.

This is only the public claim if Gate 0 passes. Otherwise the aha becomes:
Ignacio taps where natural Japanese became noise; MA rewinds the exact heard
beat, turns it into a ten-second lesson, and puts him back into the same scene.

### Why this is education, not a voice wrapper

The model is not the product boundary. The learning system owns:

- a staged skill objective;
- disappearing scaffolding;
- evidence from attempts;
- breakdown detection and repair;
- a replayable conversation timeline;
- a mastery decision based on the next attempt;
- a curriculum generated from the learner's real failures.

### Non-goals for the hackathon

- General-purpose Japanese curriculum.
- Kanji study, flashcard decks, or JLPT preparation.
- Social network, teacher marketplace, streak economy, or gamified currency.
- Perfect pronunciation scoring without a validated Japanese reference.
- A production-scale account, subscription, or analytics backend.
- Multiple languages before one Japanese travel scene is excellent.
- Claims that depend on an API model that is not publicly accessible.

## 2. Target learner and job to be done

### Primary learner

- Native or fluent Spanish speaker.
- Zero or near-zero Japanese.
- Has a concrete travel situation and limited preparation time.
- Learns better by hearing and speaking than by reading a textbook.
- Freezes when the other person answers naturally.
- Does not know kana and must not be blocked by it.

### Job to be done

When I am preparing for a real interaction in Japan, help me rehearse the exact
exchange at realistic speed, rescue me at the instant I get lost, and prove that
I can do it again with less help.

### Day-zero constraints

- Spanish is the explanation language.
- No Japanese literacy is assumed.
- Romaji is temporary scaffolding, not the final skill.
- The first choice is an intent, not a lesson category.
- The learner hears Japanese before receiving a grammar lecture.
- Every screen has one obvious next action.
- Correction is short enough that the conversation still feels alive.

### Learner outcome metric

The primary metric is independent completion of a defined exchange, not session
time, message count, or model engagement.

For the first scene, success means the learner can respond to 何名様ですか with
一人です at natural but fair speed, without visible Japanese, romaji, or Spanish
answer text.

## 3. Core experience

### The learning loop

1. Choose a real intent, such as Get a table for one.
2. Preview the one line needed now.
3. Hear the other speaker at coached speed.
4. Respond with full visual and audio scaffolding.
5. Repeat with partial scaffolding.
6. Learn the two conversation controls: はい means keep going; すみません means
   pause, I need help.
7. Enter the same exchange at natural speed.
8. Acknowledge normally or take the floor when lost.
9. Replay the last heard beat.
10. Receive one concise Spanish explanation and a slower replay.
11. Resume at the same point.
12. Repeat without scaffolding.
13. See and hear the evidence that the second attempt improved.

### First 60 seconds

The first-run scene is intentionally tiny:

1. Opening choice: Voy solo.
2. Goal card: Say 一人です.
3. Full scaffold:
   - Japanese: 一人です
   - Romaji: hitori desu
   - Spanish meaning: una persona / voy solo
   - Tap-to-hear audio and a mouthful-sized rhythm cue
4. Tutor prompt: 何名様ですか.
5. First reply with the full ghost line.
6. Second reply with only the first sound or rhythm blocks.
7. Third reply with no textual answer.
8. Result: Acabas de completar tu primera conversación en japonés.

Do not introduce the overlap superpower before the user has something meaningful
to say. A full-duplex engine that leaves a zero beginner silent is not useful.
Immediately after that first success, teach はい and すみません with Spanish
meaning, one model audio example, and one coached repetition each. Natural mode
must never assume Ignacio already knows the controls used in the demo.

### Scene catalog after the first vertical slice

Priority order:

1. Restaurant arrival: table for one or two. Its natural-speed variant includes
   a longer waiter turn with seating and one follow-up question so backchannel,
   floor-taking, and heard-beat repair have real material to act on.
2. Izakaya ordering: order one item and respond to a follow-up.
3. Convenience store: bag, payment method, receipt.
4. Train station: ask which platform or whether a train stops somewhere.
5. Hotel: check in and understand one clarification.

Only the first scene is required for the hackathon. New scenes must reuse the
same domain contracts and learning loop rather than branching into custom UI.

### Pedagogy rules

- Teach the smallest phrase that closes the immediate conversational obligation.
- Explain meaning and social function before grammar terminology.
- Prefer chunks and rhythm over isolated phonemes for the first attempt.
- Reduce scaffolding only after a successful attempt.
- Reintroduce only the help the learner actually needed.
- Treat backchannels as conversational behavior, not answer turns.
- Explicitly teach any participation token before evaluating it.
- Score the next attempt, not the learner's reaction to feedback.
- Never claim mastery from one transcription match.
- Preserve the learner's dignity: one correction at a time, no red wall of
  errors, and no fake precision.

## 4. Hero demo and submission story

### Cold-open line

I know zero Japanese. Watch me learn the conversation I need for Japan, then
survive it at natural speed.

### Three-minute sequence

1. Five seconds: show the selected real-world goal.
2. Twenty seconds: learn 一人です with disappearing scaffolding.
3. Twenty seconds: complete the exchange once.
4. Twenty seconds: learn はい as keep going and すみません as pause, help.
5. Twenty seconds: enter natural-speed mode.
6. Ten seconds: say はい during tutor speech; show capture without a stop.
7. Ten seconds: say すみません; tutor yields.
8. Twenty seconds: replay the exact last heard beat and receive a compact Spanish
   explanation.
9. Twenty seconds: resume and complete the same exchange.
10. Fifteen seconds: show attempt one versus attempt two evidence.
11. Final line: I did not build a Japanese course. I built the teacher I needed
    for the moment real Japanese becomes noise.

### Demo integrity

- The live physical-iPhone path is the hero.
- A deterministic replay mode is available from the same normalized event
  stream if venue networking fails.
- Replay mode is clearly labeled in developer controls and never presented to
  judges as live.
- The demo uses a single hero screen and one reproducible launch path.
- English subtitles can explain the Spanish UI to judges without changing the
  learner experience.

### Honest fallback demo

If Gate 0 is partial or failed:

1. Tutor speaks naturally.
2. Ignacio taps or says the explicit repair phrase.
3. Audio stops.
4. If Experiment D passed, MA plays the exact last four seconds actually
   rendered. Otherwise MA uses locally controlled, pre-segmented tutor audio and
   replays the last complete segment without calling it an exact heard window.
5. MA turns that beat into a tiny lesson.
6. Ignacio resumes and succeeds.

Do not show a fake backchannel animation driven by a button or pre-scripted
timeline.

## 5. Education-track and judging fit

### Implementation, 25

- Physical-iPhone audio and echo-cancellation evidence.
- Realtime 2.1 transport behind an app-owned provider interface.
- Timestamped rendered-audio ring buffer and deterministic replay.
- Short-lived client-secret broker; no standard key in the app.
- Structured event logs, fixtures, and testable state machine.
- Capability path for GPT-Live without rebuilding the product.

### Design, 25

- Absolute-beginner first minute rather than a blank conversation.
- One intent, one phrase, one conversational obligation.
- Disappearing scaffolding and a visible heard-beat timeline.
- Feedback appears at the breakdown moment, then gets out of the way.
- Accessible type, captions, reduced motion, and non-color-only state.

### Potential impact, 25

- A real person's concrete travel fear is visibly changed.
- The same repair loop can extend to immigrants, customer-service training,
  clinical communication, and any high-stakes spoken skill.
- The proof is an outcome before and after, not a market-size slide.

### Quality and novelty, 25

- The conversational-floor distinction is visible in seconds.
- Exact heard-audio repair links the live moment to pedagogy.
- The tutor adapts to what actually broke comprehension.
- The project makes no false full-duplex claim and has a working fallback.

## 6. Verified technical boundary on 2026-07-14

These facts come from current official OpenAI developer documentation and must
be rechecked if the implementation begins on a later model or API revision.

1. The current low-latency voice-agent model is gpt-realtime-2.1.
   Source: https://developers.openai.com/api/docs/guides/realtime
2. OpenAI recommends WebRTC for browser and mobile clients that directly capture
   and play audio.
   Source: https://developers.openai.com/api/docs/guides/realtime
3. Mobile clients should receive a short-lived Realtime client secret from a
   small server. A standard OpenAI API key remains on that server.
   Source: https://developers.openai.com/api/docs/guides/realtime-webrtc
4. With the normal VAD policy, learner speech cancels the ongoing response.
   WebRTC and SIP then truncate audio the learner did not hear.
   Source: https://developers.openai.com/api/docs/guides/realtime-conversations#interruption-and-truncation
5. Both server VAD and semantic VAD expose create_response and
   interrupt_response controls. Detection can remain enabled while MA owns the
   decision to cancel output or request the next response.
   Source: https://developers.openai.com/api/docs/guides/realtime-vad
6. A WebRTC client can use explicit response.cancel and
   output_audio_buffer.clear behavior for app-owned push-to-talk or floor
   control.
   Source: https://developers.openai.com/api/docs/guides/realtime-conversations#push-to-talk
7. gpt-realtime-whisper is a current dedicated Realtime transcription option.
   Its transcription-session path requires turn detection to be omitted or
   null and manual audio commits, so it is not a Gate 0 floor classifier.
   Source: https://developers.openai.com/api/docs/guides/realtime-transcription
8. Realtime transcript timing is not precise enough to recover a word-perfect
   heard boundary after interruption.
   Source: https://developers.openai.com/api/docs/guides/realtime-conversations#interruption-and-truncation
9. conversation.item.truncate with a render-derived audio_end_ms keeps the
   conversation context consistent with what the learner actually heard after
   an app-owned interruption.
   Source: https://developers.openai.com/api/docs/guides/realtime-conversations#interruption-and-truncation
10. output_audio_buffer.clear is available to flush local WebRTC playout after
    response.cancel when the app owns floor control.
    Source: https://developers.openai.com/api/docs/guides/realtime-conversations#push-to-talk
11. Session configuration attached to a client secret is an initial effective
    configuration that the client can override; it is not a cryptographic
    policy pin.
    Source: https://developers.openai.com/api/reference/resources/realtime/subresources/client_secrets/methods/create

### Consequences

- Default automatic interruption is only a baseline. It is expected to fail if
  はい cancels tutor output.
- Compare server VAD with automatic response/interruption disabled against a
  local-segmentation candidate with turn detection null. The local cue detector
  owns the latency-critical floor decision in either case.
- Exact heard-beat replay must use samples and timestamps from audio that reached
  the output route, not transcript or server-arrival timing.
- Gate 0 cannot pass unless a single iPhone audio topology exposes post-AEC mic
  evidence, local playout control, and an actual render clock.
- Realtime 2.1 is the current adapter. GPT-Live is a future capability adapter,
  not a dependency or a public claim.
- A reasoning model may plan lessons and evaluate structured attempts, but it is
  outside the latency-critical floor-control loop.
- On 2026-07-14 a redacted non-app smoke test minted a short-lived client secret
  and received session.created over the GA direct WebSocket endpoint. See
  docs/implementation/API_PREFLIGHT.md. This proves only the credential and
  transport handshake, not the iPhone audio topology.

## 7. Gate 0 — physical-iPhone feasibility probe

### Clock and existential question

Gate 0 starts only when its started_at timestamp is written to
docs/poc/verdict.md, no later than 2026-07-15. It ends exactly 24 clock hours
later. The Build Week submission deadline is 2026-07-21; the spike cannot
consume the product week.

The repository scaffold, docs review, account access check, paired-device check,
charging the external recorder, and a non-app client-secret/direct-WebSocket
server-handshake
smoke test may happen before started_at. The smoke test may mint a client secret
from a laptop and confirm session.created, but it may not add iPhone audio or
probe code. Probe engineering may not: adding a media dependency, implementing
the broker, audio taps, classifier, floor policy, or ring buffer starts only
after the timestamp. The 24 hours cover both building and validating the POC.

While tutor audio is actively rendering through one physical iPhone:

- can the post-AEC mic path capture はい without stopping the tutor;
- can the same running system distinguish すみません as a floor-taking repair;
- can it silence the audible tutor promptly after that decision; and
- can it replay the exact four seconds that reached the speaker before yield?

At the 24-hour deadline, any missing PASS criterion automatically produces a
PARTIAL verdict and unlocks Kaiwa Loop. There is no 25th-hour debugging exception.

### What the probe is not

- It is not a polished tutor, curriculum, account system, or product UI.
- It does not prove learning efficacy or general Japanese understanding.
- It does not prove arbitrary full-duplex conversation.
- It validates only the frozen phrases, device, OS, route, acoustic setup, and
  configuration recorded in the verdict.
- It does not depend on GPT-Live.

### Same-topology invariant

Every PASS result must come from the same live path on one physical iPhone:

learner voice -> selected post-AEC mic tap -> onset/classifier -> floor policy ->
local playout control -> actual speaker render clock -> heard-audio ring buffer.

The same selected transport/media library and version, AVAudioSession, AEC path,
classifier, model, route, cancellation policy, and ring buffer must be present
in every counted trial. One component owns the audio device. Separately passing
transport capture and local replay graphs cannot be combined into PASS. A
second raw capture/playback graph that bypasses the chosen AEC or render path is
forbidden.

### Probe architecture

The isolated MAAudioProbe target should contain:

- one explicit audio-device owner and one AVAudioSession lifecycle;
- route, permission, sample-format, I/O latency, and AEC status;
- current model, transport, turn policy, and immutable configuration hash;
- post-AEC mic onset and frame timing;
- scheduled, decoded, rendered, stopped, and transport-appropriate flushed
  output timing;
- provider events plus an app-owned monotonic event timeline;
- randomized blinded trial cue and independent ground-truth marker;
- floor decision, local playout action, cancel, transport-appropriate flush,
  and truncation events;
- bounded rolling rendered-audio buffer and replay control;
- newline-delimited structured-log export.

The server component only authenticates the private test client, mints
short-lived client secrets with a server-selected initial model/session policy,
and supplies a privacy-preserving safety identifier. It accepts no caller model,
voice, or prompt. The client records the effective session configuration and
compares its hash with the expected hash; the broker is not described as a
cryptographic policy pin. It is not an application backend.

### Reuse from FitnessOS

Reference:

- /Users/ia/code/ios/FitnessOS/FitnessOS/Services/WorkoutVoiceCoachService.swift
- /Users/ia/code/ios/FitnessOS/FitnessOSTests/WorkoutVoiceCoachServiceTests.swift
- /Users/ia/code/ios/FitnessOS/supabase/functions/create-realtime-session/index.ts
- reliability reference commit c6acf4e

Extract the permission, route/interruption, teardown, bounded-buffer, event-loop,
PCM-conversion, and ephemeral-secret mechanics. Do not copy workout coupling,
Supabase authentication by default, the old model slug, WebSocket as an
unquestioned choice, transcript timing as alignment, or simulator evidence as
device proof.

### Experimental ladder

Run the least complex variant first. Preserve failures and configuration hashes.

#### Experiment 0 — prove one observable audio topology

This is blocking and ends by hour 3.

- Implement the minimal authenticated session broker as the spike's first slice.
- Give native WebRTC a 30-minute evidence-hook audit during hours 1-1.5. It
  remains a candidate only if one readily available distribution immediately
  exposes empirically post-AEC input PCM, device-boundary output frames/render
  position, and an immediate local stop through one audio owner. If those hooks
  exist, use at most the next 60 minutes of the hour-1.5-to-3 proof window to
  validate them; otherwise pivot at hour 1.5. Do not build a custom WebRTC
  audio-device module during the spike.
- If those hooks are absent, immediately select direct Realtime WebSocket media
  with one explicitly voice-processed AVAudioEngine/VoiceProcessingIO graph.
  Record the final transport, media/audio library and exact version, and
  audio-device owner.
- Prove the installed build can observe post-AEC mic frames with monotonic
  timestamps while remote audio is playing.
- Prove it can observe or derive the actual local render head rather than only
  network receipt, decode, or scheduling events.
- Prove MA can locally duck or stop remote playout and correlate the selected
  transport's cancel/flush/truncation events without creating a second audio
  graph.
- Record the one AVAudioSession category, mode, route, sample format, I/O buffer,
  input/output latency, and voice-processing state.
- A local test peer may accelerate tap debugging, but Experiment 0 does not close
  until live Realtime remote audio traverses the exact topology used by counted
  trials.

If neither candidate can expose both ends of the measurement on one graph by
hour 3, record PARTIAL immediately. Do not fabricate precision from server
events or spend the remaining 21 hours fighting the library.

#### Experiment A — document default automatic interruption

- Use gpt-realtime-2.1 on the selected Experiment 0 transport/topology.
- Run normal server VAD against a known 12-to-20-second Japanese passage.
- Say はい at randomized points and record capture, cancellation, truncation,
  audible output, and render timing.

This validates instrumentation and establishes the default failure mode; it is
not expected to prove MA.

#### Experiment B — commit ownership and local floor evidence

- Baseline B1 uses server VAD with create_response=false and
  interrupt_response=false. The server owns commit; MA never sends
  input_audio_buffer.commit. Record whether a committed はい item pollutes the
  later conversation even though it does not create a response.
- Candidate B2 sets turn_detection=null. A local post-AEC onset/end detector
  owns segmentation. At utterance onset it clears stale input. It discards a
  backchannel with input_audio_buffer.clear; it commits a take-floor repair
  exactly once and requests one response only after floor state is coherent.
- The smallest viable local cue detector owns はい versus すみません. Supported
  conversation input transcription may be secondary evidence only.
- Do not add a separate gpt-realtime-whisper transcription session or semantic
  VAD during Gate 0. They do not solve the frozen backchannel classifier and
  would add another connection/commit policy.
- A prompt may explain はい and すみません to the tutor, but prompt compliance is
  not accepted as the classifier or ground truth.

#### Experiment C — app-owned floor policy

- Classify four states: echo/noise, backchannel, take-floor repair, answer turn.
- For はい, do not cancel or flush tutor output and do not create a response.
  Under B2, discard only the learner input buffer after classification. Continue
  output. If a ducking profile is tested, cap attenuation at 6 dB and restore it
  promptly.
- For すみません, act local-first: duck or stop playout immediately after the
  floor decision. On WebRTC, send response.cancel when active and
  output_audio_buffer.clear, then await the cleared event; clear already
  truncates unplayed audio, so do not also truncate by default. On WebSocket,
  capture the local rendered cursor, stop/flush the AVAudioPlayerNode queue,
  send response.cancel, then conversation.item.truncate with render-derived
  audio_end_ms.
- Commit learner audio exactly once only under the predeclared commit owner, and
  request the next response exactly once after floor state is coherent. Never
  combine server and app commits or let VAD create a duplicate response.
- Preserve partial evidence, class, confidence, local action, provider event,
  response/item identifiers, and independent timestamps.

This is a feasibility classifier for a frozen vocabulary, not a permanent
dual-model architecture. Answer-turn handling with 一人です is informative in
Gate 0 and becomes required in Gate 1.

#### Experiment D — exact heard-beat replay

- Keep at least six seconds of samples confirmed by the actual render head.
- At audible yield, freeze the four seconds ending at the last rendered sample.
- Exclude decoded, scheduled, queued, and output-flushed audio the learner did
  not hear.
- Replay locally without a network request.
- Align the extracted waveform with that trial's own rendered-sample record and
  synchronized external acoustic evidence. A scripted passage is a semantic aid,
  not a fixed waveform reference; do not grade from transcript text.

#### Experiment E — adversarial acoustic and continuity controls

- Built-in iPhone speaker and mic in quiet and moderate-noise rooms: required.
- Echo-only passages that themselves contain はい, すみません, close
  pronunciations, and unrelated Japanese speech: required.
- Learner distance and tutor volume fixed before the held-out run.
- Route change, app interruption, network transition, and ten-minute buffer run.
- After take-floor repair, create a new continuation from the render-truncated
  conversation context at the same scene obligation, without replaying flushed
  audio; record at least five attempts.
- AirPods/Bluetooth is informative for Gate 0 and required before public beta.

### Operational definitions and clocks

App decisions, mic frames, and render events use one local monotonic clock.
Graded acoustic latency uses the external recording as the master timebase: the
start/end sync chirps fit a clock mapping, app decision timestamps are mapped
onto it, and learner onset plus audible tutor silence are taken from the
external waveform. Maximum alignment residual must be 20 ms or less. Provider
receipt, transcript delta, decoded-buffer, and scheduled-buffer time are
diagnostics, never substitutes.

Captured backchannel:

- post-AEC evidence identifies spoken はい while tutor audio is audibly present;
- the decision is not inferred from the randomized cue or a UI tap;
- onset-to-decision p95 is at most 800 ms after configuration freeze.

Playback continuity:

- no tutor response cancel, output flush, output truncation, or new response
  occurs for はい; discarding the classified learner input under B2 is allowed;
- no audible stop and no output gap above 150 ms;
- the predeclared profile is either no-duck or at most 6 dB attenuation, with
  full level restored within 250 ms after the backchannel decision.

Prompt yield:

- すみません is captured as take floor from post-AEC evidence;
- if a ducking profile is enabled, acoustic onset-to-duck is at most 150 ms in
  every integrated trial;
- acoustic onset-to-decision median is at most 800 ms and p95 at most 1,000 ms;
- decision-to-audible-silence p95 is at most 250 ms;
- acoustic onset-to-audible-silence median is at most 1,050 ms and p95 at most
  1,250 ms;
- utterance-end-to-audible-silence is also reported so phrase duration cannot be
  hidden inside a single flattering number.

Exact four-second beat:

- duration is 4.0 seconds plus or minus 100 ms;
- its end is within 150 ms of the externally observed last tutor audio before
  yield;
- waveform content matches audio actually rendered in at least 9 of 10 trials;
- local replay is available within 250 ms after the selected output-flush state
  settles.

### Independent acoustic evidence

App logs cannot be their own only witness. Every counted held-out, hero, and
echo-control trial must have a synchronized external acoustic recording with a
sync chirp at the beginning and end. Prefer separate learner-nearfield and
phone-speaker channels; a calibrated room recording is acceptable only when
waveform review can distinguish learner onset from tutor output. Ambiguous
trials fail.

The external evidence is the authority for audible onset, output gap or duck,
audible silence, self-triggered echo, and heard-beat boundary. A repeatable
alignment/export script and synthetic clock-drift tests are part of hours 14-18;
no aggregate is trusted until that script reports its residual. Diagnostic
audio is consented, local-only, deletable, gitignored, and absent from the
tracked set.

### Required instrumentation

Every trial's structured record includes:

- monotonic and wall-clock timestamps; build commit, app version, and frozen
  configuration hash;
- device/OS, route, transport, media/audio library and exact version, audio
  owner, AEC path, sample format, I/O buffer, and measured input/output latency;
- model, session and response/item identifiers with secrets removed;
- transport, VAD settings, create_response, interrupt_response, and classifier;
- post-AEC mic onset/offset and classifier evidence/decision;
- decoded, scheduled, rendered, stopped, cancelled, transport-appropriately
  flushed, truncated, and response-done timing;
- onset-to-decision, decision-to-local-action, decision-to-cancel,
  decision-to-flush/truncate, decision-to-audible-silence, and onset-to-silence;
- output gap/duck, ring-buffer range, external recording marker, expectation,
  first-attempt result, and failure reason.
- selected transport control-channel round-trip time sampled during each trial
  set: WebRTC data-channel RTT or WebSocket event-channel RTT.

### Trial protocol

1. Use both a stable 12-to-20-second measurement passage and a realistic waiter
   follow-up long enough for mid-speech cues.
2. Teach Ignacio the social function and pronunciation of はい and すみません
   before testing; do not expect a zero beginner to invent them.
3. Tune only on a labeled calibration set. Export it, freeze all configuration,
   record its hash and freeze time, then start at least two fresh held-out
   sessions. Use as many new sessions as service limits or clean reconnects
   require; a session boundary never discards a trial.
4. Pre-generate a randomized schedule across early, middle, and late output. The
   classifier never sees the cue or expected class.
5. Count at least 40 first-attempt はい trials, 40 first-attempt すみません
   trials, and 40 echo/noise controls after the freeze.
6. Include echo passages containing exact cue words and close pronunciations;
   silence-only controls are insufficient.
7. Preserve all first attempts. A rerun is diagnostic and never replaces the
   original in the aggregate.
8. Use nearest-rank p95 only for sets of at least 40. For any ten-trial hero set,
   report count, median, and maximum rather than calling one observation p95.
9. Run ten integrated randomized hero trials per human cue and visibly verify the
   9-of-10 behavior. These may be predeclared subsets of the 40 held-out first
   attempts; they are not post-hoc cherry-picked. Characterization playback may
   supplement but never replace live physical-device trials.
10. Probe 一人です beginning before tutor completion and five resume-after-yield
    attempts as non-gating evidence carried into Gate 1.
11. Record each randomized block as one externally synchronized continuous take
    with per-trial markers. The 10-trial hero and beat sets are predeclared
    subsets, not extra runs, keeping the frozen validation volume to 80 human
    cues plus 40 automatable physical echo/noise controls.
12. Predeclare two evidence tiers before the frozen run. PASS requires the full
    40/40/40 first-attempt sets. If fatigue, recorder failure, or the hard stop
    prevents completion, preserve every attempt and report the actual smaller
    n; a characterization-only tier targets at least 10 はい, 10 すみません,
    and 20 echo/noise controls, reports count/median/maximum only, and is
    automatically PARTIAL. Falling below that tier still records PARTIAL or
    FAIL honestly; never compress, replace, or rush trials to manufacture n=40.

### PASS thresholds

All are required on the same paired physical iPhone and built-in route:

- Experiment 0 proves the single observable topology and real render clock.
- At least 9 of 10 integrated はい trials capture the cue without a
  transport-inappropriate cancel/flush/truncate, an output gap over 150 ms, or
  ducking beyond the declared profile.
- Frozen held-out はい capture and playback continuity each pass at least 36 of
  40 first attempts.
- Frozen held-out はい onset-to-decision p95 is at most 800 ms for n >= 40.
- At least 9 of 10 integrated すみません trials select take floor and meet the
  local-first stop policy.
- Frozen held-out すみません recognition and correct floor action each pass at
  least 36 of 40 first attempts.
- Frozen held-out onset-to-decision median is at most 800 ms and p95 at most
  1,000 ms, and onset-to-audible-silence median is at most 1,050 ms and p95 at
  most 1,250 ms, for n >= 40.
- Frozen held-out decision-to-audible-silence p95 is at most 250 ms for n >= 40.
- Zero backchannel or take-floor decisions across at least 40 adversarial
  echo/noise controls after freeze.
- The externally verified exact heard beat passes at least 9 of 10 yields.
- No crash, stuck session, duplicate response, replay of flushed audio, runaway
  buffer, or unrecoverable route state in required controls.

PASS is permission to claim only the measured two-phrase behavior on the named
device and route. It is not proof of general full duplex.

### Hard 24-hour schedule

- Hours 0-1: timestamp the verdict; implement and validate the minimal broker.
- Hours 1-1.5: bounded native WebRTC hook audit; keep it only if all required
  input/render/local-stop hooks are immediately available.
- Hours 1.5-3: prove the selected WebRTC topology or pivot to the app-owned
  voice-processed WebSocket graph. If neither is observable, record PARTIAL.
- Hours 3-5: default-interruption baseline and instrumentation validation.
- Hours 5-8: commit-ownership experiments and the smallest local cue detector.
- Hours 8-11: transport-specific floor state machine and duplicate tests.
- Hours 11-15: rendered ledger/ring buffer, exact replay, external sync, and
  validated clock-alignment extraction.
- Hours 15-18: route/interruption/echo controls and configuration freeze.
- Hours 18-22: run the frozen held-out/integrated trials.
- Hours 22-24: analyze without retuning, write verdict, ask Claude to audit, and
  pivot to the selected product path.

### Verdicts

PASS:

- Bind the measured overlap interaction into the existing fixture-driven MA
  product target.
- Keep Realtime21Adapter, ReplayAdapter, and future GPTLiveAdapter capability
  boundaries.
- Phrase every public claim at the scope the evidence supports.

PARTIAL:

- This is immediate at hour 3 if Experiment 0 has no defensible physical-device
  topology, and otherwise automatic at hour 24 if any PASS criterion is missing.
- Build Kaiwa Loop immediately. Transport eligibility and replay eligibility
  are independent: if Experiment 0 proved the selected topology, Kaiwa Loop may
  use live Realtime with explicit non-overlap floor control; otherwise use
  bundled local tutor audio. If D passed, use exact heard-beat rewind; otherwise
  replay the last complete controlled, labeled segment and never call it exact.
  In both cases provide explicit stop/tap, a micro-lesson, a new continuation at
  the same obligation, and next-attempt evidence.
- Keep overlap capture behind developer controls and never call it full duplex.

FAIL:

- Stop the overlap claim. Keep only independently proven replay mechanics.
- If trustworthy heard-beat extraction also failed, use an explicit user-marked
  rewind boundary and reassess the hero before investing in live audio.

### Gate 0 implementation checklist

- [x] Copy docs/poc/verdict-template.md to docs/poc/verdict.md and timestamp it.
- [x] Generate/build/test MAAudioProbe; discover the paired iPhone dynamically.
- [ ] Complete Experiment 0 and record the immutable topology.
- [x] Implement the authenticated short-lived-secret broker for
  gpt-realtime-2.1.
- [x] Add just-in-time mic permission, denial recovery, and one audio owner.
- [x] Preserve bounded redacted provider events and post-AEC mic/render timing
  in code; physical observability remained unproven.
- [ ] Add structured export plus synchronized external evidence markers.
- [ ] Implement and test app-to-external clock alignment; reject residuals over
  20 ms.
- [ ] Run A, then controlled B; add C only as needed.
- [x] Add transport-specific local-first cancel/flush/truncate behavior and
      duplicate-response tests.
- [ ] Implement the rendered-sample ring buffer and waveform-aligned replay.
- [x] Pass ring-buffer wraparound, unplayed-audio exclusion, and beat-window unit
  tests before trusting any Experiment D trial.
- [ ] Freeze the configuration and run the full first-attempt held-out protocol.
- [ ] Run echo, noise, resume, route, interruption, network, and buffer controls.
- [x] Record the zero-trial aggregate and choose PARTIAL at the mandatory hour-3
  cutoff.
- [x] Ask the persistent Claude adversary to audit the zero-trial evidence
  record, permission cuts, canonical provenance labels, and public claims.
- [x] Unlock Kaiwa Loop only under automatic PARTIAL, with live and exact replay
  permissions explicitly false.

## 8. Product requirements after Gate 0

This section defines the intended app. Ignacio explicitly authorized its
fixture-driven UI prototype on 2026-07-13 while Gate 0 remains open. Visual
states, local interactions, animation, previews, and deterministic fixtures may
be implemented now. Microphone capture, provider transport, and claims that a
mocked state is live remain blocked by Gate 0.

### Functional requirements

FR-001 — Zero-beginner entry

- User can select I know zero Japanese.
- Interface and explanations default to Spanish.
- No text entry is required to start.

FR-002 — Intent-first scene

- User selects a concrete situation and intent.
- First scene is restaurant arrival for one person.
- Scene states the outcome in plain Spanish.

FR-003 — Disappearing scaffold

- Full Japanese, romaji, Spanish meaning, and audio are available initially.
- Support fades across attempts.
- Learner can explicitly restore help without penalty.

FR-004 — Speech attempt

- App captures learner speech and associates it with the exact scene step.
- App stores transcript or phonetic evidence, timing, and help level.
- Uncertain recognition is represented as uncertain, never silently corrected.

FR-005 — Natural-speed scene

- Tutor can run the learned exchange at coached and natural speeds.
- Learner can see which conversational obligation is active without seeing the
  answer text.
- The app teaches and rehearses はい and すみません before using them as hidden
  controls in natural-speed mode.

FR-006 — Floor control

- On PASS: backchannels and take-floor repairs are distinct domain events.
- On PARTIAL: explicit stop or repair is reliable and clearly indicated.
- UI never claims a floor event that the engine did not observe.
- A learner beginning an answer such as 一人です over the end of tutor speech is
  a separate Gate 1 requirement; Gate 0's frozen two-phrase evidence does not
  prove answer-turn overlap.

FR-007 — Heard-beat repair

- App can replay audio the learner actually heard, excluding unplayed buffers.
- Repair card includes audio, Japanese, temporary romaji, Spanish meaning, and
  one pragmatic or rhythm cue.
- Learner can replay slower and then resume in context.

FR-008 — Attempt evidence

- App compares first and next attempt on understandable dimensions:
  completion, latency to begin, amount of scaffolding, and repair count.
- Raw model confidence is not exposed as a fake pronunciation percentage.
- Learner can play both attempts when audio retention was explicitly enabled.

FR-009 — Adaptive next step

- A pedagogy planner receives a structured LearningReport, not the entire UI
  state.
- It chooses repeat, reduce scaffold, isolate a beat, or advance.
- Output conforms to a schema and can be replayed from a fixture.

FR-010 — Session summary

- Summary names what the learner can now do.
- It shows one next practical objective.
- It can be used without an account for the private MVP.

FR-011 — Live and replay modes

- Provider events normalize into the same ConversationEvent stream.
- A sanitized fixture can drive the complete hero UI deterministically.
- Developer mode labels the source as live or replay.

FR-012 — Accessibility and recovery

- Captions for tutor audio are always available.
- State is not communicated only by color.
- VoiceOver labels describe mic, tutor, and replay state.
- Reduced-motion mode removes decorative waveform motion.
- Permission denial, route loss, and network waiting have a path forward.

### Core screens

Keep the hackathon build to one main navigation flow:

1. Intent picker.
2. Phrase setup.
3. Live practice hero screen.
4. Heard-beat repair card over the same screen.
5. Evidence summary.

The hero screen contains:

- conversational objective;
- tutor and learner presence;
- subtle live waveform or floor indicator;
- current scaffold;
- heard-beat timeline;
- one primary action;
- explicit connection and capture state;
- developer diagnostics hidden from the normal demo.

### Content model

ScenePlan:

- stable scene identifier;
- learner intent;
- explanation language;
- roles;
- ordered obligations;
- target phrases and acceptable variants;
- tutor prompts at coached and natural speed;
- scaffold stages;
- repair notes;
- completion criteria.

Attempt:

- scene and obligation identifiers;
- timestamps;
- transcript hypothesis and uncertainty;
- help level;
- onset latency;
- repairs;
- outcome.

LearningReport:

- completed obligation;
- before and after attempt summaries;
- breakdown beat;
- support used;
- evidence strength;
- recommended next action.

## 9. Architecture

### Monorepo shape

Current:

- apps/MAAudioProbe — Gate 0-only iPhone app.
- services/session-broker — short-lived credential endpoint.
- docs/poc — protocol, logs, and verdict.
- fixtures/realtime — sanitized event replay.

Fixture-driven UI authorized before Gate 0:

- apps/MA — product interface driven only by deterministic local fixtures.
- [x] Five-state Paper design and exact SwiftUI handoff.
- [x] Replace the bounded Paper prototype with a code-first app shell: concise
  onboarding, intent-first home, compact profile menu, and persistent local
  learner choices.
- [x] Put the first-success ladder before natural mode: full phrase, rhythm
  only, no answer text, learner self-assessment with retry, then conversation
  controls. Natural mode cannot bypass this sequence through a product intent.
- [x] Canonical restaurant fixture shared by manual interaction, previews, and
  reducer tests.
- [x] Voice-ink continuity, backchannel wake, floor handoff, repair extraction,
  and factual proof surfaces.
- [x] Honest visual-only replay feedback, fixture-state chrome, Dynamic
  Type overflow, Reduce Motion, VoiceOver labels, and 44-point hit targets.
- [x] Adversarial edge coverage for repeat acknowledgements, stale yield tokens,
  duplicate rendered beats, and second repair requests after resume.
- [x] Compact 368x800 rendering guard and running-app accessibility test for the
  single-action home hero.
- [x] Accessibility Extra Large containment across all onboarding steps, local
  no-audio labeling, and sample-only provenance for synthetic proof metrics.

After PASS, or automatic PARTIAL for the Kaiwa Loop path only:

- packages/MADomain — provider-independent contracts and state transitions.
- packages/MATestSupport — fixture clock, provider replay, and builders only if
  duplication justifies it.

Do not create packages merely to make the repository look like a monorepo.

### State and side effects

- SwiftUI views render immutable values and send intents.
- A MainActor Observable feature model owns presentation state.
- Audio, provider transport, timing, lesson planning, and persistence live
  behind narrow protocols.
- Concurrency ownership is explicit. Do not mark audio objects unchecked
  Sendable without documenting the single executor that protects them.
- App state is the bridge between async work and SwiftUI.

### Stable provider boundary

ConversationProvider owns:

- connect with a session configuration;
- disconnect;
- send text or audio-control intents;
- request or cancel a response when supported;
- expose an asynchronous stream of normalized ConversationEvent values;
- report a capability snapshot that keeps model, audio-topology, and measured
  floor-policy facts separate.

RealtimeModelCapabilities includes:

- supportsManualResponseControl;
- supportsServerManagedTruncation;
- providesExactWordTiming;
- supportsTools;
- supportsReasoning.

AudioTopologyCapabilities includes:

- exposesPostAECSamples;
- supportsOverlappingCapture;
- supportsImmediateLocalStop;
- exposesRenderedCursor;
- supportsExactRenderedReplay.

FloorPolicyCapabilities includes:

- validatedPhrases;
- classifierVersion;
- frozenConfigurationHash;
- distinguishesBackchannels;
- measuredLatencyAndErrorThresholds;
- evidenceVerdict.

`providesRenderedAudioClock` is never inferred from a model slug, and
`distinguishesBackchannels` is never inferred from the Realtime adapter. They
are properties of the proven local topology and measured MA policy.

Adapters:

- Realtime21Adapter — conditional live path only after Experiment 0 proves the
  selected topology; omit it from a local-only PARTIAL or FAIL product.
- ReplayAdapter — deterministic demo and tests.
- GPTLiveAdapter — future path implemented only when an official API exists.

Product features request capabilities and degrade honestly. They never branch on
raw model-name strings.

### Normalized event model

At minimum:

- sessionConnecting;
- sessionReady;
- sessionWaiting;
- sessionFailed;
- tutorOutputStarted;
- tutorAudioScheduled;
- timelineBeatAdvanced, with `fixtureSimulation` or `renderedAudio` provenance;
- tutorTranscriptDelta;
- learnerSpeechStarted;
- learnerPartialTranscript;
- backchannelDetected;
- takeFloorDetected;
- tutorOutputCancelled;
- repairWindowFrozen, preserving the provenance of every included beat;
- attemptCompleted;
- sessionEnded.

Each event carries a monotonic timestamp, correlation identifiers, source, and
evidence metadata. Keep the raw provider event beside it in diagnostics, not in
product state.

Only an adapter-confirmed `renderedAudio` beat may support an exact-heard claim.
Fixture-simulation beats may drive the same UI geometry but never satisfy that
evidence predicate.

### Audio design

- Use AVAudioSession play-and-record with voice-chat mode for the probe.
- Select exactly one audio-device owner. A qualifying WebRTC audio device may
  own capture/playout only if it exposes the required evidence hooks; otherwise
  one explicitly voice-processed AVAudioEngine/VoiceProcessingIO graph owns
  both. A second graph may not shadow either topology to manufacture
  measurements.
- The selected owner must expose post-AEC input samples and the actual playout
  render head or Gate 0 becomes PARTIAL.
- Observe interruptions and route changes.
- Record network receipt, decoded, scheduled, device-pulled/rendered, stopped,
  and transport-appropriately flushed playback separately. Server buffer events
  are not a device render clock.
- Bound every buffer and queue.
- Use a monotonic clock for latency and heard-beat extraction.
- The ring buffer stores only the minimum rolling window unless diagnostic audio
  capture is explicitly enabled.
- Test built-in speaker first; Bluetooth behavior is a separate route.

### Networking

- Use HTTPS URLSession for the session-broker request.
- Timebox the native WebRTC hook audit; use it only if one distribution exposes
  post-AEC input, device-boundary render position, and immediate local stop.
  Otherwise use direct Realtime WebSocket media with the single app-owned
  voice-processing graph already preflighted in
  docs/implementation/API_PREFLIGHT.md.
- Do not preflight with reachability. Represent waiting, retry, and failed states
  from the real connection.
- Handle Wi-Fi/cellular transition and cancellation.
- All async operations have timeouts and clean teardown.

### Session broker

Responsibilities:

- authenticate or rate-limit the private developer client as minimally needed;
- mint a short-lived Realtime client secret;
- choose the initial model and base session policy without accepting caller
  model, prompt, or voice overrides;
- return the effective configuration hash and require the app to compare it
  with session.created/session.updated; do not describe this as cryptographic
  policy pinning;
- attach a stable privacy-preserving safety identifier;
- return no standard API key;
- avoid logging secrets or learner audio.

Non-responsibilities:

- curriculum database;
- account profile;
- analytics warehouse;
- audio storage;
- model-provider abstraction for unrelated vendors.

### Pedagogy service

The lesson planner is separate from the low-latency conversation loop.

Input:

- ScenePlan;
- structured Attempt values;
- breakdown beat metadata;
- learner preference and support level.

Output:

- schema-validated next action;
- concise Spanish explanation;
- scaffold change;
- evidence-based reason;
- confidence and abstention.

The model can suggest; deterministic code enforces scene state, completion
criteria, and allowed actions.

### Data and privacy

Private MVP default:

- learner profile and progress stored locally;
- no account required;
- no raw audio retained after the rolling window;
- transcript history retained only when the learner chooses;
- diagnostics disabled outside developer builds;
- delete-session and delete-all-data actions;
- PrivacyInfo.xcprivacy before distribution;
- accurate microphone purpose string;
- no tracking SDK.

## 10. Reliability and quality requirements

### Latency budgets

- Connection state becomes understandable immediately.
- Learner sees speech onset feedback within 100 ms of local detection.
- Backchannel classification p95 at or below 800 ms for the Gate 0 vocabulary.
- Take-floor onset-to-decision median at or below 800 ms and p95 at or below
  1,000 ms for the frozen phrase.
- Decision-to-audible-silence p95 at or below 250 ms; total
  onset-to-audible-silence median at or below 1,050 ms and p95 at or below
  1,250 ms.
- Heard-beat replay available within 250 ms after output-flush settles.
- UI remains responsive under continuous event streaming.

These are product targets only after they are measured; do not hide violations
with animation.

### Failure behavior

- Network waiting does not discard the local scene state.
- Reconnect never duplicates a learner attempt.
- Route loss stops or pauses safely and tells the learner what happened.
- Permission denial offers Settings and a non-crashing explanation.
- Provider failure can switch the demo to a labeled replay fixture.
- Unsupported capability automatically chooses the honest fallback.

### Performance

- No unbounded transcript, PCM, event, or playback arrays.
- No audio conversion on the main actor.
- No arbitrary sleeps for synchronization.
- Diagnostics can export without blocking audio.
- Ten-minute physical-device run shows stable memory and no thermal runaway.

## 11. Test and evaluation plan

### Pure unit tests with Swift Testing

- scaffold transition rules;
- scene obligation state machine;
- backchannel versus take-floor policy from deterministic classifier inputs;
- capability degradation;
- rendered-audio ring-buffer indexing and wraparound;
- exclusion of queued unplayed audio;
- normalized provider-event mapping;
- attempt and LearningReport construction;
- pedagogy schema validation and abstention;
- redaction of secrets and identifiers.

### Async integration tests

- connect, ready, output, interruption, recovery, disconnect sequence;
- duplicate and out-of-order provider events;
- cancellation during connect and playback;
- timeout behavior;
- route-change notification handling;
- deterministic replay produces the same UI state;
- session broker error mapping without secret leakage.

Use bounded clocks and controllable async streams, not wall-clock sleeps.

### Physical-device matrix

Gate 0:

- paired iPhone, built-in speaker/mic, quiet room;
- paired iPhone, built-in speaker/mic, moderate background noise;
- echo-only output control;
- route change;
- interruption;
- network transition.

Before public beta:

- Bluetooth HFP and high-quality route where available;
- wired or USB route if supported;
- multiple iPhone generations and iOS versions;
- different speaking distance and volume;
- female and male Japanese tutor voices;
- multiple Spanish accents for the learner's repair command;
- extended memory, battery, and thermal run.

### Learning eval

For the first scene:

- Baseline: learner hears the prompt before instruction and tries to respond.
- Training: run the 60-second scaffold.
- Transfer: change tutor voice and wording while preserving the obligation.
- Outcome: independent response without answer text.
- Repair efficacy: after a breakdown lesson, repeat the same beat once.
- Human review: a Japanese speaker checks naturalness and pragmatics before
  public submission.

The app must not use its own model as the only judge of its teaching success.

## 12. Execution order after the probe

### Phase 1 — zero-to-one exchange

- [x] Create the fixture-driven MA product target before Gate 0; keep live audio
  and provider binding blocked until the verdict.
- [x] Implement fixture-local reducer/event contracts in the smallest useful
      location; the full typed ScenePlan/Attempt contracts remain Phase 3 work.
- [x] Build the canonical static restaurant-for-one fixture.
- [x] Implement full, partial, and no-scaffold states.
- [x] Prepare and bundle four deterministic tutor prompt assets.
- [ ] Wire, validate, and expose real playback for every tutor prompt.
- [ ] Complete the first 60-second learner flow offline.
- [ ] Test with Ignacio from a clean install.
- [ ] Record whether he completes the exchange without answer text.

Exit: one useful exchange learned by a real zero beginner.

### Phase 2 — live scene and repair

- [x] If Experiment 0 passed, bind Realtime21Adapter to the already-built
      Realtime client-secret broker; otherwise keep the selected product path
      local-only. The later `/learning/next` broker path remains required for
      Phase 3 in either branch.
- [ ] Normalize live events behind ConversationProvider when a live adapter is
      permitted; keep ReplayAdapter available in every verdict branch.
- [ ] Add natural-speed scene.
- [ ] Add PASS floor behavior or PARTIAL explicit repair.
- [ ] If Experiment D passed, add the rendered-audio ring buffer and exact
      heard-window replay; otherwise use the last controlled labeled segment.
- [ ] Add the verdict-appropriate repair card and local replay.
- [ ] Resume at the same scene obligation.
- [ ] Compare the next attempt.

Exit: breakdown becomes a successful second attempt.

### Phase 3 — pedagogy and evidence

- [ ] Define structured planner input and output.
- [ ] Use the strongest eligible OpenAI reasoning model configured server-side.
- [ ] Add deterministic guardrails and abstention.
- [ ] Build evidence summary.
- [ ] Validate Japanese content with a qualified speaker.
- [ ] Add fixture replay for the complete hero path.

Exit: the model adapts within a controlled educational system.

### Phase 4 — demo polish

- [ ] Make one hero screen visually excellent.
- [ ] Add English submission subtitles.
- [ ] Create one reproducible physical-device launch command or runbook.
- [ ] Rehearse live and replay paths.
- [ ] Run the five-person ten-second comprehension test.
- [ ] Remove diagnostics from the learner view.
- [ ] Record the submission video with the real learner as protagonist.

Exit: cold viewers can say what changed for Ignacio in one sentence.

### Phase 5 — hardening

- [ ] Privacy manifest and disclosure review.
- [ ] Secret scan of the tracked set.
- [ ] Device route and network matrix.
- [ ] Memory and performance profile.
- [ ] Accessibility pass.
- [ ] Failure-copy and recovery pass.
- [ ] Final rubric evidence checklist.

## 13. Risks, kill criteria, and anti-plan

### Risk: current API treats every utterance as interruption

Mitigation: finish Experiment 0 first, then run A and controlled VAD B; attempt
the smallest app-owned floor policy only if evidence justifies it.

Kill: if one same-topology implementation cannot meet the frozen latency and
echo thresholds within 24 clock hours, record PARTIAL, ship Kaiwa Loop, and stop.

### Risk: the probe measures itself instead of audible reality

Mitigation: require post-AEC and render-head clocks plus synchronized external
acoustic evidence for every counted integrated run.

Kill: if the audible behavior cannot be independently reconstructed, no PASS is
possible regardless of attractive provider logs.

### Risk: Gate 0 consumes the Build Week runway

Mitigation: start by 2026-07-15 and enforce one timestamped 24-clock-hour spike
with Experiment 0, a frozen configuration, and integrated held-out validation.

Kill: at hard_stop_at without every PASS criterion, write PARTIAL, stop overlap
engineering, and begin Kaiwa Loop that same day. No exception requires another
judgment call.

### Risk: exact beat is not semantically exact

Mitigation: define Gate 0 exactness as the rendered four-second audio window,
then add semantic alignment separately.

Kill: never label an approximate transcript clause as exact. Use Last 4 seconds
until alignment is human-verified.

### Risk: a zero beginner cannot use the live interaction

Mitigation: the first minute teaches one phrase before open conversation.

Kill: if Ignacio cannot complete the first exchange after three iterations of
the scaffold, pause all advanced audio work and redesign the lesson.

### Risk: novelty looks like a harness wrapper

Mitigation: lead with learner transformation, floor behavior, heard-beat repair,
and next-attempt evidence. Keep provider adapters invisible.

Kill: if cold viewers describe it only as ChatGPT voice for Japanese, the demo
and product boundary are not ready.

### Risk: Japanese content is awkward or wrong

Mitigation: constrain the first scene and obtain native-speaker review.

Kill: no public submission with unreviewed Japanese hero content.

### Risk: venue networking breaks the hero

Mitigation: normalized replay fixture and locally cached scene assets.

Kill: no multi-service demo with no deterministic fallback.

### Anti-plan

Do not:

- build a home dashboard, profile tab, streaks, or settings maze;
- add ten scenes before the first one teaches successfully;
- build a generic multi-provider runtime;
- spend the first day on branding;
- train a pronunciation score;
- wait for GPT-Live before making the fallback useful;
- hide Gate 0 failure with a scripted animation;
- optimize monetization before the learner outcome exists.

## 14. Productization and monetization hypothesis

The initial product is not Japanese for everyone. It is trip-specific spoken
readiness for people with a deadline.

Potential product:

- a free first survival exchange;
- paid Japan trip packs organized by real situations;
- a subscription for ongoing adaptive spoken practice;
- later, user-created trip goals and role-specific packs.

The wedge is clear:

- generic tutors wait for the learner to know what to say;
- MA starts at zero, teaches the obligation, then repairs the exact real-time
  breakdown.

The durable asset is the learner's structured breakdown history and evidence of
what they can now do, not chat transcripts.

Do not put pricing in the hackathon demo unless user interviews validate it. The
rubric rewards impact and quality; the monetization slide should be one sentence,
not the product story.

## 15. Open questions

Resolve in order:

1. Does any readily available iOS WebRTC distribution expose post-AEC mic
   samples, device-boundary render position, and local stop inside the bounded
   audit, or does Gate 0 freeze the preflighted WebSocket/AVAudioEngine path?
2. Does B1 server-owned commit leave harmless backchannel items that pollute
   later context, making B2 local segmentation mandatory?
3. What is the smallest viable local classifier for the four Gate 0 states?
4. Does the selected voice-processing graph suppress echo without erasing
   Ignacio's quiet はい on the built-in route?
5. Can the selected output render cursor reliably exclude audio that was
   received or scheduled but not heard?
6. Is a separate gpt-realtime-whisper transcription session useful after the
   existential spike, without entering the latency-critical floor loop?
7. Is four seconds the right repair window, or should the eventual UI offer
   clause and fixed-window modes?
8. Which Japanese speaker will validate the first scene?
9. Which real travel exchange feels most emotionally important to Ignacio after
   restaurant arrival?
10. What name should replace MA after the interaction is validated?
11. What exact GPT-Live API capabilities become public, and which capability
    flags do they satisfy?

## 16. Definition of hackathon done

The submission is done only when:

- a physical iPhone completes the selected honest interaction;
- a zero-Japanese learner completes one useful exchange without answer text;
- one breakdown is repaired and the next attempt improves;
- the selected honest PASS or PARTIAL physical-iPhone path and labeled replay
  fallback both work;
- standard API keys are absent from the app and tracked files;
- Japanese content is reviewed;
- privacy and microphone behavior are clear;
- a cold viewer understands the superpower in ten seconds;
- the video shows Ignacio, not an architecture diagram, as the protagonist;
- every public claim is backed by saved evidence.
