# Submission release checklist

Ignacio explicitly authorized the minimum required public repository/video
steps and one final Devpost submission on 2026-07-21. That authorization does
not widen any evidence claim.

The prior `e968354` / `29b045...` archive is **superseded and must not be
installed or submitted**. A physical report reproduced that it could launch
without usable speaking-turn review access. PID-only launch evidence was a
false release gate. The replacement archive is structurally verified at
`68ce85b`, but it was not freshly installed on the phone before submission. The
entry therefore relies on fresh Simulator/service gates, preserved qualified
physical evidence, and a narrowed claim boundary; it does not describe the
replacement archive as fresh physical Release evidence.

## Freeze identity

- [x] Replacement frozen submission/archive commit:
      `68ce85bdafd71a73f90b323071c5ae934073a90c`
- [x] Superseded archive retained for audit only:
      `e968354b04d5043d65db9c809d02f0ae209a60a1`; shipping app
      implementation commit: `f9f7a7f9fdd2ae649ac20bb18392ab14f2b6047c`
- [x] Xcode/Swift/iOS build versions recorded in the candidate packet
- [x] Release `.xcarchive` rebuilt from the clean frozen commit
- [x] `PrivacyInfo.xcprivacy` reverified inside the refreshed `MA.app`
- [x] Superseded archive install/launch reproduced on the dynamically discovered
      iPhone 17 Pro running iOS 27.0. The final Release app from the exact
      `e968354b04d5043d65db9c809d02f0ae209a60a1` archive launched as PID 20185;
      a follow-up process inventory still found that PID running from
      `MA.app`. This is launch/stability evidence only and does not strengthen
      any audio or learner claim and did not prove usable review access
- [ ] Replacement archived Release verifies exact Keychain readback, then a
      bearer-free Keychain-loaded WebSocket `session.created` policy check,
      relaunches with neither token nor nonce, and remains running on the
      device; not rerun before submission, so no fresh-device claim is made
- [x] `scripts/scan-secrets.sh` rerun after the new frozen implementation
      commit, including the archived app and compiled executable

## Automated and service evidence

- [x] Fresh submission-day no-secret MA result bundle: 230/230 executions,
      0 skipped (196 test definitions plus 38 dynamic parameter runs) on iPhone
      17 Pro Simulator/iOS 26.5 at
      `.build/test-results/MA-submission-final-simulator-20260721.xcresult`
- [x] Focused local-deletion gate: 7/7 (four transaction/Keychain tests and
      three bilingual UI journeys) at
      `.build/test-results/MA-local-data-deletion-focused.xcresult`; the same
      seven tests also passed inside the uncontended complete MA run
- [x] Exact-current production-realistic bilingual simulator gate uses the
      private broker, `gpt-realtime-2.1`, structured validator, response audio,
      waiter turn, two reviews, and `gpt-5.6-sol` planner. One smoke pair and
      three consecutive isolated English/Spanish pairs passed 2/2 each. The
      interrupted fourth and incomplete fifth pair are not counted
- [x] Focused replacement gate passed 24/24 at
      `.build/test-results/MA-release-access-focused-current.xcresult`, including
      real AVAudio playback/capture/stop followed by labeled deterministic
      review feedback, separate silence honesty, missing-access-before-mic,
      stale-warm-transport rejection, and provisioning receipt checks
- [x] Complete MAAudioProbe result bundle (51/51 executions, 49 test
      definitions, characterization only) freshly reran at
      `.build/test-results/MAAudioProbe-submission-final-simulator-20260721.xcresult`
- [x] Worker 35/35 low-reasoning and bounded-planner-retry contract output at
      `.build/test-results/MAWorker-final-freeze.tap`; private version
      `57d49379-af1f-4160-8e88-ec611ab9a1d7`
- [x] Live private health, malformed-media rejection, Realtime mint,
      exact policy-hash, and guided-planner verification
- [x] Secret scan passes the current candidate, staged inputs, reachable
      history, and the current compiled simulator executable after the 227/227,
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
- [x] Under-three-minute English-narrated final video produced: 90.23 seconds,
      1080x1920 H.264/AAC, with an explicit Simulator/deterministic-input
      disclosure; public YouTube processing remains pending

## Public claim audit

- [x] Every narration/subtitle/README/Devpost claim appears as Allowed in
      `claim-evidence-matrix.md`
- [x] Bounded product Realtime is described only as explicit non-overlap
- [x] No full-duplex overlap, AEC/no-echo, exact-heard replay, numeric latency,
      exact transcript, score, mastery, or learner-outcome claim
- [x] No claim that audio stays on-device or that GPT-5.6 reviews audio
- [x] Historical replay is unmistakably labeled **REPLAY · NOT LIVE / NO EN VIVO**
- [x] Repository URL replaced after explicit approval; video URL will be
      inserted only after YouTube confirms public availability

## Archive contents and checksums

Archive only the exact build, sanitized fixtures, redacted logs, video,
subtitles, and submission text. Never include `docs/poc/private-evidence`, raw
audio, `.dev.vars`, Keychain exports, authorization headers, DerivedData, or
standard provider credentials.

Stage optional redacted logs/video under ignored `.build/submission-inputs/`;
the archive tool rejects paths outside its canonical roots, records the build
environment and exact commit, and rescans staged copy.

- [x] Replacement archive checksum:
      `31a39d8482fc77d3297cb058a39ba8753238fe77b8bdc883c465db82cea7d116`
- [x] Superseded broken archive checksum retained for audit only:
      `29b0454396797d7483c6306731eae9c309fe8406d45227b61870845e81ba08db`
- [x] Earlier superseded archive checksum retained for audit only:
      `91c251a7d51a58c8375c9ab8bf27d85bccc51a101f3158dd90a1fc07c64d96e9`
- [x] Video checksum:
      `3c56e1f6a06a4047bdac658e90bddc78c1f7b93b88c0abb0126b204e05986a4c`
- [x] Subtitle checksum:
      `cde50e3d8f0219ba032a6d4ad55e77088dd277542ae42599c223e4a83cb97891`
- [x] Sanitized fixture checksums:
      `ConversationEvent.swift` —
      `6d0479cf791f0a74607db27c80beac9454a8409684d8c8054a507970c73b6abe`;
      `KaiwaLoopReplayFixture.swift` —
      `2fd876b1f55aaadff58c2c3f8d52c83d7df5a4d9667316309f25cc2cfb78164e`
- [x] Replacement checksum manifest reviewed and archive ZIP rehashed

## Final external actions

- [x] Ignacio approves the minimum required public repository release; source
      published at `https://github.com/nachoal/ma-build-week`
- [x] Ignacio approves the public YouTube video; upload is in progress
- [x] Root Codex project-thread Session ID recorded as
      `019f5f68-b42c-7bb2-97dc-a1243d495298`
- [x] Ignacio explicitly approves the final Devpost fields and one submission
