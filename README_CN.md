# AICodeBell

AI 编码助手的桌面通知。当 Claude Code 或 Codex 完成任务、需要你操作时，macOS 右上角弹出通知。点击通知直接跳转到对应 Terminal tab。

![AICodeBell 通知效果](./ai-code-bell.jpg)

> 灵感来源：[stick-s3-ai-alert](https://github.com/zdayang/stick-s3-ai-alert)（BLE 硬件方案）。AICodeBell 是其纯软件替代，只需 macOS + [alerter](https://github.com/vjeantet/alerter)。

[English](./README.md)

## 特性

- 右上角系统通知，停留 10 秒，带提示音，不阻塞操作
- 点击通知自动跳转到对应的 Terminal tab
- 通过目录名区分多个并行会话
- 支持 Claude Code 和 Codex
- 能识别 Codex 长期 Goal：运行中的阶段性 `Stop` 不再误报完成
- 默认纯本地运行，也可选择配置 HTTP 通知桥

## 通知效果

```
Claude Code | my-project | 任务完成
Claude Code | my-project | 需要你的操作
Codex | my-project | 任务完成
Codex | my-project | 需要你的审批
```

## 用 AI 安装（推荐）

把下面这句话发给你的 AI 编码助手（Claude Code、Codex 等）：

```
克隆 https://github.com/zdayang/ai-code-bell，然后执行 ./install.sh && ./configure.sh 安装桌面通知。
```

## 手动安装

```bash
chmod +x install.sh configure.sh
./install.sh
./configure.sh
```

然后重启 Claude Code 和 Codex。

### 可选 HTTP 通知桥

设置环境变量 `AI_NOTIFY_URL`，或者将地址写在这个文件的第一行：

```text
~/.config/ai-code-bell/notify-url
```

脚本会发送只包含 `tool`、`type` 和当前项目目录的 JSON。两者都没有配置时，不会发起网络请求。

## 详细手动安装

### 1. 安装 alerter

```bash
# Homebrew
brew install vjeantet/tap/alerter

# 或手动下载
curl -L "https://github.com/vjeantet/alerter/releases/download/v26.5/alerter-26.5.zip" -o /tmp/alerter.zip
unzip -o /tmp/alerter.zip -d /tmp/alerter-extract
cp /tmp/alerter-extract/alerter /usr/local/bin/alerter
chmod +x /usr/local/bin/alerter
```

### 2. 部署通知脚本

```bash
mkdir -p ~/.local/bin
cp bin/ai-notify.sh ~/.local/bin/ai-notify.sh
chmod +x ~/.local/bin/ai-notify.sh
```

### 3. 配置 Claude Code

在 `~/.claude/settings.json` 中添加：

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          { "type": "command", "command": "~/.local/bin/ai-notify.sh claude ask" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "~/.local/bin/ai-notify.sh claude done" }
        ]
      }
    ]
  }
}
```

### 4. 配置 Codex

在 `~/.codex/config.toml` 中添加：

```toml
[features]
hooks = true

[[hooks.PermissionRequest]]
matcher = ".*"
[[hooks.PermissionRequest.hooks]]
type = "command"
command = "~/.local/bin/ai-notify.sh codex ask"
timeout = 10
statusMessage = "发送桌面通知"

[[hooks.Stop]]
[[hooks.Stop.hooks]]
type = "command"
command = "~/.local/bin/ai-notify.sh codex done"
timeout = 10
statusMessage = "发送桌面通知"
```

### 5. 重启

重启 Claude Code 和 Codex 使配置生效。

## 原理

```
Claude Code / Codex
    ↓ hook 触发（Stop / Notification / PermissionRequest）
ai-notify.sh
    ├─ 记录当前 tty（通过 $PPID 获取）
    ├─ 读取 $PWD 获取项目目录名
    ├─ Codex Goal 尚未完成时抑制阶段性 Stop 通知
    ├─ 可选发送到 HTTP 通知桥
    ↓
alerter --title "工具 | 目录 | 状态" --timeout 10
    ↓
macOS 右上角通知（停留 10 秒）
    ↓ 用户点击
AppleScript 激活对应 Terminal tab
```

## 要求

- macOS 13.0+
- [alerter](https://github.com/vjeantet/alerter) v26+
- Terminal.app（点击跳转功能依赖 Terminal.app 的 AppleScript 支持）

## 关于 alerter

| 维度 | 说明 |
|------|------|
| 开源 | [github.com/vjeantet/alerter](https://github.com/vjeantet/alerter) |
| 协议 | MIT |
| 功能 | 纯本地，零网络请求，仅调用 macOS UserNotifications API |
| 安全 | Apple 公证签名，公司环境可放心使用 |

## 项目结构

```
ai-code-bell/
├── bin/
│   └── ai-notify.sh    # 核心通知脚本
├── install.sh          # 一键安装
├── configure.sh        # 自动配置 hooks
├── LICENSE
├── README.md           # English
└── README_CN.md        # 中文
```

## License

MIT
