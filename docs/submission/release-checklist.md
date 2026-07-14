# Submission release checklist

No item authorizes a push, public upload, repository share, `/feedback`, or
Devpost submission. Those require Ignacio's explicit approval.

## Freeze identity

- [ ] Refresh the frozen implementation/archive from current implementation
      commit `80c6eeec543c213e2e95611e1bbc9bc7441405a7`; the prior `bebac3c`
      archive is retained only as superseded evidence
- [x] Xcode/Swift/iOS build versions recorded in the candidate packet
- [ ] Release `.xcarchive` rebuilt from the final clean commit
- [ ] `PrivacyInfo.xcprivacy` reverified inside the refreshed `MA.app`
- [ ] Signed physical install/launch verified on the dynamically discovered device
- [x] `scripts/scan-secrets.sh` rerun after the frozen implementation commit,
      including the archived app and compiled executable

## Automated and service evidence

- [x] Exact documented, no-secret final-candidate MA result bundle: 206/206
      executions, 0 skipped (177 test definitions); the isolated private
      `MALive` target was absent at
      `.build/test-results/MA-final-planner-timeout-standard.xcresult`
- [x] Production-realistic bilingual simulator gate uses the private broker,
      `gpt-realtime-2.1`, structured validator, response audio, waiter turn, two
      reviews, and `gpt-5.6-sol` planner; 10/10 repetitions passed (five English,
      five Spanish) at
      `.build/test-results/MA-live-low-reasoning-bilingual-stress5.xcresult`
- [x] Separate real-audio simulator result includes English permission
      disclosure, one-tap model completion, real AVAudio capture, and stop; 1/1
      at `.build/test-results/MA-live-audio-integration.xcresult`
- [x] Complete MAAudioProbe result bundle (51/51 executions, 49 test
      definitions, characterization only) at
      `.build/test-results/MAAudioProbe-current.xcresult`
- [x] Worker 34/34 low-reasoning and bounded-planner-retry contract output at
      `.build/test-results/MAWorker-planner-timeout-20260714.tap`; private
      version `59fa3f6f-0ead-421a-bb16-2b64fd8db1ff`
- [x] Live private health, malformed-media rejection, Realtime mint,
      exact policy-hash, and guided-planner verification
- [x] Secret scan passes the current candidate, staged inputs, reachable
      history, and the current compiled simulator executable after the 206/206,
      10/10, and 1/1 gates; the final archived executable rerun remains required

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

- [x] Archive checksum:
      `3f14ecf07eaf8e594622df8f9ae43d33d3788f6117c7d7652cffd0352427605c`
- [ ] Video checksum: `________________`
- [ ] Subtitle checksum: `________________`
- [ ] Sanitized fixture checksum(s): `________________`
- [ ] Final checksum manifest reviewed

## Final external actions

- [ ] Ignacio approves private reviewer share or public repository release
- [ ] Ignacio approves and publishes YouTube video
- [ ] Root Codex task runs `/feedback`; returned ID recorded in the ledger
- [ ] Ignacio approves final Devpost fields and submission
