# ============================================
# Copilot API + Claude Code 一键安装脚本 (Windows PowerShell)
# https://github.com/brita-ai/copilot-api-claude-code
# ============================================

$ErrorActionPreference = "Stop"

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# 默认模型配置
$script:SelectedModel = "claude-sonnet-4-20250514"
$script:SelectedSmallModel = "gpt-4.1-mini"

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

# 获取可用模型并让用户选择
function Select-Models {
    Write-Info "正在启动临时 Copilot API 服务以获取可用模型..."

    # 后台启动 copilot-api
    $tempJob = $null
    try {
        $tempJob = Start-Process -FilePath "npx" -ArgumentList "copilot-api@latest", "start", "--port", "14141" -WindowStyle Hidden -PassThru
    } catch {
        Write-Err "无法启动临时服务"
        Write-Err "可尝试重新运行: npx copilot-api@latest auth"
        Read-Host "按回车键退出"
        exit 1
    }

    # 等待服务启动
    Write-Host "  等待服务就绪" -NoNewline
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 1
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:14141/v1/models" -TimeoutSec 2 -ErrorAction SilentlyContinue
            Write-Host ""
            Write-Success "服务已就绪"
            $ready = $true
            break
        } catch {
            Write-Host "." -NoNewline
        }
    }

    if (-not $ready) {
        Write-Host ""
        Write-Warn "服务启动超时"
    }

    # 获取模型列表
    $modelsJson = $null
    if ($ready) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:14141/v1/models" -TimeoutSec 5
            $modelsJson = $response.Content | ConvertFrom-Json
        } catch {
            Write-Warn "获取模型列表失败"
        }
    }

    # 停止临时服务
    if ($null -ne $tempJob) {
        try {
            Stop-Process -Id $tempJob.Id -Force -ErrorAction SilentlyContinue
        } catch {}
    }

    if ($null -eq $modelsJson -or $null -eq $modelsJson.data) {
        Write-Err "无法获取模型列表，请检查 Copilot API 认证是否成功"
        Write-Err "可尝试重新运行: npx copilot-api@latest auth"
        Read-Host "按回车键退出"
        exit 1
    }

    # 提取模型 ID
    $models = $modelsJson.data | ForEach-Object { $_.id } | Sort-Object

    if ($models.Count -eq 0) {
        Write-Err "模型列表为空，请检查 Copilot API 服务是否正常"
        Read-Host "按回车键退出"
        exit 1
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "可用模型列表:" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

    for ($i = 0; $i -lt $models.Count; $i++) {
        Write-Host "  $($i + 1)) $($models[$i])"
    }
    Write-Host ""

    # 选择主模型
    Write-Host "【选择主模型 (MODEL)】" -ForegroundColor Green
    Write-Host "用于主要的代码生成和对话任务"
    Write-Host ""

    # 查找默认选项 (优先 claude-opus-4.6 > claude-opus-4.5 > claude-sonnet)
    $defaultMain = 1
    for ($i = 0; $i -lt $models.Count; $i++) {
        if ($models[$i] -eq "claude-opus-4.6") {
            $defaultMain = $i + 1
            break
        }
    }
    # 如果没找到 opus-4.6，找 opus-4.5
    if ($defaultMain -eq 1) {
        for ($i = 0; $i -lt $models.Count; $i++) {
            if ($models[$i] -eq "claude-opus-4.5") {
                $defaultMain = $i + 1
                break
            }
        }
    }
    # 如果没找到 opus，找 sonnet
    if ($defaultMain -eq 1) {
        for ($i = 0; $i -lt $models.Count; $i++) {
            if ($models[$i] -match "claude" -and $models[$i] -match "sonnet") {
                $defaultMain = $i + 1
                break
            }
        }
    }

    $mainChoice = Read-Host "请选择主模型 [1-$($models.Count)] (默认: $defaultMain)"
    if ([string]::IsNullOrEmpty($mainChoice)) {
        $mainChoice = $defaultMain
    }

    if ($mainChoice -match '^\d+$' -and [int]$mainChoice -ge 1 -and [int]$mainChoice -le $models.Count) {
        $script:SelectedModel = $models[[int]$mainChoice - 1]
    }

    Write-Success "已选择主模型: $($script:SelectedModel)"
    Write-Host ""

    # 选择轻量模型
    Write-Host "【选择轻量模型 (SMALL_FAST_MODEL)】" -ForegroundColor Green
    Write-Host "用于快速任务，如文件摘要、简单查询等"
    Write-Host ""

    # 查找默认选项
    $defaultSmall = 1
    for ($i = 0; $i -lt $models.Count; $i++) {
        if ($models[$i] -match "mini" -or $models[$i] -match "haiku") {
            $defaultSmall = $i + 1
            break
        }
    }

    $smallChoice = Read-Host "请选择轻量模型 [1-$($models.Count)] (默认: $defaultSmall)"
    if ([string]::IsNullOrEmpty($smallChoice)) {
        $smallChoice = $defaultSmall
    }

    if ($smallChoice -match '^\d+$' -and [int]$smallChoice -ge 1 -and [int]$smallChoice -le $models.Count) {
        $script:SelectedSmallModel = $models[[int]$smallChoice - 1]
    }

    Write-Success "已选择轻量模型: $($script:SelectedSmallModel)"
    Write-Host ""
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

    # 需要设置的环境变量
    $newEnvVars = @{
        ANTHROPIC_BASE_URL = "http://localhost:4141"
        ANTHROPIC_AUTH_TOKEN = "dummy"
        ANTHROPIC_MODEL = $script:SelectedModel
        ANTHROPIC_DEFAULT_SONNET_MODEL = $script:SelectedModel
        ANTHROPIC_SMALL_FAST_MODEL = $script:SelectedSmallModel
        ANTHROPIC_DEFAULT_HAIKU_MODEL = $script:SelectedSmallModel
        DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1"
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    }

    # 读取现有配置并合并
    $existingConfig = @{}
    if (Test-Path $settingsFile) {
        try {
            $existingConfig = Get-Content $settingsFile -Raw | ConvertFrom-Json -AsHashtable
        } catch {
            Write-Warn "无法解析现有配置，将创建新配置"
            $existingConfig = @{}
        }
    }

    # 确保 env 字段存在
    if (-not $existingConfig.ContainsKey("env")) {
        $existingConfig["env"] = @{}
    }

    # 合并环境变量（只更新需要的字段，保留其他字段）
    foreach ($key in $newEnvVars.Keys) {
        $existingConfig["env"][$key] = $newEnvVars[$key]
    }

    # 写入配置
    $existingConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding UTF8

    Write-Success "已合并配置到: $settingsFile"
    Write-Host ""
    Write-Host "  主模型:   $($script:SelectedModel)" -ForegroundColor Cyan
    Write-Host "  轻量模型: $($script:SelectedSmallModel)" -ForegroundColor Cyan
}

# 初始化 Claude Code（跳过登录）
function Init-ClaudeCode {
    Write-Info "初始化 Claude Code（跳过登录）..."

    # 检查 Copilot API 服务是否在运行
    $apiRunning = $false
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4141/v1/models" -TimeoutSec 2 -ErrorAction SilentlyContinue
        $apiRunning = $true
    } catch {}

    $initJob = $null
    if (-not $apiRunning) {
        Write-Info "启动临时 Copilot API 服务..."
        $initJob = Start-Process -FilePath "npx" -ArgumentList "copilot-api@latest", "start", "--port", "4141" -WindowStyle Hidden -PassThru

        # 等待服务启动
        Write-Host "  等待服务就绪" -NoNewline
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 1
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:4141/v1/models" -TimeoutSec 2 -ErrorAction SilentlyContinue
                Write-Host ""
                Write-Success "服务已就绪"
                break
            } catch {
                Write-Host "." -NoNewline
            }
        }
        Write-Host ""
    }

    # 设置环境变量
    $env:ANTHROPIC_BASE_URL = "http://localhost:4141"
    $env:ANTHROPIC_AUTH_TOKEN = "dummy"
    $env:ANTHROPIC_MODEL = $script:SelectedModel
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = $script:SelectedModel
    $env:ANTHROPIC_SMALL_FAST_MODEL = $script:SelectedSmallModel
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = $script:SelectedSmallModel
    $env:DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1"
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"

    # 运行 claude -p "hello" 来触发初始化
    if (Test-CommandExists "claude") {
        try {
            Write-Info "运行 Claude Code 初始化测试..."
            claude -p "hello" 2>&1 | Out-Null
            Write-Success "Claude Code 初始化完成"
        } catch {
            Write-Warn "Claude Code 初始化可能未完成"
        }
    } else {
        Write-Warn "Claude Code 命令未找到，请重启 PowerShell 后手动运行初始化"
    }

    # 停止临时服务
    if ($null -ne $initJob) {
        try {
            Stop-Process -Id $initJob.Id -Force -ErrorAction SilentlyContinue
        } catch {}
    }
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
    Write-Host "【模型配置】" -ForegroundColor Yellow
    Write-Host "  主模型:   $($script:SelectedModel)" -ForegroundColor Cyan
    Write-Host "  轻量模型: $($script:SelectedSmallModel)" -ForegroundColor Cyan
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

    # 步骤 4: 运行 Copilot API 认证
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 4/7: 运行 Copilot API 认证"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Run-CopilotAuth
    Write-Host ""

    # 步骤 5: 选择模型
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 5/7: 选择模型"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Select-Models
    Write-Host ""

    # 步骤 6: 配置 Claude Code settings.json
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 6/7: 配置 Claude Code settings.json"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Configure-ClaudeSettings
    Write-Host ""

    # 步骤 7: 初始化 Claude Code
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Info "步骤 7/7: 初始化 Claude Code"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Init-ClaudeCode
    Write-Host ""

    # 显示总结
    Show-Summary
}

Main
