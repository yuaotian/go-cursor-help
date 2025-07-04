#!/bin/bash

# Cursor权限测试脚本
# 用于验证修复后的权限设置是否正确

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

# 测试权限函数
test_cursor_permissions() {
    echo
    log_info "🔍 [测试] 开始测试Cursor目录权限..."
    
    local cursor_support_dir="$HOME/Library/Application Support/Cursor"
    local cursor_home_dir="$HOME/.cursor"
    
    # 关键目录列表
    local directories=(
        "$cursor_support_dir"
        "$cursor_support_dir/User"
        "$cursor_support_dir/User/globalStorage"
        "$cursor_support_dir/logs"
        "$cursor_support_dir/CachedData"
        "$cursor_support_dir/User/workspaceStorage"
        "$cursor_support_dir/User/History"
        "$cursor_home_dir"
        "$cursor_home_dir/extensions"
    )
    
    local all_ok=true
    
    echo
    log_info "📁 [检查] 目录存在性和权限检查："
    
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            local perms=$(ls -ld "$dir" | awk '{print $1}')
            local owner=$(ls -ld "$dir" | awk '{print $3}')
            local group=$(ls -ld "$dir" | awk '{print $4}')
            
            # 检查是否可写
            if [ -w "$dir" ]; then
                echo -e "   ✅ $dir"
                echo -e "      权限: $perms | 所有者: $owner | 组: $group | 可写: 是"
            else
                echo -e "   ❌ $dir"
                echo -e "      权限: $perms | 所有者: $owner | 组: $group | 可写: 否"
                all_ok=false
            fi
        else
            echo -e "   ❌ $dir (不存在)"
            all_ok=false
        fi
    done
    
    echo
    
    # 测试创建文件
    log_info "📝 [测试] 测试文件创建权限..."
    
    local test_file="$cursor_support_dir/logs/test_permission_$(date +%s).txt"
    if touch "$test_file" 2>/dev/null; then
        log_info "✅ [成功] 可以在logs目录创建文件"
        rm -f "$test_file" 2>/dev/null
    else
        log_error "❌ [失败] 无法在logs目录创建文件"
        all_ok=false
    fi
    
    # 测试配置文件权限
    local config_file="$cursor_support_dir/User/globalStorage/storage.json"
    if [ -f "$config_file" ]; then
        log_info "📋 [检查] 配置文件权限："
        local config_perms=$(ls -l "$config_file" | awk '{print $1}')
        local config_owner=$(ls -l "$config_file" | awk '{print $3}')
        echo "   文件: $config_file"
        echo "   权限: $config_perms | 所有者: $config_owner"
        
        if [ -r "$config_file" ]; then
            log_info "✅ [成功] 配置文件可读"
        else
            log_error "❌ [失败] 配置文件不可读"
            all_ok=false
        fi
    else
        log_warn "⚠️  [警告] 配置文件不存在: $config_file"
    fi
    
    echo
    
    # 总结
    if [ "$all_ok" = true ]; then
        log_info "🎉 [结果] 所有权限测试通过！"
        return 0
    else
        log_error "❌ [结果] 权限测试失败，存在问题"
        echo
        log_info "💡 [建议] 运行以下命令修复权限："
        echo -e "${BLUE}sudo chown -R \$(whoami) \"$HOME/Library/Application Support/Cursor\"${NC}"
        echo -e "${BLUE}sudo chown -R \$(whoami) \"$HOME/.cursor\"${NC}"
        echo -e "${BLUE}chmod -R u+w \"$HOME/Library/Application Support/Cursor\"${NC}"
        echo -e "${BLUE}chmod -R u+w \"$HOME/.cursor\"${NC}"
        return 1
    fi
}

# 主函数
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Cursor 权限测试脚本${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    test_cursor_permissions
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    测试完成${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 执行主函数
main "$@"
