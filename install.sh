#!/bin/bash
# AICodeBell Installer
# 一键安装 AI 编码助手桌面通知

set -e

echo "=== AICodeBell 安装程序 ==="
echo ""

# 1. 检查 macOS
if [ "$(uname)" != "Darwin" ]; then
  echo "❌ AICodeBell 仅支持 macOS"
  exit 1
fi

# 2. 安装 alerter
if command -v alerter &>/dev/null; then
  echo "✓ alerter 已安装 ($(alerter --version))"
else
  echo "→ 安装 alerter..."
  if command -v brew &>/dev/null; then
    brew install vjeantet/tap/alerter
  else
    echo "→ 未检测到 Homebrew，使用手动下载..."
    curl -L "https://github.com/vjeantet/alerter/releases/download/v26.5/alerter-26.5.zip" -o /tmp/alerter.zip
    unzip -o /tmp/alerter.zip -d /tmp/alerter-extract
    sudo cp /tmp/alerter-extract/alerter /usr/local/bin/alerter
    sudo chmod +x /usr/local/bin/alerter
    rm -rf /tmp/alerter.zip /tmp/alerter-extract
  fi
  echo "✓ alerter 安装完成 ($(alerter --version))"
fi

# 3. 部署通知脚本
SCRIPT_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPT_DIR"

SCRIPT_SRC="$(cd "$(dirname "$0")" && pwd)/bin/ai-notify.sh"
if [ -f "$SCRIPT_SRC" ]; then
  cp "$SCRIPT_SRC" "$SCRIPT_DIR/ai-notify.sh"
else
  echo "❌ 未找到 bin/ai-notify.sh，请确保在项目根目录运行"
  exit 1
fi
chmod +x "$SCRIPT_DIR/ai-notify.sh"
echo "✓ 通知脚本已部署到 $SCRIPT_DIR/ai-notify.sh"

# 4. 提示配置
echo ""
echo "=== 安装完成 ==="
echo ""
echo "接下来请手动配置 hooks（或运行 ./configure.sh 自动配置）："
echo ""
echo "  Claude Code: ~/.claude/settings.json"
echo "  Codex:       ~/.codex/config.toml"
echo ""
echo "详见 README.md"
