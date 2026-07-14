# WP-0 operational readiness

Checked: 2026-07-14 (America/Mexico_City)

Gate 0 clock: not started at the time of this checklist

## Reproducible baseline

- Baseline commit: `c3498e2` (`chore: establish MA fixture baseline`).
- `xcodegen generate` produced an identical generated-project hash manifest.
- MA simulator suite: 78 passed, 0 failed.
- MAAudioProbe simulator suite: 1 passed, 0 failed, including the corrected
  live-binding gate language.
- Working tree was clean immediately after the baseline commit.

## Physical iPhone

- Discovered dynamically through `devicectl`; no identifier is tracked.
- iPhone 17 Pro, iOS 27.0 beta, paired, Developer Mode enabled, developer disk
  image services available.
- MA and MAAudioProbe both built with automatic team signing, installed, and
  launched. Both appeared in the physical-device process list.
- The probe Info.plist contains the microphone purpose string. The fixture-only
  MA target intentionally has no microphone declaration before the verdict.

## Broker and credentials

- Wrangler 4.108.0 is installed and authenticated to the intended Cloudflare
  account.
- The Cloudflare token is active and can read the account Worker subdomain.
- `OPENAI_API_KEY`, `CLOUDFLARE_API_TOKEN`, and `CLOUDFLARE_ACCOUNT_ID` are
  present in the private shell environment; values were not printed or copied
  into the repository.
- `.dev.vars.example` documents the local Worker contract. A temporary local
  Worker proved that Wrangler loads a hidden `.dev.vars` binding and exposes
  only its presence to code. The Gate 0 deployment will use Wrangler's
  encrypted secret store rather than duplicate the standard OpenAI key into a
  plaintext repository-local file. A local `.dev.vars` path is gitignored if
  isolated development later requires one.
- The redacted direct-WebSocket preflight in `API_PREFLIGHT.md` remains the
  credential/handshake proof; it is not iPhone audio evidence.

## Acoustic evidence

- The enumerated `Studio Display XDR Microphone` captured a real 48 kHz mono
  readiness file.
- A mixed-source readiness take played synthesized Spanish speech plus the sync
  marker through the enumerated `Studio Display XDR Speakers` and captured both
  through that microphone. The marker was recovered at 0.714 seconds with
  normalized correlation 0.284. This proves marker detectability, not
  learner-versus-iPhone-source separation; ambiguous Gate 0 takes still fail.
- Recorder host is on AC at 100% with about 1.1 TiB free.
- A mono room capture counts only when learner and tutor waveforms are
  unambiguous; otherwise the trial fails or moves to separate nearfield
  channels.
- The seeded 40/40/40 schedule and 48 kHz sync chirp were generated under the
  gitignored `docs/poc/private-evidence` directory.
- Fresh `.xcresult` bundles, physical-device snapshots, and a SHA-256 manifest
  are preserved under `docs/poc/private-evidence/wp0`; a redacted summary is
  tracked under `docs/poc/redacted-evidence/WP0_SUMMARY.md`.
- Consent, retention, deletion, private paths, and public redaction paths are
  defined in `EVIDENCE_README.md`.

## People and review

- Operator/learner: Ignacio, who explicitly commissioned the uninterrupted
  implementation task. Human held-out-trial availability must still be
  confirmed before the frozen run; missing trials produce PARTIAL rather than
  extending the clock.
- Japanese-review outreach owner: Ignacio.
- Target Japanese review window: 2026-07-18, before public recording.
- Qualified Japanese reviewer: confirmation pending; this does not block Gate
  0, but public recording/submission remains blocked until review is complete.
- Persistent evidence adversary: tmux session `ma-adversary`, present and
  reserved for the required evidence/claims audit.

## Start decision

The repository, build, physical device, signing, broker credentials, recorder,
evidence layout, and adversarial-review surface are operationally ready. The
hard clock may start by copying the verdict template, writing `started_at` and
`hard_stop_at`, and immediately beginning the broker/topology work. No live
probe implementation existed before that timestamp.
