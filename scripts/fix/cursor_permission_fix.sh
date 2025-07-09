#!/bin/bash

# Cursor权限问题专用修复脚本
# 专门解决macOS环境下Cursor权限错误问题
# 错误类型：EACCES: permission denied, mkdir '/Users/xxx/Library/Application Support/Cursor/logs/xxx'

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取当前用户信息
CURRENT_USER=$(whoami)
CURSOR_SUPPORT_DIR="$HOME/Library/Application Support/Cursor"
CURSOR_HOME_DIR="$HOME/.cursor"

# 权限诊断函数
diagnose_permissions() {
    echo
    log_info "🔍 [诊断] 开始权限诊断..."
    
    # 检查目录列表
    local directories=(
        "$CURSOR_SUPPORT_DIR"
        "$CURSOR_SUPPORT_DIR/User"
        "$CURSOR_SUPPORT_DIR/User/globalStorage"
        "$CURSOR_SUPPORT_DIR/logs"
        "$CURSOR_SUPPORT_DIR/CachedData"
        "$CURSOR_HOME_DIR"
        "$CURSOR_HOME_DIR/extensions"
    )
    
    local issues_found=false
    
    echo
    echo "📋 [权限状态] 当前权限状态："
    echo "----------------------------------------"
    
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            local perms=$(ls -ld "$dir" | awk '{print $1}')
            local owner=$(ls -ld "$dir" | awk '{print $3}')
            local group=$(ls -ld "$dir" | awk '{print $4}')
            
            if [ "$owner" = "$CURRENT_USER" ] && [ -w "$dir" ]; then
                echo -e "✅ $dir"
                echo -e "   权限: $perms | 所有者: $owner:$group | 状态: 正常"
            else
                echo -e "❌ $dir"
                echo -e "   权限: $perms | 所有者: $owner:$group | 状态: 异常"
                issues_found=true
            fi
        else
            echo -e "❌ $dir (不存在)"
            issues_found=true
        fi
        echo
    done
    
    # 特别检查logs目录
    local logs_dir="$CURSOR_SUPPORT_DIR/logs"
    echo "🎯 [logs目录] 特别检查logs目录："
    echo "----------------------------------------"
    
    if [ -d "$logs_dir" ]; then
        # 测试创建子目录
        local test_subdir="$logs_dir/test_$(date +%s)"
        if mkdir -p "$test_subdir" 2>/dev/null; then
            echo -e "✅ logs目录可以创建子目录"
            rmdir "$test_subdir" 2>/dev/null || true
        else
            echo -e "❌ logs目录无法创建子目录 - 这是问题根源！"
            issues_found=true
        fi
    else
        echo -e "❌ logs目录不存在"
        issues_found=true
    fi
    
    echo
    if [ "$issues_found" = true ]; then
        log_error "❌ [诊断结果] 发现权限问题"
        return 1
    else
        log_info "✅ [诊断结果] 权限状态正常"
        return 0
    fi
}

# 强制权限修复函数
force_fix_permissions() {
    echo
    log_info "🔧 [强制修复] 开始强制权限修复..."
    
    # 关闭所有Cursor进程
    log_info "🔄 [关闭进程] 关闭所有Cursor进程..."
    pkill -f "Cursor" 2>/dev/null || true
    sleep 2
    
    # 完全删除并重新创建目录结构
    log_info "🗑️  [重建] 删除并重新创建目录结构..."
    
    # 备份重要文件
    local backup_dir="/tmp/cursor_backup_$(date +%s)"
    if [ -d "$CURSOR_SUPPORT_DIR/User/globalStorage" ]; then
        log_info "💾 [备份] 备份配置文件..."
        mkdir -p "$backup_dir"
        cp -R "$CURSOR_SUPPORT_DIR/User/globalStorage" "$backup_dir/" 2>/dev/null || true
    fi
    
    # 删除目录
    sudo rm -rf "$CURSOR_SUPPORT_DIR" 2>/dev/null || true
    sudo rm -rf "$CURSOR_HOME_DIR" 2>/dev/null || true
    
    # 重新创建目录结构
    log_info "📁 [创建] 重新创建目录结构..."
    local directories=(
        "$CURSOR_SUPPORT_DIR"
        "$CURSOR_SUPPORT_DIR/User"
        "$CURSOR_SUPPORT_DIR/User/globalStorage"
        "$CURSOR_SUPPORT_DIR/User/globalStorage/backups"
        "$CURSOR_SUPPORT_DIR/User/workspaceStorage"
        "$CURSOR_SUPPORT_DIR/User/History"
        "$CURSOR_SUPPORT_DIR/logs"
        "$CURSOR_SUPPORT_DIR/CachedData"
        "$CURSOR_SUPPORT_DIR/CachedExtensions"
        "$CURSOR_SUPPORT_DIR/CachedExtensionVSIXs"
        "$CURSOR_SUPPORT_DIR/User/snippets"
        "$CURSOR_SUPPORT_DIR/User/keybindings"
        "$CURSOR_SUPPORT_DIR/crashDumps"
        "$CURSOR_HOME_DIR"
        "$CURSOR_HOME_DIR/extensions"
    )
    
    for dir in "${directories[@]}"; do
        sudo mkdir -p "$dir" 2>/dev/null || true
        sudo chown "$CURRENT_USER:staff" "$dir" 2>/dev/null || true
        sudo chmod 755 "$dir" 2>/dev/null || true
    done
    
    # 恢复备份的配置文件
    if [ -d "$backup_dir/globalStorage" ]; then
        log_info "🔄 [恢复] 恢复配置文件..."
        cp -R "$backup_dir/globalStorage"/* "$CURSOR_SUPPORT_DIR/User/globalStorage/" 2>/dev/null || true
        sudo chown -R "$CURRENT_USER:staff" "$CURSOR_SUPPORT_DIR/User/globalStorage" 2>/dev/null || true
        sudo chmod -R 644 "$CURSOR_SUPPORT_DIR/User/globalStorage"/*.json 2>/dev/null || true
    fi
    
    # 设置最终权限
    log_info "🔐 [权限] 设置最终权限..."
    sudo chown -R "$CURRENT_USER:staff" "$CURSOR_SUPPORT_DIR" 2>/dev/null || true
    sudo chown -R "$CURRENT_USER:staff" "$CURSOR_HOME_DIR" 2>/dev/null || true
    sudo chmod -R 755 "$CURSOR_SUPPORT_DIR" 2>/dev/null || true
    sudo chmod -R 755 "$CURSOR_HOME_DIR" 2>/dev/null || true
    
    # 特别确保logs目录权限
    log_info "🎯 [logs] 特别确保logs目录权限..."
    sudo chown "$CURRENT_USER:staff" "$CURSOR_SUPPORT_DIR/logs" 2>/dev/null || true
    sudo chmod 755 "$CURSOR_SUPPORT_DIR/logs" 2>/dev/null || true
    
    # 测试修复效果
    local test_subdir="$CURSOR_SUPPORT_DIR/logs/test_$(date +%s)"
    if mkdir -p "$test_subdir" 2>/dev/null; then
        log_info "✅ [测试] logs目录权限修复成功"
        rmdir "$test_subdir" 2>/dev/null || true
    else
        log_error "❌ [测试] logs目录权限修复失败"
        return 1
    fi
    
    log_info "✅ [完成] 强制权限修复完成"
    
    # 清理备份
    rm -rf "$backup_dir" 2>/dev/null || true
    
    return 0
}

# 主函数
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Cursor权限问题专用修复脚本${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${BLUE}🎯 [目标]${NC} 解决Cursor权限错误："
    echo -e "${BLUE}   EACCES: permission denied, mkdir${NC}"
    echo -e "${BLUE}   '/Users/xxx/Library/Application Support/Cursor/logs/xxx'${NC}"
    echo
    
    # 检查是否为macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "❌ [错误] 此脚本仅适用于macOS系统"
        exit 1
    fi
    
    # 检查sudo权限
    if ! sudo -n true 2>/dev/null; then
        log_info "🔑 [权限] 此脚本需要sudo权限来修复目录权限"
        echo "请输入您的密码："
        sudo -v
    fi
    
    # 执行诊断
    if diagnose_permissions; then
        echo
        log_info "🎉 [结果] 权限状态正常，无需修复"
        echo
        echo -e "${BLUE}💡 [建议]${NC} 如果Cursor仍有权限错误，请："
        echo -e "${BLUE}  1. 重启Cursor应用${NC}"
        echo -e "${BLUE}  2. 重启macOS系统${NC}"
        echo -e "${BLUE}  3. 如果问题持续，请运行强制修复${NC}"
    else
        echo
        log_warn "⚠️  [发现问题] 检测到权限问题，开始修复..."
        
        if force_fix_permissions; then
            echo
            log_info "🎉 [成功] 权限修复完成！"
            echo
            echo -e "${GREEN}✅ [下一步]${NC} 现在可以："
            echo -e "${GREEN}  1. 启动Cursor应用${NC}"
            echo -e "${GREEN}  2. 运行Cursor脚本${NC}"
            echo -e "${GREEN}  3. 权限错误应该已经解决${NC}"
        else
            echo
            log_error "❌ [失败] 权限修复失败"
            echo
            echo -e "${RED}💡 [手动修复]${NC} 请手动执行以下命令："
            echo -e "${RED}sudo rm -rf \"$CURSOR_SUPPORT_DIR\"${NC}"
            echo -e "${RED}sudo rm -rf \"$CURSOR_HOME_DIR\"${NC}"
            echo -e "${RED}sudo mkdir -p \"$CURSOR_SUPPORT_DIR/logs\"${NC}"
            echo -e "${RED}sudo mkdir -p \"$CURSOR_HOME_DIR/extensions\"${NC}"
            echo -e "${RED}sudo chown -R $CURRENT_USER:staff \"$CURSOR_SUPPORT_DIR\"${NC}"
            echo -e "${RED}sudo chown -R $CURRENT_USER:staff \"$CURSOR_HOME_DIR\"${NC}"
            echo -e "${RED}sudo chmod -R 755 \"$CURSOR_SUPPORT_DIR\"${NC}"
            echo -e "${RED}sudo chmod -R 755 \"$CURSOR_HOME_DIR\"${NC}"
        fi
    fi
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    修复完成${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 执行主函数
main "$@"
