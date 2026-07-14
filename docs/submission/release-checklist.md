# Submission release checklist

No item authorizes a push, public upload, repository share, `/feedback`, or
Devpost submission. Those require Ignacio's explicit approval.

## Freeze identity

- [ ] Final commit: `________________`
- [ ] Xcode/Swift/iOS build versions recorded
- [ ] Release `.xcarchive` built from that clean commit
- [ ] `PrivacyInfo.xcprivacy` verified inside `MA.app`
- [ ] Signed physical install/launch verified on the dynamically discovered device
- [ ] `scripts/scan-secrets.sh` rerun after the final commit

## Automated and service evidence

- [x] Complete MA scheme result bundle after the live review-cap correction:
      167 unit + 8 UI tests at
      `.build/test-results/MA-review-fix-full-20260714.xcresult`
- [x] Real-audio simulator UI test includes English permission disclosure,
      one-tap model completion, capture, and stop
- [x] Complete MAAudioProbe result bundle (49/49, characterization only) at
      `.build/test-results/MAAudioProbe-freeze-20260714.xcresult`
- [x] Worker 30/30 contract output at
      `.build/test-results/MAWorker-freeze-20260714.tap`
- [x] Live private health, malformed-media rejection, Realtime mint,
      exact policy-hash, and guided-planner verification
- [x] Secret scan passes the current frozen tree, staged inputs, and reachable
      history; the separate post-commit rerun above remains required

## Physical and human evidence

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

- [ ] Every narration/subtitle/README/Devpost claim appears as Allowed in
      `claim-evidence-matrix.md`
- [ ] Bounded product Realtime is described only as explicit non-overlap
- [ ] No full-duplex overlap, AEC/no-echo, exact-heard replay, numeric latency,
      exact transcript, score, mastery, or learner-outcome claim
- [ ] No claim that audio stays on-device or that GPT-5.6 reviews audio
- [ ] Historical replay is unmistakably labeled **REPLAY · NOT LIVE / NO EN VIVO**
- [ ] Video/repository URLs replace placeholders only after approval

## Archive contents and checksums

Archive only the exact build, sanitized fixtures, redacted logs, video,
subtitles, and submission text. Never include `docs/poc/private-evidence`, raw
audio, `.dev.vars`, Keychain exports, authorization headers, DerivedData, or
standard provider credentials.

Stage optional redacted logs/video under ignored `.build/submission-inputs/`;
the archive tool rejects paths outside its canonical roots, records the build
environment and exact commit, and rescans staged copy.

- [ ] Archive checksum: `________________`
- [ ] Video checksum: `________________`
- [ ] Subtitle checksum: `________________`
- [ ] Sanitized fixture checksum(s): `________________`
- [ ] Final checksum manifest reviewed

## Final external actions

- [ ] Ignacio approves private reviewer share or public repository release
- [ ] Ignacio approves and publishes YouTube video
- [ ] Root Codex task runs `/feedback`; returned ID recorded in the ledger
- [ ] Ignacio approves final Devpost fields and submission
