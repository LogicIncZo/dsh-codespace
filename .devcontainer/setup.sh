#!/usr/bin/env bash
# Codespaces postCreate: install dsh, generate the Zen+ZAI patch, add wrappers.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing dsh (npm @deepseek-ai/dsh)"
npm install -g @deepseek-ai/dsh@0.2.1-alpha.1
dsh --version

mkdir -p "$HOME/.dsh" "$HOME/.local/bin"

echo "==> Generating provider patch (OpenCode Zen + Z.AI)"
bash "$HERE/../scripts/gen-models-patch.sh" "$HOME/.dsh/cc-models.yml"

echo "==> Writing wrappers: dshcc (interactive TUI), dshrun (headless one-shot)"
cat > "$HOME/.local/bin/dshcc" <<'EOF'
#!/usr/bin/env bash
# Interactive dsh TUI with the Zen+ZAI provider patch.
exec dsh tui --patch "$HOME/.dsh/cc-models.yml" "$@"
EOF
cat > "$HOME/.local/bin/dshrun" <<'EOF'
#!/usr/bin/env bash
# One-shot headless dsh with the Zen+ZAI patch. Full access is safe in a
# disposable Codespace and required for headless (no approval channel).
export DSH_PERMISSION_MODE="${DSH_PERMISSION_MODE:-danger-full-access}"
exec dsh --profile headless --patch "$HOME/.dsh/cc-models.yml" "$@"
EOF
chmod +x "$HOME/.local/bin/dshcc" "$HOME/.local/bin/dshrun"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) grep -qs 'HOME/.local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" ;;
esac

echo "==> Credential check"
STATUS=0
for k in OPENCODE_ZEN_API_KEY ZAI_API_KEY; do
  if [[ -n "${!k:-}" ]]; then
    echo "    $k: set"
  else
    echo "    $k: MISSING — add it as a Codespaces secret (Settings → Secrets → Codespaces) and rebuild, or the ${k%%_API_KEY} route fails with MISSING_CREDENTIAL"
    STATUS=1
  fi
done

echo
echo "Done. Quick start:"
echo "  dshcc                          # interactive TUI (zen + zai models)"
echo "  dshrun \"fix the failing test\"  # one-shot headless task"
echo "  bash scripts/smoke.sh          # live check of both providers"
exit $STATUS
