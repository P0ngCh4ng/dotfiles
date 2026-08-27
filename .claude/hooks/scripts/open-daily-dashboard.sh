#!/usr/bin/env bash
# SessionStart hook: once per calendar day, ensure the project dashboard
# server is running and open it in the browser.
#
# "Once per day" is enforced by a date-stamped marker file. The first Claude
# Code session started on any given day (in any directory) opens the dashboard;
# every later session that day is a no-op. Registered in .claude/settings.json
# under hooks.SessionStart and run async so it never delays session startup.
set -u

DOTFILES_DIR="$HOME/dotfiles"
DASH_DIR="$DOTFILES_DIR/.dashboard"
MARKER="$DASH_DIR/.last-opened"
SCRIPT="$DOTFILES_DIR/bin/generate-project-dashboard"
PORT=9797
URL="http://localhost:${PORT}/"
TODAY="$(date +%Y-%m-%d)"

mkdir -p "$DASH_DIR"

# Already opened today? Nothing to do.
if [[ -f "$MARKER" && "$(cat "$MARKER" 2>/dev/null)" == "$TODAY" ]]; then
  exit 0
fi

# Ensure the server is listening; start it detached if not (same liveness
# check the dashboard itself uses -- ask the OS which ports are LISTENing).
if ! lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  if [[ -x "$SCRIPT" ]] && command -v python3 >/dev/null 2>&1; then
    nohup python3 "$SCRIPT" --serve --port "$PORT" >"$DASH_DIR/serve.log" 2>&1 &
    disown 2>/dev/null || true
    # Give it a moment to bind before we open the browser.
    for _ in 1 2 3 4 5 6; do
      lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1 && break
      sleep 0.5
    done
  fi
fi

open "$URL" >/dev/null 2>&1 || true

# Record today's date only after a successful open attempt so a failed launch
# (e.g. python3 missing) retries on the next session instead of silently
# marking the day done.
echo "$TODAY" > "$MARKER"

printf '{"systemMessage": "\360\237\223\212 Opened project dashboard for today: %s"}\n' "$URL"
exit 0
