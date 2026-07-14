#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SAFE_OUTPUT_ROOT="$ROOT_DIR/.build/submission"
INPUT_ROOT="$ROOT_DIR/.build/submission-inputs"
REQUESTED_OUTPUT="${MA_SUBMISSION_OUTPUT_DIR:-$SAFE_OUTPUT_ROOT}"

case "$REQUESTED_OUTPUT" in
  "$SAFE_OUTPUT_ROOT"|"$SAFE_OUTPUT_ROOT"/*) ;;
  *)
    printf 'MA_SUBMISSION_OUTPUT_DIR must stay under %s.\n' "$SAFE_OUTPUT_ROOT" >&2
    exit 64
    ;;
esac

if [[ -L "$ROOT_DIR/.build" || -L "$SAFE_OUTPUT_ROOT" || -L "$INPUT_ROOT" ]]; then
  printf 'Refusing symlinked submission build directories.\n' >&2
  exit 64
fi
mkdir -p "$SAFE_OUTPUT_ROOT" "$INPUT_ROOT" "$REQUESTED_OUTPUT"
CANONICAL_SAFE_ROOT="$(cd "$SAFE_OUTPUT_ROOT" && pwd -P)"
OUTPUT_DIR="$(cd "$REQUESTED_OUTPUT" && pwd -P)"
CANONICAL_INPUT_ROOT="$(cd "$INPUT_ROOT" && pwd -P)"
if [[ "$CANONICAL_SAFE_ROOT" != "$SAFE_OUTPUT_ROOT" \
   || "$CANONICAL_INPUT_ROOT" != "$INPUT_ROOT" ]]; then
  printf 'Submission build roots did not resolve inside the repository.\n' >&2
  exit 64
fi
case "$OUTPUT_DIR" in
  "$CANONICAL_SAFE_ROOT"|"$CANONICAL_SAFE_ROOT"/*) ;;
  *)
    printf 'Submission output resolved outside its safe root.\n' >&2
    exit 64
    ;;
esac

ARCHIVE_PATH="$OUTPUT_DIR/MA.xcarchive"

canonical_input() {
  local requested="$1"
  local label="$2"
  local parent
  local canonical

  [[ -f "$requested" && ! -L "$requested" ]] || {
    printf '%s must be a regular, non-symlinked file.\n' "$label" >&2
    exit 68
  }
  parent="$(cd "$(dirname "$requested")" && pwd -P)" || exit 68
  canonical="$parent/$(basename "$requested")"
  case "$canonical" in
    "$CANONICAL_INPUT_ROOT"/*) printf '%s\n' "$canonical" ;;
    *)
      printf '%s must be staged under %s.\n' "$label" "$CANONICAL_INPUT_ROOT" >&2
      exit 68
      ;;
  esac
}

cd "$ROOT_DIR"
xcodegen generate >/dev/null
if ! TREE_STATUS="$(git status --porcelain=v1 --untracked-files=all)"; then
  printf 'Unable to establish repository status. No archive created.\n' >&2
  exit 69
fi
if [[ -n "$TREE_STATUS" ]]; then
  printf 'Refusing to archive a dirty, untracked, or generator-divergent tree. Commit the frozen build first.\n' >&2
  exit 65
fi
if ! IGNORED_PRODUCT_INPUTS="$(
  git ls-files --others --ignored --exclude-standard -- apps/MA
)"; then
  printf 'Unable to audit ignored product inputs. No archive created.\n' >&2
  exit 69
fi
if [[ -n "$IGNORED_PRODUCT_INPUTS" ]]; then
  printf 'Refusing ignored files under apps/MA; XcodeGen inputs must belong to the exact commit.\n' >&2
  exit 65
fi

scripts/scan-secrets.sh
rm -rf -- "$OUTPUT_DIR"
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
codesign --verify --deep --strict "$APP_PATH"

cp apps/MA/Conversation/KaiwaLoopReplayFixture.swift \
  "$OUTPUT_DIR/sanitized-fixtures/"
cp apps/MA/Conversation/ConversationEvent.swift \
  "$OUTPUT_DIR/sanitized-fixtures/"
cp docs/submission/subtitles-en.srt "$OUTPUT_DIR/submission-copy/"
cp docs/submission/devpost-draft.md "$OUTPUT_DIR/submission-copy/"
cp docs/submission/testing-instructions.md "$OUTPUT_DIR/submission-copy/"
cp docs/submission/privacy-disclosure.md "$OUTPUT_DIR/submission-copy/"

if [[ -n "${MA_REDACTED_LOG:-}" ]]; then
  REDACTED_LOG="$(canonical_input "$MA_REDACTED_LOG" "MA_REDACTED_LOG")"
  cp "$REDACTED_LOG" "$OUTPUT_DIR/submission-copy/product-redacted.log"
fi

if [[ -n "${MA_VIDEO_PATH:-}" ]]; then
  VIDEO_PATH="$(canonical_input "$MA_VIDEO_PATH" "MA_VIDEO_PATH")"
  cp "$VIDEO_PATH" "$OUTPUT_DIR/submission-copy/final-demo.mp4"
fi

git rev-parse HEAD >"$OUTPUT_DIR/GIT_COMMIT"
{
  xcodebuild -version
  xcrun swift --version
  printf 'iPhoneOS SDK %s\n' "$(xcrun --sdk iphoneos --show-sdk-version)"
} >"$OUTPUT_DIR/BUILD_ENVIRONMENT"

scripts/scan-secrets.sh \
  "$OUTPUT_DIR/archive.log" \
  "$OUTPUT_DIR/sanitized-fixtures" \
  "$OUTPUT_DIR/submission-copy" \
  "$OUTPUT_DIR/BUILD_ENVIRONMENT"

ditto -c -k --sequesterRsrc --keepParent "$ARCHIVE_PATH" "$OUTPUT_DIR/MA.xcarchive.zip"
(
  cd "$OUTPUT_DIR"
  find . -type f ! -name SHA256SUMS -print0 \
    | sort -z \
    | xargs -0 shasum -a 256 \
    > SHA256SUMS
)

printf 'Release archive and checksums created at %s\n' "$OUTPUT_DIR"
