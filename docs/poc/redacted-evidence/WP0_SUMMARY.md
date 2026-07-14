# WP-0 redacted verification summary

Verified by root task `019f5f68-b42c-7bb2-97dc-a1243d495298` on
2026-07-14 before the Gate 0 clock.

## Generated project

- Baseline `project.pbxproj` SHA-256:
  `1fb1e0642708c675f657a80a049474f4b8a02b29c98c614672b39aaf15958651`.
- Regenerated `project.pbxproj` SHA-256: identical.
- `git diff --exit-code -- MA.xcodeproj`: passed after regeneration.

## Fresh simulator suites

| Scheme | Simulator | Result | Passed | Failed | Skipped |
|---|---|---:|---:|---:|---:|
| MA | iPhone 17, iOS 26.4.1 | passed | 78 | 0 | 0 |
| MAAudioProbe | iPhone 17, iOS 26.4.1 | passed | 1 | 0 | 0 |

The complete `.xcresult` bundles and their SHA-256 manifest remain under the
gitignored `docs/poc/private-evidence/wp0/xcresults` path.

## Physical-device smoke

- Device was selected dynamically from paired, available physical iPhones.
- Selected device: iPhone 17 Pro, iOS 27.0 beta, Developer Mode enabled.
- Automatic development signing succeeded for both application schemes.
- `com.ia.ma` version 0.0.1 installed and launched.
- `com.ia.ma.audio-probe` version 0.0.1 installed and launched.
- Both application executables appeared in the device process snapshot.

Raw device detail, installed-app, and process JSON is retained only in the
gitignored private-evidence path because it contains stable identifiers.

## Tool and secret-binding readiness

- Wrangler 4.108.0 authenticated successfully and the configured token
  reported active.
- A temporary local Worker loaded a benign marker from `.dev.vars`; its endpoint
  returned `bindingPresent: true` and `valueDisclosed: false`.
- No real secret was written into the temporary readiness fixture or repository.
- The first local run rejected a compatibility date one day newer than the
  installed runtime supported; setting the readiness fixture to the latest
  supported date made the same binding test pass. This is a tooling constraint
  to carry into the real Worker configuration.

## Recorder calibration

- First mixed-source attempt on the default room output was preserved as a
  failure: normalized marker correlation 0.008.
- A MacBook microphone attempt produced a zero-amplitude capture and was also
  preserved as a failure.
- The controlled Studio Display speaker/microphone attempt captured synthesized
  speech plus the marker and recovered the marker at 0.714 seconds with
  normalized correlation 0.284.
- This proves that the external recorder can detect the marker under competing
  speech. It does not prove separation of a real learner from iPhone tutor
  output; any ambiguous physical trial still fails.
