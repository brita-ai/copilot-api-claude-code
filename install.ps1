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

# 配置系统环境变量 (备用)
function Configure-SystemEnv {
    Write-Info "配置系统环境变量 (备用)..."

    $envVars = @{
        "ANTHROPIC_BASE_URL" = "http://localhost:4141"
        "ANTHROPIC_AUTH_TOKEN" = "dummy"
        "ANTHROPIC_MODEL" = "claude-sonnet-4-20250514"
        "ANTHROPIC_DEFAULT_SONNET_MODEL" = "claude-sonnet-4-20250514"
        "ANTHROPIC_SMALL_FAST_MODEL" = "gpt-4.1-mini"
        "ANTHROPIC_DEFAULT_HAIKU_MODEL" = "gpt-4.1-mini"
        "DISABLE_NON_ESSENTIAL_MODEL_CALLS" = "1"
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" = "1"
    }

    foreach ($key in $envVars.Keys) {
        $value = $envVars[$key]

        # 设置用户级环境变量
        [System.Environment]::SetEnvironmentVariable($key, $value, "User")

        # 同时设置当前会话
        Set-Item -Path "Env:$key" -Value $value
    }

    Write-Success "环境变量已配置到用户级别（永久生效）"
    Write-Info "  ANTHROPIC_BASE_URL = http://localhost:4141"
    Write-Info "  ANTHROPIC_MODEL = claude-sonnet-4-20250514"
    Write-Info "  ANTHROPIC_SMALL_FAST_MODEL = gpt-4.1-mini"
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

# 创建启动脚本
function Create-StartScripts {
    # Copilot API 启动脚本
    $copilotScript = "$env:USERPROFILE\start-copilot-api.bat"
    @"
@echo off
echo 正在启动 Copilot API...
echo 服务地址: http://localhost:4141
echo 按 Ctrl+C 停止服务
echo.
npx copilot-api@latest start
pause
"@ | Out-File -FilePath $copilotScript -Encoding ASCII
    Write-Success "Copilot API 启动脚本: $copilotScript"

    # Claude Code 启动脚本 (带环境变量)
    $claudeScript = "$env:USERPROFILE\start-claude-code.bat"
    @"
@echo off
REM Claude Code 环境变量配置
set ANTHROPIC_BASE_URL=http://localhost:4141
set ANTHROPIC_AUTH_TOKEN=dummy
set ANTHROPIC_MODEL=claude-sonnet-4-20250514
set ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-20250514
set ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1-mini
set ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-4.1-mini
set DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

echo Claude Code 配置:
echo   API 后端: %ANTHROPIC_BASE_URL%
echo   主模型:   %ANTHROPIC_MODEL%
echo   轻量模型: %ANTHROPIC_SMALL_FAST_MODEL%
echo.

if "%~1"=="" (
    claude
) else (
    cd /d "%~1"
    claude
)
pause
"@ | Out-File -FilePath $claudeScript -Encoding ASCII
    Write-Success "Claude Code 启动脚本: $claudeScript"

    # 一键启动脚本 (PowerShell)
    $allInOneScript = "$env:USERPROFILE\start-all.ps1"
    @'
# 一键启动 Copilot API + Claude Code

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   启动 Copilot API + Claude Code"
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Copilot API 是否已运行
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4141/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
    Write-Host "[OK] Copilot API 已在运行" -ForegroundColor Green
} catch {
    Write-Host "[*] 正在后台启动 Copilot API..." -ForegroundColor Yellow
    Start-Process -FilePath "npx" -ArgumentList "copilot-api@latest", "start" -WindowStyle Minimized

    Write-Host "    等待服务就绪" -NoNewline
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 1
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:4141/health" -TimeoutSec 1 -ErrorAction SilentlyContinue
            Write-Host ""
            Write-Host "[OK] Copilot API 启动成功" -ForegroundColor Green
            break
        } catch {
            Write-Host "." -NoNewline
        }
    }
    Write-Host ""
}

Write-Host ""

# 设置环境变量 (备用，settings.json 已配置)
$env:ANTHROPIC_BASE_URL = "http://localhost:4141"
$env:ANTHROPIC_AUTH_TOKEN = "dummy"
$env:ANTHROPIC_MODEL = "claude-sonnet-4-20250514"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-20250514"
$env:ANTHROPIC_SMALL_FAST_MODEL = "gpt-4.1-mini"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "gpt-4.1-mini"
$env:DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1"
$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"

Write-Host "[OK] 环境变量已配置" -ForegroundColor Green
Write-Host "    API 后端: $env:ANTHROPIC_BASE_URL"
Write-Host "    主模型:   $env:ANTHROPIC_MODEL"
Write-Host ""

# 切换到指定目录
if ($args[0]) {
    Set-Location $args[0]
}

Write-Host "正在启动 Claude Code..." -ForegroundColor Cyan
Write-Host ""

# 启动 Claude Code
claude
'@ | Out-File -FilePath $allInOneScript -Encoding UTF8
    Write-Success "一键启动脚本 (PowerShell): $allInOneScript"

    # 一键启动脚本 (Batch)
    $allInOneBat = "$env:USERPROFILE\start-all.bat"
    @"
@echo off
echo ============================================
echo    启动 Copilot API + Claude Code
echo ============================================
echo.

REM 设置环境变量
set ANTHROPIC_BASE_URL=http://localhost:4141
set ANTHROPIC_AUTH_TOKEN=dummy
set ANTHROPIC_MODEL=claude-sonnet-4-20250514
set ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-20250514
set ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1-mini
set ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-4.1-mini
set DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

echo [*] 正在后台启动 Copilot API...
start /min cmd /c "npx copilot-api@latest start"

echo [*] 等待服务就绪 (10秒)...
timeout /t 10 /nobreak > nul

echo [OK] 环境变量已配置
echo     API 后端: %ANTHROPIC_BASE_URL%
echo     主模型:   %ANTHROPIC_MODEL%
echo.

if "%~1"=="" (
    claude
) else (
    cd /d "%~1"
    claude
)
pause
"@ | Out-File -FilePath $allInOneBat -Encoding ASCII
    Write-Success "一键启动脚本 (Batch): $allInOneBat"

    # 创建桌面快捷方式
    $desktopPath = [Environment]::GetFolderPath("Desktop")

    try {
        $WshShell = New-Object -ComObject WScript.Shell

        # Copilot API 快捷方式
        $copilotShortcut = $WshShell.CreateShortcut("$desktopPath\Copilot API.lnk")
        $copilotShortcut.TargetPath = $copilotScript
        $copilotShortcut.WorkingDirectory = $env:USERPROFILE
        $copilotShortcut.Description = "启动 Copilot API 服务"
        $copilotShortcut.Save()

        # 一键启动快捷方式 (推荐)
        $allInOneShortcut = $WshShell.CreateShortcut("$desktopPath\Claude Code (一键启动).lnk")
        $allInOneShortcut.TargetPath = $allInOneBat
        $allInOneShortcut.WorkingDirectory = $env:USERPROFILE
        $allInOneShortcut.Description = "一键启动 Copilot API + Claude Code"
        $allInOneShortcut.Save()

        Write-Success "桌面快捷方式已创建"
    } catch {
        Write-Warn "创建桌面快捷方式失败，请手动运行启动脚本"
    }
}

# 显示总结
function Show-Summary {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "        安装完成！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "【推荐】一键启动（自动启动 Copilot API + Claude Code）：" -ForegroundColor Yellow
    Write-Host "  双击桌面的 'Claude Code (一键启动)' 图标"
    Write-Host "  或运行: $env:USERPROFILE\start-all.bat"
    Write-Host ""
    Write-Host "【分别启动】" -ForegroundColor Yellow
    Write-Host "  Copilot API: $env:USERPROFILE\start-copilot-api.bat"
    Write-Host "  Claude Code: $env:USERPROFILE\start-claude-code.bat"
    Write-Host ""
    Write-Host "【配置文件】" -ForegroundColor Yellow
    Write-Host "  Claude Code: $env:USERPROFILE\.claude\settings.json"
    Write-Host "  系统环境变量: 已配置到用户级别"
    Write-Host ""
    Write-Host "【环境变量配置】" -ForegroundColor Yellow
    Write-Host "  ANTHROPIC_BASE_URL = http://localhost:4141"
    Write-Host "  ANTHROPIC_MODEL = claude-sonnet-4-20250514"
    Write-Host "  ANTHROPIC_SMALL_FAST_MODEL = gpt-4.1-mini"
    Write-Host ""
    Write-Host "【提示】" -ForegroundColor Yellow
    Write-Host "  - 使用 Copilot API 作为后端，无需 Anthropic 账号"
    Write-Host "  - 首次使用需要完成 GitHub Copilot 认证"
    Write-Host "  - 配置已写入 settings.json，无需每次设置环境变量"
    Write-Host ""
}

# 主流程
function Main {
    Write-Host ""

    # 步骤 1: 安装 Node.js
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 1/7: 安装 Node.js"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Install-NodeJS
    Write-Host ""

    # 步骤 2: 验证 npx
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 2/7: 验证 npx"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Verify-Npx
    Write-Host ""

    # 步骤 3: 安装 Claude Code
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 3/7: 安装 Claude Code"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Install-ClaudeCode
    Write-Host ""

    # 步骤 4: 配置 Claude Code settings.json
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 4/7: 配置 Claude Code settings.json"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Configure-ClaudeSettings
    Write-Host ""

    # 步骤 5: 配置系统环境变量
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 5/7: 配置系统环境变量 (备用)"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Configure-SystemEnv
    Write-Host ""

    # 步骤 6: 运行 Copilot API 认证
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 6/7: 运行 Copilot API 认证"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Run-CopilotAuth
    Write-Host ""

    # 步骤 7: 创建启动脚本
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 7/7: 创建启动脚本"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Create-StartScripts
    Write-Host ""

    # 显示总结
    Show-Summary

    # 询问是否启动服务
    Write-Host "请选择操作:"
    Write-Host "  1) 一键启动 Copilot API + Claude Code (推荐)"
    Write-Host "  2) 仅启动 Copilot API"
    Write-Host "  3) 退出"
    Write-Host ""
    $choice = Read-Host "请输入选项 (1/2/3)"

    switch ($choice) {
        "1" {
            # 启动 Copilot API 在后台
            Write-Info "正在后台启动 Copilot API..."
            Start-Process -FilePath "npx" -ArgumentList "copilot-api@latest", "start" -WindowStyle Minimized
            Start-Sleep -Seconds 5

            # 启动 Claude Code
            claude
        }
        "2" { npx copilot-api@latest start }
        default {
            Write-Host ""
            Write-Info "安装完成，稍后可双击桌面的 'Claude Code (一键启动)' 图标"
        }
    }
}

Main
