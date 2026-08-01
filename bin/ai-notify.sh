#!/bin/bash
# AICodeBell - AI coding assistant desktop and remote notifications
# Usage: ai-notify.sh <tool> <state>
# tool: claude | codex
# state: ask | done

TOOL="$1"
STATE="$2"
DIR="${AI_NOTIFY_DIR:-$(basename "$PWD")}"
TTY="${AI_NOTIFY_TTY:-/dev/$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ')}"
NOTIFY_URL="${AI_NOTIFY_URL:-}"
if [ -z "$NOTIFY_URL" ] && [ -r "$HOME/.config/ai-code-bell/notify-url" ]; then
  NOTIFY_URL="$(head -n 1 "$HOME/.config/ai-code-bell/notify-url")"
fi
ALERTER_BIN="${AI_NOTIFY_ALERTER:-/usr/local/bin/alerter}"

# Codex Stop means a turn ended, not necessarily that a durable Goal finished.
# Suppress turn-level completion notices while a Goal is still active, and send
# exactly one notice after that Goal reaches the complete state.
if [ "$TOOL" = "codex" ] && [ "$STATE" = "done" ] && [ "${AI_NOTIFY_BACKGROUND:-}" != "1" ] && [ ! -t 0 ]; then
  HOOK_PAYLOAD="$(cat)"
  GOAL_INFO="$(AI_NOTIFY_HOOK_PAYLOAD="$HOOK_PAYLOAD" /usr/bin/python3 - "$HOME/.codex/goals_1.sqlite" 2>/dev/null <<'PY'
import json
import os
import sqlite3
import sys

db_path = sys.argv[1]
try:
    payload = json.loads(os.environ.get("AI_NOTIFY_HOOK_PAYLOAD", "{}"))
    session_id = payload.get("session_id") or payload.get("sessionId") or ""
    if not session_id:
        raise ValueError("missing session id")
    with sqlite3.connect(f"file:{db_path}?mode=ro", uri=True, timeout=1) as db:
        row = db.execute(
            "SELECT goal_id, status FROM thread_goals WHERE thread_id = ?",
            (session_id,),
        ).fetchone()
    if row:
        print(f"{row[1]}\t{row[0]}")
except Exception:
    pass
PY
)"

  GOAL_STATUS="${GOAL_INFO%%$'\t'*}"
  GOAL_ID="${GOAL_INFO#*$'\t'}"
  case "$GOAL_STATUS" in
    active|paused|blocked|usage_limited|budget_limited)
      exit 0
      ;;
    complete)
      MARKER_DIR="$HOME/.local/state/ai-notify/completed-goals"
      MARKER="$MARKER_DIR/$GOAL_ID"
      if [ -e "$MARKER" ]; then
        exit 0
      fi
      mkdir -p "$MARKER_DIR"
      : > "$MARKER"
      ;;
  esac
fi

if [ "${AI_NOTIFY_BACKGROUND:-}" != "1" ]; then
  AI_NOTIFY_BACKGROUND=1 AI_NOTIFY_DIR="$DIR" AI_NOTIFY_TTY="$TTY" \
    nohup "$0" "$TOOL" "$STATE" >/dev/null 2>&1 </dev/null &
  exit 0
fi

case "$STATE" in
  ask)  MSG="需要你的操作" ;;
  done) MSG="任务完成" ;;
  *)    MSG="$STATE" ;;
esac

case "$TOOL" in
  claude) TITLE="Claude Code" ;;
  codex)  TITLE="Codex" ;;
  *)      TITLE="$TOOL" ;;
esac

# Optionally send through a Raspberry Pi notification gateway. The endpoint is
# configurable so the public project does not require or assume one.
if [ -n "$NOTIFY_URL" ]; then
  /usr/bin/python3 - "$NOTIFY_URL" "$TOOL" "$STATE" "$DIR" >/dev/null 2>&1 <<'PY' &
import json
import sys
import urllib.request

url, tool, state, session = sys.argv[1:5]
payload = json.dumps({
    "tool": tool,
    "type": state,
    "session": session,
}).encode("utf-8")
req = urllib.request.Request(
    url,
    data=payload,
    headers={"Content-Type": "application/json"},
    method="POST",
)
try:
    urllib.request.urlopen(req, timeout=5).read()
except Exception:
    pass
PY
fi

if [ ! -x "$ALERTER_BIN" ]; then
  ALERTER_BIN="$(command -v alerter || true)"
fi
if [ -x "$ALERTER_BIN" ]; then
  RESULT=$("$ALERTER_BIN" --title "$TITLE | $DIR | $MSG" --message " " --timeout 10 --sound default --ignore-dnd 2>/dev/null)
else
  RESULT=""
  osascript -e "display notification \" \" with title \"$TITLE | $DIR | $MSG\"" >/dev/null 2>&1
fi

if [ "$RESULT" = "@CONTENTCLICKED" ] || [ "$RESULT" = "@ACTIONCLICKED" ]; then
  osascript -e "
    on run argv
      set targetTTY to item 1 of argv
      tell application \"Terminal\"
        activate
        repeat with w in windows
          repeat with t in tabs of w
            if tty of t is targetTTY then
              set selected of t to true
              set index of w to 1
              return
            end if
          end repeat
        end repeat
      end tell
    end run" "$TTY"
fi
