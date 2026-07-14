# Devpost draft — MA

Status: copy prepared. Publication, repository sharing, video upload, `/feedback`,
and final submission require Ignacio's explicit approval.

## Submission fields

- Project name: **MA**
- Track/category: **Education**
- Tagline: **Hear it, say it, understand the feedback, use it for real.**
- Video URL: `[PENDING — public upload requires approval]`
- Repository URL: `[PENDING — private reviewer share or public release requires approval]`
- Codex `/feedback` Session ID: `[PENDING — run in root task after final evidence freeze]`

## Short description

MA is a bilingual iPhone tutor for an English- or Spanish-speaking absolute
beginner traveling to Japan. It explains one useful response before playing any
Japanese, lets the learner hear a short model, reviews two explicit speaking
turns with GPT Realtime, and always makes the next action clear.

## Inspiration

Most voice tutors begin with an empty prompt: “What do you want to talk about?”
That is the wrong first minute for someone who knows zero Japanese. A beginner
needs meaning, a model, a safe attempt, useful feedback, and a clear reason to
try again. MA starts with one concrete obligation—tell a restaurant server that
you are dining alone—and builds a complete teaching loop around it.

## What it does

English is the fresh-install default for American judges. An always-visible
switch changes the product interface and feedback to Spanish without resetting
the lesson.

MA first shows `一人です`, `hitori desu`, and “One person · I’m dining alone.”
The learner taps once to hear a bundled model; recording never starts
automatically. After an explicit push-to-talk attempt, MA labels the Japanese
transcription as approximate and shows one grounded positive plus one canonical
retry focus. The learner can retry or continue with the answer still visible.

Before the restaurant turn, MA explains the waiter’s question, its romaji,
meaning, and the exact response task. GPT Realtime then produces one short,
captioned waiter turn. The learner explicitly records again and receives a
second review before the scene completes. There is no score, self-rating,
phoneme diagnosis, or mastery claim.

The next practice is available locally as soon as the lesson ends. If the
learner explicitly opts in, MA sends only versioned aggregate facts—stage,
attempt count, qualitative result, and visible support—to a private Cloudflare
Worker. The Worker calls `gpt-5.6-sol` with strict structured output and
`store: false`; it receives no audio, transcript, or free-form Realtime
feedback.

## How we built it

The iPhone app uses SwiftUI and Swift 6 concurrency. One app-owned
`AudioGraphController` owns all product playout and microphone capture. Learner
audio is bounded in memory, sent directly from the phone to OpenAI with a
short-lived client secret, and never written to a recording file. The private
Worker holds the standard OpenAI key, fixes the Realtime session policy, and
returns only the ephemeral secret, expiry, and expected policy hash.

The Realtime review tool returns only four enum codes: phrase ID, assessment,
evidence, and retry focus. The app treats them as untrusted, validates the exact
combination against the independent approximate transcript, and renders
canonical English/Spanish feedback locally. Provider-authored prose never
becomes scoring or teaching copy.

Codex was the implementation environment for the complete build: physical
readiness, the timed audio feasibility gate, the selected one-owner product
audio path, Realtime transport, the Worker, pedagogy, bilingual UI, planner,
privacy, tests, and submission evidence. The root task also preserved failed
approaches and independent audits so public claims follow evidence.

## Evidence-led scope decision

The 24-hour Gate 0 ended PARTIAL because the mandatory physical overlap/AEC and
exact-rendered-window protocol did not run. MA permanently cuts full-duplex
overlap, speech-over-playout classification, and exact heard-window replay.
That verdict does not prohibit the separate product path: deliberate,
non-overlapping push-to-talk with one capture, one review, and one response at a
time. The historical deterministic replay remains isolated and visibly labeled
as not live.

## Challenges

- Turning Realtime capability into an actual zero-beginner teaching sequence.
- Preventing an approximate transcript or model claim from becoming a false
  pronunciation score.
- Keeping one owner for local model playback, capture, and Realtime playout.
- Making cancellation, retry, restart, route loss, and late provider results
  fail visibly instead of mutating a new lesson phase.
- Keeping the standard OpenAI key server-side while retaining a private,
  revocable device-demo boundary.

## Accomplishments

- A genuine first minute with meaning before Japanese and no ambiguous phase
  jumps.
- English-default and Spanish interfaces with phase-preserving switching.
- One-tap model playback and explicit recording with no auto-start.
- Two grounded qualitative speaking-turn reviews before completion.
- A fully briefed and captioned Realtime waiter exchange.
- Enum-only, app-validated Realtime feedback with no numeric grading.
- Optional aggregate-only `gpt-5.6-sol` planning with a local fallback.
- Honest separation of simulator, service, physical, and learner evidence.

## What we learned

Adding a frontier voice model is not the same as designing a lesson. The key
building blocks are meaning, modeling, deliberate production, feedback, retry,
and transfer to a situation the learner understands. Realtime makes those
blocks responsive; careful product ordering makes them educational.

## What's next

More scenes should follow only after the restaurant lesson is validated with
real zero beginners and a qualified Japanese speaker. Full-duplex overlap,
exact heard-audio replay, and pronunciation scoring remain outside the current
claim boundary.

## Reviewer testing summary

1. Launch MA; confirm English appears by default and the English/Spanish switch
   is always available.
2. Open **Arriving at a restaurant** and read the objective, Japanese, romaji,
   and meaning.
3. Tap the model once, then explicitly record and finish the first attempt.
4. Inspect the approximate transcript, useful feedback, and retry focus; retry
   or continue.
5. Read the waiter briefing and captions before playing Japanese.
6. Play the waiter turn, explicitly respond, and inspect the second review.
7. Complete the scene. The optional GPT-5.6 plan is a separate disclosed tap;
   the local next practice is already available.
