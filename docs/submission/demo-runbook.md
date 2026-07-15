# MA demo runbook

Status: prepared for rehearsal. Recording, human performance, public upload,
and publication remain external gates.

## One-command physical launch

From the repository root:

```sh
scripts/install-release-product.sh
```

The command dynamically discovers the paired iPhone 17 Pro on iOS 27 and
installs only the exact signed, checksummed Release archive from a clean tree.
It provisions the private demo token from macOS Keychain, requires exact
Keychain readback, then uses a second bearer-free launch to load Keychain and
complete a real WebSocket `session.created` policy verification. A third launch
is completely ordinary. Retained evidence contains no token.
Keep the phone unlocked and awake.

This is a private, single-device demo distribution procedure on the authorized
Mac. It is not a public, TestFlight, or fresh-install enrollment mechanism.
`scripts/device-ma.sh product` remains a development-build helper and cannot
close the archived Release gate.

Operator-only visual fallback:

```sh
scripts/device-ma.sh replay
```

Never narrate the fallback as live, learner evidence, or replayed audio.

## Under-three-minute story

| Time | Screen/action | Narration intent | Evidence rule |
|---|---|---|---|
| 0:00–0:12 | Fresh English home; briefly show EN/ES switch | “I know zero Japanese, so MA never starts with a blank conversation.” | English default and bilingual UI are visible |
| 0:12–0:30 | Objective + `一人です` + romaji + meaning | “I understand the task before I hear Japanese.” | No unexplained Japanese |
| 0:30–0:43 | Tap model once | “One tap gives me a short model; recording does not start itself.” | Physical take must be audible |
| 0:43–1:03 | Explicit first record/finish | “Now I choose when to speak and when I am done.” | Non-overlapping push-to-talk |
| 1:03–1:27 | Approximate transcript + feedback | “MA shows what it approximately understood and one useful next focus.” | No score, exact-transcript, or mastery claim |
| 1:27–1:42 | Retry once or continue | “I act on feedback before the situation moves on.” | Same visible target; no silent phase jump |
| 1:42–2:03 | Waiter briefing + captions | “Before Japanese plays, I know the question, meaning, and my exact task.” | Captions and support remain visible |
| 2:03–2:18 | Play short waiter turn | “GPT Realtime gives one bounded restaurant turn.” | Explicit non-overlap; no full-duplex claim |
| 2:18–2:38 | Explicit second record/review | “MA reviews my response before completion.” | Second independent reviewed turn |
| 2:38–2:52 | Completion + local next step | “No score—just a completed exchange and a defensible next practice.” | Completion is not mastery |
| 2:52–2:59 | Optional GPT-5.6 action | “I can opt in to planning from aggregate facts only.” | No audio/transcript reaches planner |

Use [subtitles-en.srt](subtitles-en.srt) as the English subtitle file.

## Before each take

- Confirm `scripts/scan-secrets.sh` passes and the exact commit is recorded.
- Install through `scripts/install-release-product.sh`; do not accept PID-only
  launch evidence or the development helper as Release readiness.
- Keep the iPhone unlocked; confirm built-in speaker/microphone and network.
- Reset the scene and choose the intended English or Spanish interface.
- Confirm the model plays audibly on the first tap.
- Confirm recording starts only after the explicit record tap.
- Hide private notifications before screen recording.
- Do not capture Keychain output, authorization headers, raw private evidence,
  diagnostic payloads, or any standard provider credential.

## Take acceptance

- Under 3:00 with audible model/waiter audio and readable English subtitles.
- English-default UI is understandable to an American judge; the Spanish
  switch is visible without interrupting the phase.
- Model playback works on the first tap and never auto-starts recording.
- Both learner turns receive visible qualitative review before progression.
- The waiter’s meaning and response task are visible before Japanese plays.
- Approximate transcript, no-score, and non-overlap boundaries are clear.
- Optional planning is visibly separate and opt-in.
- No notification, token, raw private evidence, or debug UI appears.

Record every take in [rehearsal-matrix.md](rehearsal-matrix.md). Public upload
and the final URL require Ignacio's approval.
