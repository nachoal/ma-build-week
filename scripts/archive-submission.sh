#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${MA_SUBMISSION_OUTPUT_DIR:-$ROOT_DIR/.build/submission}"
ARCHIVE_PATH="$OUTPUT_DIR/MA.xcarchive"

cd "$ROOT_DIR"
xcodegen generate >/dev/null
if ! git diff --quiet || ! git diff --cached --quiet; then
  printf 'Refusing to archive a dirty or generator-divergent tracked tree. Commit the frozen build first.\n' >&2
  exit 65
fi

scripts/scan-secrets.sh
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/sanitized-fixtures" "$OUTPUT_DIR/submission-copy"

xcodebuild archive \
  -project MA.xcodeproj \
  -scheme MA \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  >"$OUTPUT_DIR/archive.log" 2>&1

APP_PATH="$ARCHIVE_PATH/Products/Applications/MA.app"
[[ -d "$APP_PATH" ]] || {
  printf 'Archive did not contain MA.app.\n' >&2
  exit 66
}
[[ -f "$APP_PATH/PrivacyInfo.xcprivacy" ]] || {
  printf 'PrivacyInfo.xcprivacy is missing from the archived app.\n' >&2
  exit 67
}
plutil -lint "$APP_PATH/PrivacyInfo.xcprivacy" >/dev/null

cp apps/MA/Conversation/KaiwaLoopReplayFixture.swift \
  "$OUTPUT_DIR/sanitized-fixtures/"
cp apps/MA/Conversation/ConversationEvent.swift \
  "$OUTPUT_DIR/sanitized-fixtures/"
cp docs/submission/subtitles-en.srt "$OUTPUT_DIR/submission-copy/"
cp docs/submission/devpost-draft.md "$OUTPUT_DIR/submission-copy/"
cp docs/submission/testing-instructions.md "$OUTPUT_DIR/submission-copy/"
cp docs/submission/privacy-disclosure.md "$OUTPUT_DIR/submission-copy/"

if [[ -n "${MA_REDACTED_LOG:-}" ]]; then
  case "$MA_REDACTED_LOG" in
    *docs/poc/private-evidence*|*docs/poc/raw-logs*)
      printf 'Private/raw evidence cannot enter the submission archive.\n' >&2
      exit 68
      ;;
  esac
  cp "$MA_REDACTED_LOG" "$OUTPUT_DIR/submission-copy/product-redacted.log"
fi

if [[ -n "${MA_VIDEO_PATH:-}" ]]; then
  cp "$MA_VIDEO_PATH" "$OUTPUT_DIR/submission-copy/final-demo.mp4"
fi

git rev-parse HEAD >"$OUTPUT_DIR/GIT_COMMIT"
ditto -c -k --sequesterRsrc --keepParent "$ARCHIVE_PATH" "$OUTPUT_DIR/MA.xcarchive.zip"
(
  cd "$OUTPUT_DIR"
  find . -type f ! -name SHA256SUMS -print0 \
    | sort -z \
    | xargs -0 shasum -a 256 \
    > SHA256SUMS
)

printf 'Release archive and checksums created at %s\n' "$OUTPUT_DIR"
