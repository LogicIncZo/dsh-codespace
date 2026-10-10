#!/usr/bin/env bash
# Boot dsh web on 127.0.0.1:3080, fully detached from the lifecycle runner.
# Called (via setsid) from postStartCommand / dotfiles install.sh.
# On success, beacons {cs, repo, token} to the dsh-anywhere dashboard.
set -u

BEACON="${DSH_ANYWHERE_BEACON:-https://cashlessconsumer.zo.space/api/dsh-beacon}"

# dsh lands in an nvm bin dir; probe the known locations
for d in "$HOME/.nvm/versions/node"/*/bin /usr/local/share/nvm/versions/node/*/bin /usr/local/bin; do
  if [ -x "$d/dsh" ]; then export PATH="$d:$PATH"; break; fi
done
command -v dsh >/dev/null 2>&1 || exit 0

CS="${GITHUB_CODESPACE_NAME:-codespace}"
REPO="${GITHUB_REPOSITORY:-}"
PUB="https://$CS-3080.app.github.dev"
LOG="$HOME/dsh-web.log"

PATCH=""
[ -f "$HOME/.dsh/cc-models.yml" ] && PATCH="--patch $HOME/.dsh/cc-models.yml"

setsid nohup dsh web --host 127.0.0.1 --port 3080 --no-open \
  --public-url "$PUB" --trusted-host "$PUB" $PATCH \
  > "$LOG" 2>&1 < /dev/null &

TOK=""
for _ in $(seq 1 150); do
  TOK=$(grep -aoE 'token=[A-Za-z0-9_-]+' "$LOG" 2>/dev/null | head -1 | cut -d= -f2)
  [ -n "$TOK" ] && break
  sleep 3
done

curl -fsS -m 10 "$BEACON?cs=$CS&repo=$REPO&token=$TOK" >/dev/null 2>&1
exit 0
