#!/bin/bash
# AICodeBell 自动配置脚本
# 将 hooks 写入 Claude Code 和 Codex 的配置文件

set -e

NOTIFY_CMD="$HOME/.local/bin/ai-notify.sh"

if [ ! -x "$NOTIFY_CMD" ]; then
  echo "❌ 请先运行 ./install.sh"
  exit 1
fi

echo "=== AICodeBell 配置程序 ==="
echo ""

# --- Claude Code ---
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

if [ -f "$CLAUDE_SETTINGS" ]; then
  if grep -q "ai-notify.sh" "$CLAUDE_SETTINGS" 2>/dev/null; then
    echo "✓ Claude Code hooks 已配置"
  else
    echo "→ 配置 Claude Code hooks..."
    # 使用 python3 安全地修改 JSON
    python3 -c "
import json, sys

path = '$CLAUDE_SETTINGS'
with open(path) as f:
    cfg = json.load(f)

cfg['hooks'] = {
    'Notification': [{'hooks': [{'type': 'command', 'command': '$NOTIFY_CMD claude ask'}]}],
    'Stop': [{'hooks': [{'type': 'command', 'command': '$NOTIFY_CMD claude done'}]}]
}

with open(path, 'w') as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
    echo "✓ Claude Code hooks 已写入 $CLAUDE_SETTINGS"
  fi
else
  echo "⚠ 未找到 $CLAUDE_SETTINGS，跳过 Claude Code 配置"
fi

# --- Codex ---
CODEX_CONFIG="$HOME/.codex/config.toml"

if [ -f "$CODEX_CONFIG" ]; then
  if grep -q "ai-notify.sh" "$CODEX_CONFIG" 2>/dev/null; then
    echo "✓ Codex hooks 已配置"
  else
    echo "→ 配置 Codex hooks..."
    cat >> "$CODEX_CONFIG" << EOF

[features]
codex_hooks = true

[[hooks.PermissionRequest]]
matcher = ".*"
[[hooks.PermissionRequest.hooks]]
type = "command"
command = "$NOTIFY_CMD codex ask"
timeout = 10
statusMessage = "发送桌面通知"

[[hooks.Stop]]
[[hooks.Stop.hooks]]
type = "command"
command = "$NOTIFY_CMD codex done"
timeout = 10
statusMessage = "发送桌面通知"
EOF
    echo "✓ Codex hooks 已写入 $CODEX_CONFIG"
  fi
else
  echo "⚠ 未找到 $CODEX_CONFIG，跳过 Codex 配置"
fi

echo ""
echo "=== 配置完成 ==="
echo "请重启 Claude Code 和 Codex 使配置生效。"
