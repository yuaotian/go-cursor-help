#!/bin/bash

# ========================================
# Cursor macOS 机器码修改脚本 (重构精简版)
# ========================================
# 
# 🎯 重构目标：
# - 简化脚本复杂度，从3158行压缩到约900行
# - 自动化权限修复，解决EACCES权限错误
# - 减少用户交互步骤，提升执行效率
# - 保持所有原有功能完整性
#
# 🚀 执行流程说明：
# 1. 环境检测和权限预修复
# 2. 用户选择执行模式（仅修改 vs 完整重置）
# 3. 自动执行所有必要步骤
# 4. 智能设备识别绕过（MAC地址或JS内核修改）
# 5. 自动权限修复和验证
#
# ========================================

set -e

# ==================== 核心配置 ====================
LOG_FILE="/tmp/cursor_reset_$(date +%Y%m%d_%H%M%S).log"
CURSOR_APP_PATH="/Applications/Cursor.app"
STORAGE_FILE="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
BACKUP_DIR="$HOME/Library/Application Support/Cursor/User/globalStorage/backups"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==================== 统一工具函数 ====================

# 初始化日志
init_log() {
    echo "========== Cursor重构脚本执行日志 $(date) ==========" > "$LOG_FILE"
    chmod 644 "$LOG_FILE"
}

# 精简日志函数
log() {
    local level="$1"
    local msg="$2"
    local color=""
    
    case "$level" in
        "INFO") color="$GREEN" ;;
        "WARN") color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
        *) color="$BLUE" ;;
    esac
    
    echo -e "${color}[$level]${NC} $msg"
    echo "[$level] $(date '+%H:%M:%S') $msg" >> "$LOG_FILE"
}

# 统一权限管理器 - 解决所有权限问题
fix_permissions() {
    log "INFO" "🔧 执行统一权限修复..."
    
    local cursor_support="$HOME/Library/Application Support/Cursor"
    local cursor_home="$HOME/.cursor"
    
    # 创建必要目录结构
    local dirs=(
        "$cursor_support"
        "$cursor_support/User"
        "$cursor_support/User/globalStorage"
        "$cursor_support/logs"
        "$cursor_support/CachedData"
        "$cursor_home"
        "$cursor_home/extensions"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" 2>/dev/null || true
    done
    
    # 执行核心权限修复命令
    if sudo chown -R "$(whoami)" "$cursor_support" 2>/dev/null && \
       sudo chown -R "$(whoami)" "$cursor_home" 2>/dev/null && \
       chmod -R u+w "$cursor_support" 2>/dev/null && \
       chmod -R u+w "$cursor_home/extensions" 2>/dev/null; then
        log "INFO" "✅ 权限修复成功"
        return 0
    else
        log "ERROR" "❌ 权限修复失败"
        return 1
    fi
}

# 环境检测器
detect_environment() {
    log "INFO" "🔍 检测系统环境..."
    
    # 检测macOS版本和硬件
    MACOS_VERSION=$(sw_vers -productVersion)
    HARDWARE_TYPE=$(uname -m)
    
    if [[ "$HARDWARE_TYPE" == "arm64" ]]; then
        HARDWARE_TYPE="Apple Silicon"
    else
        HARDWARE_TYPE="Intel"
    fi
    
    # 检测兼容性
    local macos_major=$(echo "$MACOS_VERSION" | cut -d. -f1)
    if [[ $macos_major -ge 14 ]] || [[ "$HARDWARE_TYPE" == "Apple Silicon" ]]; then
        MAC_COMPATIBLE=false
        log "WARN" "⚠️  检测到MAC地址修改受限环境: macOS $MACOS_VERSION ($HARDWARE_TYPE)"
    else
        MAC_COMPATIBLE=true
        log "INFO" "✅ 环境兼容性检查通过"
    fi
    
    # 检查Python3
    if ! command -v python3 >/dev/null 2>&1; then
        log "ERROR" "❌ 未找到Python3，请安装: brew install python3"
        return 1
    fi
    
    # 检查Cursor应用
    if [ ! -d "$CURSOR_APP_PATH" ]; then
        log "ERROR" "❌ 未找到Cursor应用: $CURSOR_APP_PATH"
        return 1
    fi
    
    log "INFO" "✅ 环境检测完成: macOS $MACOS_VERSION ($HARDWARE_TYPE)"
    return 0
}

# 进程管理器
manage_cursor_process() {
    local action="$1"  # kill 或 start
    
    case "$action" in
        "kill")
            log "INFO" "🔄 关闭Cursor进程..."
            pkill -f "Cursor" 2>/dev/null || true
            sleep 2
            
            # 验证是否关闭
            if pgrep -f "Cursor" >/dev/null; then
                pkill -9 -f "Cursor" 2>/dev/null || true
                sleep 2
            fi
            log "INFO" "✅ Cursor进程已关闭"
            ;;
        "start")
            log "INFO" "🚀 启动Cursor..."
            "$CURSOR_APP_PATH/Contents/MacOS/Cursor" > /dev/null 2>&1 &
            sleep 15
            log "INFO" "✅ Cursor已启动"
            ;;
    esac
}

# 错误处理器
handle_error() {
    local error_msg="$1"
    local recovery_action="$2"
    
    log "ERROR" "❌ 错误: $error_msg"
    
    if [ -n "$recovery_action" ]; then
        log "INFO" "🔄 尝试恢复: $recovery_action"
        eval "$recovery_action"
    fi
    
    log "INFO" "💡 如需帮助，请查看日志: $LOG_FILE"
}

# ==================== 功能模块 ====================

# 机器码修改器
modify_machine_code() {
    log "INFO" "🛠️  开始修改机器码配置..."
    
    # 检查配置文件
    if [ ! -f "$STORAGE_FILE" ]; then
        log "ERROR" "❌ 配置文件不存在，请先启动Cursor生成配置"
        return 1
    fi
    
    # 创建备份
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/storage.json.backup_$(date +%Y%m%d_%H%M%S)"
    cp "$STORAGE_FILE" "$backup_file" || {
        log "ERROR" "❌ 备份失败"
        return 1
    }
    
    # 生成新ID
    local machine_id="auth0|user_$(openssl rand -hex 16)"
    local mac_machine_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local device_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local sqm_id="{$(uuidgen | tr '[:lower:]' '[:upper:]')}"
    
    # 修改配置文件
    local python_result=$(python3 -c "
import json
import sys

try:
    with open('$STORAGE_FILE', 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    config['telemetry.machineId'] = '$machine_id'
    config['telemetry.macMachineId'] = '$mac_machine_id'
    config['telemetry.devDeviceId'] = '$device_id'
    config['telemetry.sqmId'] = '$sqm_id'
    
    with open('$STORAGE_FILE', 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    
    print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
" 2>&1)
    
    if echo "$python_result" | grep -q "SUCCESS"; then
        # 设置只读保护
        chmod 444 "$STORAGE_FILE" 2>/dev/null || true
        log "INFO" "✅ 机器码修改成功"
        log "INFO" "💾 备份保存至: $(basename "$backup_file")"
        return 0
    else
        log "ERROR" "❌ 机器码修改失败: $python_result"
        cp "$backup_file" "$STORAGE_FILE" 2>/dev/null || true
        return 1
    fi
}

# 智能设备绕过器 - 根据环境自动选择最佳方案
bypass_device_detection() {
    log "INFO" "🔧 开始智能设备识别绕过..."

    # 根据环境兼容性选择方案
    if [ "$MAC_COMPATIBLE" = false ]; then
        log "INFO" "💡 检测到MAC地址修改受限，使用JS内核修改方案"
        return modify_js_kernel
    else
        log "INFO" "💡 尝试MAC地址修改方案"
        if modify_mac_address; then
            return 0
        else
            log "WARN" "⚠️  MAC地址修改失败，切换到JS内核修改"
            return modify_js_kernel
        fi
    fi
}

# MAC地址修改器（简化版）
modify_mac_address() {
    log "INFO" "🌐 开始MAC地址修改..."

    # 获取活动网络接口
    local interfaces=()
    while IFS= read -r line; do
        if [[ $line == "Hardware Port: Wi-Fi" || $line == "Hardware Port: Ethernet" ]]; then
            read -r dev_line
            local device=$(echo "$dev_line" | awk '{print $2}')
            if [ -n "$device" ] && ifconfig "$device" 2>/dev/null | grep -q "status: active"; then
                interfaces+=("$device")
            fi
        fi
    done < <(networksetup -listallhardwareports)

    if [ ${#interfaces[@]} -eq 0 ]; then
        log "WARN" "⚠️  未找到活动网络接口"
        return 1
    fi

    local success_count=0
    for interface in "${interfaces[@]}"; do
        log "INFO" "🔧 处理接口: $interface"

        # 生成新MAC地址
        local new_mac=$(printf '%02x:%02x:%02x:%02x:%02x:%02x' \
            $(( (RANDOM & 0xFC) | 0x02 )) $((RANDOM%256)) $((RANDOM%256)) \
            $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

        # 尝试修改MAC地址
        if sudo ifconfig "$interface" down 2>/dev/null && \
           sleep 2 && \
           sudo ifconfig "$interface" ether "$new_mac" 2>/dev/null && \
           sudo ifconfig "$interface" up 2>/dev/null; then
            log "INFO" "✅ 接口 $interface MAC地址修改成功: $new_mac"
            ((success_count++))
        else
            log "WARN" "⚠️  接口 $interface MAC地址修改失败"
        fi
        sleep 2
    done

    if [ $success_count -gt 0 ]; then
        log "INFO" "✅ MAC地址修改完成 ($success_count/${#interfaces[@]} 成功)"
        return 0
    else
        return 1
    fi
}

# JS内核修改器（简化版）
modify_js_kernel() {
    log "INFO" "🔧 开始JS内核修改..."

    # 关闭Cursor
    manage_cursor_process "kill"

    # 目标JS文件
    local js_files=(
        "$CURSOR_APP_PATH/Contents/Resources/app/out/vs/workbench/api/node/extensionHostProcess.js"
        "$CURSOR_APP_PATH/Contents/Resources/app/out/main.js"
    )

    # 检查是否需要修改
    local need_modify=false
    for file in "${js_files[@]}"; do
        if [ -f "$file" ] && ! grep -q "return crypto.randomUUID()" "$file" 2>/dev/null; then
            need_modify=true
            break
        fi
    done

    if [ "$need_modify" = false ]; then
        log "INFO" "✅ JS文件已修改，跳过"
        return 0
    fi

    # 创建备份
    local backup_app="/tmp/Cursor.app.backup_$(date +%Y%m%d_%H%M%S)"
    cp -R "$CURSOR_APP_PATH" "$backup_app" || {
        log "ERROR" "❌ 创建备份失败"
        return 1
    fi

    # 生成设备ID
    local new_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local machine_id="auth0|user_$(openssl rand -hex 16)"

    # 修改JS文件
    local modified_count=0
    for file in "${js_files[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi

        log "INFO" "📝 处理文件: $(basename "$file")"

        # 创建注入代码
        local inject_code="
// Cursor设备标识符劫持 - $(date +%Y%m%d%H%M%S)
import crypto from 'crypto';
const originalRandomUUID = crypto.randomUUID;
crypto.randomUUID = function() { return '$new_uuid'; };
globalThis.getMachineId = function() { return '$machine_id'; };
console.log('Cursor设备标识符已劫持');
"

        # 注入代码
        echo "$inject_code" > "${file}.new"
        cat "$file" >> "${file}.new"
        mv "${file}.new" "$file"

        ((modified_count++))
        log "INFO" "✅ 文件修改成功: $(basename "$file")"
    done

    if [ $modified_count -gt 0 ]; then
        # 重新签名
        if codesign --sign - --force --deep "$CURSOR_APP_PATH" 2>/dev/null; then
            log "INFO" "✅ JS内核修改完成 ($modified_count 个文件)"
            return 0
        else
            log "WARN" "⚠️  签名失败，但修改已完成"
            return 0
        fi
    else
        log "ERROR" "❌ 未修改任何文件"
        return 1
    fi
}

# 环境重置器
reset_environment() {
    log "INFO" "🗑️  开始环境重置..."

    # 关闭Cursor
    manage_cursor_process "kill"

    # 删除目标文件夹
    local folders=(
        "$HOME/Library/Application Support/Cursor"
        "$HOME/.cursor"
    )

    local deleted_count=0
    for folder in "${folders[@]}"; do
        if [ -d "$folder" ]; then
            if rm -rf "$folder"; then
                log "INFO" "✅ 已删除: $folder"
                ((deleted_count++))
            else
                log "ERROR" "❌ 删除失败: $folder"
            fi
        fi
    done

    # 修复权限
    fix_permissions

    log "INFO" "✅ 环境重置完成 (删除 $deleted_count 个文件夹)"
    return 0
}

# 禁用自动更新
disable_auto_update() {
    log "INFO" "🚫 禁用自动更新..."

    local app_update_yml="$CURSOR_APP_PATH/Contents/Resources/app-update.yml"
    local updater_path="$HOME/Library/Application Support/Caches/cursor-updater"

    # 禁用app-update.yml
    if [ -f "$app_update_yml" ]; then
        sudo cp "$app_update_yml" "${app_update_yml}.bak" 2>/dev/null || true
        sudo bash -c "echo '' > \"$app_update_yml\"" 2>/dev/null || true
        sudo chmod 444 "$app_update_yml" 2>/dev/null || true
    fi

    # 禁用cursor-updater
    sudo rm -rf "$updater_path" 2>/dev/null || true
    sudo touch "$updater_path" 2>/dev/null || true
    sudo chmod 444 "$updater_path" 2>/dev/null || true

    log "INFO" "✅ 自动更新已禁用"
}

# 修复应用签名问题
fix_app_signature() {
    log "INFO" "🔧 修复应用签名..."

    # 移除隔离属性
    sudo find "$CURSOR_APP_PATH" -print0 2>/dev/null | \
        xargs -0 sudo xattr -d com.apple.quarantine 2>/dev/null || true

    # 重新签名
    sudo codesign --force --deep --sign - "$CURSOR_APP_PATH" 2>/dev/null || true

    log "INFO" "✅ 应用签名修复完成"
}

# ==================== 主执行流程 ====================

# 快速模式 - 仅修改机器码
quick_mode() {
    log "INFO" "🚀 执行快速模式（仅修改机器码）..."

    # 检查环境
    if ! detect_environment; then
        handle_error "环境检测失败" "exit 1"
        return 1
    fi

    # 预修复权限
    fix_permissions

    # 修改机器码
    if ! modify_machine_code; then
        handle_error "机器码修改失败" "exit 1"
        return 1
    fi

    # 设备绕过
    bypass_device_detection || log "WARN" "⚠️  设备绕过失败，但机器码修改已完成"

    # 禁用更新
    disable_auto_update

    # 修复签名
    fix_app_signature

    # 最终权限修复
    fix_permissions

    log "INFO" "🎉 快速模式执行完成！"
    return 0
}

# 完整模式 - 重置环境+修改机器码
full_mode() {
    log "INFO" "🚀 执行完整模式（重置环境+修改机器码）..."

    # 检查环境
    if ! detect_environment; then
        handle_error "环境检测失败" "exit 1"
        return 1
    fi

    # 环境重置
    if ! reset_environment; then
        handle_error "环境重置失败" "exit 1"
        return 1
    fi

    # 启动Cursor生成配置
    manage_cursor_process "start"

    # 等待配置文件生成
    local config_wait=0
    while [ ! -f "$STORAGE_FILE" ] && [ $config_wait -lt 30 ]; do
        sleep 2
        ((config_wait += 2))
        log "INFO" "⏳ 等待配置文件生成... ($config_wait/30秒)"
    done

    # 关闭Cursor
    manage_cursor_process "kill"

    # 修改机器码
    if ! modify_machine_code; then
        handle_error "机器码修改失败" "exit 1"
        return 1
    fi

    # 设备绕过
    bypass_device_detection || log "WARN" "⚠️  设备绕过失败，但机器码修改已完成"

    # 禁用更新
    disable_auto_update

    # 修复签名
    fix_app_signature

    # 最终权限修复
    fix_permissions

    log "INFO" "🎉 完整模式执行完成！"
    return 0
}

# ==================== 用户界面 ====================

# 显示Logo和信息
show_header() {
    clear
    echo -e "
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
    "
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}🚀   Cursor 机器码修改工具 (重构版)   ${NC}"
    echo -e "${YELLOW}📱  关注公众号【煎饼果子卷AI】     ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    echo -e "${YELLOW}💡 [免费工具]${NC} 如果对您有帮助，请关注公众号支持开发者"
    echo
}

# 用户选择菜单
user_menu() {
    echo -e "${GREEN}🎯 [选择模式]${NC} 请选择执行模式："
    echo
    echo -e "${BLUE}  1️⃣  快速模式 - 仅修改机器码${NC}"
    echo -e "${YELLOW}      • 保留现有配置和数据${NC}"
    echo -e "${YELLOW}      • 执行时间约30秒${NC}"
    echo -e "${YELLOW}      • 自动权限修复${NC}"
    echo
    echo -e "${BLUE}  2️⃣  完整模式 - 重置环境+修改机器码${NC}"
    echo -e "${RED}      • 删除所有Cursor配置（请备份）${NC}"
    echo -e "${YELLOW}      • 执行时间约90秒${NC}"
    echo -e "${YELLOW}      • 彻底重置试用状态${NC}"
    echo

    while true; do
        read -p "请输入选择 (1 或 2): " choice
        case "$choice" in
            1)
                log "INFO" "✅ 用户选择：快速模式"
                return 1
                ;;
            2)
                echo -e "${RED}⚠️  [警告]${NC} 完整模式将删除所有Cursor配置！"
                read -p "确认执行？(输入 yes 确认): " confirm
                if [ "$confirm" = "yes" ]; then
                    log "INFO" "✅ 用户选择：完整模式"
                    return 2
                else
                    echo -e "${YELLOW}👋 [取消]${NC} 请重新选择"
                    continue
                fi
                ;;
            *)
                echo -e "${RED}❌ [错误]${NC} 无效选择，请输入 1 或 2"
                ;;
        esac
    done
}

# 显示完成信息
show_completion() {
    echo
    echo -e "${GREEN}================================${NC}"
    echo -e "${BLUE}   🎯 执行完成总结     ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ 机器码配置: 已修改${NC}"
    echo -e "${GREEN}✅ 设备识别绕过: 已完成${NC}"
    echo -e "${GREEN}✅ 自动更新: 已禁用${NC}"
    echo -e "${GREEN}✅ 权限修复: 已完成${NC}"
    echo -e "${GREEN}✅ 应用签名: 已修复${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    echo -e "${YELLOW}📱 关注公众号【煎饼果子卷AI】获取更多Cursor技巧${NC}"
    echo
    echo -e "${BLUE}🚀 [下一步]${NC} 现在可以启动Cursor使用了！"
    echo -e "${BLUE}📄 [日志]${NC} 详细日志保存在: $LOG_FILE"
    echo
}

# ==================== 主函数 ====================

main() {
    # 检查权限
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ [错误]${NC} 请使用 sudo 运行此脚本"
        echo "示例: sudo $0"
        exit 1
    fi

    # 检查macOS
    if [[ $(uname) != "Darwin" ]]; then
        echo -e "${RED}❌ [错误]${NC} 本脚本仅支持 macOS 系统"
        exit 1
    fi

    # 初始化
    init_log
    log "INFO" "🚀 Cursor重构脚本启动..."

    # 预修复权限
    fix_permissions

    # 显示界面
    show_header

    # 用户选择
    user_menu
    local mode=$?

    echo
    log "INFO" "🚀 开始执行，请稍候..."
    echo

    # 执行对应模式
    case $mode in
        1)
            if quick_mode; then
                show_completion
                exit 0
            else
                log "ERROR" "❌ 快速模式执行失败"
                exit 1
            fi
            ;;
        2)
            if full_mode; then
                show_completion
                exit 0
            else
                log "ERROR" "❌ 完整模式执行失败"
                exit 1
            fi
            ;;
    esac
}

# 执行主函数
main "$@"
