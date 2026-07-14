# Reviewer testing instructions

## Local repository

```sh
xcodegen generate
xcodebuild test -project MA.xcodeproj -scheme MA \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
cd services/session-broker && npm test
```

No secret is required for tests. Sample reports and replay events are fixed,
sanitized fixtures and are labeled as such.

## Physical product

Use the provided signed build or, on the paired development Mac:

```sh
scripts/device-ma.sh product
```

1. Complete the three onboarding choices.
2. Open the available restaurant scene.
3. Practice the phrase three times, reducing support, and self-assess each.
4. Start the natural scene and tap **Pausa y ayuda** while tutor audio is active.
5. Play the complete controlled segment; it is intentionally not labeled exact.
6. Resume the same situation, complete the no-text retry, and inspect proof.
7. Optionally tap the clearly disclosed GPT plan action. Without reviewer
   credential/network, the deterministic local plan remains complete.

## Deterministic fallback

```sh
scripts/device-ma.sh replay
```

The fallback is a visual sample only. It must remain labeled
`REPLAY · NO EN VIVO` and intentionally uses no microphone, audio hardware,
network, or planner call.

Gate 0 probe code is included for audit history but is not a product live path.
Do not infer live Realtime, overlap, AEC, exact rendered replay, or physical
latency claims from it.
