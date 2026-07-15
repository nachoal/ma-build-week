#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKET_DIR="${MA_SUBMISSION_DIR:-$ROOT_DIR/.build/submission}"
APP_PATH="$PACKET_DIR/MA.xcarchive/Products/Applications/MA.app"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
EVIDENCE_DIR="${MA_DEVICE_EVIDENCE_DIR:-$ROOT_DIR/.build/device-evidence}/$RUN_ID-release-product"
DEVICE_JSON="$(mktemp -t ma-release-devices.XXXXXX.json)"
LOCK_JSON="$(mktemp -t ma-release-lock.XXXXXX.json)"
RAW_LAUNCH_JSON="$(mktemp -t ma-release-provision.XXXXXX.json)"
RAW_LAUNCH_LOG="$(mktemp -t ma-release-provision.XXXXXX.log)"
FILES_JSON="$(mktemp -t ma-release-files.XXXXXX.json)"
INSTALL_VERIFIED=false

cleanup() {
  local original_status=$?
  trap - EXIT
  unset DEVICECTL_CHILD_MA_INSTALL_TOKEN DEVICECTL_CHILD_MA_INSTALL_PROVISION_NONCE
  unset token nonce
  rm -f "$DEVICE_JSON" "$LOCK_JSON" "$RAW_LAUNCH_JSON" \
    "$RAW_LAUNCH_LOG" "$FILES_JSON"
  if [[ "$INSTALL_VERIFIED" != "true" && -d "$EVIDENCE_DIR" ]]; then
    rm -rf "$EVIDENCE_DIR"
  fi
  exit "$original_status"
}
trap cleanup EXIT

for command in jq security shasum uuidgen; do
  command -v "$command" >/dev/null || {
    printf 'Missing required command: %s\n' "$command" >&2
    exit 69
  }
done

cd "$ROOT_DIR"
[[ -z "$(git status --porcelain=v1 --untracked-files=all)" ]] || {
  printf 'Refusing a final device install from a dirty tree.\n' >&2
  exit 65
}
[[ -d "$APP_PATH" && -f "$PACKET_DIR/GIT_COMMIT" \
    && -f "$PACKET_DIR/SHA256SUMS" ]] || {
  printf 'The verified submission archive is missing. Run scripts/archive-submission.sh first.\n' >&2
  exit 66
}

ARCHIVE_COMMIT="$(tr -d '\n' < "$PACKET_DIR/GIT_COMMIT")"
git cat-file -e "$ARCHIVE_COMMIT^{commit}" 2>/dev/null || {
  printf 'The archive does not identify a reachable Git commit.\n' >&2
  exit 66
}
git diff --quiet "$ARCHIVE_COMMIT" -- apps/MA project.yml || {
  printf 'Current product inputs differ from the archived commit. Rebuild the archive.\n' >&2
  exit 65
}
(cd "$PACKET_DIR" && shasum -a 256 -c SHA256SUMS >/dev/null)
codesign --verify --deep --strict "$APP_PATH"

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

xcrun devicectl device info lockState \
  --device "$DEVICE_ID" \
  --json-output "$LOCK_JSON" >/dev/null
[[ "$(jq -r '.result.passcodeRequired' "$LOCK_JSON")" == "false" ]] || {
  printf 'The paired iPhone is locked. Unlock it and immediately rerun this command.\n' >&2
  exit 71
}

token="$(security find-generic-password \
  -a private-product-install-token \
  -s com.ia.ma.learning-planner.deployment \
  -w)"
[[ ${#token} -ge 32 ]] || {
  printf 'The private product install credential is missing or invalid.\n' >&2
  exit 77
}
nonce="$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')"
[[ "$nonce" =~ ^[a-f0-9]{32}$ ]] || {
  printf 'Could not create the bounded provisioning nonce.\n' >&2
  exit 69
}
STORED_MARKER="ma-release-review-access-stored-$nonce"
READY_MARKER="ma-release-review-access-ready-$nonce"

mkdir -p "$EVIDENCE_DIR"
cp "$DEVICE_JSON" "$EVIDENCE_DIR/devices.json"
cp "$LOCK_JSON" "$EVIDENCE_DIR/lock-state.json"
cp "$PACKET_DIR/GIT_COMMIT" "$EVIDENCE_DIR/archive-commit"

xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  --json-output "$EVIDENCE_DIR/install.json" \
  --log-output "$EVIDENCE_DIR/install.log" \
  "$APP_PATH" >/dev/null

export DEVICECTL_CHILD_MA_INSTALL_TOKEN="$token"
export DEVICECTL_CHILD_MA_INSTALL_PROVISION_NONCE="$nonce"
xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  --terminate-existing \
  --json-output "$RAW_LAUNCH_JSON" \
  --log-output "$RAW_LAUNCH_LOG" \
  com.ia.ma >/dev/null

# CoreDevice can serialize launch environment values into its result. Destroy
# those raw files and the parent-shell credential immediately after launch;
# no polling subprocess may inherit the bearer token.
rm -f "$RAW_LAUNCH_JSON" "$RAW_LAUNCH_LOG"
unset DEVICECTL_CHILD_MA_INSTALL_TOKEN DEVICECTL_CHILD_MA_INSTALL_PROVISION_NONCE
unset token

stored=false
for _ in {1..150}; do
  rm -f "$FILES_JSON"
  if xcrun devicectl device info files \
      --device "$DEVICE_ID" \
      --domain-type appDataContainer \
      --domain-identifier com.ia.ma \
      --subdirectory Documents \
      --json-output "$FILES_JSON" >/dev/null 2>&1 \
    && jq -e --arg marker "$STORED_MARKER" \
      '.. | strings | select(endswith($marker))' "$FILES_JSON" >/dev/null; then
    stored=true
    break
  fi
  sleep 0.1
done
[[ "$stored" == "true" ]] || {
  printf 'The Release app did not verify exact Keychain credential readback.\n' >&2
  exit 79
}

# A second launch receives only the random, non-secret nonce. It must load the
# credential from Keychain and complete broker mint + WebSocket session.created
# policy verification before the app can create the ready receipt.
export DEVICECTL_CHILD_MA_INSTALL_PROVISION_NONCE="$nonce"
xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  --terminate-existing \
  --json-output "$EVIDENCE_DIR/verification-launch.json" \
  --log-output "$EVIDENCE_DIR/verification-launch.log" \
  com.ia.ma >/dev/null
unset DEVICECTL_CHILD_MA_INSTALL_PROVISION_NONCE

verified=false
for _ in {1..200}; do
  rm -f "$FILES_JSON"
  if xcrun devicectl device info files \
      --device "$DEVICE_ID" \
      --domain-type appDataContainer \
      --domain-identifier com.ia.ma \
      --subdirectory Documents \
      --json-output "$FILES_JSON" >/dev/null 2>&1 \
    && jq -e --arg marker "$READY_MARKER" \
      '.. | strings | select(endswith($marker))' "$FILES_JSON" >/dev/null \
    && ! jq -e --arg marker "$STORED_MARKER" \
      '.. | strings | select(endswith($marker))' "$FILES_JSON" >/dev/null; then
    verified=true
    break
  fi
  sleep 0.1
done
[[ "$verified" == "true" ]] || {
  printf 'The credential-free Release launch did not verify a private Realtime session.\n' >&2
  exit 79
}

unset nonce

xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  --terminate-existing \
  --json-output "$EVIDENCE_DIR/launch.json" \
  --log-output "$EVIDENCE_DIR/launch.log" \
  com.ia.ma >/dev/null
PID="$(jq -r '.result.process.processIdentifier' "$EVIDENCE_DIR/launch.json")"
[[ "$PID" =~ ^[0-9]+$ ]] || {
  printf 'The normally relaunched Release app returned no process identifier.\n' >&2
  exit 72
}

receipt_removed=false
for _ in {1..50}; do
  rm -f "$FILES_JSON"
  if xcrun devicectl device info files \
      --device "$DEVICE_ID" \
      --domain-type appDataContainer \
      --domain-identifier com.ia.ma \
      --subdirectory Documents \
      --json-output "$FILES_JSON" >/dev/null 2>&1 \
    && ! jq -e --arg ready "$READY_MARKER" \
      '.. | strings | select(endswith($ready))' "$FILES_JSON" >/dev/null \
    && ! jq -e --arg stored "$STORED_MARKER" \
      '.. | strings | select(endswith($stored))' "$FILES_JSON" >/dev/null; then
    receipt_removed=true
    break
  fi
  sleep 0.1
done
if [[ "$receipt_removed" != "true" ]]; then
  printf 'The value-free provisioning receipt was not removed on normal relaunch.\n' >&2
  exit 79
fi

PROCESS_JSON="$EVIDENCE_DIR/processes.json"
xcrun devicectl device info processes \
  --device "$DEVICE_ID" \
  --json-output "$PROCESS_JSON" >/dev/null
jq -e --argjson pid "$PID" \
  '.result.runningProcesses[] | select(.processIdentifier == $pid)' \
  "$PROCESS_JSON" >/dev/null || {
  printf 'The Release app was not running after its credential-free relaunch.\n' >&2
  exit 72
}

VERIFICATION_TMP="$EVIDENCE_DIR/.verification.json.tmp"
jq -n \
  --arg archiveCommit "$ARCHIVE_COMMIT" \
  --arg device "iPhone 17 Pro" \
  --arg osVersion "$DEVICE_OS" \
  --argjson processIdentifier "$PID" \
  '{
    archive_commit: $archiveCommit,
    device: $device,
    os_version: $osVersion,
    process_identifier: $processIdentifier,
    keychain_readback_verified: true,
    credential_free_realtime_session_verified: true,
    normal_relaunch_verified: true,
    retained_credential_value: false
  }' >"$VERIFICATION_TMP"
scripts/scan-secrets.sh "$EVIDENCE_DIR"
mv "$VERIFICATION_TMP" "$EVIDENCE_DIR/VERIFIED.json"
INSTALL_VERIFIED=true
printf 'Installed archived commit %s on iPhone 17 Pro/iOS %s; verified Keychain readback, a policy-checked Realtime session, and normal relaunch as PID %s.\n' \
  "$ARCHIVE_COMMIT" "$DEVICE_OS" "$PID"
printf 'Value-free local evidence: %s\n' "$EVIDENCE_DIR"
