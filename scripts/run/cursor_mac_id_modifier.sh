#!/bin/bash

# 设置错误处理
set -e

# 定义日志文件路径
LOG_FILE="/tmp/cursor_free_trial_reset.log"

# 初始化日志文件
initialize_log() {
    echo "========== Cursor Free Trial Reset Tool Log Start $(date) ==========" > "$LOG_FILE"
    chmod 644 "$LOG_FILE"
}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数 - 同时输出到终端和日志文件
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# 记录命令输出到日志文件
log_cmd_output() {
    local cmd="$1"
    local msg="$2"
    echo "[CMD] $(date '+%Y-%m-%d %H:%M:%S') 执行命令: $cmd" >> "$LOG_FILE"
    echo "[CMD] $msg:" >> "$LOG_FILE"
    eval "$cmd" 2>&1 | tee -a "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# 🚀 新增 Cursor 防掉试用Pro删除文件夹功能
remove_cursor_trial_folders() {
    echo
    log_info "🎯 [核心功能] 正在执行 Cursor 防掉试用Pro删除文件夹..."
    log_info "📋 [说明] 此功能将删除指定的Cursor相关文件夹以重置试用状态"
    echo

    # 定义需要删除的文件夹路径
    local folders_to_delete=(
        "$HOME/Library/Application Support/Cursor"
        "$HOME/.cursor"
    )

    log_info "📂 [检测] 将检查以下文件夹："
    for folder in "${folders_to_delete[@]}"; do
        echo "   📁 $folder"
    done
    echo

    local deleted_count=0
    local skipped_count=0
    local error_count=0

    # 删除指定文件夹
    for folder in "${folders_to_delete[@]}"; do
        log_debug "🔍 [检查] 检查文件夹: $folder"

        if [ -d "$folder" ]; then
            log_warn "⚠️  [警告] 发现文件夹存在，正在删除..."
            if rm -rf "$folder"; then
                log_info "✅ [成功] 已删除文件夹: $folder"
                ((deleted_count++))
            else
                log_error "❌ [错误] 删除文件夹失败: $folder"
                ((error_count++))
            fi
        else
            log_warn "⏭️  [跳过] 文件夹不存在: $folder"
            ((skipped_count++))
        fi
        echo
    done

    # 🔧 重要：深度修复权限问题
    log_info "🔧 [深度修复] 正在进行全面的权限修复..."
    local cursor_support_dir="$HOME/Library/Application Support/Cursor"
    local cursor_home_dir="$HOME/.cursor"

    # 创建完整的目录结构（包括Cursor可能需要的所有子目录）
    local directories=(
        "$cursor_support_dir"
        "$cursor_support_dir/User"
        "$cursor_support_dir/User/globalStorage"
        "$cursor_support_dir/User/workspaceStorage"
        "$cursor_support_dir/User/History"
        "$cursor_support_dir/logs"
        "$cursor_support_dir/CachedData"
        "$cursor_support_dir/CachedExtensions"
        "$cursor_support_dir/CachedExtensionVSIXs"
        "$cursor_home_dir"
        "$cursor_home_dir/extensions"
    )

    log_info "[创建] 创建完整的目录结构..."
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            log_debug "✅ 创建目录: $dir"
        else
            log_warn "⚠️  创建目录失败: $dir"
        fi
    done

    # 设置递归权限（确保所有子目录都有正确权限）
    log_info "🔐 [权限] 设置递归权限..."
    chmod -R 755 "$cursor_support_dir" 2>/dev/null || true
    chmod -R 755 "$cursor_home_dir" 2>/dev/null || true

    # 特别处理：确保当前用户拥有这些目录
    log_info "👤 [所有权] 确保目录所有权正确..."
    chown -R "$(whoami)" "$cursor_support_dir" 2>/dev/null || true
    chown -R "$(whoami)" "$cursor_home_dir" 2>/dev/null || true

    # 🔑 关键修复：使用sudo确保目录所有权（解决EACCES错误）
    log_info "🔑 [关键修复] 使用sudo确保目录所有权正确..."
    if sudo chown -R "$(whoami)" "$HOME/Library/Application Support/Cursor" 2>/dev/null; then
        log_info "✅ [成功] sudo设置Application Support/Cursor目录所有权成功"
    else
        log_warn "⚠️  [警告] sudo设置Application Support/Cursor目录所有权失败"
    fi

    if sudo chown -R "$(whoami)" "$HOME/.cursor" 2>/dev/null; then
        log_info "✅ [成功] sudo设置.cursor目录所有权成功"
    else
        log_warn "⚠️  [警告] sudo设置.cursor目录所有权失败"
    fi

    # 🔓 关键修复：设置用户写入权限
    log_info "🔓 [关键修复] 设置用户写入权限..."
    if chmod -R u+w "$HOME/Library/Application Support/Cursor" 2>/dev/null; then
        log_info "✅ [成功] 设置Application Support/Cursor写入权限成功"
    else
        log_warn "⚠️  [警告] 设置Application Support/Cursor写入权限失败"
    fi

    if chmod -R u+w "$HOME/.cursor/extensions" 2>/dev/null; then
        log_info "✅ [成功] 设置.cursor/extensions写入权限成功"
    else
        log_warn "⚠️  [警告] 设置.cursor/extensions写入权限失败"
    fi

    # 验证权限设置
    log_info "🔍 [验证] 验证权限设置..."
    local permission_ok=true

    # 检查目录是否可写
    if [ -w "$cursor_support_dir" ]; then
        log_info "✅ [验证] Application Support/Cursor目录可写"
    else
        log_warn "⚠️  [验证] Application Support/Cursor目录不可写"
        permission_ok=false
    fi

    if [ -w "$cursor_home_dir" ]; then
        log_info "✅ [验证] .cursor目录可写"
    else
        log_warn "⚠️  [验证] .cursor目录不可写"
        permission_ok=false
    fi

    # 检查关键子目录是否可写
    if [ -w "$cursor_support_dir/logs" ] || [ ! -d "$cursor_support_dir/logs" ]; then
        log_info "✅ [验证] logs目录权限正常"
    else
        log_warn "⚠️  [验证] logs目录权限异常"
        permission_ok=false
    fi

    if $permission_ok; then
        log_info "✅ [成功] 权限验证通过"
    else
        log_warn "⚠️  [警告] 权限验证失败，可能仍存在问题"
        log_info "💡 [提示] 如果Cursor启动时仍有权限错误，请手动执行："
        echo "   sudo chown -R \$(whoami) \"$HOME/Library/Application Support/Cursor\""
        echo "   sudo chown -R \$(whoami) \"$HOME/.cursor\""
        echo "   chmod -R u+w \"$HOME/Library/Application Support/Cursor\""
        echo "   chmod -R u+w \"$HOME/.cursor\""
    fi

    # 🔍 权限诊断
    log_info "🔍 [诊断] 执行权限诊断..."
    echo "   📁 目录权限检查："
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            local perms=$(ls -ld "$dir" | awk '{print $1, $3, $4}')
            echo "     ✅ $dir: $perms"
        else
            echo "     ❌ $dir: 不存在"
        fi
    done

    log_info "✅ [完成] 深度权限修复完成"
    echo

    # 🔧 额外修复：再次调用统一权限修复函数确保一致性
    log_info "🔧 [额外修复] 使用统一权限修复函数进行最终确认..."
    ensure_cursor_directory_permissions

    # 显示操作统计
    log_info "📊 [统计] 操作完成统计："
    echo "   ✅ 成功删除: $deleted_count 个文件夹"
    echo "   ⏭️  跳过处理: $skipped_count 个文件夹"
    echo "   ❌ 删除失败: $error_count 个文件夹"
    echo

    if [ $deleted_count -gt 0 ]; then
        log_info "🎉 [完成] Cursor 防掉试用Pro文件夹删除完成！"
    else
        log_warn "🤔 [提示] 未找到需要删除的文件夹，可能已经清理过了"
    fi
    echo
}

# 🔄 重启Cursor并等待配置文件生成
restart_cursor_and_wait() {
    echo
    log_info "🔄 [重启] 正在重启Cursor以重新生成配置文件..."

    if [ -z "$CURSOR_PROCESS_PATH" ]; then
        log_error "❌ [错误] 未找到Cursor进程信息，无法重启"
        return 1
    fi

    log_info "📍 [路径] 使用路径: $CURSOR_PROCESS_PATH"

    if [ ! -f "$CURSOR_PROCESS_PATH" ]; then
        log_error "❌ [错误] Cursor可执行文件不存在: $CURSOR_PROCESS_PATH"
        return 1
    fi

    # 🔧 启动前最后一次权限确认
    log_info "🔧 [最终权限] 启动前最后一次权限确认..."
    local cursor_support_dir="$HOME/Library/Application Support/Cursor"
    local cursor_home_dir="$HOME/.cursor"

    # 再次确认完整目录结构存在
    local directories=(
        "$cursor_support_dir"
        "$cursor_support_dir/User"
        "$cursor_support_dir/User/globalStorage"
        "$cursor_support_dir/logs"
        "$cursor_support_dir/CachedData"
        "$cursor_home_dir"
        "$cursor_home_dir/extensions"
    )

    for dir in "${directories[@]}"; do
        mkdir -p "$dir" 2>/dev/null || true
    done

    # 设置强制权限
    chmod -R 755 "$cursor_support_dir" 2>/dev/null || true
    chmod -R 755 "$cursor_home_dir" 2>/dev/null || true
    chown -R "$(whoami)" "$cursor_support_dir" 2>/dev/null || true
    chown -R "$(whoami)" "$cursor_home_dir" 2>/dev/null || true

    # 🔑 最终权限修复：使用sudo确保权限正确
    log_info "🔑 [最终修复] 使用sudo确保启动前权限正确..."
    sudo chown -R "$(whoami)" "$HOME/Library/Application Support/Cursor" 2>/dev/null || true
    sudo chown -R "$(whoami)" "$HOME/.cursor" 2>/dev/null || true
    chmod -R u+w "$HOME/Library/Application Support/Cursor" 2>/dev/null || true
    chmod -R u+w "$HOME/.cursor" 2>/dev/null || true

    # 启动Cursor
    log_info "🚀 [启动] 正在启动Cursor..."
    "$CURSOR_PROCESS_PATH" > /dev/null 2>&1 &
    CURSOR_PID=$!

    log_info "⏳ [等待] 等待15秒让Cursor完全启动并生成配置文件..."
    sleep 15

    # 检查配置文件是否生成
    local config_path="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
    local max_wait=30
    local waited=0

    while [ ! -f "$config_path" ] && [ $waited -lt $max_wait ]; do
        log_info "⏳ [等待] 等待配置文件生成... ($waited/$max_wait 秒)"
        sleep 1
        waited=$((waited + 1))
    done

    if [ -f "$config_path" ]; then
        log_info "✅ [成功] 配置文件已生成: $config_path"

        # 🛡️ 关键修复：配置文件生成后立即确保权限正确
        ensure_cursor_directory_permissions
    else
        log_warn "⚠️  [警告] 配置文件未在预期时间内生成，继续执行..."

        # 即使配置文件未生成，也要确保目录权限正确
        ensure_cursor_directory_permissions
    fi

    # 强制关闭Cursor
    log_info "🔄 [关闭] 正在关闭Cursor以进行配置修改..."
    if [ ! -z "$CURSOR_PID" ]; then
        kill $CURSOR_PID 2>/dev/null || true
    fi

    # 确保所有Cursor进程都关闭
    pkill -f "Cursor" 2>/dev/null || true

    log_info "✅ [完成] Cursor重启流程完成"
    return 0
}

# 🔍 检查Cursor环境
test_cursor_environment() {
    local mode=${1:-"FULL"}

    echo
    log_info "🔍 [环境检查] 正在检查Cursor环境..."

    local config_path="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
    local cursor_app_data="$HOME/Library/Application Support/Cursor"
    local cursor_app_path="/Applications/Cursor.app"
    local issues=()

    # 检查Python3环境（macOS版本需要）
    if ! command -v python3 >/dev/null 2>&1; then
        issues+=("Python3环境不可用，macOS版本需要Python3来处理JSON配置文件")
        log_warn "⚠️  [警告] 未找到Python3，请安装Python3: brew install python3"
    else
        log_info "✅ [检查] Python3环境可用: $(python3 --version)"
    fi

    # 检查配置文件
    if [ ! -f "$config_path" ]; then
        issues+=("配置文件不存在: $config_path")
    else
        # 验证JSON格式
        if python3 -c "import json; json.load(open('$config_path'))" 2>/dev/null; then
            log_info "✅ [检查] 配置文件格式正确"
        else
            issues+=("配置文件格式错误或损坏")
        fi
    fi

    # 检查Cursor目录结构
    if [ ! -d "$cursor_app_data" ]; then
        issues+=("Cursor应用数据目录不存在: $cursor_app_data")
    fi

    # 检查Cursor应用安装
    if [ ! -d "$cursor_app_path" ]; then
        issues+=("未找到Cursor应用安装: $cursor_app_path")
    else
        log_info "✅ [检查] 找到Cursor应用: $cursor_app_path"
    fi

    # 检查目录权限
    if [ -d "$cursor_app_data" ] && [ ! -w "$cursor_app_data" ]; then
        issues+=("Cursor应用数据目录无写入权限: $cursor_app_data")
    fi

    # 返回检查结果
    if [ ${#issues[@]} -eq 0 ]; then
        log_info "✅ [环境检查] 所有检查通过"
        return 0
    else
        log_error "❌ [环境检查] 发现 ${#issues[@]} 个问题："
        for issue in "${issues[@]}"; do
            echo -e "${RED}  • $issue${NC}"
        done
        return 1
    fi
}

# 🚀 启动Cursor生成配置文件
start_cursor_to_generate_config() {
    log_info "🚀 [启动] 正在尝试启动Cursor生成配置文件..."

    local cursor_app_path="/Applications/Cursor.app"
    local cursor_executable="$cursor_app_path/Contents/MacOS/Cursor"

    if [ ! -f "$cursor_executable" ]; then
        log_error "❌ [错误] 未找到Cursor可执行文件: $cursor_executable"
        return 1
    fi

    log_info "📍 [路径] 使用Cursor路径: $cursor_executable"

    # 启动Cursor
    "$cursor_executable" > /dev/null 2>&1 &
    local cursor_pid=$!
    log_info "🚀 [启动] Cursor已启动，PID: $cursor_pid"

    log_info "⏳ [等待] 请等待Cursor完全加载（约30秒）..."
    log_info "💡 [提示] 您可以在Cursor完全加载后手动关闭它"

    # 等待配置文件生成
    local config_path="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
    local max_wait=60
    local waited=0

    while [ ! -f "$config_path" ] && [ $waited -lt $max_wait ]; do
        sleep 2
        waited=$((waited + 2))
        if [ $((waited % 10)) -eq 0 ]; then
            log_info "⏳ [等待] 等待配置文件生成... ($waited/$max_wait 秒)"
        fi
    done

    if [ -f "$config_path" ]; then
        log_info "✅ [成功] 配置文件已生成！"
        log_info "💡 [提示] 现在可以关闭Cursor并重新运行脚本"
        return 0
    else
        log_warn "⚠️  [超时] 配置文件未在预期时间内生成"
        log_info "💡 [建议] 请手动操作Cursor（如创建新文件）以触发配置生成"
        return 1
    fi
}

# �️ 确保Cursor目录权限正确（新增函数）
ensure_cursor_directory_permissions() {
    log_info "🛡️ [权限修复] 确保Cursor目录权限正确..."

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

    # 确保所有目录存在并有正确权限
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" 2>/dev/null || true
        fi

        # 设置目录权限：用户可读写执行，组和其他用户可读执行
        chmod 755 "$dir" 2>/dev/null || true
        chown "$(whoami)" "$dir" 2>/dev/null || true
    done

    # 特别处理：使用sudo确保关键目录权限
    if sudo chown -R "$(whoami)" "$cursor_support_dir" 2>/dev/null; then
        log_info "✅ [权限] Application Support/Cursor目录权限修复成功"
    else
        log_warn "⚠️  [权限] Application Support/Cursor目录权限修复失败"
    fi

    if sudo chown -R "$(whoami)" "$cursor_home_dir" 2>/dev/null; then
        log_info "✅ [权限] .cursor目录权限修复成功"
    else
        log_warn "⚠️  [权限] .cursor目录权限修复失败"
    fi

    # 设置用户写入权限
    chmod -R u+w "$cursor_support_dir" 2>/dev/null || true
    chmod -R u+w "$cursor_home_dir" 2>/dev/null || true

    log_info "✅ [权限修复] Cursor目录权限修复完成"
}

# �🛠️ 修改机器码配置（增强版）
modify_machine_code_config() {
    local mode=${1:-"FULL"}

    echo
    log_info "🛠️  [配置] 正在修改机器码配置..."

    local config_path="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"

    # 增强的配置文件检查
    if [ ! -f "$config_path" ]; then
        log_error "❌ [错误] 配置文件不存在: $config_path"
        echo
        log_info "💡 [解决方案] 请尝试以下步骤："
        echo -e "${BLUE}  1️⃣  手动启动Cursor应用程序${NC}"
        echo -e "${BLUE}  2️⃣  等待Cursor完全加载（约30秒）${NC}"
        echo -e "${BLUE}  3️⃣  关闭Cursor应用程序${NC}"
        echo -e "${BLUE}  4️⃣  重新运行此脚本${NC}"
        echo
        log_warn "⚠️  [备选方案] 如果问题持续："
        echo -e "${BLUE}  • 选择脚本的'重置环境+修改机器码'选项${NC}"
        echo -e "${BLUE}  • 该选项会自动生成配置文件${NC}"
        echo

        # 提供用户选择
        read -p "是否现在尝试启动Cursor生成配置文件？(y/n): " user_choice
        if [[ "$user_choice" =~ ^(y|yes)$ ]]; then
            log_info "🚀 [尝试] 正在尝试启动Cursor..."
            if start_cursor_to_generate_config; then
                return 0
            fi
        fi

        return 1
    fi

    # 验证配置文件格式并显示结构
    log_info "🔍 [验证] 检查配置文件格式..."
    if ! python3 -c "import json; json.load(open('$config_path'))" 2>/dev/null; then
        log_error "❌ [错误] 配置文件格式错误或损坏"
        log_info "💡 [建议] 配置文件可能已损坏，建议选择'重置环境+修改机器码'选项"
        return 1
    fi
    log_info "✅ [验证] 配置文件格式正确"

    # 显示当前配置文件中的相关属性
    log_info "📋 [当前配置] 检查现有的遥测属性："
    python3 -c "
import json
try:
    with open('$config_path', 'r', encoding='utf-8') as f:
        config = json.load(f)

    properties = ['telemetry.machineId', 'telemetry.macMachineId', 'telemetry.devDeviceId', 'telemetry.sqmId']
    for prop in properties:
        if prop in config:
            value = config[prop]
            display_value = value[:20] + '...' if len(value) > 20 else value
            print(f'  ✓ {prop} = {display_value}')
        else:
            print(f'  - {prop} (不存在，将创建)')
except Exception as e:
    print(f'Error reading config: {e}')
"
    echo

    # 显示操作进度
    log_info "⏳ [进度] 1/5 - 生成新的设备标识符..."

    # 生成新的ID
    local MAC_MACHINE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local MACHINE_ID="auth0|user_$(openssl rand -hex 32)"
    local SQM_ID="{$(uuidgen | tr '[:lower:]' '[:upper:]')}"

    log_info "✅ [进度] 1/5 - 设备标识符生成完成"

    log_info "⏳ [进度] 2/5 - 创建备份目录..."

    # 备份原始配置（增强版）
    local backup_dir="$HOME/Library/Application Support/Cursor/User/globalStorage/backups"
    if ! mkdir -p "$backup_dir"; then
        log_error "❌ [错误] 无法创建备份目录: $backup_dir"
        return 1
    fi

    local backup_name="storage.json.backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$backup_dir/$backup_name"

    log_info "⏳ [进度] 3/5 - 备份原始配置..."
    if ! cp "$config_path" "$backup_path"; then
        log_error "❌ [错误] 备份配置文件失败"
        return 1
    fi

    # 验证备份是否成功
    if [ -f "$backup_path" ]; then
        local backup_size=$(wc -c < "$backup_path")
        local original_size=$(wc -c < "$config_path")
        if [ "$backup_size" -eq "$original_size" ]; then
            log_info "✅ [进度] 3/5 - 配置备份成功: $backup_name"
        else
            log_warn "⚠️  [警告] 备份文件大小不匹配，但继续执行"
        fi
    else
        log_error "❌ [错误] 备份文件创建失败"
        return 1
    fi

    log_info "⏳ [进度] 4/5 - 更新配置文件..."

    # 使用Python修改JSON配置（更可靠，安全方式）
    local python_result=$(python3 -c "
import json
import sys

try:
    with open('$config_path', 'r', encoding='utf-8') as f:
        config = json.load(f)

    # 安全更新配置，确保属性存在
    properties_to_update = {
        'telemetry.machineId': '$MACHINE_ID',
        'telemetry.macMachineId': '$MAC_MACHINE_ID',
        'telemetry.devDeviceId': '$UUID',
        'telemetry.sqmId': '$SQM_ID'
    }

    for key, value in properties_to_update.items():
        if key in config:
            print(f'  ✓ 更新属性: {key}')
        else:
            print(f'  + 添加属性: {key}')
        config[key] = value

    with open('$config_path', 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

    print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
" 2>&1)

    # 🔧 关键修复：正确解析Python执行结果
    local python_exit_code=$?
    local python_success=false

    # 检查Python脚本是否成功执行
    if [ $python_exit_code -eq 0 ]; then
        # 检查输出中是否包含SUCCESS标记（忽略其他输出）
        if echo "$python_result" | grep -q "SUCCESS"; then
            python_success=true
            log_info "✅ [Python] 配置修改执行成功"
        else
            log_warn "⚠️  [Python] 执行成功但未找到SUCCESS标记"
            log_info "💡 [调试] Python完整输出:"
            echo "$python_result"
        fi
    else
        log_error "❌ [Python] 脚本执行失败，退出码: $python_exit_code"
        log_info "💡 [调试] Python完整输出:"
        echo "$python_result"
    fi

    if [ "$python_success" = true ]; then
        log_info "⏳ [进度] 5/5 - 验证修改结果..."

        # 🔒 关键修复：在验证前确保文件权限正确
        chmod 644 "$config_path" 2>/dev/null || true

        # 验证修改是否成功
        local verification_result=$(python3 -c "
import json
try:
    with open('$config_path', 'r', encoding='utf-8') as f:
        config = json.load(f)

    properties_to_check = {
        'telemetry.machineId': '$MACHINE_ID',
        'telemetry.macMachineId': '$MAC_MACHINE_ID',
        'telemetry.devDeviceId': '$UUID',
        'telemetry.sqmId': '$SQM_ID'
    }

    verification_passed = True
    for key, expected_value in properties_to_check.items():
        actual_value = config.get(key)
        if actual_value == expected_value:
            print(f'✓ {key}: 验证通过')
        else:
            print(f'✗ {key}: 验证失败 (期望: {expected_value}, 实际: {actual_value})')
            verification_passed = False

    if verification_passed:
        print('VERIFICATION_SUCCESS')
    else:
        print('VERIFICATION_FAILED')
except Exception as e:
    print(f'VERIFICATION_ERROR: {e}')
" 2>&1)

        # 检查验证结果（忽略其他输出，只关注最终结果）
        if echo "$verification_result" | grep -q "VERIFICATION_SUCCESS"; then
            log_info "✅ [进度] 5/5 - 修改验证成功"

            # 🔐 关键修复：设置配置文件为只读保护
            if chmod 444 "$config_path" 2>/dev/null; then
                log_info "🔐 [保护] 配置文件已设置为只读保护"
            else
                log_warn "⚠️  [警告] 无法设置配置文件只读保护"
            fi

            # 🛡️ 关键修复：确保目录权限正确
            ensure_cursor_directory_permissions

            echo
            log_info "🎉 [成功] 机器码配置修改完成！"
            log_info "📋 [详情] 已更新以下标识符："
            echo "   🔹 machineId: ${MACHINE_ID:0:20}..."
            echo "   🔹 macMachineId: $MAC_MACHINE_ID"
            echo "   🔹 devDeviceId: $UUID"
            echo "   🔹 sqmId: $SQM_ID"
            echo
            log_info "💾 [备份] 原配置已备份至: $backup_name"
            return 0
        else
            log_error "❌ [错误] 修改验证失败"
            log_info "💡 [验证详情]:"
            echo "$verification_result"
            log_info "🔄 [恢复] 正在恢复备份并修复权限..."

            # 恢复备份并确保权限正确
            if cp "$backup_path" "$config_path"; then
                chmod 644 "$config_path" 2>/dev/null || true
                ensure_cursor_directory_permissions
                log_info "✅ [恢复] 已恢复原始配置并修复权限"
            else
                log_error "❌ [错误] 恢复备份失败"
            fi
            return 1
        fi
    else
        log_error "❌ [错误] 修改配置失败"
        log_info "💡 [调试信息] Python执行详情:"
        echo "$python_result"

        # 尝试恢复备份并修复权限
        if [ -f "$backup_path" ]; then
            log_info "🔄 [恢复] 正在恢复备份配置并修复权限..."
            if cp "$backup_path" "$config_path"; then
                chmod 644 "$config_path" 2>/dev/null || true
                ensure_cursor_directory_permissions
                log_info "✅ [恢复] 已恢复原始配置并修复权限"
            else
                log_error "❌ [错误] 恢复备份失败"
            fi
        fi

        return 1
    fi
}



# 获取当前用户
get_current_user() {
    if [ "$EUID" -eq 0 ]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

CURRENT_USER=$(get_current_user)
if [ -z "$CURRENT_USER" ]; then
    log_error "无法获取用户名"
    exit 1
fi

# 定义配置文件路径
STORAGE_FILE="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
BACKUP_DIR="$HOME/Library/Application Support/Cursor/User/globalStorage/backups"

# 定义 Cursor 应用程序路径
CURSOR_APP_PATH="/Applications/Cursor.app"

# 新增：判断接口类型是否为Wi-Fi
is_wifi_interface() {
    local interface_name="$1"
    # 通过networksetup判断接口类型
    networksetup -listallhardwareports | \
        awk -v dev="$interface_name" 'BEGIN{found=0} /Hardware Port: Wi-Fi/{found=1} /Device:/{if(found && $2==dev){exit 0}else{found=0}}' && return 0 || return 1
}

# 新增：生成本地管理+单播MAC地址（IEEE标准）
generate_local_unicast_mac() {
    # 第一字节：LAA+单播（低两位10），其余随机
    local first_byte=$(( (RANDOM & 0xFC) | 0x02 ))
    local mac=$(printf '%02x:%02x:%02x:%02x:%02x:%02x' \
        $first_byte $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
    echo "$mac"
}

# 新增：自动检测并调用macchanger或spoof-mac
try_third_party_mac_tool() {
    local interface_name="$1"
    local random_mac="$2"
    local success=false
    # 优先macchanger
    if command -v macchanger >/dev/null 2>&1; then
        log_info "尝试使用macchanger修改接口 '$interface_name' 的MAC地址..."
        sudo macchanger -m "$random_mac" "$interface_name" >>"$LOG_FILE" 2>&1 && success=true
    fi
    # 若macchanger不可用，尝试spoof-mac
    if ! $success && command -v spoof-mac >/dev/null 2>&1; then
        log_info "尝试使用spoof-mac修改接口 '$interface_name' 的MAC地址..."
        sudo spoof-mac set $random_mac $interface_name >>"$LOG_FILE" 2>&1 && success=true
    fi
    if $success; then
        log_info "第三方工具修改MAC地址成功。"
        return 0
    else
        log_warn "未检测到可用的macchanger或spoof-mac，或第三方工具修改失败。"
        return 1
    fi
}

# 检测macOS版本和硬件类型
detect_macos_environment() {
    local macos_version=$(sw_vers -productVersion)
    local macos_major=$(echo "$macos_version" | cut -d. -f1)
    local macos_minor=$(echo "$macos_version" | cut -d. -f2)
    local hardware_type=""

    # 检测硬件类型
    if [[ $(uname -m) == "arm64" ]]; then
        hardware_type="Apple Silicon"
    else
        hardware_type="Intel"
    fi

    log_info "系统环境检测: macOS $macos_version ($hardware_type)"

    # 检查SIP状态
    local sip_status=$(csrutil status 2>/dev/null | grep -o "enabled\|disabled" || echo "unknown")
    log_info "系统完整性保护(SIP)状态: $sip_status"

    # 设置环境变量
    export MACOS_VERSION="$macos_version"
    export MACOS_MAJOR="$macos_major"
    export MACOS_MINOR="$macos_minor"
    export HARDWARE_TYPE="$hardware_type"
    export SIP_STATUS="$sip_status"

    # 检查是否为问题版本
    if [[ $macos_major -ge 12 ]] && [[ "$hardware_type" == "Apple Silicon" ]]; then
        log_warn "检测到可能存在MAC地址修改限制的环境 (macOS $macos_major+ Apple Silicon)"
        return 1
    fi

    return 0
}

# 增强的MAC地址修改函数，支持多种方法和兼容性检测
_change_mac_for_one_interface() {
    local interface_name="$1"
    if [ -z "$interface_name" ]; then
        log_error "_change_mac_for_one_interface: 未提供接口名称"
        return 1
    fi

    log_info "开始处理接口: $interface_name"

    # 环境检测
    detect_macos_environment
    local env_compatible=$?

    local current_mac=$(ifconfig "$interface_name" | awk '/ether/{print $2}')
    if [ -z "$current_mac" ]; then
        log_warn "无法获取接口 '$interface_name' 的当前 MAC 地址，可能已禁用或不存在。"
    else
        log_info "接口 '$interface_name' 当前 MAC 地址: $current_mac"
    fi

    local random_mac=$(generate_local_unicast_mac)
    log_info "为接口 '$interface_name' 生成新的本地管理+单播 MAC 地址: $random_mac"

    local mac_change_success=false
    local method_used=""

    # 方法1: 传统ifconfig方法 (优先用于兼容环境)
    if [[ $env_compatible -eq 0 ]]; then
        log_info "使用传统ifconfig方法修改MAC地址..."
        if _try_ifconfig_method "$interface_name" "$random_mac"; then
            mac_change_success=true
            method_used="ifconfig"
        fi
    fi

    # 方法2: 第三方工具方法 (用于新版本macOS或Apple Silicon)
    if [[ $mac_change_success == false ]]; then
        log_info "尝试使用第三方工具修改MAC地址..."
        if try_third_party_mac_tool "$interface_name" "$random_mac"; then
            mac_change_success=true
            method_used="third-party"
        fi
    fi

    # 方法3: 系统网络偏好设置方法 (最后尝试)
    if [[ $mac_change_success == false ]]; then
        log_info "尝试使用系统网络偏好设置方法..."
        if _try_networksetup_method "$interface_name" "$random_mac"; then
            mac_change_success=true
            method_used="networksetup"
        fi
    fi

    # 验证修改结果
    if [[ $mac_change_success == true ]]; then
        local final_mac_check=$(ifconfig "$interface_name" | awk '/ether/{print $2}')
        log_info "最终验证接口 '$interface_name' 新 MAC 地址: $final_mac_check"
        if [ "$final_mac_check" == "$random_mac" ]; then
            echo -e "${GREEN}✅ 成功使用 $method_used 方法修改接口 '$interface_name' 的 MAC 地址${NC}"
            return 0
        else
            log_warn "验证失败，MAC地址可能未生效或已被重置"
            mac_change_success=false
        fi
    fi

    # 失败处理
    if [[ $mac_change_success == false ]]; then
        log_error "所有MAC地址修改方法都失败了"
        _show_troubleshooting_info "$interface_name"

        # 失败时提供恢复/重试选项
        select_menu_option "MAC地址修改失败，您可以：" "重试本接口|跳过本接口|退出脚本" 0
        local choice=$?
        if [ "$choice" = "0" ]; then
            log_info "用户选择重试本接口。"
            _change_mac_for_one_interface "$interface_name"
        elif [ "$choice" = "1" ]; then
            log_info "用户选择跳过本接口。"
            return 1
        else
            log_info "用户选择退出脚本。"
            exit 1
        fi
        return 1
    fi
}

# 传统ifconfig方法
_try_ifconfig_method() {
    local interface_name="$1"
    local random_mac="$2"

    if is_wifi_interface "$interface_name"; then
        log_info "检测到接口 '$interface_name' 为Wi-Fi，先断开SSID..."
        sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -z 2>>"$LOG_FILE"
        sleep 3
    fi

    log_info "临时禁用接口 '$interface_name' 以修改 MAC 地址 (网络会短暂中断)..."
    if ! sudo ifconfig "$interface_name" down; then
        log_error "禁用接口 '$interface_name' 失败"
        return 1
    fi

    sleep 3

    # 尝试修改MAC地址
    if sudo ifconfig "$interface_name" ether "$random_mac" 2>>"$LOG_FILE"; then
        sudo ifconfig "$interface_name" up
        sleep 2
        return 0
    else
        log_error "ifconfig ether 命令失败"
        sudo ifconfig "$interface_name" up 2>/dev/null || true
        return 1
    fi
}

# 使用networksetup方法 (适用于某些受限环境)
_try_networksetup_method() {
    local interface_name="$1"
    local random_mac="$2"

    # 获取硬件端口名称
    local hardware_port=$(networksetup -listallhardwareports | grep -A1 "Device: $interface_name" | grep "Hardware Port:" | cut -d: -f2 | xargs)

    if [ -z "$hardware_port" ]; then
        log_warn "无法找到接口 $interface_name 对应的硬件端口"
        return 1
    fi

    log_info "尝试通过networksetup修改硬件端口 '$hardware_port' 的MAC地址"

    # 某些版本的macOS支持通过networksetup修改MAC地址
    if sudo networksetup -setmanual "$hardware_port" 2>/dev/null; then
        log_info "networksetup方法可能成功"
        return 0
    else
        log_warn "networksetup方法不支持或失败"
        return 1
    fi
}

# 显示故障排除信息
_show_troubleshooting_info() {
    local interface_name="$1"

    echo
    echo -e "${YELLOW}=== MAC地址修改故障排除信息 ===${NC}"
    echo -e "${BLUE}系统信息:${NC}"
    echo "  • macOS版本: $MACOS_VERSION"
    echo "  • 硬件类型: $HARDWARE_TYPE"
    echo "  • SIP状态: $SIP_STATUS"
    echo "  • 接口名称: $interface_name"
    echo

    echo -e "${BLUE}可能的原因:${NC}"
    if [[ "$HARDWARE_TYPE" == "Apple Silicon" ]] && [[ $MACOS_MAJOR -ge 12 ]]; then
        echo "  • Apple Silicon Mac在macOS 12+版本中对MAC地址修改有硬件限制"
        echo "  • 某些网络驱动程序不允许MAC地址修改"
    fi

    if [[ "$SIP_STATUS" == "enabled" ]]; then
        echo "  • 系统完整性保护(SIP)可能阻止了MAC地址修改"
    fi

    echo "  • 网络接口可能不支持MAC地址修改"
    echo "  • 权限不足或系统安全策略限制"
    echo

    echo -e "${BLUE}建议的解决方案:${NC}"
    echo "  1. 安装第三方工具:"
    echo "     brew install spoof-mac"
    echo "     brew install macchanger"
    echo
    echo "  2. 如果使用Apple Silicon Mac，考虑:"
    echo "     • 使用虚拟机运行需要MAC地址修改的应用"
    echo "     • 使用路由器级别的MAC地址过滤绕过"
    echo
    echo "  3. 临时禁用SIP (不推荐):"
    echo "     • 重启进入恢复模式"
    echo "     • 运行: csrutil disable"
    echo "     • 重启后尝试修改"
    echo "     • 完成后重新启用: csrutil enable"
    echo
    echo -e "${BLUE}技术细节:${NC}"
    echo "  • 错误通常为: ifconfig: ioctl (SIOCAIFADDR): Can't assign requested address"
    echo "  • 这表明系统内核拒绝了MAC地址修改请求"
    echo "  • 在Apple Silicon Mac上，这是硬件和驱动程序级别的限制"
    echo
}

# 检查权限
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 运行此脚本"
        echo "示例: sudo $0"
        exit 1
    fi
}

# 检查并关闭 Cursor 进程（保存进程信息）
check_and_kill_cursor() {
    log_info "🔍 [检查] 检查 Cursor 进程..."

    local attempt=1
    local max_attempts=5

    # 💾 保存Cursor进程路径
    CURSOR_PROCESS_PATH="/Applications/Cursor.app/Contents/MacOS/Cursor"

    # 函数：获取进程详细信息
    get_process_details() {
        local process_name="$1"
        log_debug "正在获取 $process_name 进程详细信息："
        ps aux | grep -i "/Applications/Cursor.app" | grep -v grep
    }

    while [ $attempt -le $max_attempts ]; do
        # 使用更精确的匹配来获取 Cursor 进程
        CURSOR_PIDS=$(ps aux | grep -i "/Applications/Cursor.app" | grep -v grep | awk '{print $2}')

        if [ -z "$CURSOR_PIDS" ]; then
            log_info "💡 [提示] 未发现运行中的 Cursor 进程"
            # 确认Cursor应用路径存在
            if [ -f "$CURSOR_PROCESS_PATH" ]; then
                log_info "💾 [保存] 已保存Cursor路径: $CURSOR_PROCESS_PATH"
            else
                log_warn "⚠️  [警告] 未找到Cursor应用，请确认已安装"
            fi
            return 0
        fi

        log_warn "⚠️  [警告] 发现 Cursor 进程正在运行"
        # 💾 保存进程信息
        log_info "💾 [保存] 已保存Cursor路径: $CURSOR_PROCESS_PATH"
        get_process_details "cursor"

        log_warn "🔄 [操作] 尝试关闭 Cursor 进程..."

        if [ $attempt -eq $max_attempts ]; then
            log_warn "💥 [强制] 尝试强制终止进程..."
            kill -9 $CURSOR_PIDS 2>/dev/null || true
        else
            kill $CURSOR_PIDS 2>/dev/null || true
        fi

        sleep 3

        # 同样使用更精确的匹配来检查进程是否还在运行
        if ! ps aux | grep -i "/Applications/Cursor.app" | grep -v grep > /dev/null; then
            log_info "✅ [成功] Cursor 进程已成功关闭"
            return 0
        fi

        log_warn "⏳ [等待] 等待进程关闭，尝试 $attempt/$max_attempts..."
        ((attempt++))
    done

    log_error "❌ [错误] 在 $max_attempts 次尝试后仍无法关闭 Cursor 进程"
    get_process_details "cursor"
    log_error "💥 [错误] 请手动关闭进程后重试"
    exit 1
}

# 备份配置文件
backup_config() {
    if [ ! -f "$STORAGE_FILE" ]; then
        log_warn "配置文件不存在，跳过备份"
        return 0
    fi

    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/storage.json.backup_$(date +%Y%m%d_%H%M%S)"

    if cp "$STORAGE_FILE" "$backup_file"; then
        chmod 644 "$backup_file"
        chown "$CURRENT_USER" "$backup_file"
        log_info "配置已备份到: $backup_file"
    else
        log_error "备份失败"
        exit 1
    fi
}

# 增强的系统MAC地址修改函数，支持多种兼容性检测和修改方法
change_system_mac_address() {
    log_info "开始尝试修改所有活动的 Wi-Fi/Ethernet 接口的系统 MAC 地址..."
    echo

    # 环境兼容性预检查
    detect_macos_environment
    local env_compatible=$?

    if [[ $env_compatible -ne 0 ]]; then
        echo -e "${YELLOW}⚠️  [兼容性警告]${NC} 检测到可能存在MAC地址修改限制的环境:"
        echo -e "${YELLOW}   • macOS版本: $MACOS_VERSION${NC}"
        echo -e "${YELLOW}   • 硬件类型: $HARDWARE_TYPE${NC}"
        echo -e "${YELLOW}   • SIP状态: $SIP_STATUS${NC}"
        echo
        echo -e "${BLUE}💡 [建议]${NC} 在此环境中，传统的ifconfig方法可能失败。"
        echo -e "${BLUE}   脚本将自动尝试多种兼容性方法，包括第三方工具。${NC}"
        echo

        # 检查第三方工具可用性
        local tools_available=false
        if command -v spoof-mac >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 检测到 spoof-mac 工具${NC}"
            tools_available=true
        fi
        if command -v macchanger >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 检测到 macchanger 工具${NC}"
            tools_available=true
        fi

        if [[ $tools_available == false ]]; then
            echo -e "${YELLOW}⚠️  未检测到第三方MAC修改工具${NC}"
            echo -e "${BLUE}💡 建议安装: brew install spoof-mac 或 brew install macchanger${NC}"
            echo
            read -p "是否继续尝试修改？(y/n): " continue_choice
            if [[ ! "$continue_choice" =~ ^(y|yes)$ ]]; then
                log_info "用户选择跳过MAC地址修改"
                return 1
            fi
        fi
    fi

    echo -e "${YELLOW}[警告]${NC} 即将尝试修改您所有活动的 Wi-Fi 或以太网接口的 MAC 地址。"
    echo -e "${YELLOW}[警告]${NC} 此更改是 ${RED}临时${NC} 的，将在您重启 Mac 后恢复为原始地址。"
    echo -e "${YELLOW}[警告]${NC} 修改 MAC 地址可能会导致临时的网络中断或连接问题。"
    echo -e "${YELLOW}[警告]${NC} 请确保您了解相关风险。此操作主要影响本地网络识别，而非互联网身份。"
    echo

    local active_interfaces=()
    local potential_interfaces=()
    local default_route_interface=""

    # 0. 尝试获取默认路由接口，作为后备
    log_info "尝试通过路由表获取默认网络接口 (用于后备)..."
    default_route_interface=$(route get default | grep 'interface:' | awk '{print $2}')
    if [ -n "$default_route_interface" ]; then
        log_info "检测到默认路由接口 (后备): $default_route_interface"
    else
        log_warn "未能通过路由表获取默认接口 (后备)。"
    fi

    # 1. 获取所有 Wi-Fi 和 Ethernet 接口名称
    log_info "正在检测 Wi-Fi 和 Ethernet 接口..."
    while IFS= read -r line; do
        if [[ $line == "Hardware Port: Wi-Fi" || $line == "Hardware Port: Ethernet" ]]; then
            read -r dev_line # 读取下一行 Device: enX
            device=$(echo "$dev_line" | awk '{print $2}')
            if [ -n "$device" ]; then
                log_debug "检测到潜在接口: $device ($line)"
                potential_interfaces+=("$device")
            fi
        fi
    done < <(networksetup -listallhardwareports)

    if [ ${#potential_interfaces[@]} -eq 0 ]; then
        log_warn "未能通过 networksetup 检测到任何 Wi-Fi 或 Ethernet 接口。"
        # 检查是否有路由表接口作为后备
        if [ -n "$default_route_interface" ]; then
            log_warn "将使用路由表检测到的接口 '$default_route_interface' 作为后备。"
            potential_interfaces+=("$default_route_interface")
        else
            log_warn "路由表也未能提供后备接口。"
            # 在此情况下，potential_interfaces 仍为空，后续逻辑会处理
        fi
    fi

    # 2. 检查哪些接口是活动的
    log_info "正在检查接口活动状态..."
    for interface_name in "${potential_interfaces[@]}"; do
        log_debug "检查接口 '$interface_name' 状态..."
        if ifconfig "$interface_name" 2>/dev/null | grep -q "status: active"; then
            log_info "发现活动接口: $interface_name"
            active_interfaces+=("$interface_name")
        else
            log_debug "接口 '$interface_name' 非活动或不存在。"
        fi
    done

    # 3. 检查是否找到活动接口
    if [ ${#active_interfaces[@]} -eq 0 ]; then
        log_warn "未找到任何活动的 Wi-Fi 或 Ethernet 接口可供修改 MAC 地址。"
        echo -e "${YELLOW}未找到活动的 Wi-Fi 或 Ethernet 接口。跳过 MAC 地址修改。${NC}"
        return 1 # 返回错误码，表示没有接口被修改
    fi

    log_info "将尝试为以下活动接口修改 MAC 地址: ${active_interfaces[*]}"
    echo

    # 4. 循环处理找到的活动接口
    local overall_success=true
    for interface_name in "${active_interfaces[@]}"; do
        if ! _change_mac_for_one_interface "$interface_name"; then
            log_warn "接口 '$interface_name' 的 MAC 地址修改失败或未完全成功。"
            overall_success=false
        fi
        echo # 在每个接口处理后添加空行
    done

    log_info "所有活动接口的 MAC 地址修改尝试完成。"

    if $overall_success; then
        return 0 # 所有尝试都成功
    else
        return 1 # 至少有一个尝试失败
    fi
}

# 生成随机 ID
generate_random_id() {
    # 生成32字节(64个十六进制字符)的随机数
    openssl rand -hex 32
}

# 生成随机 UUID
generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# 修改现有文件
modify_or_add_config() {
    local key="$1"
    local value="$2"
    local file="$3"

    if [ ! -f "$file" ]; then
        log_error "文件不存在: $file"
        return 1
    fi

    # 确保文件可写
    chmod 644 "$file" || {
        log_error "无法修改文件权限: $file"
        return 1
    }

    # 创建临时文件
    local temp_file=$(mktemp)

    # 检查key是否存在
    if grep -q "\"$key\":" "$file"; then
        # key存在,执行替换
        sed "s/\"$key\":[[:space:]]*\"[^\"]*\"/\"$key\": \"$value\"/" "$file" > "$temp_file" || {
            log_error "修改配置失败: $key"
            rm -f "$temp_file"
            return 1
        }
    else
        # key不存在,添加新的key-value对
        sed "s/}$/,\n    \"$key\": \"$value\"\n}/" "$file" > "$temp_file" || {
            log_error "添加配置失败: $key"
            rm -f "$temp_file"
            return 1
        }
    fi

    # 检查临时文件是否为空
    if [ ! -s "$temp_file" ]; then
        log_error "生成的临时文件为空"
        rm -f "$temp_file"
        return 1
    fi

    # 使用 cat 替换原文件内容
    cat "$temp_file" > "$file" || {
        log_error "无法写入文件: $file"
        rm -f "$temp_file"
        return 1
    }

    rm -f "$temp_file"

    # 恢复文件权限
    chmod 444 "$file"

    return 0
}

# 清理 Cursor 之前的修改
clean_cursor_app() {
    log_info "尝试清理 Cursor 之前的修改..."

    # 如果存在备份，直接恢复备份
    local latest_backup=""

    # 查找最新的备份
    latest_backup=$(find /tmp -name "Cursor.app.backup_*" -type d -print 2>/dev/null | sort -r | head -1)

    if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
        log_info "找到现有备份: $latest_backup"
        log_info "正在恢复原始版本..."

        # 停止 Cursor 进程
        check_and_kill_cursor

        # 恢复备份
        sudo rm -rf "$CURSOR_APP_PATH"
        sudo cp -R "$latest_backup" "$CURSOR_APP_PATH"
        sudo chown -R "$CURRENT_USER:staff" "$CURSOR_APP_PATH"
        sudo chmod -R 755 "$CURSOR_APP_PATH"

        log_info "已恢复原始版本"
        return 0
    else
        log_warn "未找到现有备份，尝试重新安装 Cursor..."
        echo "您可以从 https://cursor.sh 下载并重新安装 Cursor"
        echo "或者继续执行此脚本，将尝试修复现有安装"

        # 可以在这里添加重新下载和安装的逻辑
        return 1
    fi
}

# 修改 Cursor 主程序文件（安全模式）
modify_cursor_app_files() {
    log_info "正在安全修改 Cursor 主程序文件..."
    log_info "详细日志将记录到: $LOG_FILE"

    # 先清理之前的修改
    clean_cursor_app

    # 验证应用是否存在
    if [ ! -d "$CURSOR_APP_PATH" ]; then
        log_error "未找到 Cursor.app，请确认安装路径: $CURSOR_APP_PATH"
        return 1
    fi

    # 定义目标文件 - 将extensionHostProcess.js放在最前面优先处理
    local target_files=(
        "${CURSOR_APP_PATH}/Contents/Resources/app/out/vs/workbench/api/node/extensionHostProcess.js"
        "${CURSOR_APP_PATH}/Contents/Resources/app/out/main.js"
        "${CURSOR_APP_PATH}/Contents/Resources/app/out/vs/code/node/cliProcessMain.js"
    )

    # 检查文件是否存在并且是否已修改
    local need_modification=false
    local missing_files=false

    log_debug "检查目标文件..."
    for file in "${target_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_warn "文件不存在: ${file/$CURSOR_APP_PATH\//}"
            echo "[FILE_CHECK] 文件不存在: $file" >> "$LOG_FILE"
            missing_files=true
            continue
        fi

        echo "[FILE_CHECK] 文件存在: $file ($(wc -c < "$file") 字节)" >> "$LOG_FILE"

        if ! grep -q "return crypto.randomUUID()" "$file" 2>/dev/null; then
            log_info "文件需要修改: ${file/$CURSOR_APP_PATH\//}"
            grep -n "IOPlatformUUID" "$file" | head -3 >> "$LOG_FILE" || echo "[FILE_CHECK] 未找到 IOPlatformUUID" >> "$LOG_FILE"
            need_modification=true
            break
        else
            log_info "文件已修改: ${file/$CURSOR_APP_PATH\//}"
        fi
    done

    # 如果所有文件都已修改或不存在，则退出
    if [ "$missing_files" = true ]; then
        log_error "部分目标文件不存在，请确认 Cursor 安装是否完整"
        return 1
    fi

    if [ "$need_modification" = false ]; then
        log_info "所有目标文件已经被修改过，无需重复操作"
        return 0
    fi

    # 创建临时工作目录
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local temp_dir="/tmp/cursor_reset_${timestamp}"
    local temp_app="${temp_dir}/Cursor.app"
    local backup_app="/tmp/Cursor.app.backup_${timestamp}"

    log_debug "创建临时目录: $temp_dir"
    echo "[TEMP_DIR] 创建临时目录: $temp_dir" >> "$LOG_FILE"

    # 清理可能存在的旧临时目录
    if [ -d "$temp_dir" ]; then
        log_info "清理已存在的临时目录..."
        rm -rf "$temp_dir"
    fi

    # 创建新的临时目录
    mkdir -p "$temp_dir" || {
        log_error "无法创建临时目录: $temp_dir"
        echo "[ERROR] 无法创建临时目录: $temp_dir" >> "$LOG_FILE"
        return 1
    }

    # 备份原应用
    log_info "备份原应用..."
    echo "[BACKUP] 开始备份: $CURSOR_APP_PATH -> $backup_app" >> "$LOG_FILE"

    cp -R "$CURSOR_APP_PATH" "$backup_app" || {
        log_error "无法创建应用备份"
        echo "[ERROR] 备份失败: $CURSOR_APP_PATH -> $backup_app" >> "$LOG_FILE"
        rm -rf "$temp_dir"
        return 1
    }

    echo "[BACKUP] 备份完成" >> "$LOG_FILE"

    # 复制应用到临时目录
    log_info "创建临时工作副本..."
    echo "[COPY] 开始复制: $CURSOR_APP_PATH -> $temp_dir" >> "$LOG_FILE"

    cp -R "$CURSOR_APP_PATH" "$temp_dir" || {
        log_error "无法复制应用到临时目录"
        echo "[ERROR] 复制失败: $CURSOR_APP_PATH -> $temp_dir" >> "$LOG_FILE"
        rm -rf "$temp_dir" "$backup_app"
        return 1
    }

    echo "[COPY] 复制完成" >> "$LOG_FILE"

    # 确保临时目录的权限正确
    chown -R "$CURRENT_USER:staff" "$temp_dir"
    chmod -R 755 "$temp_dir"

    # 移除签名（增强兼容性）
    log_info "移除应用签名..."
    echo "[CODESIGN] 移除签名: $temp_app" >> "$LOG_FILE"

    codesign --remove-signature "$temp_app" 2>> "$LOG_FILE" || {
        log_warn "移除应用签名失败"
        echo "[WARN] 移除签名失败: $temp_app" >> "$LOG_FILE"
    }

    # 移除所有相关组件的签名
    local components=(
        "$temp_app/Contents/Frameworks/Cursor Helper.app"
        "$temp_app/Contents/Frameworks/Cursor Helper (GPU).app"
        "$temp_app/Contents/Frameworks/Cursor Helper (Plugin).app"
        "$temp_app/Contents/Frameworks/Cursor Helper (Renderer).app"
    )

    for component in "${components[@]}"; do
        if [ -e "$component" ]; then
            log_info "正在移除签名: $component"
            codesign --remove-signature "$component" || {
                log_warn "移除组件签名失败: $component"
            }
        fi
    done

    # 修改目标文件 - 优先处理js文件
    local modified_count=0
    local files=(
        "${temp_app}/Contents/Resources/app/out/vs/workbench/api/node/extensionHostProcess.js"
        "${temp_app}/Contents/Resources/app/out/main.js"
        "${temp_app}/Contents/Resources/app/out/vs/code/node/cliProcessMain.js"
    )

    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            log_warn "文件不存在: ${file/$temp_dir\//}"
            continue
        fi

        log_debug "处理文件: ${file/$temp_dir\//}"
        echo "[PROCESS] 开始处理文件: $file" >> "$LOG_FILE"
        echo "[PROCESS] 文件大小: $(wc -c < "$file") 字节" >> "$LOG_FILE"

        # 输出文件部分内容到日志
        echo "[FILE_CONTENT] 文件头部 100 行:" >> "$LOG_FILE"
        head -100 "$file" 2>/dev/null | grep -v "^$" | head -50 >> "$LOG_FILE"
        echo "[FILE_CONTENT] ..." >> "$LOG_FILE"

        # 创建文件备份
        cp "$file" "${file}.bak" || {
            log_error "无法创建文件备份: ${file/$temp_dir\//}"
            echo "[ERROR] 无法创建文件备份: $file" >> "$LOG_FILE"
            continue
        }

        # 使用 sed 替换而不是字符串操作
        if [[ "$file" == *"extensionHostProcess.js"* ]]; then
            log_debug "处理 extensionHostProcess.js 文件..."
            echo "[PROCESS_DETAIL] 开始处理 extensionHostProcess.js 文件" >> "$LOG_FILE"

            # 检查是否包含目标代码
            if grep -q 'i.header.set("x-cursor-checksum' "$file"; then
                log_debug "找到 x-cursor-checksum 设置代码"
                echo "[FOUND] 找到 x-cursor-checksum 设置代码" >> "$LOG_FILE"

                # 记录匹配的行到日志
                grep -n 'i.header.set("x-cursor-checksum' "$file" >> "$LOG_FILE"

                # 执行特定的替换
                if sed -i.tmp 's/i\.header\.set("x-cursor-checksum",e===void 0?`${p}${t}`:`${p}${t}\/${e}`)/i.header.set("x-cursor-checksum",e===void 0?`${p}${t}`:`${p}${t}\/${p}`)/' "$file"; then
                    log_info "成功修改 x-cursor-checksum 设置代码"
                    echo "[SUCCESS] 成功完成 x-cursor-checksum 设置代码替换" >> "$LOG_FILE"
                    # 记录修改后的行
                    grep -n 'i.header.set("x-cursor-checksum' "$file" >> "$LOG_FILE"
                    ((modified_count++))
                    log_info "成功修改文件: ${file/$temp_dir\//}"
                else
                    log_error "修改 x-cursor-checksum 设置代码失败"
                    cp "${file}.bak" "$file"
                fi
            else
                log_warn "未找到 x-cursor-checksum 设置代码"
                echo "[FILE_CHECK] 未找到 x-cursor-checksum 设置代码" >> "$LOG_FILE"

                # 记录文件部分内容到日志以便排查
                echo "[FILE_CONTENT] 文件中包含 'header.set' 的行:" >> "$LOG_FILE"
                grep -n "header.set" "$file" | head -20 >> "$LOG_FILE"

                echo "[FILE_CONTENT] 文件中包含 'checksum' 的行:" >> "$LOG_FILE"
                grep -n "checksum" "$file" | head -20 >> "$LOG_FILE"
            fi

            echo "[PROCESS_DETAIL] 完成处理 extensionHostProcess.js 文件" >> "$LOG_FILE"
        elif grep -q "IOPlatformUUID" "$file"; then
            log_debug "找到 IOPlatformUUID 关键字"
            echo "[FOUND] 找到 IOPlatformUUID 关键字" >> "$LOG_FILE"
            grep -n "IOPlatformUUID" "$file" | head -5 >> "$LOG_FILE"

            # 定位 IOPlatformUUID 相关函数
            if grep -q "function a\$" "$file"; then
                # 检查是否已经修改过
                if grep -q "return crypto.randomUUID()" "$file"; then
                    log_info "文件已经包含 randomUUID 调用，跳过修改"
                    ((modified_count++))
                    continue
                fi

                # 针对 main.js 中发现的代码结构进行修改
                if sed -i.tmp 's/function a\$(t){switch/function a\$(t){return crypto.randomUUID(); switch/' "$file"; then
                    log_debug "成功注入 randomUUID 调用到 a\$ 函数"
                    ((modified_count++))
                    log_info "成功修改文件: ${file/$temp_dir\//}"
                else
                    log_error "修改 a\$ 函数失败"
                    cp "${file}.bak" "$file"
                fi
            elif grep -q "async function v5" "$file"; then
                # 检查是否已经修改过
                if grep -q "return crypto.randomUUID()" "$file"; then
                    log_info "文件已经包含 randomUUID 调用，跳过修改"
                    ((modified_count++))
                    continue
                fi

                # 替代方法 - 修改 v5 函数
                if sed -i.tmp 's/async function v5(t){let e=/async function v5(t){return crypto.randomUUID(); let e=/' "$file"; then
                    log_debug "成功注入 randomUUID 调用到 v5 函数"
                    ((modified_count++))
                    log_info "成功修改文件: ${file/$temp_dir\//}"
                else
                    log_error "修改 v5 函数失败"
                    cp "${file}.bak" "$file"
                fi
            else
                # 检查是否已经注入了自定义代码
                if grep -q "// Cursor ID 修改工具注入" "$file"; then
                    log_info "文件已经包含自定义注入代码，跳过修改"
                    ((modified_count++))
                    continue
                fi

                # 新增检查：检查是否已存在 randomDeviceId_ 时间戳模式
                if grep -q "const randomDeviceId_[0-9]\\{10,\\}" "$file"; then
                    log_info "文件已经包含 randomDeviceId_ 模式，跳过通用注入"
                    echo "[FOUND] 文件已包含 randomDeviceId_ 模式，跳过通用注入: $file" >> "$LOG_FILE"
                    ((modified_count++)) # 计为已修改，防止后续尝试其他方法
                    continue
                fi

                # 使用更通用的注入方法
                log_warn "未找到具体函数，尝试使用通用修改方法"
                inject_code="
// Cursor ID 修改工具注入 - $(date +%Y%m%d%H%M%S)
// 随机设备ID生成器注入 - $(date +%s)
const randomDeviceId_$(date +%s) = () => {
    try {
        return require('crypto').randomUUID();
    } catch (e) {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
            const r = Math.random() * 16 | 0;
            return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }
};
"
                # 将代码注入到文件开头
                echo "$inject_code" > "${file}.new"
                cat "$file" >> "${file}.new"
                mv "${file}.new" "$file"

                # 替换调用点
                sed -i.tmp 's/await v5(!1)/randomDeviceId_'"$(date +%s)"'()/g' "$file"
                sed -i.tmp 's/a\$(t)/randomDeviceId_'"$(date +%s)"'()/g' "$file"

                log_debug "完成通用修改"
                ((modified_count++))
                log_info "使用通用方法成功修改文件: ${file/$temp_dir\//}"
            fi
        else
            # 未找到 IOPlatformUUID，可能是文件结构变化
            log_warn "未找到 IOPlatformUUID，尝试替代方法"

            # 检查是否已经注入或修改过
            if grep -q "return crypto.randomUUID()" "$file" || grep -q "// Cursor ID 修改工具注入" "$file"; then
                log_info "文件已经被修改过，跳过修改"
                ((modified_count++))
                continue
            fi

            # 尝试找其他关键函数如 getMachineId 或 getDeviceId
            if grep -q "function t\$()" "$file" || grep -q "async function y5" "$file"; then
                log_debug "找到设备ID相关函数"

                # 修改 MAC 地址获取函数
                if grep -q "function t\$()" "$file"; then
                    sed -i.tmp 's/function t\$(){/function t\$(){return "00:00:00:00:00:00";/' "$file"
                    log_debug "修改 MAC 地址获取函数成功"
                fi

                # 修改设备ID获取函数
                if grep -q "async function y5" "$file"; then
                    sed -i.tmp 's/async function y5(t){/async function y5(t){return crypto.randomUUID();/' "$file"
                    log_debug "修改设备ID获取函数成功"
                fi

                ((modified_count++))
                log_info "使用替代方法成功修改文件: ${file/$temp_dir\//}"
            else
                # 最后尝试的通用方法 - 在文件顶部插入重写函数定义
                log_warn "未找到任何已知函数，使用最通用的方法"

                inject_universal_code="
// Cursor ID 修改工具注入 - $(date +%Y%m%d%H%M%S)
// 全局拦截设备标识符 - $(date +%s)
const originalRequire_$(date +%s) = require;
require = function(module) {
    const result = originalRequire_$(date +%s)(module);
    if (module === 'crypto' && result.randomUUID) {
        const originalRandomUUID_$(date +%s) = result.randomUUID;
        result.randomUUID = function() {
            return '${new_uuid}';
        };
    }
    return result;
};

// 覆盖所有可能的系统ID获取函数
global.getMachineId = function() { return '${machine_id}'; };
global.getDeviceId = function() { return '${device_id}'; };
global.macMachineId = '${mac_machine_id}';
"
                # 将代码注入到文件开头
                local new_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
                local machine_id="auth0|user_$(openssl rand -hex 16)"
                local device_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
                local mac_machine_id=$(openssl rand -hex 32)

                inject_universal_code=${inject_universal_code//\$\{new_uuid\}/$new_uuid}
                inject_universal_code=${inject_universal_code//\$\{machine_id\}/$machine_id}
                inject_universal_code=${inject_universal_code//\$\{device_id\}/$device_id}
                inject_universal_code=${inject_universal_code//\$\{mac_machine_id\}/$mac_machine_id}

                echo "$inject_universal_code" > "${file}.new"
                cat "$file" >> "${file}.new"
                mv "${file}.new" "$file"

                log_debug "完成通用覆盖"
                ((modified_count++))
                log_info "使用最通用方法成功修改文件: ${file/$temp_dir\//}"
            fi
        fi

        # 添加在关键操作后记录日志
        echo "[MODIFIED] 文件修改后内容:" >> "$LOG_FILE"
        grep -n "return crypto.randomUUID()" "$file" | head -3 >> "$LOG_FILE"

        # 清理临时文件
        rm -f "${file}.tmp" "${file}.bak"
        echo "[PROCESS] 文件处理完成: $file" >> "$LOG_FILE"
    done

    if [ "$modified_count" -eq 0 ]; then
        log_error "未能成功修改任何文件"
        rm -rf "$temp_dir"
        return 1
    fi

    # 重新签名应用（增加重试机制）
    local max_retry=3
    local retry_count=0
    local sign_success=false

    while [ $retry_count -lt $max_retry ]; do
        ((retry_count++))
        log_info "尝试签名 (第 $retry_count 次)..."

        # 使用更详细的签名参数
        if codesign --sign - --force --deep --preserve-metadata=entitlements,identifier,flags "$temp_app" 2>&1 | tee /tmp/codesign.log; then
            # 验证签名
            if codesign --verify -vvvv "$temp_app" 2>/dev/null; then
                sign_success=true
                log_info "应用签名验证通过"
                break
            else
                log_warn "签名验证失败，错误日志："
                cat /tmp/codesign.log
            fi
        else
            log_warn "签名失败，错误日志："
            cat /tmp/codesign.log
        fi
        
        sleep 3
    done

    if ! $sign_success; then
        log_error "经过 $max_retry 次尝试仍无法完成签名"
        log_error "请手动执行以下命令完成签名："
        echo -e "${BLUE}sudo codesign --sign - --force --deep '${temp_app}'${NC}"
        echo -e "${YELLOW}操作完成后，请手动将应用复制到原路径：${NC}"
        echo -e "${BLUE}sudo cp -R '${temp_app}' '/Applications/'${NC}"
        log_info "临时文件保留在：${temp_dir}"
        return 1
    fi

    # 替换原应用
    log_info "安装修改版应用..."
    if ! sudo rm -rf "$CURSOR_APP_PATH" || ! sudo cp -R "$temp_app" "/Applications/"; then
        log_error "应用替换失败，正在恢复..."
        sudo rm -rf "$CURSOR_APP_PATH"
        sudo cp -R "$backup_app" "$CURSOR_APP_PATH"
        rm -rf "$temp_dir" "$backup_app"
        return 1
    fi

    # 清理临时文件
    rm -rf "$temp_dir" "$backup_app"

    # 设置权限
    sudo chown -R "$CURRENT_USER:staff" "$CURSOR_APP_PATH"
    sudo chmod -R 755 "$CURSOR_APP_PATH"

    log_info "Cursor 主程序文件修改完成！原版备份在: ${backup_app/$HOME/\~}"
    return 0
}

# 显示文件树结构
show_file_tree() {
    local base_dir=$(dirname "$STORAGE_FILE")
    echo
    log_info "文件结构:"
    echo -e "${BLUE}$base_dir${NC}"
    echo "├── globalStorage"
    echo "│   ├── storage.json (已修改)"
    echo "│   └── backups"

    # 列出备份文件
    if [ -d "$BACKUP_DIR" ]; then
        local backup_files=("$BACKUP_DIR"/*)
        if [ ${#backup_files[@]} -gt 0 ]; then
            for file in "${backup_files[@]}"; do
                if [ -f "$file" ]; then
                    echo "│       └── $(basename "$file")"
                fi
            done
        else
            echo "│       └── (空)"
        fi
    fi
    echo
}

# 显示公众号信息
show_follow_info() {
    echo
    echo -e "${GREEN}================================${NC}"
    echo -e "${YELLOW}  关注公众号【煎饼果子卷AI】一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬) ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
}

# 禁用自动更新
disable_auto_update() {
    local updater_path="$HOME/Library/Application Support/Caches/cursor-updater"
    local app_update_yml="/Applications/Cursor.app/Contents/Resources/app-update.yml"

    echo
    log_info "正在禁用 Cursor 自动更新..."

    # 备份并清空 app-update.yml
    if [ -f "$app_update_yml" ]; then
        log_info "备份并修改 app-update.yml..."
        if ! sudo cp "$app_update_yml" "${app_update_yml}.bak" 2>/dev/null; then
            log_warn "备份 app-update.yml 失败，继续执行..."
        fi

        if sudo bash -c "echo '' > \"$app_update_yml\"" && \
           sudo chmod 444 "$app_update_yml"; then
            log_info "成功禁用 app-update.yml"
        else
            log_error "修改 app-update.yml 失败，请手动执行以下命令："
            echo -e "${BLUE}sudo cp \"$app_update_yml\" \"${app_update_yml}.bak\"${NC}"
            echo -e "${BLUE}sudo bash -c 'echo \"\" > \"$app_update_yml\"'${NC}"
            echo -e "${BLUE}sudo chmod 444 \"$app_update_yml\"${NC}"
        fi
    else
        log_warn "未找到 app-update.yml 文件"
    fi

    # 同时也处理 cursor-updater
    log_info "处理 cursor-updater..."
    if sudo rm -rf "$updater_path" && \
       sudo touch "$updater_path" && \
       sudo chmod 444 "$updater_path"; then
        log_info "成功禁用 cursor-updater"
    else
        log_error "禁用 cursor-updater 失败，请手动执行以下命令："
        echo -e "${BLUE}sudo rm -rf \"$updater_path\" && sudo touch \"$updater_path\" && sudo chmod 444 \"$updater_path\"${NC}"
    fi

    echo
    log_info "验证方法："
    echo "1. 运行命令：ls -l \"$updater_path\""
    echo "   确认文件权限显示为：r--r--r--"
    echo "2. 运行命令：ls -l \"$app_update_yml\""
    echo "   确认文件权限显示为：r--r--r--"
    echo
    log_info "完成后请重启 Cursor"
}

# 新增恢复功能选项
restore_feature() {
    # 检查备份目录是否存在
    if [ ! -d "$BACKUP_DIR" ]; then
        log_warn "备份目录不存在"
        return 1
    fi

    # 使用 find 命令获取备份文件列表并存储到数组
    backup_files=()
    while IFS= read -r file; do
        [ -f "$file" ] && backup_files+=("$file")
    done < <(find "$BACKUP_DIR" -name "*.backup_*" -type f 2>/dev/null | sort)

    # 检查是否找到备份文件
    if [ ${#backup_files[@]} -eq 0 ]; then
        log_warn "未找到任何备份文件"
        return 1
    fi

    echo
    log_info "可用的备份文件："

    # 构建菜单选项字符串
    menu_options="退出 - 不恢复任何文件"
    for i in "${!backup_files[@]}"; do
        menu_options="$menu_options|$(basename "${backup_files[$i]}")"
    done

    # 使用菜单选择函数
    select_menu_option "请使用上下箭头选择要恢复的备份文件，按Enter确认:" "$menu_options" 0
    choice=$?

    # 处理用户输入
    if [ "$choice" = "0" ]; then
        log_info "跳过恢复操作"
        return 0
    fi

    # 获取选择的备份文件 (减1是因为第一个选项是"退出")
    local selected_backup="${backup_files[$((choice-1))]}"

    # 验证文件存在性和可读性
    if [ ! -f "$selected_backup" ] || [ ! -r "$selected_backup" ]; then
        log_error "无法访问选择的备份文件"
        return 1
    fi

    # 尝试恢复配置
    if cp "$selected_backup" "$STORAGE_FILE"; then
        chmod 644 "$STORAGE_FILE"
        chown "$CURRENT_USER" "$STORAGE_FILE"
        log_info "已从备份文件恢复配置: $(basename "$selected_backup")"
        return 0
    else
        log_error "恢复配置失败"
        return 1
    fi
}

# 解决"应用已损坏，无法打开"问题
fix_damaged_app() {
    log_info "正在修复"应用已损坏"问题..."

    # 检查Cursor应用是否存在
    if [ ! -d "$CURSOR_APP_PATH" ]; then
        log_error "未找到Cursor应用: $CURSOR_APP_PATH"
        return 1
    fi

    log_info "尝试移除隔离属性..."
    if sudo xattr -rd com.apple.quarantine "$CURSOR_APP_PATH" 2>/dev/null; then
        log_info "成功移除隔离属性"
    else
        log_warn "移除隔离属性失败，尝试其他方法..."
    fi

    log_info "尝试重新签名应用..."
    if sudo codesign --force --deep --sign - "$CURSOR_APP_PATH" 2>/dev/null; then
        log_info "应用重新签名成功"
    else
        log_warn "应用重新签名失败"
    fi

    echo
    log_info "修复完成！请尝试重新打开Cursor应用"
    echo
    echo -e "${YELLOW}如果仍然无法打开，您可以尝试以下方法：${NC}"
    echo "1. 在系统偏好设置->安全性与隐私中，点击"仍要打开"按钮"
    echo "2. 暂时关闭Gatekeeper（不建议）: sudo spctl --master-disable"
    echo "3. 重新下载安装Cursor应用"
    echo
    echo -e "${BLUE}参考链接: https://sysin.org/blog/macos-if-crashes-when-opening/${NC}"

    return 0
}

# 新增：通用菜单选择函数
# 参数:
# $1 - 提示信息
# $2 - 选项数组，格式为 "选项1|选项2|选项3"
# $3 - 默认选项索引 (从0开始)
# 返回: 选中的选项索引 (从0开始)
select_menu_option() {
    local prompt="$1"
    IFS='|' read -ra options <<< "$2"
    local default_index=${3:-0}
    local selected_index=$default_index
    local key_input
    local cursor_up='\033[A'
    local cursor_down='\033[B'
    local enter_key=$'\n'

    # 保存光标位置
    tput sc

    # 显示提示信息
    echo -e "$prompt"

    # 第一次显示菜单
    for i in "${!options[@]}"; do
        if [ $i -eq $selected_index ]; then
            echo -e " ${GREEN}►${NC} ${options[$i]}"
        else
            echo -e "   ${options[$i]}"
        fi
    done

    # 循环处理键盘输入
    while true; do
        # 读取单个按键
        read -rsn3 key_input

        # 检测按键
        case "$key_input" in
            # 上箭头键
            $'\033[A')
                if [ $selected_index -gt 0 ]; then
                    ((selected_index--))
                fi
                ;;
            # 下箭头键
            $'\033[B')
                if [ $selected_index -lt $((${#options[@]}-1)) ]; then
                    ((selected_index++))
                fi
                ;;
            # Enter键
            "")
                echo # 换行
                log_info "您选择了: ${options[$selected_index]}"
                return $selected_index
                ;;
        esac

        # 恢复光标位置
        tput rc

        # 重新显示菜单
        for i in "${!options[@]}"; do
            if [ $i -eq $selected_index ]; then
                echo -e " ${GREEN}►${NC} ${options[$i]}"
            else
                echo -e "   ${options[$i]}"
            fi
        done
    done
}

# 主函数
main() {

    # 初始化日志文件
    initialize_log
    log_info "脚本启动..."

    # 记录系统信息
    log_info "系统信息: $(uname -a)"
    log_info "当前用户: $CURRENT_USER"
    log_cmd_output "sw_vers" "macOS 版本信息"
    log_cmd_output "which codesign" "codesign 路径"
    log_cmd_output "ls -ld "$CURSOR_APP_PATH"" "Cursor 应用信息"

    # 新增环境检查
    if [[ $(uname) != "Darwin" ]]; then
        log_error "本脚本仅支持 macOS 系统"
        exit 1
    fi

    clear
    # 显示 Logo
    echo -e "
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
    "
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}🚀   Cursor 防掉试用Pro删除工具          ${NC}"
    echo -e "${YELLOW}📱  关注公众号【煎饼果子卷AI】     ${NC}"
    echo -e "${YELLOW}🤝  一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    echo -e "${YELLOW}💰  [小小广告]  出售CursorPro教育号一年质保三个月，有需要找我(86)，WeChat：JavaRookie666  ${NC}"
    echo
    echo -e "${YELLOW}💡 [重要提示]${NC} 本工具采用分阶段执行策略，既能彻底清理又能修改机器码。"
    echo -e "${YELLOW}💡 [重要提示]${NC} 本工具免费，如果对您有帮助，请关注公众号【煎饼果子卷AI】"
    echo

    # 🎯 用户选择菜单
    echo
    echo -e "${GREEN}🎯 [选择模式]${NC} 请选择您要执行的操作："
    echo
    echo -e "${BLUE}  1️⃣  仅修改机器码${NC}"
    echo -e "${YELLOW}      • 仅执行机器码修改功能${NC}"
    echo -e "${YELLOW}      • 跳过文件夹删除/环境重置步骤${NC}"
    echo -e "${YELLOW}      • 保留现有Cursor配置和数据${NC}"
    echo
    echo -e "${BLUE}  2️⃣  重置环境+修改机器码${NC}"
    echo -e "${RED}      • 执行完全环境重置（删除Cursor文件夹）${NC}"
    echo -e "${RED}      • ⚠️  配置将丢失，请注意备份${NC}"
    echo -e "${YELLOW}      • 按照机器代码修改${NC}"
    echo -e "${YELLOW}      • 这相当于当前的完整脚本行为${NC}"
    echo

    # 获取用户选择
    while true; do
        read -p "请输入选择 (1 或 2): " user_choice
        if [ "$user_choice" = "1" ]; then
            echo -e "${GREEN}✅ [选择]${NC} 您选择了：仅修改机器码"
            execute_mode="MODIFY_ONLY"
            break
        elif [ "$user_choice" = "2" ]; then
            echo -e "${GREEN}✅ [选择]${NC} 您选择了：重置环境+修改机器码"
            echo -e "${RED}⚠️  [重要警告]${NC} 此操作将删除所有Cursor配置文件！"
            read -p "确认执行完全重置？(输入 yes 确认，其他任意键取消): " confirm_reset
            if [ "$confirm_reset" = "yes" ]; then
                execute_mode="RESET_AND_MODIFY"
                break
            else
                echo -e "${YELLOW}👋 [取消]${NC} 用户取消重置操作"
                continue
            fi
        else
            echo -e "${RED}❌ [错误]${NC} 无效选择，请输入 1 或 2"
        fi
    done

    echo

    # 📋 根据选择显示执行流程说明
    if [ "$execute_mode" = "MODIFY_ONLY" ]; then
        echo -e "${GREEN}📋 [执行流程]${NC} 仅修改机器码模式将按以下步骤执行："
        echo -e "${BLUE}  1️⃣  检测Cursor配置文件${NC}"
        echo -e "${BLUE}  2️⃣  备份现有配置文件${NC}"
        echo -e "${BLUE}  3️⃣  修改机器码配置${NC}"
        echo -e "${BLUE}  4️⃣  显示操作完成信息${NC}"
        echo
        echo -e "${YELLOW}⚠️  [注意事项]${NC}"
        echo -e "${YELLOW}  • 不会删除任何文件夹或重置环境${NC}"
        echo -e "${YELLOW}  • 保留所有现有配置和数据${NC}"
        echo -e "${YELLOW}  • 原配置文件会自动备份${NC}"
        echo -e "${YELLOW}  • 需要Python3环境来处理JSON配置文件${NC}"
    else
        echo -e "${GREEN}📋 [执行流程]${NC} 重置环境+修改机器码模式将按以下步骤执行："
        echo -e "${BLUE}  1️⃣  检测并关闭Cursor进程${NC}"
        echo -e "${BLUE}  2️⃣  保存Cursor程序路径信息${NC}"
        echo -e "${BLUE}  3️⃣  删除指定的Cursor试用相关文件夹${NC}"
        echo -e "${BLUE}      📁 ~/Library/Application Support/Cursor${NC}"
        echo -e "${BLUE}      📁 ~/.cursor${NC}"
        echo -e "${BLUE}  3.5️⃣ 预创建必要目录结构，避免权限问题${NC}"
        echo -e "${BLUE}  4️⃣  重新启动Cursor让其生成新的配置文件${NC}"
        echo -e "${BLUE}  5️⃣  等待配置文件生成完成（最多45秒）${NC}"
        echo -e "${BLUE}  6️⃣  关闭Cursor进程${NC}"
        echo -e "${BLUE}  7️⃣  修改新生成的机器码配置文件${NC}"
        echo -e "${BLUE}  8️⃣  修改系统MAC地址${NC}"
        echo -e "${BLUE}  9️⃣  禁用自动更新${NC}"
        echo -e "${BLUE}  🔟  显示操作完成统计信息${NC}"
        echo
        echo -e "${YELLOW}⚠️  [注意事项]${NC}"
        echo -e "${YELLOW}  • 脚本执行过程中请勿手动操作Cursor${NC}"
        echo -e "${YELLOW}  • 建议在执行前关闭所有Cursor窗口${NC}"
        echo -e "${YELLOW}  • 执行完成后需要重新启动Cursor${NC}"
        echo -e "${YELLOW}  • 原配置文件会自动备份到backups文件夹${NC}"
        echo -e "${YELLOW}  • 需要Python3环境来处理JSON配置文件${NC}"
        echo -e "${YELLOW}  • MAC地址修改是临时的，重启后恢复${NC}"
    fi
    echo

    # 🤔 用户确认
    echo -e "${GREEN}🤔 [确认]${NC} 请确认您已了解上述执行流程"
    read -p "是否继续执行？(输入 y 或 yes 继续，其他任意键退出): " confirmation
    if [[ ! "$confirmation" =~ ^(y|yes)$ ]]; then
        echo -e "${YELLOW}👋 [退出]${NC} 用户取消执行，脚本退出"
        exit 0
    fi
    echo -e "${GREEN}✅ [确认]${NC} 用户确认继续执行"
    echo

    # 🚀 根据用户选择执行相应功能
    if [ "$execute_mode" = "MODIFY_ONLY" ]; then
        log_info "🚀 [开始] 开始执行仅修改机器码功能..."

        # 先进行环境检查
        if ! test_cursor_environment "MODIFY_ONLY"; then
            echo
            log_error "❌ [环境检查失败] 无法继续执行"
            echo
            log_info "💡 [建议] 请选择以下操作："
            echo -e "${BLUE}  1️⃣  选择'重置环境+修改机器码'选项（推荐）${NC}"
            echo -e "${BLUE}  2️⃣  手动启动Cursor一次，然后重新运行脚本${NC}"
            echo -e "${BLUE}  3️⃣  检查Cursor是否正确安装${NC}"
            echo -e "${BLUE}  4️⃣  安装Python3: brew install python3${NC}"
            echo
            read -p "按回车键退出..."
            exit 1
        fi

        # 执行机器码修改
        if modify_machine_code_config "MODIFY_ONLY"; then
            echo
            log_info "🎉 [完成] 机器码修改完成！"
            log_info "💡 [提示] 现在可以启动Cursor使用新的机器码配置"
        else
            echo
            log_error "❌ [失败] 机器码修改失败！"
            log_info "💡 [建议] 请尝试'重置环境+修改机器码'选项"
        fi

        # 🔧 修改系统MAC地址（仅修改模式也需要）
        echo
        log_info "🔧 [MAC地址] 开始修改系统MAC地址..."
        if change_system_mac_address; then
            log_info "✅ [成功] MAC地址修改完成！"
        else
            log_warn "⚠️  [警告] MAC地址修改失败或部分失败"
            log_info "💡 [提示] 这可能影响设备识别绕过的效果"
        fi

        # 🚫 禁用自动更新（仅修改模式也需要）
        echo
        log_info "🚫 [禁用更新] 正在禁用Cursor自动更新..."
        disable_auto_update
    else
        # 完整的重置环境+修改机器码流程
        log_info "🚀 [开始] 开始执行重置环境+修改机器码功能..."

        # 🚀 执行主要功能
        check_permissions
        check_and_kill_cursor

        # 🚨 重要警告提示
        echo
        echo -e "${RED}🚨 [重要警告]${NC} ============================================"
        log_warn "⚠️  [风控提醒] Cursor 风控机制非常严格！"
        log_warn "⚠️  [必须删除] 必须完全删除指定文件夹，不能有任何残留设置"
        log_warn "⚠️  [防掉试用] 只有彻底清理才能有效防止掉试用Pro状态"
        echo -e "${RED}🚨 [重要警告]${NC} ============================================"
        echo

        # 🎯 执行 Cursor 防掉试用Pro删除文件夹功能
        log_info "🚀 [开始] 开始执行核心功能..."
        remove_cursor_trial_folders

        # 🔄 重启Cursor让其重新生成配置文件
        restart_cursor_and_wait

        # 🛠️ 修改机器码配置
        modify_machine_code_config

        # 🔧 修改系统MAC地址
        echo
        log_info "🔧 [MAC地址] 开始修改系统MAC地址..."
        if change_system_mac_address; then
            log_info "✅ [成功] MAC地址修改完成！"
        else
            log_warn "⚠️  [警告] MAC地址修改失败或部分失败"
            log_info "💡 [提示] 这可能影响设备识别绕过的效果"
        fi
    fi

    # 🚫 禁用自动更新
    echo
    log_info "🚫 [禁用更新] 正在禁用Cursor自动更新..."
    disable_auto_update

    # 🎉 显示操作完成信息
    echo
    log_info "🎉 [完成] Cursor 防掉试用Pro删除操作已完成！"
    echo

    # 📱 显示公众号信息
    echo -e "${GREEN}================================${NC}"
    echo -e "${YELLOW}📱  关注公众号【煎饼果子卷AI】一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    log_info "🚀 [提示] 现在可以重新启动 Cursor 尝试使用了！"
    echo

    # 🎉 显示修改结果总结
    echo
    echo -e "${GREEN}================================${NC}"
    echo -e "${BLUE}   🎯 修改结果总结     ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ JSON配置文件修改: 完成${NC}"
    echo -e "${GREEN}✅ MAC地址修改: 完成${NC}"
    echo -e "${GREEN}✅ 自动更新禁用: 完成${NC}"
    echo -e "${GREEN}================================${NC}"
    echo

    # 🎉 脚本执行完成
    log_info "🎉 [完成] 所有操作已完成！"
    echo
    log_info "💡 [重要提示] 完整的Cursor破解流程已执行："
    echo -e "${BLUE}  ✅ 机器码配置文件修改${NC}"
    echo -e "${BLUE}  ✅ 系统MAC地址修改${NC}"
    echo -e "${BLUE}  ✅ 自动更新功能禁用${NC}"
    echo
    log_warn "⚠️  [注意] 重启 Cursor 后生效"
    echo
    log_info "🚀 [下一步] 现在可以启动 Cursor 尝试使用了！"
    echo

    # 记录脚本完成信息
    log_info "📝 [日志] 脚本执行完成"
    echo "========== Cursor 防掉试用Pro删除工具日志结束 $(date) ==========" >> "$LOG_FILE"

    # 显示日志文件位置
    echo
    log_info "📄 [日志] 详细日志已保存到: $LOG_FILE"
    echo "如遇问题请将此日志文件提供给开发者以协助排查"
    echo
}

# 执行主函数
main

