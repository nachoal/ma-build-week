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
FILE_LIST="$(mktemp -t ma-secret-files.XXXXXX)"
trap 'rm -f "$WORKING_RAW" "$WORKING_FINDINGS" "$HISTORY_RAW" "$HISTORY_FINDINGS" "$FILE_LIST"' EXIT

git ls-files --cached --others --exclude-standard -z >"$FILE_LIST"
if [[ -s "$FILE_LIST" ]]; then
  xargs -0 rg -nI --no-heading --with-filename -e "$PATTERN" \
    --glob '!scripts/scan-secrets.sh' \
    -- <"$FILE_LIST" >"$WORKING_RAW" || true
fi
grep -Ev "$WORKING_ALLOWLIST" "$WORKING_RAW" >"$WORKING_FINDINGS" || true

while IFS= read -r commit; do
  git grep -nIE "$PATTERN" "$commit" -- . \
    ':(exclude)scripts/scan-secrets.sh' >>"$HISTORY_RAW" 2>/dev/null || true
done < <(git rev-list --all)
grep -Ev "$HISTORY_ALLOWLIST" "$HISTORY_RAW" >"$HISTORY_FINDINGS" || true

if [[ -s "$WORKING_FINDINGS" || -s "$HISTORY_FINDINGS" ]]; then
  printf 'Potential secret material found. Values are intentionally redacted.\n' >&2
  if [[ -s "$WORKING_FINDINGS" ]]; then
    printf 'Current tracked/untracked paths:\n' >&2
    awk -F: '{print "  " $1 ":" $2}' "$WORKING_FINDINGS" | sort -u >&2
  fi
  if [[ -s "$HISTORY_FINDINGS" ]]; then
    printf 'Git history locations:\n' >&2
    awk -F: '{print "  " $1 ":" $2 ":" $3}' "$HISTORY_FINDINGS" | sort -u >&2
  fi
  exit 1
fi

printf 'Secret scan passed: current tracked/untracked set and all reachable Git history; only explicit fixture/placeholders allow-listed.\n'
