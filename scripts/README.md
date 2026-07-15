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
  launches a development product build or the unmistakably labeled no-live
  replay. `product` is a development helper, not proof that the archived
  Release is usable.
- `install-release-product.sh` accepts only a clean tree and the exact signed,
  checksummed archive. It installs that archive, reads the private demo token
  from macOS Keychain without retaining it in evidence, requires the Release
  app to confirm exact Keychain readback. A second bearer-free launch must load
  Keychain and complete a real WebSocket `session.created` policy verification;
  the app then relaunches normally with no launch environment. The final
  private-demo credential remains
  in this-device-only Keychain until explicit deletion.
- `test-live-guided-device.sh` refuses a locked paired device, provisions the
  private test credential through a value-free app-container sentinel, and runs
  either the complete production-Realtime UI journey or the real-microphone
  integration test before deleting the test credential. It pins the generated
  `arm64` XCTest architecture because Xcode advertises both `arm64e` and
  `arm64` destinations for the paired phone.
- `scan-secrets.sh` scans the current tracked/untracked source set and every
  reachable Git commit, redacting any candidate value and failing closed. Its
  `--binary PATH` mode also scans printable strings in a compiled executable
  without emitting a matched value.
- `archive-submission.sh` refuses tracked or untracked drift, constrains output
  and optional inputs to ignored repository-local roots, reruns the secret scan
  after staging, creates and verifies the signed Release archive and privacy
  manifest, and writes `SHA256SUMS`.
