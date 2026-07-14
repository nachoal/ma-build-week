# iOS language-learning UI research

Snapshot: 2026-07-13

This note records the patterns that informed MA's code-first onboarding, home,
and first-minute experience. It is a product-decision log, not a request to copy
another app's visual identity. Current claims below come from official product
pages, help centers, and App Store listings; some marketing screenshots may not
match every signed-in iOS state exactly.

## Decision in one line

Use this loop:

**intent -> one concrete scene -> explicit speaking state -> one repair ->
can-do evidence**

Keep the white, black, and blue MA language. Do not import avatars, streak
economies, crowded catalogs, or a five-tab information architecture.

## What each reference contributed

### Speak

Sources: [current onboarding](https://app.speak.com/us-en/try?showOnboarding=),
[home screen](https://help.speak.com/en/articles/11430473-explore-your-new-home-screen),
[Free Talk roleplay](https://help.speak.com/en/articles/13182402-free-talk-immersive-roleplay),
and [Speak Tutor](https://help.speak.com/en/articles/11396739-what-is-speak-tutor).

Observed strengths:

- It asks about intent, challenge, level, and pace, then visibly echoes those
  answers in a plan.
- The home screen identifies the next learning action instead of presenting an
  empty dashboard.
- Roleplay explains context and success criteria before requesting microphone
  access.
- Speaking, listening, correction, retry, and quiet alternatives are visually
  distinct states.
- Progress is expressed partly as abilities the learner has demonstrated.

MA decision:

- Keep three decisions, not six: current ability, real-world goal, and desired
  situations plus practice rhythm.
- Use those answers immediately on home and in the compact profile menu.
- Make the ready restaurant scene the dominant home action.
- Preserve explicit states when real audio is wired; never leave a dead-looking
  microphone or ambiguous listening indicator.

### Loora

Sources: [App Store](https://apps.apple.com/us/app/speak-english-with-loora-ai/id1552708303),
[start guide](https://www.loora.com/support/getting-started/loora-start-guide),
and [key takeaways](https://www.loora.com/support/features/key-takeaways).

Observed strength: corrections do not need to interrupt every utterance. A
conversation can retain momentum, then close with one durable takeaway.

MA decision: the exact-beat repair is the priority lesson, not one entry in a
wall of red corrections. It should return the learner to the same scene and be
measured on the next attempt.

### Duolingo

Sources: [App Store](https://apps.apple.com/us/app/duolingo-language-lessons/id570060128),
[onboarding overview](https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/),
and [beginner video call](https://blog.duolingo.com/beginner-video-call-with-falstaff/).

Observed strengths: a linear next-action path and conspicuous voice states such
as calling, tap to speak, captions, and a graceful cannot-speak-now path.

MA decision: guided and natural modes must look different, and the live build
must label ready, listening, checking, tutor speaking, repair, and success. MA
does not adopt hearts, leagues, XP, or character-led gamification.

### Memrise

Sources: [App Store](https://apps.apple.com/us/app/memrise-easy-language-learning/id635966718),
[current product changes](https://www.memrise.com/blog/changes-to-the-memrise-app),
and [My Activities](https://www.memrise.com/blog/my-activities-2025).

Observed strength: progress can distinguish material learned, understood in
context, reviewed, and used in conversation.

MA decision: completion means a concrete ability demonstrated with less help.
For the first scene, the evidence is answering how many people without visible
Japanese, romaji, or Spanish answer text.

### iago

Sources: [App Store](https://apps.apple.com/us/app/iago-learn-japanese/id6471793412)
and [official site](https://iago.ai/).

Observed strength: Japanese-specific phrase analysis can layer meaning,
romanization, grammar, pronunciation, and suggested corrections.

MA decision: reveal those layers only when they solve the learner's current
breakdown. The first-minute scaffold deliberately removes information in three
rounds rather than displaying every annotation at once.

### Pimsleur and Praktika

Sources: [Pimsleur App Store](https://apps.apple.com/us/app/pimsleur-language-learning/id1405735469),
[Pimsleur overview](https://www.pimsleur.com/blog/advanced-language-learning-with-the-pimsleur-app/),
[Praktika App Store](https://apps.apple.com/us/app/praktika-ai-language-tutor/id1624701477),
and [Praktika 4.0](https://praktika.ai/blog/praktika-4-0).

Pimsleur reinforces the value of one canonical continue action with drills kept
secondary. Praktika demonstrates how an avatar and open-ended free talk can
dominate the product. MA takes the former hierarchy and rejects the latter
spectacle for this build.

## Decisions applied in SwiftUI

- Three short onboarding screens with valid defaults and a one-tap shortcut.
- One semantic hero button on home, followed by an honestly labeled roadmap.
- A compact menu sheet for the saved profile and reset/replay actions.
- Lesson arc: `APRENDE -> CONVERSA -> REPARA -> REPITE`.
- Scaffold ladder: full phrase -> rhythm only -> no answer text.
- First-success screen before teaching the natural-mode controls.
- Capability statement that explains what was done without text and how many
  attempts established it.
- No tabs, avatar dependency, streak, XP, subscription wall, or fake live state.

## Rules for the upcoming audio pass

1. Every visible audio control must either work or be removed.
2. Listening, processing, tutor playback, learner turn, repair, and success
   must have different labels and motion.
3. A learner who cannot speak must have a clear escape that does not imply an
   error.
4. Corrections stay concise during conversation; one repair becomes the durable
   takeaway.
5. Progress reports a communicative capability, not an opaque score.
