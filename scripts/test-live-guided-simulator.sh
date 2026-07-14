#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${MA_LIVE_SIM_DERIVED_DATA:-$ROOT_DIR/.build/live-simulator-derived-data}"
RESULT_PATH="${MA_LIVE_SIM_RESULT:-$ROOT_DIR/.build/test-results/MA-live-production-simulator.xcresult}"
LOG_PATH="${MA_LIVE_SIM_LOG:-$ROOT_DIR/.build/test-results/MA-live-production-simulator.log}"
ITERATIONS="${MA_LIVE_SIM_ITERATIONS:-1}"
TEST_SELECTION="${MA_LIVE_SIM_TEST:-MALiveUITests/GuidedProductionRealtimeUITests}"
TEST_SCHEME="MALive"
PROVISIONING_STARTED=false
CREDENTIAL_CLEANUP_VERIFIED=false

[[ "$ITERATIONS" =~ ^[1-9][0-9]*$ ]] && (( ITERATIONS <= 5 )) || {
  printf 'MA_LIVE_SIM_ITERATIONS must be an integer from 1 through 5.\n' >&2
  exit 64
}
case "$TEST_SELECTION" in
  MALiveUITests/GuidedProductionRealtimeUITests | \
  MALiveUITests/GuidedProductionRealtimeUITests/[A-Za-z0-9_]*)
    ;;
  MAUITests/GuidedLiveAudioIntegrationUITests/testOneTapModelPlaybackAndRealCaptureStopStayResponsive)
    TEST_SCHEME="MA"
    ;;
  *)
    printf 'MA_LIVE_SIM_TEST must select the production Realtime UI suite, one of its methods, or the named live-audio integration test.\n' >&2
    exit 64
    ;;
esac
iteration_arguments=()
if (( ITERATIONS > 1 )); then
  iteration_arguments=(-test-iterations "$ITERATIONS")
fi

refresh_simulator_credential_paths() {
  DATA_CONTAINER="$(xcrun simctl get_app_container "$SIMULATOR_ID" com.ia.ma data)" \
    || return 1
  CREDENTIAL_READY_SENTINEL="$DATA_CONTAINER/Documents/ma-private-credential-ready"
  CREDENTIAL_DELETED_SENTINEL="$DATA_CONTAINER/Documents/ma-private-credential-deleted"
}

delete_simulator_credential() {
  # XCTest may reinstall the app and replace its data-container UUID even for
  # test-without-building. Never verify a marker through the pre-test path.
  refresh_simulator_credential_paths || return 1
  if ! SIMCTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN=true \
      xcrun simctl launch --terminate-running-process "$SIMULATOR_ID" com.ia.ma \
      >/dev/null 2>&1; then
    return 1
  fi
  for _ in {1..100}; do
    if [[ -f "$CREDENTIAL_DELETED_SENTINEL" \
        && ! -e "$CREDENTIAL_READY_SENTINEL" ]]; then
      xcrun simctl terminate "$SIMULATOR_ID" com.ia.ma >/dev/null 2>&1 || true
      return 0
    fi
    sleep 0.1
  done
  xcrun simctl terminate "$SIMULATOR_ID" com.ia.ma >/dev/null 2>&1 || true
  return 1
}

cleanup() {
  local original_status=$?
  local cleanup_failed=false
  trap - EXIT
  unset token SIMCTL_CHILD_MA_INSTALL_TOKEN SIMCTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN \
    SIMCTL_CHILD_MA_UI_TEST_PROVISION_ONLY
  if [[ -n "${SIMULATOR_ID:-}" \
      && "$PROVISIONING_STARTED" == "true" \
      && "$CREDENTIAL_CLEANUP_VERIFIED" != "true" ]]; then
    if delete_simulator_credential; then
      CREDENTIAL_CLEANUP_VERIFIED=true
    else
      cleanup_failed=true
      printf 'WARNING: could not verify deletion of the simulator test credential.\n' >&2
    fi
  fi
  if [[ -n "${SIMULATOR_ID:-}" ]]; then
    xcrun simctl terminate "$SIMULATOR_ID" com.ia.ma >/dev/null 2>&1 || true
  fi
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

DEVICE_JSON="$(xcrun simctl list devices available -j)"
SIMULATOR_COUNT="$(jq '[.devices[][] | select(
  .name == "iPhone 17 Pro" and .state == "Booted"
)] | length' <<<"$DEVICE_JSON")"
[[ "$SIMULATOR_COUNT" == "1" ]] || {
  printf 'Expected exactly one booted iPhone 17 Pro simulator; found %s.\n' \
    "$SIMULATOR_COUNT" >&2
  exit 70
}
SIMULATOR_ID="$(jq -r '.devices[][] | select(
  .name == "iPhone 17 Pro" and .state == "Booted"
) | .udid' <<<"$DEVICE_JSON")"

token="$(security find-generic-password \
  -a private-product-install-token \
  -s com.ia.ma.learning-planner.deployment \
  -w)"
[[ ${#token} -ge 32 ]] || {
  printf 'The private product test credential is missing or invalid.\n' >&2
  exit 77
}

mkdir -p "$(dirname "$RESULT_PATH")" "$DERIVED_DATA"
rm -rf "$RESULT_PATH"
cd "$ROOT_DIR"
xcodegen generate >/dev/null
xcodebuild build-for-testing \
  -project MA.xcodeproj \
  -scheme "$TEST_SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  >"$LOG_PATH" 2>&1

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/MA.app"
[[ -d "$APP_PATH" ]] || {
  printf 'The simulator app was not built.\n' >&2
  exit 66
}
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
refresh_simulator_credential_paths
PROVISIONING_STARTED=true
SIMCTL_CHILD_MA_INSTALL_TOKEN="$token" \
SIMCTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN=true \
SIMCTL_CHILD_MA_UI_TEST_PROVISION_ONLY=true \
  xcrun simctl launch --terminate-running-process "$SIMULATOR_ID" com.ia.ma \
  >/dev/null
for _ in {1..100}; do
  [[ -f "$CREDENTIAL_READY_SENTINEL" \
      && ! -e "$CREDENTIAL_DELETED_SENTINEL" ]] && break
  sleep 0.1
done
[[ -f "$CREDENTIAL_READY_SENTINEL" \
    && ! -e "$CREDENTIAL_DELETED_SENTINEL" ]] || {
  printf 'The simulator app did not confirm private credential provisioning.\n' >&2
  exit 78
}
unset SIMCTL_CHILD_MA_INSTALL_TOKEN SIMCTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN \
  SIMCTL_CHILD_MA_UI_TEST_PROVISION_ONLY token
xcrun simctl terminate "$SIMULATOR_ID" com.ia.ma >/dev/null

if [[ "$TEST_SELECTION" == MAUITests/GuidedLiveAudioIntegrationUITests/* ]]; then
  xcrun simctl privacy "$SIMULATOR_ID" reset microphone com.ia.ma
fi

xcodebuild test-without-building \
  -project MA.xcodeproj \
  -scheme "$TEST_SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -collect-test-diagnostics never \
  -only-testing:"$TEST_SELECTION" \
  "${iteration_arguments[@]}" \
  -resultBundlePath "$RESULT_PATH" \
  >>"$LOG_PATH" 2>&1

if ! delete_simulator_credential; then
  printf 'The app did not prove deletion of the simulator test credential. This run is not a passing release gate.\n' >&2
  exit 80
fi
CREDENTIAL_CLEANUP_VERIFIED=true
printf 'Verified simulator test-credential deletion.\n'
xcrun xcresulttool get test-results summary \
  --path "$RESULT_PATH" --compact
