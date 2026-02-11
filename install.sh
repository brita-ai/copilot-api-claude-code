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
    print_info "步骤 1/5: 安装 Node.js"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    install_nodejs
    echo ""

    # 步骤 2: 验证 npx
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 2/5: 验证 npx"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    verify_npx
    echo ""

    # 步骤 3: 安装 Claude Code
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 3/5: 安装 Claude Code"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    install_claude_code
    echo ""

    # 步骤 4: 配置 Claude Code settings.json
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 4/5: 配置 Claude Code settings.json"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    configure_claude_settings
    echo ""

    # 步骤 5: 运行 Copilot API 认证
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_info "步骤 5/5: 运行 Copilot API 认证"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    run_copilot_auth
    echo ""

    # 显示总结
    show_summary
}

main
