# AICodeBell

Desktop notifications for AI coding assistants. Get notified in macOS Notification Center when Claude Code or Codex finishes a task or needs your input. Click the notification to jump directly to the corresponding Terminal tab.

![AICodeBell notification](./ai-code-bell.jpg)

> Inspired by [stick-s3-ai-alert](https://github.com/zdayang/stick-s3-ai-alert) (BLE hardware approach). AICodeBell is a pure-software alternative — no hardware, no network, just macOS + [alerter](https://github.com/vjeantet/alerter).

[中文文档](./README_CN.md)

## Features

- Native macOS notifications with sound, stays for 10 seconds
- Click notification to jump to the corresponding Terminal tab
- Distinguish multiple parallel sessions by directory name
- Supports Claude Code and Codex
- Goal-aware Codex notifications: active long-running Goals stay quiet until
  their real `complete` state
- Optional native Codex notification gate for the same Goal-aware behavior
- Fully local by default; an optional HTTP notification bridge can be configured

## Install with AI (Recommended)

Copy the following prompt to your AI coding assistant (Claude Code, Codex, etc.):

```
Clone https://github.com/zdayang/ai-code-bell, then run ./install.sh && ./configure.sh to set up desktop notifications.
```

## Manual Install

```bash
chmod +x install.sh configure.sh
./install.sh
./configure.sh
```

Then restart Claude Code and Codex.

### Optional HTTP notification bridge

Set `AI_NOTIFY_URL`, or put the endpoint on the first line of:

```text
~/.config/ai-code-bell/notify-url
```

The script sends a small JSON payload containing `tool`, `type`, and the current
project directory. Without either setting, no network request is made.

## How It Works

```
Claude Code / Codex
    ↓ hook fires (Stop / Notification / PermissionRequest)
ai-notify.sh
    ├─ captures current tty (via $PPID)
    ├─ reads $PWD for project directory name
    ├─ suppresses Stop notifications while a Codex Goal is still active
    ├─ optionally posts to an HTTP notification bridge
    ↓
alerter --title "Tool | Dir | Status" --timeout 10
    ↓
macOS Notification Center (stays 10s)
    ↓ user clicks
AppleScript activates the matching Terminal tab
```

For Codex's own `notify` command, put `codex-native-notify.py` before the native
notification client. The wrapper forwards ordinary task notifications, suppresses
incomplete Goal turns, and forwards the first notification after Goal completion.

## Requirements

- macOS 13.0+
- [alerter](https://github.com/vjeantet/alerter) v26+
- Terminal.app (click-to-jump relies on Terminal.app AppleScript support)

## License

MIT
