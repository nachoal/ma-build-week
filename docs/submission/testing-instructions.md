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
and accepts the simulator's honest recoverable no-speech/provider-unavailable
state; it does not claim a successful semantic review.

On the authorized development Mac, the production-realistic gate provisions
the separately revocable product credential from macOS Keychain without
printing it, runs the complete `MALive` journey, and deletes the simulator copy:

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
scripts/device-ma.sh product
```

Keep the iPhone unlocked and awake.

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
- Record silence: no fabricated transcript or positive review appears.
- Fail Realtime/network: the attempt remains unreviewed and recoverable; the app
  never jumps to the waiter or completion.
- Make spoken feedback unavailable: on-screen feedback remains usable.
- Interrupt or change route during playback/capture: the audio owner stops
  safely, rejects stale results, and exposes a recovery action.
- Go offline after completion: local next practice remains; the optional
  planner does not erase it.

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
