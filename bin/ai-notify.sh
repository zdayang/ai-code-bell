#!/bin/bash
# AICodeBell — AI 编码助手桌面通知
# Usage: ai-notify.sh <tool> <state>
# tool: claude | codex
# state: ask | done

TOOL="$1"
STATE="$2"
DIR=$(basename "$PWD")
TTY="/dev/$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ')"

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

# 发送通知，点击后跳转到对应 Terminal tab
RESULT=$(alerter --title "$TITLE | $DIR | $MSG" --message " " --timeout 10 --sound default 2>/dev/null)

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
