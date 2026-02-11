# ============================================
# Copilot API + Claude Code 一键安装脚本 (Windows PowerShell)
# https://github.com/brita-ai/copilot-api-claude-code
# ============================================

$ErrorActionPreference = "Stop"

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Copilot API + Claude Code 一键安装脚本"
Write-Host "   https://github.com/brita-ai/copilot-api-claude-code"
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [1] Copilot API: https://github.com/ericc-ch/copilot-api"
Write-Host "  [2] Claude Code: https://code.claude.com"
Write-Host ""
Write-Host "  本脚本会配置 Claude Code 使用 Copilot API 作为后端" -ForegroundColor Yellow
Write-Host "  无需 Anthropic 账号登录！" -ForegroundColor Yellow
Write-Host ""

# 检查命令是否存在
function Test-CommandExists {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# 刷新环境变量
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# 安装 Node.js
function Install-NodeJS {
    if (Test-CommandExists "node") {
        $nodeVersion = node -v
        Write-Success "Node.js 已安装: $nodeVersion"
        return
    }

    Write-Info "正在安装 Node.js..."

    # 方式1: 使用 winget (Windows 10 1709+ 自带)
    if (Test-CommandExists "winget") {
        Write-Info "使用 winget 安装 Node.js..."
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        Refresh-Path
    }
    # 方式2: 使用 Chocolatey
    elseif (Test-CommandExists "choco") {
        Write-Info "使用 Chocolatey 安装 Node.js..."
        choco install nodejs-lts -y
        Refresh-Path
    }
    # 方式3: 直接下载安装
    else {
        Write-Info "下载 Node.js 安装程序..."

        $nodeUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
        $installerPath = "$env:TEMP\node-installer.msi"

        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath

        Write-Info "正在安装 Node.js (可能需要管理员权限)..."
        Start-Process msiexec.exe -ArgumentList "/i", $installerPath, "/quiet", "/norestart" -Wait

        Refresh-Path
        Remove-Item $installerPath -Force
    }

    # 验证安装
    if (Test-CommandExists "node") {
        Write-Success "Node.js 安装完成: $(node -v)"
    } else {
        Write-Err "Node.js 安装失败"
        Write-Warn "请手动从 https://nodejs.org 下载安装，然后重新运行此脚本"
        Read-Host "按回车键退出"
        exit 1
    }
}

# 验证 npx
function Verify-Npx {
    if (Test-CommandExists "npx") {
        Write-Success "npx 已就绪: $(npx -v)"
    } else {
        Write-Err "npx 不可用，请检查 Node.js 安装"
        exit 1
    }
}

# 安装 Claude Code
function Install-ClaudeCode {
    if (Test-CommandExists "claude") {
        Write-Success "Claude Code 已安装"
        return
    }

    Write-Info "正在安装 Claude Code..."

    # 方式1: 使用 winget
    if (Test-CommandExists "winget") {
        Write-Info "使用 winget 安装 Claude Code..."
        winget install Anthropic.ClaudeCode --accept-package-agreements --accept-source-agreements
        Refresh-Path
    }
    # 方式2: 使用官方安装脚本
    else {
        Write-Info "使用官方脚本安装 Claude Code..."
        Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
        Refresh-Path
    }

    if (Test-CommandExists "claude") {
        Write-Success "Claude Code 安装完成"
    } else {
        Write-Warn "Claude Code 安装可能需要重启 PowerShell 才能生效"
    }
}

# 配置 Claude Code settings.json
function Configure-ClaudeSettings {
    Write-Info "配置 Claude Code settings.json..."

    $claudeDir = "$env:USERPROFILE\.claude"
    $settingsFile = "$claudeDir\settings.json"

    # 创建 .claude 目录
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
        Write-Info "创建目录: $claudeDir"
    }

    # 备份原配置文件
    if (Test-Path $settingsFile) {
        $backupFile = "${settingsFile}.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $settingsFile $backupFile
        Write-Info "已备份原配置文件"
    }

    # 写入新配置
    $settings = @{
        env = @{
            ANTHROPIC_BASE_URL = "http://localhost:4141"
            ANTHROPIC_AUTH_TOKEN = "dummy"
            ANTHROPIC_MODEL = "claude-sonnet-4-20250514"
            ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-20250514"
            ANTHROPIC_SMALL_FAST_MODEL = "gpt-4.1-mini"
            ANTHROPIC_DEFAULT_HAIKU_MODEL = "gpt-4.1-mini"
            DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1"
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
        }
    }

    $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding UTF8

    Write-Success "已写入配置: $settingsFile"
}

# 运行 Copilot API 认证
function Run-CopilotAuth {
    Write-Info "正在运行 copilot-api 认证..."
    Write-Host ""
    Write-Host "请按照提示完成 GitHub Copilot 认证" -ForegroundColor Yellow
    Write-Host ""
    npx copilot-api@latest auth
    Write-Host ""
    Write-Success "Copilot API 认证完成"
}

# 显示总结
function Show-Summary {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "              安装完成！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "【使用方法】" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  步骤 1: 启动 Copilot API 服务" -ForegroundColor Green
    Write-Host ""
    Write-Host "          npx copilot-api@latest start" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  步骤 2: 新开一个终端，在任意项目目录运行 Claude Code" -ForegroundColor Green
    Write-Host ""
    Write-Host "          claude" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "【配置文件】" -ForegroundColor Yellow
    Write-Host "  $env:USERPROFILE\.claude\settings.json"
    Write-Host ""
    Write-Host "【提示】" -ForegroundColor Yellow
    Write-Host "  - 使用 Copilot API 作为后端，无需 Anthropic 账号"
    Write-Host "  - Copilot API 服务需要保持运行"
    Write-Host "  - 服务地址: http://localhost:4141"
    Write-Host ""
}

# 主流程
function Main {
    Write-Host ""

    # 步骤 1: 安装 Node.js
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 1/5: 安装 Node.js"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Install-NodeJS
    Write-Host ""

    # 步骤 2: 验证 npx
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 2/5: 验证 npx"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Verify-Npx
    Write-Host ""

    # 步骤 3: 安装 Claude Code
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 3/5: 安装 Claude Code"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Install-ClaudeCode
    Write-Host ""

    # 步骤 4: 配置 Claude Code settings.json
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 4/5: 配置 Claude Code settings.json"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Configure-ClaudeSettings
    Write-Host ""

    # 步骤 5: 运行 Copilot API 认证
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 5/5: 运行 Copilot API 认证"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Run-CopilotAuth
    Write-Host ""

    # 显示总结
    Show-Summary
}

Main
