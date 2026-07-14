#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-status}"
DERIVED_DATA="${MA_DERIVED_DATA:-$ROOT_DIR/.build/device-derived-data}"
EVIDENCE_ROOT="${MA_DEVICE_EVIDENCE_DIR:-$ROOT_DIR/.build/device-evidence}"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$EVIDENCE_ROOT/$RUN_ID-$MODE"
DEVICE_JSON="$(mktemp -t ma-devices.XXXXXX.json)"
trap 'rm -f "$DEVICE_JSON"; unset DEVICECTL_CHILD_MA_INSTALL_TOKEN DEVICECTL_CHILD_MA_DEMO_MODE token' EXIT

usage() {
  printf '%s\n' \
    "Usage: scripts/device-ma.sh status|build-install|product|replay" \
    "  status         Discover the paired iPhone 17 Pro on iOS 27." \
    "  build-install  Generate, sign, build, and install MA." \
    "  product        Build/install, provision the private planner token, and launch." \
    "  replay         Build/install and launch the labeled no-live replay."
}

case "$MODE" in
  status|build-install|product|replay) ;;
  *) usage >&2; exit 64 ;;
esac

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

if [[ "$MATCH_COUNT" != "1" ]]; then
  printf 'Expected exactly one paired iPhone 17 Pro on iOS 27 with Developer Mode; found %s.\n' "$MATCH_COUNT" >&2
  jq -r '.result.devices[] | select(.hardwareProperties.deviceType == "iPhone") |
    "candidate: \(.hardwareProperties.marketingName // .hardwareProperties.productType) · iOS \(.deviceProperties.osVersionNumber) · developer=\(.deviceProperties.developerModeStatus // "unknown")"' \
    "$DEVICE_JSON" >&2
  exit 70
fi

DEVICE_ID="$(jq -r '.result.devices[] | select(
  .hardwareProperties.deviceType == "iPhone"
  and .hardwareProperties.marketingName == "iPhone 17 Pro"
  and (.deviceProperties.osVersionNumber | startswith("27."))
  and .deviceProperties.developerModeStatus == "enabled"
) | .identifier' "$DEVICE_JSON")"
DEVICE_NAME="$(jq -r --arg id "$DEVICE_ID" '.result.devices[] | select(.identifier == $id) | .hardwareProperties.marketingName' "$DEVICE_JSON")"
DEVICE_OS="$(jq -r --arg id "$DEVICE_ID" '.result.devices[] | select(.identifier == $id) | .deviceProperties.osVersionNumber' "$DEVICE_JSON")"

printf 'Discovered %s on iOS %s (runtime CoreDevice identifier: %s).\n' "$DEVICE_NAME" "$DEVICE_OS" "$DEVICE_ID"
if [[ "$MODE" == "status" ]]; then
  exit 0
fi

mkdir -p "$RUN_DIR" "$DERIVED_DATA"
cp "$DEVICE_JSON" "$RUN_DIR/devices.json"

cd "$ROOT_DIR"
xcodegen generate >"$RUN_DIR/xcodegen.log" 2>&1
xcodebuild build \
  -project MA.xcodeproj \
  -scheme MA \
  -configuration Debug \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  >"$RUN_DIR/build.log" 2>&1

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/MA.app"
[[ -d "$APP_PATH" ]] || {
  printf 'Signed app was not produced at %s\n' "$APP_PATH" >&2
  exit 66
}

xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  --json-output "$RUN_DIR/install.json" \
  --log-output "$RUN_DIR/install.log" \
  "$APP_PATH" >/dev/null
printf 'Built and installed com.ia.ma. Local evidence: %s\n' "$RUN_DIR"

if [[ "$MODE" == "build-install" ]]; then
  exit 0
fi

if [[ "$MODE" == "product" ]]; then
  token="$(security find-generic-password \
    -a private-product-install-token \
    -s com.ia.ma.learning-planner.deployment \
    -w)"
  [[ ${#token} -ge 32 ]] || {
    printf 'The deployment Keychain item is missing or invalid.\n' >&2
    exit 77
  }
  export DEVICECTL_CHILD_MA_INSTALL_TOKEN="$token"
else
  export DEVICECTL_CHILD_MA_DEMO_MODE="labeled-replay-no-live"
fi

xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  --terminate-existing \
  --json-output "$RUN_DIR/launch.json" \
  --log-output "$RUN_DIR/launch.log" \
  com.ia.ma >/dev/null

unset DEVICECTL_CHILD_MA_INSTALL_TOKEN DEVICECTL_CHILD_MA_DEMO_MODE token
printf 'Launched MA in %s mode. No credential value was logged.\n' "$MODE"
