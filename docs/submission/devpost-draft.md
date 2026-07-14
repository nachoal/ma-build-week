# Devpost draft — MA

Status: copy prepared; publication, repository sharing, video URL, and final
submission require Ignacio's explicit approval.

## Submission fields

- Project name: **MA**
- Track/category: **Education**
- Tagline: **Practice the moment real Japanese becomes noise.**
- Video URL: `[PENDING — public upload requires approval]`
- Repository URL: `[PENDING — private reviewer share or public release requires approval]`
- Codex `/feedback` Session ID: `[PENDING — run in root task after final evidence freeze]`

## Short description

MA is an iPhone tutor for a Spanish-speaking absolute beginner traveling to
Japan. It teaches one immediately useful restaurant exchange, lets the learner
practice it with disappearing support, turns a breakdown in natural Japanese
into a tiny repair lesson, and then proves whether the next attempt improved.

## Inspiration

Most voice tutors begin with a blank prompt: “What do you want to talk about?”
That is the wrong first minute for someone who knows zero Japanese. MA begins
with one obligation—ask for a table for one—and builds enough confidence to
survive that exact moment. The product is designed around the point where
natural speech stops sounding like language and starts sounding like noise.

## What it does

MA first teaches `一人です` with full text, rhythm-only support, and then no
answer text. The learner records a short local attempt and self-assesses it; MA
does not pretend to grade pronunciation. A bundled natural-speed restaurant
turn follows. The learner can stop it locally on an explicit tap, study one
complete labeled segment, return to the same conversational obligation, and
try again. The proof screen compares bounded attempt facts such as duration,
approximate onset, help used, and repair count.

The default next action is deterministic and local. If the learner explicitly
chooses, MA sends only those structured facts—not audio or a transcript—to a
private Cloudflare Worker. The Worker calls `gpt-5.6-sol` with strict structured
output and `store: false`; deterministic guardrails reject unsupported or
contradictory recommendations.

## How we built it

The iPhone app is SwiftUI with Swift 6 concurrency. One app-owned
`AudioGraphController` owns bundled playout and bounded microphone capture.
Product and deterministic fallback share one pure semantic reducer. The replay
adapter accepts at most 64 sanitized monotonic events, has no model/audio/floor
capabilities, and is permanently labeled as not live.

Codex was the implementation environment for the complete build: physical
readiness, the timed audio feasibility gate, audio ownership, event contracts,
replay, the Worker, local pedagogy, privacy, tests, and submission evidence.
The root Codex task also recorded failed approaches and adversarial reviews so
the public claim boundary follows evidence rather than the desired demo.

## Evidence-led scope decision

The 24-hour Gate 0 ended PARTIAL because the mandatory physical overlap and
exact-render evidence protocol did not run. MA therefore cut live Realtime,
speech-over-playout classification, and exact heard-window replay from the
submission product. It ships the defensible branch: bundled local audio,
non-overlapping capture, explicit stop, and a complete controlled repair
segment. The deterministic visual replay is a labeled fallback, never a fake
live demo.

## Challenges

- Keeping decoded, scheduled, and actually rendered audio concepts separate.
- Refusing to infer physical AEC or audible-stop behavior from simulator tests.
- Making learner evidence understandable without a pronunciation score.
- Ensuring a cancelled/restarted replay or capture cannot inject stale proof.
- Keeping the standard OpenAI key server-side while preserving a private,
  revocable device-testing path.

## Accomplishments

- A genuine zero-beginner first minute rather than an open-ended chat screen.
- One-owner local playback/capture with no retained raw learner audio.
- Repair and resume bound to the same obligation and a second attempt.
- Bounded normalized replay that reaches the shipping UI without side effects.
- A strict `gpt-5.6-sol` post-lesson contract with deterministic fallback.
- Honest UI and documentation that distinguish code, simulator, and physical
  evidence.

## What we learned

A model's conversational ability does not prove a phone's audio topology. A
beautiful replay does not prove audio was rendered. And a speech detector does
not prove a learner completed an obligation. The strongest product came from
preserving those distinctions and designing a useful learning loop inside the
evidence we actually had.

## What's next

After the submission build, MA can add more scenes only after the restaurant
lesson is validated with a real learner and a qualified Japanese speaker. Live
overlap or exact heard-audio repair remains a future measured capability, not a
roadmap promise disguised as a current feature.

## Reviewer testing summary

1. Install the provided signed build on an iPhone with microphone permission.
2. Complete onboarding and open **Restaurante · Una mesa para uno**.
3. Finish the three self-assessed scaffold attempts.
4. Start the local natural scene, tap **Pausa y ayuda** while it is playing,
   play the complete controlled segment, and resume.
5. Finish the second no-text attempt and inspect the proof.
6. The optional GPT plan requires the private reviewer credential; the local
   deterministic result is complete without network access.
7. If audio or network conditions are unsuitable, launch the permanently
   labeled replay using the repository runbook. Do not treat it as live evidence.
