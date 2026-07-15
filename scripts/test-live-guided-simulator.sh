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
refresh_simulator_credential_paths() {
  DATA_CONTAINER="$(xcrun simctl get_app_container "$SIMULATOR_ID" com.ia.ma data)" \
    || return 1
  CREDENTIAL_READY_SENTINEL="$DATA_CONTAINER/Documents/ma-private-credential-ready"
  CREDENTIAL_DELETED_SENTINEL="$DATA_CONTAINER/Documents/ma-private-credential-deleted"
}

private_install_token() {
  local token
  if ! token="$(security find-generic-password \
      -a private-product-install-token \
      -s com.ia.ma.learning-planner.deployment \
      -w)"; then
    unset token
    return 1
  fi
  [[ ${#token} -ge 32 ]] || {
    unset token
    return 1
  }
  printf '%s' "$token"
  unset token
}

provision_simulator_credential() {
  local token
  if ! token="$(private_install_token)"; then
    printf 'The private product test credential is missing or invalid.\n' >&2
    return 1
  fi

  if ! xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"; then
    unset token
    return 1
  fi
  if ! refresh_simulator_credential_paths; then
    unset token
    return 1
  fi
  # simctl install preserves the app data container. Remove both generic DEBUG
  # proofs before launching so a failed launch can never inherit a green marker
  # from an earlier invocation.
  if ! rm -f "$CREDENTIAL_READY_SENTINEL" "$CREDENTIAL_DELETED_SENTINEL"; then
    unset token
    return 1
  fi
  PROVISIONING_STARTED=true
  CREDENTIAL_CLEANUP_VERIFIED=false
  if ! SIMCTL_CHILD_MA_INSTALL_TOKEN="$token" \
      SIMCTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN=true \
      SIMCTL_CHILD_MA_UI_TEST_PROVISION_ONLY=true \
      xcrun simctl launch --terminate-running-process \
      "$SIMULATOR_ID" com.ia.ma >/dev/null; then
    unset token
    return 1
  fi
  unset token

  for _ in {1..100}; do
    [[ -f "$CREDENTIAL_READY_SENTINEL" \
        && ! -e "$CREDENTIAL_DELETED_SENTINEL" ]] && return 0
    sleep 0.1
  done
  printf 'The simulator app did not confirm private credential provisioning.\n' >&2
  return 1
}

validate_pair_result() {
  local pair_result="$1"
  local summary tests expected_count actual_ids expected_ids method

  if ! summary="$(xcrun xcresulttool get test-results summary \
      --path "$pair_result" --compact)"; then
    return 1
  fi
  case "$TEST_SELECTION" in
    MALiveUITests/GuidedProductionRealtimeUITests)
      expected_count=2
      expected_ids=$'GuidedProductionRealtimeUITests/testCompleteProductionRealtimeLessonInEnglish()\nGuidedProductionRealtimeUITests/testCompleteProductionRealtimeLessonInSpanish()'
      ;;
    MALiveUITests/GuidedProductionRealtimeUITests/*)
      expected_count=1
      method="${TEST_SELECTION##*/}"
      expected_ids="GuidedProductionRealtimeUITests/${method}()"
      ;;
    MAUITests/GuidedLiveAudioIntegrationUITests/*)
      expected_count=1
      method="${TEST_SELECTION##*/}"
      expected_ids="GuidedLiveAudioIntegrationUITests/${method}()"
      ;;
    *)
      return 1
      ;;
  esac

  if ! jq -e \
      --argjson expected "$expected_count" \
      '.result == "Passed"
       and .totalTestCount == $expected
       and .passedTests == $expected
       and .failedTests == 0
       and .skippedTests == 0
       and .expectedFailures == 0
       and (.devicesAndConfigurations | length) == 1
       and .devicesAndConfigurations[0].passedTests == $expected
       and .devicesAndConfigurations[0].failedTests == 0
       and .devicesAndConfigurations[0].skippedTests == 0
       and .devicesAndConfigurations[0].expectedFailures == 0
       and ([.statistics[]? | (.title // ""), (.subtitle // "")]
            | join(" ") | test("test runs"; "i") | not)' \
      <<<"$summary" >/dev/null; then
    printf 'Pair result counts do not match the exact release gate.\n' >&2
    return 1
  fi
  if ! tests="$(xcrun xcresulttool get test-results tests \
      --path "$pair_result" --compact)"; then
    return 1
  fi
  if ! actual_ids="$(jq -r \
      '.. | objects | select(.nodeType? == "Test Case") | .nodeIdentifier // empty' \
      <<<"$tests" | sort)"; then
    return 1
  fi
  expected_ids="$(printf '%s\n' "$expected_ids" | sort)"
  if [[ "$actual_ids" != "$expected_ids" ]]; then
    printf 'Pair result did not contain exactly the selected learner journey test identifiers.\n' >&2
    return 1
  fi
  printf '%s\n' "$summary"
}

result_path_for_pair() {
  local pair="$1"
  if (( ITERATIONS == 1 )); then
    printf '%s' "$RESULT_PATH"
  elif [[ "$RESULT_PATH" == *.xcresult ]]; then
    printf '%s-pair-%s.xcresult' "${RESULT_PATH%.xcresult}" "$pair"
  else
    printf '%s-pair-%s.xcresult' "$RESULT_PATH" "$pair"
  fi
}

log_path_for_pair() {
  local pair="$1"
  if (( ITERATIONS == 1 )); then
    printf '%s' "$LOG_PATH"
  elif [[ "$LOG_PATH" == *.log ]]; then
    printf '%s-pair-%s.log' "${LOG_PATH%.log}" "$pair"
  else
    printf '%s-pair-%s.log' "$LOG_PATH" "$pair"
  fi
}

delete_simulator_credential() {
  # XCTest may reinstall the app and replace its data-container UUID even for
  # test-without-building. Never verify a marker through the pre-test path.
  refresh_simulator_credential_paths || return 1
  # The post-XCTest container can be an older preserved container. Clear its
  # generic proof before launch so only this deletion attempt can satisfy the
  # gate.
  rm -f "$CREDENTIAL_DELETED_SENTINEL" || return 1
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

private_install_token >/dev/null || {
  printf 'The private product test credential is missing or invalid.\n' >&2
  exit 77
}

mkdir -p "$(dirname "$RESULT_PATH")" "$(dirname "$LOG_PATH")" "$DERIVED_DATA"
if (( ITERATIONS == 1 )); then
  rm -rf "$RESULT_PATH"
else
  rm -rf "$RESULT_PATH"
  rm -rf "${RESULT_PATH%.xcresult}"-pair-*.xcresult
  rm -f "${LOG_PATH%.log}"-pair-*.log
fi
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

# Xcode's -test-iterations keeps rapidly relaunching UI-test processes in one
# runner session. After enough launches, simulator AX can fail and securityd
# can return errSecMissingEntitlement (-34018) to later processes. That is not
# a product pass or a useful retry. Run each requested pair as an isolated
# XCTest invocation and bracket it with independently verified provisioning
# and deletion instead.
for (( pair = 1; pair <= ITERATIONS; pair++ )); do
  pair_result="$(result_path_for_pair "$pair")"
  pair_log="$(log_path_for_pair "$pair")"
  rm -rf "$pair_result"
  if (( ITERATIONS > 1 )); then
    : >"$pair_log"
  fi

  if ! provision_simulator_credential; then
    exit 78
  fi
  unset SIMCTL_CHILD_MA_INSTALL_TOKEN SIMCTL_CHILD_MA_UI_TEST_DELETE_INSTALL_TOKEN \
    SIMCTL_CHILD_MA_UI_TEST_PROVISION_ONLY
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
    -resultBundlePath "$pair_result" \
    >>"$pair_log" 2>&1

  if ! delete_simulator_credential; then
    printf 'Pair %s did not prove deletion of the simulator test credential. This run is not a passing release gate.\n' "$pair" >&2
    exit 80
  fi
  CREDENTIAL_CLEANUP_VERIFIED=true
  PROVISIONING_STARTED=false
  if ! validated_summary="$(validate_pair_result "$pair_result")"; then
    printf 'Pair %s did not satisfy the exact xcresult release contract.\n' \
      "$pair" >&2
    exit 81
  fi
  printf 'Verified simulator test-credential deletion for isolated pair %s/%s.\n' \
    "$pair" "$ITERATIONS"
  printf '%s\n' "$validated_summary"
done

printf 'Verified %s isolated live simulator pair(s) with credential cleanup after every pair.\n' \
  "$ITERATIONS"
