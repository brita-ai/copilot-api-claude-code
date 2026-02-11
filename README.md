# Copilot API + Claude Code 一键安装

使用 GitHub Copilot 作为 Claude Code 的后端，**无需 Anthropic 账号**即可使用 Claude Code！

## ✨ 特性

- 🚀 一键安装所有依赖（Node.js、Claude Code、Copilot API）
- ⚙️ 自动配置环境变量和 `~/.claude/settings.json`
- 🔐 使用 GitHub Copilot 订阅，无需 Anthropic 账号
- 💻 支持 macOS、Linux、Windows

## 📋 前提条件

- 有效的 [GitHub Copilot](https://github.com/features/copilot) 订阅

## 🚀 一键安装

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/brita-ai/copilot-api-claude-code/main/install.sh | bash
```

### Windows (PowerShell 管理员模式)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iwr -useb https://raw.githubusercontent.com/brita-ai/copilot-api-claude-code/main/install.ps1 | iex
```

## 📦 安装流程

脚本会自动完成以下步骤：

| 步骤 | 内容 |
|------|------|
| 1 | 安装 Node.js（如果未安装） |
| 2 | 验证 npx |
| 3 | 安装 Claude Code |
| 4 | 配置 `~/.claude/settings.json` |
| 5 | 配置 Shell 环境变量 |
| 6 | 运行 Copilot API 认证（需要 GitHub 登录） |
| 7 | 创建启动脚本 |

## 🎯 使用方法

### 推荐：一键启动

```bash
# macOS / Linux
~/start-all.sh

# 指定项目目录
~/start-all.sh /path/to/your/project
```

**Windows**: 双击桌面的 **"Claude Code (一键启动)"** 图标

### 分别启动

```bash
# 启动 Copilot API
~/start-copilot-api.sh

# 启动 Claude Code
~/start-claude-code.sh
```

## ⚙️ 配置说明

安装完成后，以下配置会自动生效：

### `~/.claude/settings.json`

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:4141",
    "ANTHROPIC_AUTH_TOKEN": "dummy",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-20250514",
    "ANTHROPIC_SMALL_FAST_MODEL": "gpt-4.1-mini",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gpt-4.1-mini",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

### 环境变量

| 变量 | 值 | 说明 |
|------|-----|------|
| `ANTHROPIC_BASE_URL` | `http://localhost:4141` | Copilot API 地址 |
| `ANTHROPIC_MODEL` | `claude-sonnet-4-20250514` | 主模型 |
| `ANTHROPIC_SMALL_FAST_MODEL` | `gpt-4.1-mini` | 轻量模型 |

## 📁 生成的文件

| 文件 | 说明 |
|------|------|
| `~/.claude/settings.json` | Claude Code 配置文件 |
| `~/start-all.sh` | 一键启动脚本 |
| `~/start-copilot-api.sh` | Copilot API 启动脚本 |
| `~/start-claude-code.sh` | Claude Code 启动脚本 |

## 🔧 故障排除

### Copilot API 认证失败

重新运行认证：

```bash
npx copilot-api@latest auth
```

### Claude Code 找不到命令

重启终端或运行：

```bash
source ~/.zshrc  # 或 source ~/.bashrc
```

### 端口 4141 被占用

```bash
# 查找占用进程
lsof -i :4141

# 结束进程
kill -9 <PID>
```

## 📚 相关项目

- [copilot-api](https://github.com/ericc-ch/copilot-api) - 将 GitHub Copilot 转换为 OpenAI/Anthropic 兼容 API
- [Claude Code](https://code.claude.com) - Anthropic 的 AI 编程助手

## 📄 License

MIT
