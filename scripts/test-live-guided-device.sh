#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${MA_LIVE_DEVICE_DERIVED_DATA:-$ROOT_DIR/.build/live-device-derived-data}"
RESULT_PATH="${MA_LIVE_DEVICE_RESULT:-$ROOT_DIR/.build/test-results/MA-live-production-device.xcresult}"
LOG_PATH="${MA_LIVE_DEVICE_LOG:-$ROOT_DIR/.build/test-results/MA-live-production-device.log}"
TEST_SELECTION="${MA_LIVE_DEVICE_TEST:-MALiveUITests/GuidedProductionRealtimeUITests}"
TEST_SCHEME="MALive"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="$ROOT_DIR/.build/device-evidence/$RUN_ID-live-ui"
CREDENTIAL_READY_SENTINEL="ma-private-credential-ready"
CREDENTIAL_DELETED_SENTINEL="ma-private-credential-deleted"

case "$TEST_SELECTION" in
  MALiveUITests/GuidedProductionRealtimeUITests | \
  MALiveUITests/GuidedProductionRealtimeUITests/[A-Za-z0-9_]*)
    ;;
  MAUITests/GuidedLiveAudioIntegrationUITests/testOneTapModelPlaybackAndRealCaptureStopStayResponsive)
    TEST_SCHEME="MA"
    ;;
  *)
    printf 'MA_LIVE_DEVICE_TEST must select the production Realtime UI suite, one of its methods, or the named live-audio integration test.\n' >&2
    exit 64
    ;;
esac

DEVICE_JSON="$(mktemp -t ma-live-device.XXXXXX.json)"
LOCK_JSON="$(mktemp -t ma-live-device-lock.XXXXXX.json)"
RAW_LAUNCH_JSON="$(mktemp -t ma-live-device-launch.XXXXXX.json)"
RAW_LAUNCH_LOG="$(mktemp -t ma-live-device-launch.XXXXXX.log)"
FILES_JSON="$(mktemp -t ma-live-device-files.XXXXXX.json)"
DELETE_JSON="$(mktemp -t ma-live-device-delete.XXXXXX.json)"
DELETE_LOG="$(mktemp -t ma-live-device-delete.XXXXXX.log)"
PROVISIONING_STARTED=false
CREDENTIAL_CLEANUP_VERIFIED=false

contains_private_value() {
  local path="$1"
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "${token:-}" && "$line" == *"$token"* ]] && return 0
  done <"$path"
  return 1
}

delete_device_credential() {
  rm -f "$DELETE_JSON" "$DELETE_LOG"
  if ! DEVICECTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN=true \
      xcrun devicectl device process launch \
        --device "$DEVICE_ID" \
        --terminate-existing \
        --json-output "$DELETE_JSON" \
        --log-output "$DELETE_LOG" \
        com.ia.ma >/dev/null 2>&1; then
    return 1
  fi

  for _ in {1..50}; do
    if xcrun devicectl device info files \
        --device "$DEVICE_ID" \
        --domain-type appDataContainer \
        --domain-identifier com.ia.ma \
        --subdirectory Documents \
        --json-output "$FILES_JSON" >/dev/null 2>&1; then
      if jq -e --arg marker "$CREDENTIAL_DELETED_SENTINEL" \
          '.. | strings | select(endswith($marker))' "$FILES_JSON" >/dev/null \
        && ! jq -e --arg marker "$CREDENTIAL_READY_SENTINEL" \
          '.. | strings | select(endswith($marker))' "$FILES_JSON" >/dev/null; then
        return 0
      fi
    fi
    sleep 0.1
  done
  return 1
}

cleanup() {
  local original_status=$?
  local cleanup_failed=false
  trap - EXIT
  unset DEVICECTL_CHILD_MA_INSTALL_TOKEN DEVICECTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN \
    DEVICECTL_CHILD_MA_UI_TEST_PROVISION_ONLY
  if [[ -n "${DEVICE_ID:-}" \
      && "$PROVISIONING_STARTED" == "true" \
      && "$CREDENTIAL_CLEANUP_VERIFIED" != "true" ]]; then
    if delete_device_credential; then
      CREDENTIAL_CLEANUP_VERIFIED=true
    else
      cleanup_failed=true
      printf 'WARNING: could not verify deletion of the physical test credential. Unlock the phone and rerun cleanup before treating this run as releasable evidence.\n' >&2
    fi
  fi
  unset token
  rm -f "$DEVICE_JSON" "$LOCK_JSON" "$RAW_LAUNCH_JSON" "$RAW_LAUNCH_LOG" \
    "$FILES_JSON" "$DELETE_JSON" "$DELETE_LOG"
  if [[ "$original_status" == "0" && "$cleanup_failed" == "true" ]]; then
    exit 80
  fi
  exit "$original_status"
}
trap cleanup EXIT

for command in jq xcodegen xcodebuild security; do
  command -v "$command" >/dev/null || {
    printf 'Missing required command: %s\n' "$command" >&2
    exit 69
  }
done

xcrun devicectl list devices --json-output "$DEVICE_JSON" >/dev/null
MATCH_COUNT="$(jq '[.result.devices[] | select(
  .hardwareProperties.deviceType == "iPhone"
  and .hardwareProperties.marketingName == "iPhone 17 Pro"
  and (.deviceProperties.osVersionNumber | startswith("27."))
  and .deviceProperties.developerModeStatus == "enabled"
)] | length' "$DEVICE_JSON")"
[[ "$MATCH_COUNT" == "1" ]] || {
  printf 'Expected exactly one paired iPhone 17 Pro on iOS 27 with Developer Mode; found %s.\n' \
    "$MATCH_COUNT" >&2
  exit 70
}

DEVICE_ID="$(jq -r '.result.devices[] | select(
  .hardwareProperties.deviceType == "iPhone"
  and .hardwareProperties.marketingName == "iPhone 17 Pro"
  and (.deviceProperties.osVersionNumber | startswith("27."))
  and .deviceProperties.developerModeStatus == "enabled"
) | .identifier' "$DEVICE_JSON")"
DEVICE_OS="$(jq -r --arg id "$DEVICE_ID" '.result.devices[] |
  select(.identifier == $id) | .deviceProperties.osVersionNumber' "$DEVICE_JSON")"

token="$(security find-generic-password \
  -a private-product-install-token \
  -s com.ia.ma.learning-planner.deployment \
  -w)"
[[ ${#token} -ge 32 ]] || {
  printf 'The private product test credential is missing or invalid.\n' >&2
  exit 77
}

mkdir -p "$(dirname "$RESULT_PATH")" "$DERIVED_DATA" "$EVIDENCE_DIR"
rm -rf "$RESULT_PATH"
cd "$ROOT_DIR"
xcodegen generate >"$EVIDENCE_DIR/xcodegen.log" 2>&1
if [[ -n "$(git status --porcelain=v1 --untracked-files=all)" ]]; then
  printf 'Refusing physical evidence from a dirty or generator-divergent tree. Commit the candidate first.\n' >&2
  exit 65
fi
git rev-parse HEAD >"$EVIDENCE_DIR/GIT_COMMIT"
xcodebuild build-for-testing \
  -project MA.xcodeproj \
  -scheme "$TEST_SCHEME" \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  >"$LOG_PATH" 2>&1

xcrun devicectl device info lockState \
  --device "$DEVICE_ID" \
  --json-output "$LOCK_JSON" >/dev/null
[[ "$(jq -r '.result.passcodeRequired' "$LOCK_JSON")" == "false" ]] || {
  printf 'The paired iPhone is locked. Unlock it and keep it awake before running physical UI evidence.\n' >&2
  exit 71
}
cp "$LOCK_JSON" "$EVIDENCE_DIR/lock-state.json"

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/MA.app"
[[ -d "$APP_PATH" ]] || {
  printf 'The signed physical-device app was not built.\n' >&2
  exit 66
}
xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  --json-output "$EVIDENCE_DIR/install.json" \
  --log-output "$EVIDENCE_DIR/install.log" \
  "$APP_PATH" >/dev/null

PROVISIONING_STARTED=true
DEVICECTL_CHILD_MA_INSTALL_TOKEN="$token" \
DEVICECTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN=true \
DEVICECTL_CHILD_MA_UI_TEST_PROVISION_ONLY=true \
  xcrun devicectl device process launch \
    --device "$DEVICE_ID" \
    --terminate-existing \
    --json-output "$RAW_LAUNCH_JSON" \
    --log-output "$RAW_LAUNCH_LOG" \
    com.ia.ma >/dev/null
if contains_private_value "$RAW_LAUNCH_LOG"; then
  printf 'Private launch credential reached the device-tool log; refusing to continue.\n' >&2
  exit 78
fi

sentinel_ready=false
for _ in {1..50}; do
  if xcrun devicectl device info files \
      --device "$DEVICE_ID" \
      --domain-type appDataContainer \
      --domain-identifier com.ia.ma \
      --subdirectory Documents \
      --json-output "$FILES_JSON" >/dev/null 2>&1 \
    && jq -e --arg marker "$CREDENTIAL_READY_SENTINEL" \
      '.. | strings | select(endswith($marker))' "$FILES_JSON" >/dev/null \
    && ! jq -e --arg marker "$CREDENTIAL_DELETED_SENTINEL" \
      '.. | strings | select(endswith($marker))' "$FILES_JSON" >/dev/null; then
    sentinel_ready=true
    break
  fi
  sleep 0.1
done
[[ "$sentinel_ready" == "true" ]] || {
  printf 'The physical app did not confirm value-free credential provisioning.\n' >&2
  exit 79
}

# CoreDevice currently serializes the launch environment into its JSON result.
# That raw file is always temporary and is deleted before the test. Retained
# evidence must still be independently proven not to contain the exact token.
rm -f "$RAW_LAUNCH_JSON" "$RAW_LAUNCH_LOG"
while IFS= read -r -d '' retained_path; do
  if contains_private_value "$retained_path"; then
    printf 'Private launch credential reached retained physical evidence; deleting the run.\n' >&2
    rm -rf "$EVIDENCE_DIR"
    exit 78
  fi
done < <(find "$EVIDENCE_DIR" -type f -print0)
unset DEVICECTL_CHILD_MA_INSTALL_TOKEN DEVICECTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN \
  DEVICECTL_CHILD_MA_UI_TEST_PROVISION_ONLY token

xcodebuild test-without-building \
  -project MA.xcodeproj \
  -scheme "$TEST_SCHEME" \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -collect-test-diagnostics never \
  -only-testing:"$TEST_SELECTION" \
  -resultBundlePath "$RESULT_PATH" \
  >>"$LOG_PATH" 2>&1

cp "$LOG_PATH" "$EVIDENCE_DIR/test.log"
if ! delete_device_credential; then
  printf 'The app did not prove deletion of the physical test credential. This run is not a passing release gate.\n' >&2
  exit 80
fi
CREDENTIAL_CLEANUP_VERIFIED=true
printf 'Verified physical test-credential deletion.\n'
scripts/scan-secrets.sh "$EVIDENCE_DIR"
printf 'Physical %s on iOS %s passed: %s\n' "$TEST_SCHEME" "$DEVICE_OS" "$TEST_SELECTION"
xcrun xcresulttool get test-results summary \
  --path "$RESULT_PATH" --compact
