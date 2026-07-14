# Scripts

Only add repeatable helpers that make the physical-device probe or evidence
reproducible: project generation, device discovery, structured-log export, and
fixture replay. Scripts must discover devices dynamically.

- `generate_trial_schedule.py` writes a balanced, seeded 40/40/40 first-attempt
  schedule and predeclares the two 10-trial hero subsets.
- `generate_sync_chirp.py` writes the deterministic 48 kHz acoustic clock
  marker used at the beginning and end of each continuous take.
- `device-ma.sh status|build-install|product|replay` dynamically discovers the
  paired iPhone 17 Pro on iOS 27, builds/signs/installs MA, and optionally
  launches the local product or the unmistakably labeled no-live replay. The
  product token is read from macOS Keychain and is never printed or persisted.
- `scan-secrets.sh` scans the current tracked/untracked source set and every
  reachable Git commit, redacting any candidate value and failing closed.
- `archive-submission.sh` refuses a dirty tracked tree, reruns the secret scan,
  creates the signed Release archive, verifies its bundled privacy manifest,
  copies only sanitized submission inputs, and writes `SHA256SUMS`.
