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

    # 写入新配置
    cat > "$SETTINGS_FILE" << 'EOF'
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
EOF

    print_success "已写入配置: $SETTINGS_FILE"
}

# 配置 Shell 环境变量 (作为备用)
configure_shell_env() {
    print_info "配置 Shell 环境变量 (备用)..."

    # 环境变量内容
    ENV_BLOCK="
# ============================================
# Claude Code + Copilot API 配置
# https://github.com/brita-ai/copilot-api-claude-code
# 使用 Copilot API 作为后端，无需 Anthropic 账号
# ============================================
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=dummy
export ANTHROPIC_MODEL=claude-sonnet-4-20250514
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-20250514
export ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1-mini
export ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-4.1-mini
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
# ============================================
"

    # 检查是否已经配置过
    if grep -q "ANTHROPIC_BASE_URL=http://localhost:4141" "$SHELL_RC" 2>/dev/null; then
        print_success "Shell 环境变量已配置过，跳过"
        return
    fi

    # 备份原配置文件
    if [[ -f "$SHELL_RC" ]]; then
        cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d%H%M%S)"
        print_info "已备份 Shell 配置文件"
    fi

    # 追加环境变量
    echo "$ENV_BLOCK" >> "$SHELL_RC"
    print_success "环境变量已写入 $SHELL_RC"

    # 立即加载环境变量
    export ANTHROPIC_BASE_URL=http://localhost:4141
    export ANTHROPIC_AUTH_TOKEN=dummy
    export ANTHROPIC_MODEL=claude-sonnet-4-20250514
    export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-20250514
    export ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1-mini
    export ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-4.1-mini
    export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

    print_success "环境变量已生效"
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

# 创建启动脚本
create_start_scripts() {
    # Copilot API 启动脚本
    COPILOT_SCRIPT="$HOME/start-copilot-api.sh"
    cat > "$COPILOT_SCRIPT" << 'EOF'
#!/bin/bash
echo "正在启动 Copilot API..."
echo "服务地址: http://localhost:4141"
echo "按 Ctrl+C 停止服务"
echo ""
npx copilot-api@latest start
EOF
    chmod +x "$COPILOT_SCRIPT"
    print_success "Copilot API 启动脚本: $COPILOT_SCRIPT"

    # Claude Code 启动脚本 (带环境变量)
    CLAUDE_SCRIPT="$HOME/start-claude-code.sh"
    cat > "$CLAUDE_SCRIPT" << 'EOF'
#!/bin/bash

# Claude Code 环境变量配置
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=dummy
export ANTHROPIC_MODEL=claude-sonnet-4-20250514
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-20250514
export ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1-mini
export ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-4.1-mini
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

echo "Claude Code 配置:"
echo "  API 后端: $ANTHROPIC_BASE_URL"
echo "  主模型:   $ANTHROPIC_MODEL"
echo "  轻量模型: $ANTHROPIC_SMALL_FAST_MODEL"
echo ""

# 切换到指定目录
cd "${1:-.}"

# 启动 Claude Code
claude
EOF
    chmod +x "$CLAUDE_SCRIPT"
    print_success "Claude Code 启动脚本: $CLAUDE_SCRIPT"

    # 一键启动脚本 (同时启动 Copilot API 和 Claude Code)
    ALL_IN_ONE_SCRIPT="$HOME/start-all.sh"
    cat > "$ALL_IN_ONE_SCRIPT" << 'EOF'
#!/bin/bash

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   启动 Copilot API + Claude Code          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

# 检查 Copilot API 是否已运行
if curl -s http://localhost:4141/health > /dev/null 2>&1; then
    echo -e "${GREEN}[✓] Copilot API 已在运行${NC}"
else
    echo -e "${YELLOW}[*] 正在后台启动 Copilot API...${NC}"
    npx copilot-api@latest start > /tmp/copilot-api.log 2>&1 &
    COPILOT_PID=$!
    echo "    PID: $COPILOT_PID"
    echo "    日志: /tmp/copilot-api.log"

    # 等待服务启动
    echo -n "    等待服务就绪"
    for i in {1..30}; do
        if curl -s http://localhost:4141/health > /dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}[✓] Copilot API 启动成功${NC}"
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""
fi

echo ""

# 设置环境变量 (备用，settings.json 已配置)
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=dummy
export ANTHROPIC_MODEL=claude-sonnet-4-20250514
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-20250514
export ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1-mini
export ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-4.1-mini
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

echo -e "${GREEN}[✓] 环境变量已配置${NC}"
echo "    API 后端: $ANTHROPIC_BASE_URL"
echo "    主模型:   $ANTHROPIC_MODEL"
echo ""

# 切换到指定目录
cd "${1:-.}"

echo -e "${CYAN}正在启动 Claude Code...${NC}"
echo ""

# 启动 Claude Code
claude
EOF
    chmod +x "$ALL_IN_ONE_SCRIPT"
    print_success "一键启动脚本: $ALL_IN_ONE_SCRIPT"
}

# 显示最终信息
show_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${GREEN}            安装完成！                      ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}【推荐】一键启动（自动启动 Copilot API + Claude Code）：${NC}"
    echo "  ~/start-all.sh"
    echo "  ~/start-all.sh /path/to/project"
    echo ""
    echo -e "${YELLOW}【分别启动】${NC}"
    echo "  Copilot API:  ~/start-copilot-api.sh"
    echo "  Claude Code:  ~/start-claude-code.sh"
    echo ""
    echo -e "${YELLOW}【配置文件】${NC}"
    echo "  Claude Code: ~/.claude/settings.json"
    echo "  Shell 环境:  $SHELL_RC"
    echo ""
    echo -e "${YELLOW}【环境变量配置】${NC}"
    echo "  ANTHROPIC_BASE_URL=http://localhost:4141"
    echo "  ANTHROPIC_MODEL=claude-sonnet-4-20250514"
    echo "  ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1-mini"
    echo ""
    echo -e "${YELLOW}【提示】${NC}"
    echo "  - 使用 Copilot API 作为后端，无需 Anthropic 账号"
    echo "  - 首次使用需要完成 GitHub Copilot 认证"
    echo "  - 配置已写入 settings.json，无需每次设置环境变量"
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

    # 步骤 4: 配置 Claude Code settings.json
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 4/7: 配置 Claude Code settings.json"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    configure_claude_settings
    echo ""

    # 步骤 5: 配置 Shell 环境变量
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 5/7: 配置 Shell 环境变量 (备用)"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    configure_shell_env
    echo ""

    # 步骤 6: 运行 Copilot API 认证
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 6/7: 运行 Copilot API 认证"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    run_copilot_auth
    echo ""

    # 步骤 7: 创建启动脚本
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 7/7: 创建启动脚本"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    create_start_scripts
    echo ""

    # 显示总结
    show_summary

    # 询问是否启动服务
    echo "请选择操作:"
    echo "  1) 一键启动 Copilot API + Claude Code (推荐)"
    echo "  2) 仅启动 Copilot API"
    echo "  3) 退出"
    echo ""
    read -p "请输入选项 (1/2/3): " choice

    case $choice in
        1)
            ~/start-all.sh
            ;;
        2)
            npx copilot-api@latest start
            ;;
        *)
            echo ""
            print_info "安装完成，稍后可运行 ~/start-all.sh 启动服务"
            ;;
    esac
}

main
