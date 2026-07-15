# Reviewer testing instructions

## Simulator and service checks

From the repository root:

```sh
xcodegen generate
xcodebuild test -project MA.xcodeproj -scheme MA \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'
xcodebuild test -project MA.xcodeproj -scheme MAAudioProbe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'
cd services/session-broker && npm test
```

No secret is required for the standard `MA` or `MAAudioProbe` schemes. The
private production-Realtime UI suite is isolated in the opt-in `MALive` scheme,
so a normal `xcodebuild test` never depends on a private credential or network
provider. Guided deterministic tests and the historical replay use sanitized
fixtures. The real-audio integration test exercises the shipping audio owner
with real Apple playback/capture, replaces only the simulator's often-silent
post-stop learner payload with the labeled bundled learner sample, and uses a
deterministic secret-free review provider. It requires the complete
capture/stop/review transition and may not
accept missing private access, unauthorized access, or a generic recoverable
provider failure as success. It does not claim a live semantic review.

The standard `MA` suite also exercises local deletion as a transaction: four
unit/Keychain tests prove delete-before-reset ordering, error propagation,
retained-token rejection, and an isolated real Keychain round trip; three UI
tests cover English failure, Spanish failure, and verified success returning to
onboarding. To run only this focused gate:

```sh
xcodebuild test -project MA.xcodeproj -scheme MA \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -only-testing:MATests/LocalDataDeletionTests \
  -only-testing:MAUITests/LocalDataDeletionUITests
```

On the authorized development Mac, the production-realistic gate provisions
the separately revocable product credential from macOS Keychain without
printing it, runs the complete `MALive` journey, then requires the app to prove
Keychain deletion with a value-free deleted marker before reporting success:

```sh
scripts/test-live-guided-simulator.sh
MA_LIVE_SIM_ITERATIONS=5 scripts/test-live-guided-simulator.sh
```

The first command runs one English and one Spanish journey. The second runs
five of each. Only microphone input is deterministic; the private broker,
Realtime session, validation, spoken feedback, waiter audio, playback, and
optional planner are production implementations. These checks still do not
substitute for physical-device capture, route, or learner evidence.

## Physical product

Use the provided signed build or, on the paired development Mac:

```sh
scripts/install-release-product.sh
```

Keep the iPhone unlocked and awake. The installer refuses a dirty tree, stale
archive, checksum or signature mismatch, and a locked phone. It retains only
value-free evidence after the Release app has verified exact Keychain readback.
A second launch has no bearer token and must load Keychain, mint a short-lived
secret, open the Realtime WebSocket, and policy-verify `session.created`. A
third launch has neither token nor nonce. This is the authorized private-demo
installation path, not public/TestFlight enrollment.

`scripts/device-ma.sh product` builds and provisions a development candidate;
it is useful during implementation but is not archived-Release evidence.

The two automated physical checks use the same dynamic discovery, compile
without requiring the phone to remain awake, then fail immediately before
install/provision/test if the phone is locked:

```sh
scripts/test-live-guided-device.sh
MA_LIVE_DEVICE_TEST=MAUITests/GuidedLiveAudioIntegrationUITests/testOneTapModelPlaybackAndRealCaptureStopStayResponsive \
  scripts/test-live-guided-device.sh
```

The runner dynamically discovers the phone but explicitly selects its `arm64`
XCTest destination. On this iPhone/Xcode combination, omitting the architecture
can select an advertised `arm64e` destination for the generated `arm64` test
bundle and fail before app assertions with `Bad CPU type in executable`.

The first retains the production broker/Realtime/planner path with repeatable
bundled learner input. The second starts and stops the actual microphone
capture graph, then substitutes only a labeled deterministic learner payload so
its secret-free provider must reach completed feedback. A separate silence test
requires no transcript and no review. Neither
automated check can establish human audibility, Japanese teaching quality,
route-change recovery, or learner outcome; record those observations
separately. A passing runner also requires value-free proof that its temporary
device Keychain credential was deleted; a locked cleanup launch fails the gate.

1. Confirm a fresh install starts in English. Toggle to Spanish and back; the
   current route and lesson phase must remain unchanged.
2. Complete onboarding and open **Arriving at a restaurant**.
3. Confirm Japanese, romaji, English/Spanish meaning, and the task are visible
   before any Japanese plays.
4. Tap the model once. It must be audible and must not start recording.
5. Explicitly record one short answer, tap **Finish and review**, and inspect
   the approximate transcript plus canonical qualitative feedback.
6. Use **Try again** or explicitly continue with the answer visible.
7. Read the waiter question, romaji, meaning, and response task. Play the short
   captioned waiter turn only when ready.
8. Explicitly record the answer and inspect the second review before completing
   the scene.
9. Confirm a local next step exists. Optionally request the disclosed GPT-5.6
   plan; the lesson must remain complete if the network/model is unavailable.

Repeat a reviewed turn in both English and Spanish. Record the device, iOS
version, route, network, commit, and evidence path.

## Recovery checks

- Deny microphone permission: no capture begins; the error and Settings action
  are accurate.
- Grant permission and retry: capture starts only after another explicit tap.
- Remove or revoke private review access: the bilingual access error is visible
  on the model screen and recording remains disabled; retry never starts the
  microphone until connection readiness succeeds.
- Record silence: no fabricated transcript or positive review appears.
- Fail Realtime/network: the attempt remains unreviewed and recoverable; the app
  never jumps to the waiter or completion.
- Make spoken feedback unavailable: on-screen feedback remains usable.
- Interrupt or change route during playback/capture: the audio owner stops
  safely, rejects stale results, and exposes a recovery action.
- Go offline after completion: local next practice remains; the optional
  planner does not erase it.
- Force local credential deletion to fail in the DEBUG UI seam: the bilingual
  error appears, the profile sheet stays open, and onboarding/profile choices
  remain unchanged. With normal deletion, verified Keychain absence returns
  the app to onboarding. A deleted private-demo credential must be reprovisioned
  by the authorized Mac; this build has no public self-enrollment path.

## Historical deterministic replay

```sh
scripts/device-ma.sh replay
```

This operator-only fallback is a visual historical sample. It must remain
labeled as **REPLAY · NOT LIVE / NO EN VIVO** and invokes no microphone, audio
hardware, network, learner review, or planner call. It is not the shipping
guided hero and cannot substitute for physical Realtime evidence.

Gate 0 probe code is retained for audit history. Do not infer overlap, AEC,
speech-over-playout classification, exact rendered replay, or physical latency
from simulator/probe output.
