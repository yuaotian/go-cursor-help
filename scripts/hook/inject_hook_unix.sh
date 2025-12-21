#!/bin/bash

# ========================================
# Cursor Hook 注入脚本 (macOS/Linux)
# ========================================
#
# 🎯 功能：将 cursor_hook.js 注入到 Cursor 的 main.js 文件顶部
# 
# 📦 使用方式：
# chmod +x inject_hook_unix.sh
# ./inject_hook_unix.sh
#
# 参数：
#   --rollback  回滚到原始版本
#   --force     强制重新注入
#   --debug     启用调试模式
#
# ========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 参数解析
ROLLBACK=false
FORCE=false
DEBUG=false

for arg in "$@"; do
    case $arg in
        --rollback) ROLLBACK=true ;;
        --force) FORCE=true ;;
        --debug) DEBUG=true ;;
    esac
done

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { if $DEBUG; then echo -e "${BLUE}[DEBUG]${NC} $1"; fi; }

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/cursor_hook.js"

# 获取 Cursor main.js 路径
get_cursor_path() {
    local paths=()
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        paths=(
            "/Applications/Cursor.app/Contents/Resources/app/out/main.js"
            "$HOME/Applications/Cursor.app/Contents/Resources/app/out/main.js"
        )
    else
        # Linux
        paths=(
            "/opt/Cursor/resources/app/out/main.js"
            "/usr/share/cursor/resources/app/out/main.js"
            "$HOME/.local/share/cursor/resources/app/out/main.js"
            "/snap/cursor/current/resources/app/out/main.js"
        )
    fi
    
    for path in "${paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# 检查是否已注入
check_already_injected() {
    local main_js="$1"
    grep -q "__cursor_patched__" "$main_js" 2>/dev/null
}

# 备份原始文件
backup_main_js() {
    local main_js="$1"
    local backup_dir="$(dirname "$main_js")/backups"
    
    mkdir -p "$backup_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_dir/main.js.backup_$timestamp"
    local original_backup="$backup_dir/main.js.original"
    
    # 创建原始备份（如果不存在）
    if [[ ! -f "$original_backup" ]]; then
        cp "$main_js" "$original_backup"
        log_info "已创建原始备份: $original_backup"
    fi
    
    cp "$main_js" "$backup_path"
    log_info "已创建时间戳备份: $backup_path"
    
    echo "$original_backup"
}

# 回滚到原始版本
restore_main_js() {
    local main_js="$1"
    local backup_dir="$(dirname "$main_js")/backups"
    local original_backup="$backup_dir/main.js.original"
    
    if [[ -f "$original_backup" ]]; then
        cp "$original_backup" "$main_js"
        log_info "已回滚到原始版本"
        return 0
    else
        log_error "未找到原始备份文件"
        return 1
    fi
}

# 关闭 Cursor 进程
stop_cursor_process() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        pkill -x "Cursor" 2>/dev/null || true
        pkill -x "Cursor Helper" 2>/dev/null || true
    else
        # Linux
        pkill -f "cursor" 2>/dev/null || true
    fi
    
    sleep 2
    log_info "Cursor 进程已关闭"
}

# 注入 Hook 代码
inject_hook() {
    local main_js="$1"
    local hook_script="$2"
    
    # 读取 Hook 脚本内容
    local hook_content=$(cat "$hook_script")
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 读取 main.js 并注入 Hook
    # 在版权声明之后注入
    awk -v hook="$hook_content" '
    /^\*\// && !injected {
        print
        print ""
        print "// ========== Cursor Hook 注入开始 =========="
        print hook
        print "// ========== Cursor Hook 注入结束 =========="
        print ""
        injected = 1
        next
    }
    { print }
    ' "$main_js" > "$temp_file"
    
    # 替换原文件
    mv "$temp_file" "$main_js"

    return 0
}

# 主函数
main() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Cursor Hook 注入工具 (Unix)         ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # 获取 Cursor main.js 路径
    local main_js
    main_js=$(get_cursor_path) || {
        log_error "未找到 Cursor 安装路径"
        log_error "请确保 Cursor 已正确安装"
        exit 1
    }
    log_info "找到 Cursor main.js: $main_js"

    # 回滚模式
    if $ROLLBACK; then
        log_info "执行回滚操作..."
        stop_cursor_process
        if restore_main_js "$main_js"; then
            log_info "回滚成功！"
        else
            log_error "回滚失败！"
            exit 1
        fi
        exit 0
    fi

    # 检查是否已注入
    if check_already_injected "$main_js" && ! $FORCE; then
        log_warn "Hook 已经注入，无需重复操作"
        log_info "如需强制重新注入，请使用 --force 参数"
        exit 0
    fi

    # 检查 Hook 脚本是否存在
    if [[ ! -f "$HOOK_SCRIPT" ]]; then
        log_error "未找到 cursor_hook.js 文件"
        log_error "请确保 cursor_hook.js 与此脚本在同一目录"
        exit 1
    fi
    log_info "找到 Hook 脚本: $HOOK_SCRIPT"

    # 关闭 Cursor 进程
    stop_cursor_process

    # 备份原始文件
    log_info "正在备份原始文件..."
    backup_main_js "$main_js"

    # 注入 Hook 代码
    log_info "正在注入 Hook 代码..."
    if inject_hook "$main_js" "$HOOK_SCRIPT"; then
        log_info "Hook 注入成功！"
    else
        log_error "Hook 注入失败！"
        log_warn "正在回滚..."
        restore_main_js "$main_js"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   ✅ Hook 注入完成！                   ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    log_info "现在可以启动 Cursor 了"
    log_info "ID 配置文件位置: ~/.cursor_ids.json"
    echo ""
    echo -e "${YELLOW}提示:${NC}"
    echo "  - 如需回滚，请运行: ./inject_hook_unix.sh --rollback"
    echo "  - 如需强制重新注入，请运行: ./inject_hook_unix.sh --force"
    echo "  - 如需启用调试日志，请运行: ./inject_hook_unix.sh --debug"
    echo ""
}

# 执行主函数
main

