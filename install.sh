#!/bin/bash

# ============================================
# Copilot API + Claude Code 一键安装脚本 (macOS / Linux)
# https://github.com/brita-ai/copilot-api-claude-code
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 默认模型配置
SELECTED_MODEL="claude-sonnet-4-20250514"
SELECTED_SMALL_MODEL="gpt-4.1-mini"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Copilot API + Claude Code 一键安装脚本                 ║${NC}"
echo -e "${CYAN}║     https://github.com/brita-ai/copilot-api-claude-code    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  [1] Copilot API: https://github.com/ericc-ch/copilot-api"
echo "  [2] Claude Code: https://code.claude.com"
echo ""
echo -e "${YELLOW}  本脚本会配置 Claude Code 使用 Copilot API 作为后端${NC}"
echo -e "${YELLOW}  无需 Anthropic 账号登录！${NC}"
echo ""

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
    elif [[ -f /etc/redhat-release ]]; then
        OS="redhat"
    elif [[ -f /etc/arch-release ]]; then
        OS="arch"
    else
        OS="linux"
    fi
    print_info "检测到操作系统: $OS"
}

# 检测当前使用的 shell
detect_shell() {
    CURRENT_SHELL=$(basename "$SHELL")
    case $CURRENT_SHELL in
        zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        bash)
            if [[ "$OS" == "macos" ]]; then
                SHELL_RC="$HOME/.bash_profile"
            else
                SHELL_RC="$HOME/.bashrc"
            fi
            ;;
        *)
            SHELL_RC="$HOME/.profile"
            ;;
    esac
    print_info "检测到 Shell: $CURRENT_SHELL (配置文件: $SHELL_RC)"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" &> /dev/null
}

# 安装 Homebrew (macOS)
install_homebrew() {
    if ! command_exists brew; then
        print_info "正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # 添加到 PATH (Apple Silicon)
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        fi
        print_success "Homebrew 安装完成"
    else
        print_success "Homebrew 已安装"
    fi
}

# 安装 Node.js
install_nodejs() {
    if command_exists node; then
        NODE_VERSION=$(node -v)
        print_success "Node.js 已安装: $NODE_VERSION"
        return
    fi

    print_info "正在安装 Node.js..."

    case $OS in
        macos)
            install_homebrew
            brew install node
            ;;
        debian)
            print_info "添加 NodeSource 仓库..."
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        redhat)
            print_info "添加 NodeSource 仓库..."
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo yum install -y nodejs
            ;;
        arch)
            sudo pacman -S --noconfirm nodejs npm
            ;;
        *)
            print_warning "未知 Linux 发行版，尝试使用 nvm 安装..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            nvm install --lts
            ;;
    esac

    if command_exists node; then
        print_success "Node.js 安装完成: $(node -v)"
    else
        print_error "Node.js 安装失败，请手动安装"
        exit 1
    fi
}

# 验证 npx
verify_npx() {
    if command_exists npx; then
        print_success "npx 已就绪: $(npx -v)"
    else
        print_error "npx 不可用，请检查 Node.js 安装"
        exit 1
    fi
}

# 安装 Claude Code
install_claude_code() {
    if command_exists claude; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "已安装")
        print_success "Claude Code 已安装: $CLAUDE_VERSION"
        return
    fi

    print_info "正在安装 Claude Code..."

    # 使用官方安装脚本
    curl -fsSL https://claude.ai/install.sh | bash

    # 刷新 PATH
    export PATH="$HOME/.claude/bin:$PATH"

    if command_exists claude; then
        print_success "Claude Code 安装完成"
    else
        print_warning "Claude Code 安装可能需要重启终端才能生效"
    fi
}

# 运行 copilot-api 认证
run_copilot_auth() {
    print_info "正在运行 copilot-api 认证..."
    echo ""
    echo -e "${YELLOW}请按照提示完成 GitHub Copilot 认证${NC}"
    echo ""
    npx copilot-api@latest auth
    echo ""
    print_success "Copilot API 认证完成"
}

# 清理临时服务
cleanup_temp_service() {
    if [[ -n "$TEMP_API_PID" ]]; then
        kill $TEMP_API_PID 2>/dev/null || true
        wait $TEMP_API_PID 2>/dev/null || true
    fi
}

# 获取可用模型并让用户选择
select_models() {
    print_info "正在启动临时 Copilot API 服务以获取可用模型..."

    # 确保退出时清理
    trap cleanup_temp_service EXIT

    # 后台启动 copilot-api
    npx copilot-api@latest start --port 14141 > /tmp/copilot-api-temp.log 2>&1 &
    TEMP_API_PID=$!

    # 等待服务启动
    echo -n "  等待服务就绪"
    SERVICE_READY=false
    for i in {1..30}; do
        if curl -s http://localhost:14141/v1/models > /dev/null 2>&1; then
            echo ""
            print_success "服务已就绪"
            SERVICE_READY=true
            break
        fi
        echo -n "."
        sleep 1
    done

    if [[ "$SERVICE_READY" != "true" ]]; then
        echo ""
        print_error "服务启动超时"
    fi

    # 获取模型列表
    MODELS_JSON=$(curl -s http://localhost:14141/v1/models 2>/dev/null)

    # 停止临时服务
    cleanup_temp_service
    trap - EXIT  # 清除 trap

    if [[ -z "$MODELS_JSON" ]] || [[ "$MODELS_JSON" == *"error"* ]]; then
        print_error "无法获取模型列表，请检查 Copilot API 认证是否成功"
        print_error "可尝试重新运行: npx copilot-api@latest auth"
        exit 1
    fi

    # 解析模型列表 - 使用更健壮的方式
    MODEL_LIST=$(echo "$MODELS_JSON" | grep -o '"id":"[^"]*"' | sed 's/"id":"//g' | sed 's/"//g' | sort)

    if [[ -z "$MODEL_LIST" ]]; then
        print_error "模型列表为空，请检查 Copilot API 服务是否正常"
        exit 1
    fi

    # 转换为数组 - 使用更兼容的方式
    MODELS_ARRAY=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && MODELS_ARRAY+=("$line")
    done <<< "$MODEL_LIST"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}可用模型列表:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    i=1
    for model in "${MODELS_ARRAY[@]}"; do
        echo "  $i) $model"
        ((i++))
    done
    echo ""

    # 选择主模型 (MODEL)
    echo -e "${GREEN}【选择主模型 (MODEL)】${NC}"
    echo -e "用于主要的代码生成和对话任务"
    echo ""

    # 查找默认选项
    default_main=1
    for idx in "${!MODELS_ARRAY[@]}"; do
        if [[ "${MODELS_ARRAY[$idx]}" == *"claude"* ]] && [[ "${MODELS_ARRAY[$idx]}" == *"sonnet"* ]]; then
            default_main=$((idx + 1))
            break
        fi
    done

    # 尝试从终端读取用户输入
    if [[ -t 0 ]] || [[ -e /dev/tty ]]; then
        exec 3</dev/tty 2>/dev/null || exec 3<&0
        printf "请选择主模型 [1-${#MODELS_ARRAY[@]}] (默认: $default_main): "
        read -r main_choice <&3 || main_choice=""
    else
        main_choice=""
    fi
    main_choice=${main_choice:-$default_main}

    if [[ "$main_choice" =~ ^[0-9]+$ ]] && [[ "$main_choice" -ge 1 ]] && [[ "$main_choice" -le "${#MODELS_ARRAY[@]}" ]]; then
        SELECTED_MODEL="${MODELS_ARRAY[$((main_choice - 1))]}"
    fi

    print_success "已选择主模型: $SELECTED_MODEL"
    echo ""

    # 选择轻量模型 (SMALL_FAST_MODEL)
    echo -e "${GREEN}【选择轻量模型 (SMALL_FAST_MODEL)】${NC}"
    echo -e "用于快速任务，如文件摘要、简单查询等"
    echo ""

    # 查找默认选项 (优先选择 gpt-4.1-mini 或类似的轻量模型)
    default_small=1
    for idx in "${!MODELS_ARRAY[@]}"; do
        if [[ "${MODELS_ARRAY[$idx]}" == *"mini"* ]] || [[ "${MODELS_ARRAY[$idx]}" == *"haiku"* ]]; then
            default_small=$((idx + 1))
            break
        fi
    done

    # 尝试从终端读取用户输入
    if [[ -t 0 ]] || [[ -e /dev/tty ]]; then
        exec 3</dev/tty 2>/dev/null || exec 3<&0
        printf "请选择轻量模型 [1-${#MODELS_ARRAY[@]}] (默认: $default_small): "
        read -r small_choice <&3 || small_choice=""
    else
        small_choice=""
    fi
    small_choice=${small_choice:-$default_small}

    if [[ "$small_choice" =~ ^[0-9]+$ ]] && [[ "$small_choice" -ge 1 ]] && [[ "$small_choice" -le "${#MODELS_ARRAY[@]}" ]]; then
        SELECTED_SMALL_MODEL="${MODELS_ARRAY[$((small_choice - 1))]}"
    fi

    print_success "已选择轻量模型: $SELECTED_SMALL_MODEL"
    echo ""
}

# 配置 Claude Code settings.json
configure_claude_settings() {
    print_info "配置 Claude Code settings.json..."

    CLAUDE_DIR="$HOME/.claude"
    SETTINGS_FILE="$CLAUDE_DIR/settings.json"

    # 创建 .claude 目录
    if [[ ! -d "$CLAUDE_DIR" ]]; then
        mkdir -p "$CLAUDE_DIR"
        print_info "创建目录: $CLAUDE_DIR"
    fi

    # 备份原配置文件
    if [[ -f "$SETTINGS_FILE" ]]; then
        cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup.$(date +%Y%m%d%H%M%S)"
        print_info "已备份原配置文件"
    fi

    # 需要设置的环境变量
    declare -A NEW_ENV_VARS=(
        ["ANTHROPIC_BASE_URL"]="http://localhost:4141"
        ["ANTHROPIC_AUTH_TOKEN"]="dummy"
        ["ANTHROPIC_MODEL"]="${SELECTED_MODEL}"
        ["ANTHROPIC_DEFAULT_SONNET_MODEL"]="${SELECTED_MODEL}"
        ["ANTHROPIC_SMALL_FAST_MODEL"]="${SELECTED_SMALL_MODEL}"
        ["ANTHROPIC_DEFAULT_HAIKU_MODEL"]="${SELECTED_MODEL}"
        ["DISABLE_NON_ESSENTIAL_MODEL_CALLS"]="1"
        ["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"]="1"
    )

    # 检查是否有 jq
    if command_exists jq; then
        # 使用 jq 合并配置
        if [[ -f "$SETTINGS_FILE" ]]; then
            EXISTING_CONFIG=$(cat "$SETTINGS_FILE")
        else
            EXISTING_CONFIG='{}'
        fi

        # 构建要合并的 env 对象
        NEW_ENV_JSON=$(cat << EOF
{
    "ANTHROPIC_BASE_URL": "http://localhost:4141",
    "ANTHROPIC_AUTH_TOKEN": "dummy",
    "ANTHROPIC_MODEL": "${SELECTED_MODEL}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "${SELECTED_MODEL}",
    "ANTHROPIC_SMALL_FAST_MODEL": "${SELECTED_SMALL_MODEL}",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "${SELECTED_MODEL}",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
}
EOF
)

        # 合并配置：保留原有配置，更新/添加 env 中的特定字段
        echo "$EXISTING_CONFIG" | jq --argjson newenv "$NEW_ENV_JSON" '.env = ((.env // {}) + $newenv)' > "$SETTINGS_FILE"

        print_success "已合并配置到: $SETTINGS_FILE"
    else
        # 没有 jq，使用简单的覆盖方式（但尝试保留其他顶级字段）
        if [[ -f "$SETTINGS_FILE" ]]; then
            # 尝试提取非 env 的其他字段（简单处理）
            print_warning "未安装 jq，将覆盖 env 配置（其他配置已备份）"
        fi

        # 写入新配置
        cat > "$SETTINGS_FILE" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:4141",
    "ANTHROPIC_AUTH_TOKEN": "dummy",
    "ANTHROPIC_MODEL": "${SELECTED_MODEL}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "${SELECTED_MODEL}",
    "ANTHROPIC_SMALL_FAST_MODEL": "${SELECTED_SMALL_MODEL}",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "${SELECTED_MODEL}",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
EOF
        print_success "已写入配置: $SETTINGS_FILE"
    fi

    echo ""
    echo -e "  ${CYAN}主模型:${NC}   $SELECTED_MODEL"
    echo -e "  ${CYAN}轻量模型:${NC} $SELECTED_SMALL_MODEL"
}

# 初始化 Claude Code（跳过登录）
init_claude_code() {
    print_info "初始化 Claude Code（跳过登录）..."

    # 检查 Copilot API 服务是否在运行
    if ! curl -s http://localhost:4141/v1/models > /dev/null 2>&1; then
        print_info "启动临时 Copilot API 服务..."
        npx copilot-api@latest start --port 4141 > /tmp/copilot-api-init.log 2>&1 &
        INIT_API_PID=$!

        # 等待服务启动
        echo -n "  等待服务就绪"
        for i in {1..30}; do
            if curl -s http://localhost:4141/v1/models > /dev/null 2>&1; then
                echo ""
                print_success "服务已就绪"
                break
            fi
            echo -n "."
            sleep 1
        done
        echo ""
    fi

    # 通过环境变量运行 claude 进行初始化
    print_info "正在初始化 Claude Code..."

    export ANTHROPIC_BASE_URL="http://localhost:4141"
    export ANTHROPIC_AUTH_TOKEN="dummy"
    export ANTHROPIC_MODEL="${SELECTED_MODEL}"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="${SELECTED_MODEL}"
    export ANTHROPIC_SMALL_FAST_MODEL="${SELECTED_SMALL_MODEL}"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="${SELECTED_MODEL}"
    export DISABLE_NON_ESSENTIAL_MODEL_CALLS="1"
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"

    # 运行 claude --version 或 claude --help 来触发初始化
    if command_exists claude; then
        claude --version > /dev/null 2>&1 || true
        print_success "Claude Code 初始化完成"
    else
        print_warning "Claude Code 命令未找到，请重启终端后手动运行初始化"
    fi

    # 停止临时服务
    if [[ -n "$INIT_API_PID" ]]; then
        kill $INIT_API_PID 2>/dev/null || true
        wait $INIT_API_PID 2>/dev/null || true
    fi
}

# 显示最终信息
show_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${GREEN}                    安装完成！                              ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}【使用方法】${NC}"
    echo ""
    echo -e "  ${GREEN}步骤 1:${NC} 启动 Copilot API 服务"
    echo ""
    echo -e "          ${CYAN}npx copilot-api@latest start${NC}"
    echo ""
    echo -e "  ${GREEN}步骤 2:${NC} 新开一个终端，在任意项目目录运行 Claude Code"
    echo ""
    echo -e "          ${CYAN}claude${NC}"
    echo ""
    echo -e "${YELLOW}【模型配置】${NC}"
    echo -e "  主模型:   ${CYAN}${SELECTED_MODEL}${NC}"
    echo -e "  轻量模型: ${CYAN}${SELECTED_SMALL_MODEL}${NC}"
    echo ""
    echo -e "${YELLOW}【配置文件】${NC}"
    echo "  ~/.claude/settings.json"
    echo ""
    echo -e "${YELLOW}【提示】${NC}"
    echo "  - 使用 Copilot API 作为后端，无需 Anthropic 账号"
    echo "  - Copilot API 服务需要保持运行"
    echo "  - 服务地址: http://localhost:4141"
    echo ""
}

# 主流程
main() {
    detect_os
    detect_shell
    echo ""

    # 步骤 1: 安装 Node.js
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 1/7: 安装 Node.js"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    install_nodejs
    echo ""

    # 步骤 2: 验证 npx
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 2/7: 验证 npx"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    verify_npx
    echo ""

    # 步骤 3: 安装 Claude Code
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 3/7: 安装 Claude Code"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    install_claude_code
    echo ""

    # 步骤 4: 运行 Copilot API 认证
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 4/7: 运行 Copilot API 认证"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    run_copilot_auth
    echo ""

    # 步骤 5: 选择模型
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 5/7: 选择模型"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    select_models
    echo ""

    # 步骤 6: 配置 Claude Code settings.json
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 6/7: 配置 Claude Code settings.json"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    configure_claude_settings
    echo ""

    # 步骤 7: 初始化 Claude Code
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 7/7: 初始化 Claude Code"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    init_claude_code
    echo ""

    # 显示总结
    show_summary
}

main
