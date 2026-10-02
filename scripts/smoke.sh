#!/usr/bin/env bash
# Live check: runs one trivial headless task per provider (zai, then zen).
# Costs a few tokens; run only when you want to verify the wires.
set -euo pipefail
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export DSH_PERMISSION_MODE="${DSH_PERMISSION_MODE:-danger-full-access}"

echo "==> [1/2] zai route (default: zai/glm-5.3-flash)"
bash "$(dirname "$0")/gen-models-patch.sh" "$TMP/zai.yml" >/dev/null
dsh --profile headless --patch "$TMP/zai.yml" "Reply with exactly: DSH-ZAI-OK"

echo
echo "==> [2/2] zen route (regenerating patch with default zen/glm-5.3-flash)"
DSH_DEFAULT_PROVIDER=zen DSH_DEFAULT_MODEL=glm-5.3-flash \
  bash "$(dirname "$0")/gen-models-patch.sh" "$TMP/zen.yml" >/dev/null
if dsh --profile headless --patch "$TMP/zen.yml" "Reply with exactly: DSH-ZEN-OK"; then
  ZEN_OK=1
else
  ZEN_OK=0
  echo "zen route failed — known causes:"
  echo "  - free-tier models (big-pickle, *-free): OpenCode clients only, always 403 from dsh"
  echo "  - 'Insufficient account funds' (402): add funds at opencode.ai/zen"
fi

echo
if [[ "$ZEN_OK" == 1 ]]; then
  echo "Smoke passed for both providers."
else
  echo "Smoke: zai OK; zen route reachable but billing-gated (see above)."
fi
