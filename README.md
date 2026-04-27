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
- Fully local, zero network requests

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

## How It Works

```
Claude Code / Codex
    ↓ hook fires (Stop / Notification / PermissionRequest)
ai-notify.sh
    ├─ captures current tty (via $PPID)
    ├─ reads $PWD for project directory name
    ↓
alerter --title "Tool | Dir | Status" --timeout 10
    ↓
macOS Notification Center (stays 10s)
    ↓ user clicks
AppleScript activates the matching Terminal tab
```

## Requirements

- macOS 13.0+
- [alerter](https://github.com/vjeantet/alerter) v26+
- Terminal.app (click-to-jump relies on Terminal.app AppleScript support)

## License

MIT
