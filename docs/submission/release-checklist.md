# Submission release checklist

No item authorizes a push, public upload, repository share, `/feedback`, or
Devpost submission. Those require Ignacio's explicit approval.

## Freeze identity

- [x] Frozen submission/archive commit:
      `e968354b04d5043d65db9c809d02f0ae209a60a1`; shipping app
      implementation commit: `f9f7a7f9fdd2ae649ac20bb18392ab14f2b6047c`
- [x] Xcode/Swift/iOS build versions recorded in the candidate packet
- [x] Release `.xcarchive` rebuilt from the clean frozen commit
- [x] `PrivacyInfo.xcprivacy` reverified inside the refreshed `MA.app`
- [x] Signed physical install/launch verified on the dynamically discovered
      iPhone 17 Pro running iOS 27.0. The final Release app from the exact
      `e968354b04d5043d65db9c809d02f0ae209a60a1` archive launched as PID 20185;
      a follow-up process inventory still found that PID running from
      `MA.app`. This is launch/stability evidence only and does not strengthen
      any audio or learner claim
- [x] `scripts/scan-secrets.sh` rerun after the new frozen implementation
      commit, including the archived app and compiled executable

## Automated and service evidence

- [x] Exact documented, no-secret hardened-candidate MA result bundle: 213/213
      executions, 0 skipped (184 test definitions); the isolated private
      `MALive` target was absent at
      `.build/test-results/MA-final-verified-deletion-standard.xcresult`
- [x] Focused local-deletion gate: 7/7 (four transaction/Keychain tests and
      three bilingual UI journeys) at
      `.build/test-results/MA-local-data-deletion-focused.xcresult`; the same
      seven tests also passed inside the uncontended complete MA run
- [x] Production-realistic bilingual simulator gate uses the private broker,
      `gpt-realtime-2.1`, structured validator, response audio, waiter turn, two
      reviews, and `gpt-5.6-sol` planner; two test definitions each ran five
      times with `MA_LIVE_SIM_ITERATIONS=5`, and all 10 journeys passed (five
      English, five Spanish) at
      `.build/test-results/MA-live-low-reasoning-bilingual-stress5.xcresult`
- [x] Separate real-audio simulator result includes English permission
      disclosure, one-tap model completion, real AVAudio capture, and stop; 1/1
      with verified credential deletion at
      `.build/test-results/MA-live-audio-cleanup-proof-simulator.xcresult`
- [x] Complete MAAudioProbe result bundle (51/51 executions, 49 test
      definitions, characterization only) at
      `.build/test-results/MAAudioProbe-final-hardening.xcresult`
- [x] Worker 35/35 low-reasoning and bounded-planner-retry contract output at
      `.build/test-results/MAWorker-final-freeze.tap`; private version
      `57d49379-af1f-4160-8e88-ec611ab9a1d7`
- [x] Live private health, malformed-media rejection, Realtime mint,
      exact policy-hash, and guided-planner verification
- [x] Secret scan passes the current candidate, staged inputs, reachable
      history, and the current compiled simulator executable after the 213/213,
      10/10, and 1/1 gates; the refreshed archive bundle and compiled executable
      scan also passed from the exact frozen commit

## Physical and human evidence

- [x] Automated real-iPhone capture gate: one model tap, actual AVAudio capture,
      explicit stop, recoverable terminal state, verified credential deletion,
      and evidence scan; 1/1 at
      `.build/test-results/MA-live-audio-cleanup-proof-device.xcresult`
- [x] Exact-frozen-implementation local-deletion gate on the iPhone 17 Pro,
      iOS 27.0: 4/4 transaction/real-Keychain tests at
      `.build/test-results/MA-local-data-deletion-unit-device-arm64.xcresult`
      and 3/3 English failure, Spanish failure, and verified-success UI journeys
      at `.build/test-results/MA-local-data-deletion-ui-device-arm64.xcresult`

- [ ] Fresh-install English guided flow
- [ ] Spanish switch preserves phase and produces coherent visible/spoken review
- [ ] First-tap model playback on built-in speaker
- [ ] JIT microphone permission, capture, stop, and no crash/freeze
- [ ] Live first review and waiter turn
- [ ] Live second review before completion
- [ ] Denial, silence, network failure, route change, and interruption recovery
- [ ] Wi-Fi, cellular, offline, ten-minute, VoiceOver/AX/Reduce Motion matrix
- [ ] At least 9/10 consecutive frozen-path rehearsals
- [ ] Qualified Japanese-speaker review
- [ ] Five-person 4/5 cold-viewer result
- [ ] Under-three-minute final video and matching English subtitles

## Public claim audit

- [x] Every narration/subtitle/README/Devpost claim appears as Allowed in
      `claim-evidence-matrix.md`
- [x] Bounded product Realtime is described only as explicit non-overlap
- [x] No full-duplex overlap, AEC/no-echo, exact-heard replay, numeric latency,
      exact transcript, score, mastery, or learner-outcome claim
- [x] No claim that audio stays on-device or that GPT-5.6 reviews audio
- [x] Historical replay is unmistakably labeled **REPLAY · NOT LIVE / NO EN VIVO**
- [ ] Video/repository URLs replace placeholders only after approval

## Archive contents and checksums

Archive only the exact build, sanitized fixtures, redacted logs, video,
subtitles, and submission text. Never include `docs/poc/private-evidence`, raw
audio, `.dev.vars`, Keychain exports, authorization headers, DerivedData, or
standard provider credentials.

Stage optional redacted logs/video under ignored `.build/submission-inputs/`;
the archive tool rejects paths outside its canonical roots, records the build
environment and exact commit, and rescans staged copy.

- [x] Refreshed archive checksum:
      `29b0454396797d7483c6306731eae9c309fe8406d45227b61870845e81ba08db`
- [x] Latest superseded archive checksum retained for audit only:
      `91c251a7d51a58c8375c9ab8bf27d85bccc51a101f3158dd90a1fc07c64d96e9`
- [ ] Video checksum: `________________`
- [x] Subtitle checksum:
      `cde50e3d8f0219ba032a6d4ad55e77088dd277542ae42599c223e4a83cb97891`
- [x] Sanitized fixture checksums:
      `ConversationEvent.swift` —
      `6d0479cf791f0a74607db27c80beac9454a8409684d8c8054a507970c73b6abe`;
      `KaiwaLoopReplayFixture.swift` —
      `2fd876b1f55aaadff58c2c3f8d52c83d7df5a4d9667316309f25cc2cfb78164e`
- [x] Final 26-entry checksum manifest reviewed and rehashed

## Final external actions

- [ ] Ignacio approves private reviewer share or public repository release
- [ ] Ignacio approves and publishes YouTube video
- [ ] Root Codex task runs `/feedback`; returned ID recorded in the ledger
- [ ] Ignacio approves final Devpost fields and submission
