#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

command -v rg >/dev/null || {
  printf 'ripgrep is required.\n' >&2
  exit 69
}

PATTERN="(-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|(sk-(proj-|svcacct-)?|gh[pousr]_)[A-Za-z0-9_-]{20,}|(OPENAI_API_KEY|CLOUDFLARE_API_TOKEN|CF_API_TOKEN|MA_INSTALL_TOKEN|MA_PRODUCT_INSTALL_TOKEN|PRODUCT_INSTALL_TOKEN|MA_SAFETY_SALT)[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9._~-]{20,}|[Aa]uthorization[[:space:]]*:[[:space:]]*[Bb]earer[[:space:]]+[A-Za-z0-9._~-]{20,})"
WORKING_ALLOWLIST='^services/session-broker/\.dev\.vars\.example:[0-9]+:(OPENAI_API_KEY|MA_INSTALL_TOKEN|MA_PRODUCT_INSTALL_TOKEN|MA_SAFETY_SALT)=replace-with-[a-z0-9-]+$'
HISTORY_ALLOWLIST='^[0-9a-f]{40}:services/session-broker/\.dev\.vars\.example:[0-9]+:(OPENAI_API_KEY|MA_INSTALL_TOKEN|MA_PRODUCT_INSTALL_TOKEN|MA_SAFETY_SALT)=replace-with-[a-z0-9-]+$'
WORKING_RAW="$(mktemp -t ma-secret-working.XXXXXX)"
WORKING_FINDINGS="$(mktemp -t ma-secret-working-findings.XXXXXX)"
HISTORY_RAW="$(mktemp -t ma-secret-history.XXXXXX)"
HISTORY_FINDINGS="$(mktemp -t ma-secret-history-findings.XXXXXX)"
EXTRA_RAW="$(mktemp -t ma-secret-extra.XXXXXX)"
FILE_LIST="$(mktemp -t ma-secret-files.XXXXXX)"
COMMIT_LIST="$(mktemp -t ma-secret-commits.XXXXXX)"
ERROR_LOG="$(mktemp -t ma-secret-errors.XXXXXX)"
trap 'rm -f "$WORKING_RAW" "$WORKING_FINDINGS" "$HISTORY_RAW" "$HISTORY_FINDINGS" "$EXTRA_RAW" "$FILE_LIST" "$COMMIT_LIST" "$ERROR_LOG"' EXIT

fail_scan() {
  printf 'Secret scan failed before completion (%s). No PASS recorded.\n' "$1" >&2
  exit 2
}

scan_path() {
  local path="$1"
  local output="$2"
  local status

  if rg -nI --no-heading --with-filename -e "$PATTERN" -- "$path" \
    >>"$output" 2>>"$ERROR_LOG"; then
    return
  else
    status=$?
  fi
  [[ "$status" == "1" ]] || fail_scan "ripgrep error"
}

filter_allowlist() {
  local raw="$1"
  local allowlist="$2"
  local output="$3"
  local status

  if grep -Ev "$allowlist" "$raw" >"$output" 2>>"$ERROR_LOG"; then
    return
  else
    status=$?
  fi
  [[ "$status" == "1" ]] || fail_scan "allow-list filter error"
}

git ls-files --cached --others --exclude-standard -z >"$FILE_LIST"
while IFS= read -r -d '' path; do
  [[ "$path" == "scripts/scan-secrets.sh" ]] && continue
  scan_path "$path" "$WORKING_RAW"
done <"$FILE_LIST"
filter_allowlist "$WORKING_RAW" "$WORKING_ALLOWLIST" "$WORKING_FINDINGS"

git rev-list --all >"$COMMIT_LIST"
while IFS= read -r commit; do
  if git grep -nIE "$PATTERN" "$commit" -- . \
    ':(exclude)scripts/scan-secrets.sh' >>"$HISTORY_RAW" 2>>"$ERROR_LOG"; then
    continue
  else
    status=$?
  fi
  [[ "$status" == "1" ]] || fail_scan "Git history scan error"
done <"$COMMIT_LIST"
filter_allowlist "$HISTORY_RAW" "$HISTORY_ALLOWLIST" "$HISTORY_FINDINGS"

for path in "$@"; do
  [[ -e "$path" ]] || fail_scan "extra scan path missing"
  scan_path "$path" "$EXTRA_RAW"
done

if [[ -s "$WORKING_FINDINGS" || -s "$HISTORY_FINDINGS" || -s "$EXTRA_RAW" ]]; then
  printf 'Potential secret material found. Values are intentionally redacted.\n' >&2
  if [[ -s "$WORKING_FINDINGS" ]]; then
    printf 'Current tracked/untracked paths:\n' >&2
    awk -F: '{print "  " $1 ":" $2}' "$WORKING_FINDINGS" | sort -u >&2
  fi
  if [[ -s "$HISTORY_FINDINGS" ]]; then
    printf 'Git history locations:\n' >&2
    awk -F: '{print "  " $1 ":" $2 ":" $3}' "$HISTORY_FINDINGS" | sort -u >&2
  fi
  if [[ -s "$EXTRA_RAW" ]]; then
    printf 'Additional staged input locations:\n' >&2
    awk -F: '{print "  " $1 ":" $2}' "$EXTRA_RAW" | sort -u >&2
  fi
  exit 1
fi

printf 'Secret scan passed: current tracked/untracked set, all reachable Git history, and %s additional staged input(s); only exact fixture placeholders allow-listed.\n' "$#"
