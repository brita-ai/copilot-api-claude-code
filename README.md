# Copilot API + Claude Code 一键安装

使用 GitHub Copilot 作为 Claude Code 的后端，**无需 Anthropic 账号**即可使用 Claude Code！

## ✨ 特性

- 🚀 一键安装所有依赖（Node.js、Claude Code、Copilot API）
- 🎯 **自动检测可用模型，支持自定义选择**
- ⚙️ 自动配置 `~/.claude/settings.json`
- 🔐 使用 GitHub Copilot 订阅，无需 Anthropic 账号
- 💻 支持 macOS、Linux、Windows

## 📋 前提条件

- 有效的 [GitHub Copilot](https://github.com/features/copilot) 订阅

## 🚀 一键安装

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/brita-ai/copilot-api-claude-code/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
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
| 4 | 运行 Copilot API 认证（需要 GitHub 登录） |
| 5 | **检测可用模型并让用户选择** |
| 6 | 配置 `~/.claude/settings.json` |
| 7 | **初始化 Claude Code（跳过登录）** |

### 模型选择

安装过程中，脚本会自动启动 Copilot API 服务获取可用模型列表，让你选择：

- **主模型 (MODEL)**: 用于主要的代码生成和对话任务
- **轻量模型 (SMALL_FAST_MODEL)**: 用于快速任务，如文件摘要、简单查询等

示例输出：
```
可用模型列表:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1) claude-3.5-sonnet
  2) claude-sonnet-4-20250514
  3) gpt-4.1
  4) gpt-4.1-mini
  5) o3-mini

【选择主模型 (MODEL)】
用于主要的代码生成和对话任务

请选择主模型 [1-5] (默认: 2):
```

## 🎯 使用方法

安装完成后，按以下步骤使用：

### 步骤 1: 启动 Copilot API 服务

```bash
npx copilot-api@latest start
```

### 步骤 2: 新开一个终端，运行 Claude Code

```bash
claude
```

> **提示**: Copilot API 服务需要保持运行，服务地址: `http://localhost:4141`

## ⚙️ 配置说明

安装完成后，配置会自动写入 `~/.claude/settings.json`，包含你选择的模型：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:4141",
    "ANTHROPIC_AUTH_TOKEN": "dummy",
    "ANTHROPIC_MODEL": "<你选择的主模型>",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "<你选择的主模型>",
    "ANTHROPIC_SMALL_FAST_MODEL": "<你选择的轻量模型>",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "<你选择的主模型>",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

## 🔄 更换模型

如果想更换模型，可以：

1. 重新运行安装脚本
2. 或手动编辑 `~/.claude/settings.json`

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

### 模型列表获取失败

如果无法获取模型列表，安装流程会中断。请检查：

1. Copilot API 认证是否成功
2. 网络连接是否正常

可尝试重新运行认证：
```bash
npx copilot-api@latest auth
```

## 📚 相关项目

- [copilot-api](https://github.com/ericc-ch/copilot-api) - 将 GitHub Copilot 转换为 OpenAI/Anthropic 兼容 API
- [Claude Code](https://code.claude.com) - Anthropic 的 AI 编程助手

## 📄 License

MIT
