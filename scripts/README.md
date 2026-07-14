# Scripts

Only add repeatable helpers that make the physical-device probe or evidence
reproducible: project generation, device discovery, structured-log export, and
fixture replay. Scripts must discover devices dynamically.

- `generate_trial_schedule.py` writes a balanced, seeded 40/40/40 first-attempt
  schedule and predeclares the two 10-trial hero subsets.
- `generate_sync_chirp.py` writes the deterministic 48 kHz acoustic clock
  marker used at the beginning and end of each continuous take.
