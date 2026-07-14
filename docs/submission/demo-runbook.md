# MA demo runbook

Status: prepared for rehearsal. Recording, human performance, YouTube upload,
and public publication are still external gates.

## One-command physical launch

From the repository root:

```sh
scripts/device-ma.sh product
```

The command dynamically discovers the paired iPhone 17 Pro on iOS 27, signs,
builds, installs, provisions the private product token from macOS Keychain, and
launches MA. It never prints the token or writes it to files/logs; MA persists
it only in this-device-only iOS Keychain until Delete all data. Keep the phone
unlocked.

Fallback, with no microphone/audio/network/planner side effects:

```sh
scripts/device-ma.sh replay
```

The fallback must display `REPLAY · NO EN VIVO` throughout. Never narrate it as
live, recorded learner evidence, or approximate audio replay.

## Under-three-minute story

| Time | Screen/action | Narration intent | Evidence rule |
|---|---|---|---|
| 0:00–0:10 | Home → restaurant scene | “I know zero Japanese. I need one table for one.” | Real product UI |
| 0:10–0:38 | Full phrase → rhythm → no text | Show the zero-beginner first minute | Ignacio speaks and self-assesses; no pronunciation-score claim |
| 0:38–0:52 | First success + control explanation | “Now I can answer once; here is my repair control.” | Local aggregates only |
| 0:52–1:18 | Start bundled natural scene; tap pause | Japanese becomes noise; explicit local stop | Physical take must make the stop audible |
| 1:18–1:40 | Controlled repair segment | Explain one complete beat in Spanish | Say “controlled segment,” never “exact last seconds” |
| 1:40–2:05 | Resume same obligation; second attempt | Return to the restaurant task | Same obligation ID; fresh self-assessed attempt |
| 2:05–2:30 | Proof screen | Compare first and second attempt facts | No mastery or model-confidence claim |
| 2:30–2:48 | Optional plan | Learner opts in to a GPT-5.6 next action | Structured aggregates only; local result already exists |
| 2:48–2:58 | Closing frame | “I built the teacher I needed for when real Japanese becomes noise.” | Keep PARTIAL/replay labels visible where applicable |

Use [subtitles-en.srt](subtitles-en.srt) as the English working subtitle file.
The Spanish learner UI stays unchanged.

## Before each take

- Confirm `scripts/scan-secrets.sh` passes.
- Confirm the exact Git commit and archive checksum are recorded.
- Keep the iPhone unlocked; confirm built-in speaker/microphone route.
- Confirm microphone permission state and whether this take is denial/recovery.
- Confirm the optional planner is either deliberately enabled or deliberately
  left unused; the hero must still finish locally.
- Start screen recording only after private notifications are hidden.
- Do not capture `docs/poc/private-evidence`, Keychain output, Worker secrets,
  raw authorization headers, or a standard OpenAI key.

## Take acceptance

- Under 3:00, audible narration and tutor audio, readable English subtitles.
- One uninterrupted selected PARTIAL path; no live Realtime or overlap claim.
- Pause occurs only while bundled tutor audio is active.
- Controlled segment is labeled as not exact.
- Same obligation resumes and a fresh second attempt reaches proof.
- Optional external planning is visibly opt-in.
- No notification, token, raw private evidence, or debug diagnostics appears.

Record each take in [rehearsal-matrix.md](rehearsal-matrix.md). A public upload
and final URL require Ignacio's approval.
