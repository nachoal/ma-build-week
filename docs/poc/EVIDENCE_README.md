# Gate 0 evidence handling

This file defines the public, tracked evidence layout. Private acoustic captures,
raw provider events, device identifiers, secrets, and learner identifiers never
enter Git.

## Local-only paths

- `docs/poc/private-evidence/trial-schedule.csv` — frozen randomized schedule.
- `docs/poc/private-evidence/sync-chirp.wav` — deterministic take marker.
- `docs/poc/private-evidence/raw/` — consented external acoustic recordings.
- `docs/poc/private-evidence/app/` — raw redacted-on-export app NDJSON.
- `docs/poc/private-evidence/analysis/` — waveform alignment and aggregates.

The entire `private-evidence` directory is gitignored. Public artifacts belong
under `docs/poc/redacted-evidence/` only after an explicit redaction review.

## Recorder readiness

The readiness recorder is the enumerated `Studio Display XDR Microphone` at 48
kHz mono. A real capture succeeded on 2026-07-14 while the Mac was on AC power
at 100% and had about 1.1 TiB free. A mono room recording counts only when
waveform review can distinguish learner onset from iPhone output; an ambiguous
trial fails. Use separate learner-nearfield and phone-speaker channels if that
separation is not unambiguous during calibration.

## Consent, retention, and deletion

Before recording, the learner must explicitly agree to a local diagnostic
capture for Gate 0. State that raw audio remains local, is excluded from Git,
is used only to grade acoustic timing, and may be deleted immediately on
request. Record consent status in `docs/poc/verdict.md`, never a signature or
personal identifier.

Delete all private evidence with:

```sh
rm -rf docs/poc/private-evidence
```

The tracked verdict may retain only aggregate timings, configuration facts, and
redacted artifact names.

## Reproducible preparation

Choose and record a seed before calibration results are visible:

```sh
python3 scripts/generate_trial_schedule.py \
  --seed 20260714 \
  --output docs/poc/private-evidence/trial-schedule.csv

python3 scripts/generate_sync_chirp.py \
  --output docs/poc/private-evidence/sync-chirp.wav
```

The schedule generator asserts 40 first attempts per class, two balanced fresh
sessions, and predeclared 10-trial human-cue hero subsets.

## Japanese review readiness

- Outreach owner: Ignacio.
- Target review window: 2026-07-18, before public recording.
- Reviewer: qualified Japanese speaker, confirmation pending.
- Scope: restaurant prompt naturalness, `はい`/`すみません` pragmatics, romaji,
  Spanish meaning, and English video subtitles.

Reviewer confirmation is not a Gate 0 blocker, but completed review is required
before public recording or submission.
