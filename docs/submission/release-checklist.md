# Submission release checklist

No item authorizes a push, public upload, repository share, `/feedback`, or
Devpost submission. Those require Ignacio's explicit approval.

## Freeze identity

- [ ] Final commit: `________________`
- [ ] Xcode/Swift/iOS build versions recorded
- [ ] Release `.xcarchive` built from that clean commit
- [ ] `PrivacyInfo.xcprivacy` verified inside `MA.app`
- [ ] Signed physical install/launch verified on dynamically discovered device
- [ ] `scripts/scan-secrets.sh` rerun after the final commit

## Evidence

- [ ] Complete MA scheme test result bundle
- [ ] Complete MAAudioProbe scheme test result bundle (characterization only)
- [ ] Worker 18/18 contract output
- [ ] Physical matrix and 9/10 rehearsals
- [ ] Real learner first/second-attempt evidence
- [ ] Qualified Japanese-speaker review
- [ ] Five-person 4/5 cold-viewer result
- [ ] Redacted final product log; no raw private evidence
- [ ] Under-three-minute final video and matching English subtitles

## Public claim audit

- [ ] Every narration/subtitle/README/Devpost claim appears as Allowed in
      `claim-evidence-matrix.md`
- [ ] No live Realtime, overlap, AEC, exact-heard, latency, or learner-outcome
      claim without its physical/human evidence
- [ ] Replay label is unmistakable in every fallback frame
- [ ] Video/repository URLs replace placeholders only after approval

## Archive contents and checksums

Archive only the exact build, sanitized fixtures, redacted logs, video,
subtitles, and submission text. Never include `docs/poc/private-evidence`, raw
audio, `.dev.vars`, Keychain exports, authorization headers, DerivedData, or
standard provider credentials.

Create `SHA256SUMS` in the ignored release directory with:

```sh
find .build/submission -type f ! -name SHA256SUMS -print0 \
  | sort -z \
  | xargs -0 shasum -a 256 \
  > .build/submission/SHA256SUMS
```

- [ ] Archive checksum: `________________`
- [ ] Video checksum: `________________`
- [ ] Subtitle checksum: `________________`
- [ ] Sanitized fixture checksum(s): `________________`
- [ ] Final checksum manifest reviewed

## Final external actions

- [ ] Ignacio approves private reviewer share or public repository release
- [ ] Ignacio approves and publishes YouTube video
- [ ] Root Codex task runs `/feedback`; returned ID recorded in ledger
- [ ] Ignacio approves final Devpost fields and submission
