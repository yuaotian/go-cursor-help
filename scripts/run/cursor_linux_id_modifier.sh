#!/bin/bash

# 设置错误处理
set -e

# 定义日志文件路径
LOG_FILE="/tmp/cursor_linux_id_modifier.log"

# 初始化日志文件
initialize_log() {
    echo "========== Cursor ID 修改工具日志开始 $(date) ==========" > "$LOG_FILE"
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

# 定义Linux下的Cursor路径
CURSOR_CONFIG_DIR="$HOME/.config/Cursor"
STORAGE_FILE="$CURSOR_CONFIG_DIR/User/globalStorage/storage.json"
BACKUP_DIR="$CURSOR_CONFIG_DIR/User/globalStorage/backups"

# 可能的Cursor二进制路径
CURSOR_BIN_PATHS=(
    "/usr/bin/cursor"
    "/usr/local/bin/cursor"
    "$HOME/.local/bin/cursor"
    "/opt/cursor/cursor"
    "/snap/bin/cursor"
)

# 找到Cursor安装路径
find_cursor_path() {
    log_info "查找Cursor安装路径..."
    
    for path in "${CURSOR_BIN_PATHS[@]}"; do
        if [ -f "$path" ]; then
            log_info "找到Cursor安装路径: $path"
            CURSOR_PATH="$path"
            return 0
        fi
    done

    # 尝试通过which命令定位
    if command -v cursor &> /dev/null; then
        CURSOR_PATH=$(which cursor)
        log_info "通过which找到Cursor: $CURSOR_PATH"
        return 0
    fi
    
    # 尝试查找可能的安装路径
    local cursor_paths=$(find /usr /opt $HOME/.local -name "cursor" -type f -executable 2>/dev/null)
    if [ -n "$cursor_paths" ]; then
        CURSOR_PATH=$(echo "$cursor_paths" | head -1)
        log_info "通过查找找到Cursor: $CURSOR_PATH"
        return 0
    fi
    
    log_warn "未找到Cursor可执行文件，将尝试使用配置目录"
    return 1
}

# 查找并定位Cursor资源文件目录
find_cursor_resources() {
    log_info "查找Cursor资源目录..."
    
    # 可能的资源目录路径
    local resource_paths=(
        "/usr/lib/cursor"
        "/usr/share/cursor"
        "/opt/cursor"
        "$HOME/.local/share/cursor"
    )
    
    for path in "${resource_paths[@]}"; do
        if [ -d "$path" ]; then
            log_info "找到Cursor资源目录: $path"
            CURSOR_RESOURCES="$path"
            return 0
        fi
    done
    
    # 如果有CURSOR_PATH，尝试从它推断
    if [ -n "$CURSOR_PATH" ]; then
        local base_dir=$(dirname "$CURSOR_PATH")
        if [ -d "$base_dir/resources" ]; then
            CURSOR_RESOURCES="$base_dir/resources"
            log_info "通过二进制路径找到资源目录: $CURSOR_RESOURCES"
            return 0
        fi
    fi
    
    log_warn "未找到Cursor资源目录"
    return 1
}

# 检查权限
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 运行此脚本"
        echo "示例: sudo $0"
        exit 1
    fi
}

# 检查并关闭 Cursor 进程
check_and_kill_cursor() {
    log_info "检查 Cursor 进程..."
    
    local attempt=1
    local max_attempts=5
    
    # 函数：获取进程详细信息
    get_process_details() {
        local process_name="$1"
        log_debug "正在获取 $process_name 进程详细信息："
        ps aux | grep -i "cursor" | grep -v grep
    }
    
    while [ $attempt -le $max_attempts ]; do
        # 使用更精确的匹配来获取 Cursor 进程
        CURSOR_PIDS=$(pgrep -f "cursor" || true)
        
        if [ -z "$CURSOR_PIDS" ]; then
            log_info "未发现运行中的 Cursor 进程"
            return 0
        fi
        
        log_warn "发现 Cursor 进程正在运行"
        get_process_details "cursor"
        
        log_warn "尝试关闭 Cursor 进程..."
        
        if [ $attempt -eq $max_attempts ]; then
            log_warn "尝试强制终止进程..."
            kill -9 $CURSOR_PIDS 2>/dev/null || true
        else
            kill $CURSOR_PIDS 2>/dev/null || true
        fi
        
        sleep 1
        
        # 再次检查进程是否还在运行
        if ! pgrep -f "cursor" > /dev/null; then
            log_info "Cursor 进程已成功关闭"
            return 0
        fi
        
        log_warn "等待进程关闭，尝试 $attempt/$max_attempts..."
        ((attempt++))
    done
    
    log_error "在 $max_attempts 次尝试后仍无法关闭 Cursor 进程"
    get_process_details "cursor"
    log_error "请手动关闭进程后重试"
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

# 生成随机 ID
generate_random_id() {
    # 生成32字节(64个十六进制字符)的随机数
    openssl rand -hex 32
}

# 生成随机 UUID
generate_uuid() {
    # 在Linux上使用uuidgen生成UUID
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # 备选方案：使用/proc/sys/kernel/random/uuid
        if [ -f /proc/sys/kernel/random/uuid ]; then
            cat /proc/sys/kernel/random/uuid
        else
            # 最后备选方案：使用openssl生成
            openssl rand -hex 16 | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-\9\10-\11\12\13\14\15\16/'
        fi
    fi
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

# 生成新的配置
generate_new_config() {
    echo
    log_warn "机器码重置选项"
    
    # 使用菜单选择函数询问用户是否重置机器码
    select_menu_option "是否需要重置机器码? (通常情况下，只修改js文件即可)：" "不重置 - 仅修改js文件即可|重置 - 同时修改配置文件和机器码" 0
    reset_choice=$?
    
    # 记录日志以便调试
    echo "[INPUT_DEBUG] 机器码重置选项选择: $reset_choice" >> "$LOG_FILE"
    
    # 处理用户选择 - 索引0对应"不重置"选项，索引1对应"重置"选项
    if [ "$reset_choice" = "1" ]; then
        log_info "您选择了重置机器码"
        
        # 确保配置文件目录存在
        if [ -f "$STORAGE_FILE" ]; then
            log_info "发现已有配置文件: $STORAGE_FILE"
            
            # 备份现有配置（以防万一）
            backup_config
            
            # 生成并设置新的设备ID
            local new_device_id=$(generate_uuid)
            local new_machine_id="auth0|user_$(openssl rand -hex 16)"
            
            log_info "正在设置新的设备和机器ID..."
            log_debug "新设备ID: $new_device_id"
            log_debug "新机器ID: $new_machine_id"
            
            # 修改配置文件
            if modify_or_add_config "deviceId" "$new_device_id" "$STORAGE_FILE" && \
               modify_or_add_config "machineId" "$new_machine_id" "$STORAGE_FILE"; then
                log_info "配置文件修改成功"
            else
                log_error "配置文件修改失败"
            fi
        else
            log_warn "未找到配置文件，这是正常的，脚本将跳过ID修改"
        fi
    else
        log_info "您选择了不重置机器码，将仅修改js文件"
        
        # 确保配置文件目录存在
        if [ -f "$STORAGE_FILE" ]; then
            log_info "发现已有配置文件: $STORAGE_FILE"
            
            # 备份现有配置（以防万一）
            backup_config
        else
            log_warn "未找到配置文件，这是正常的，脚本将跳过ID修改"
        fi
    fi
    
    echo
    log_info "配置处理完成"
}

# 查找Cursor的JS文件
find_cursor_js_files() {
    log_info "查找Cursor的JS文件..."
    
    local js_files=()
    local found=false
    
    # 如果找到了资源目录，在资源目录中搜索
    if [ -n "$CURSOR_RESOURCES" ]; then
        log_debug "在资源目录中搜索JS文件: $CURSOR_RESOURCES"
        
        # 在资源目录中递归搜索特定JS文件
        local js_patterns=(
            "*/extensionHostProcess.js"
            "*/main.js"
            "*/cliProcessMain.js"
            "*/app/out/vs/workbench/api/node/extensionHostProcess.js"
            "*/app/out/main.js"
            "*/app/out/vs/code/node/cliProcessMain.js"
        )
        
        for pattern in "${js_patterns[@]}"; do
            local files=$(find "$CURSOR_RESOURCES" -path "$pattern" -type f 2>/dev/null)
            if [ -n "$files" ]; then
                while read -r file; do
                    log_info "找到JS文件: $file"
                    js_files+=("$file")
                    found=true
                done <<< "$files"
            fi
        done
    fi
    
    # 如果还没找到，尝试在/usr和$HOME目录下搜索
    if [ "$found" = false ]; then
        log_warn "在资源目录中未找到JS文件，尝试在其他目录中搜索..."
        
        # 在系统目录中搜索，限制深度以避免过长搜索
        local search_dirs=(
            "/usr/lib/cursor"
            "/usr/share/cursor"
            "/opt/cursor"
            "$HOME/.config/Cursor"
            "$HOME/.local/share/cursor"
        )
        
        for dir in "${search_dirs[@]}"; do
            if [ -d "$dir" ]; then
                log_debug "搜索目录: $dir"
                local files=$(find "$dir" -name "*.js" -type f -exec grep -l "IOPlatformUUID\|x-cursor-checksum" {} \; 2>/dev/null)
                if [ -n "$files" ]; then
                    while read -r file; do
                        log_info "找到JS文件: $file"
                        js_files+=("$file")
                        found=true
                    done <<< "$files"
                fi
            fi
        done
    fi
    
    if [ "$found" = false ]; then
        log_error "未找到任何可修改的JS文件"
        return 1
    fi
    
    # 保存找到的文件列表到全局变量
    CURSOR_JS_FILES=("${js_files[@]}")
    log_info "找到 ${#CURSOR_JS_FILES[@]} 个JS文件需要修改"
    return 0
}

# 修改Cursor的JS文件
modify_cursor_js_files() {
    log_info "开始修改Cursor的JS文件..."
    
    # 先查找需要修改的JS文件
    if ! find_cursor_js_files; then
        log_error "无法找到可修改的JS文件"
        return 1
    fi
    
    local modified_count=0
    
    for file in "${CURSOR_JS_FILES[@]}"; do
        log_info "处理文件: $file"
        
        # 创建文件备份
        local backup_file="${file}.backup_$(date +%Y%m%d%H%M%S)"
        if ! cp "$file" "$backup_file"; then
            log_error "无法创建文件备份: $file"
            continue
        fi
        
        # 确保文件可写
        chmod 644 "$file" || {
            log_error "无法修改文件权限: $file"
            continue
        }
        
        # 检查文件内容并进行相应修改
        if grep -q 'i.header.set("x-cursor-checksum' "$file"; then
            log_debug "找到 x-cursor-checksum 设置代码"
            
            # 执行特定的替换
            if sed -i 's/i\.header\.set("x-cursor-checksum",e===void 0?`${p}${t}`:`${p}${t}\/${e}`)/i.header.set("x-cursor-checksum",e===void 0?`${p}${t}`:`${p}${t}\/${p}`)/' "$file"; then
                log_info "成功修改 x-cursor-checksum 设置代码"
                ((modified_count++))
            else
                log_error "修改 x-cursor-checksum 设置代码失败"
                # 恢复备份
                cp "$backup_file" "$file"
            fi
        elif grep -q "IOPlatformUUID" "$file"; then
            log_debug "找到 IOPlatformUUID 关键字"
            
            # 尝试不同的替换模式
            if grep -q "function a\$" "$file" && ! grep -q "return crypto.randomUUID()" "$file"; then
                if sed -i 's/function a\$(t){switch/function a\$(t){return crypto.randomUUID(); switch/' "$file"; then
                    log_debug "成功注入 randomUUID 调用到 a\$ 函数"
                    ((modified_count++))
                else
                    log_error "修改 a\$ 函数失败"
                    cp "$backup_file" "$file"
                fi
            elif grep -q "async function v5" "$file" && ! grep -q "return crypto.randomUUID()" "$file"; then
                if sed -i 's/async function v5(t){let e=/async function v5(t){return crypto.randomUUID(); let e=/' "$file"; then
                    log_debug "成功注入 randomUUID 调用到 v5 函数"
                    ((modified_count++))
                else
                    log_error "修改 v5 函数失败"
                    cp "$backup_file" "$file"
                fi
            else
                # 通用注入方法
                if ! grep -q "// Cursor ID 修改工具注入" "$file"; then
                    local inject_code="
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
                    sed -i 's/await v5(!1)/randomDeviceId_'"$(date +%s)"'()/g' "$file"
                    sed -i 's/a\$(t)/randomDeviceId_'"$(date +%s)"'()/g' "$file"
                    
                    log_debug "完成通用修改"
                    ((modified_count++))
                else
                    log_info "文件已经包含自定义注入代码，跳过修改"
                fi
            fi
        else
            # 未找到关键字，尝试通用方法
            if ! grep -q "return crypto.randomUUID()" "$file" && ! grep -q "// Cursor ID 修改工具注入" "$file"; then
                # 尝试找其他关键函数
                if grep -q "function t\$()" "$file" || grep -q "async function y5" "$file"; then
                    # 修改 MAC 地址获取函数
                    if grep -q "function t\$()" "$file"; then
                        sed -i 's/function t\$(){/function t\$(){return "00:00:00:00:00:00";/' "$file"
                    fi
                    
                    # 修改设备ID获取函数
                    if grep -q "async function y5" "$file"; then
                        sed -i 's/async function y5(t){/async function y5(t){return crypto.randomUUID();/' "$file"
                    fi
                    
                    ((modified_count++))
                else
                    # 最通用的注入方法
                    local new_uuid=$(generate_uuid)
                    local machine_id="auth0|user_$(openssl rand -hex 16)"
                    local device_id=$(generate_uuid)
                    local mac_machine_id=$(openssl rand -hex 32)
                    
                    local inject_universal_code="
// Cursor ID 修改工具注入 - $(date +%Y%m%d%H%M%S)
// 全局拦截设备标识符 - $(date +%s)
const originalRequire_$(date +%s) = require;
require = function(module) {
    const result = originalRequire_$(date +%s)(module);
    if (module === 'crypto' && result.randomUUID) {
        const originalRandomUUID_$(date +%s) = result.randomUUID;
        result.randomUUID = function() {
            return '$new_uuid';
        };
    }
    return result;
};

// 覆盖所有可能的系统ID获取函数
global.getMachineId = function() { return '$machine_id'; };
global.getDeviceId = function() { return '$device_id'; };
global.macMachineId = '$mac_machine_id';
"
                    # 替换变量
                    inject_universal_code=${inject_universal_code//\$new_uuid/$new_uuid}
                    inject_universal_code=${inject_universal_code//\$machine_id/$machine_id}
                    inject_universal_code=${inject_universal_code//\$device_id/$device_id}
                    inject_universal_code=${inject_universal_code//\$mac_machine_id/$mac_machine_id}
                    
                    # 将代码注入到文件开头
                    echo "$inject_universal_code" > "${file}.new"
                    cat "$file" >> "${file}.new"
                    mv "${file}.new" "$file"
                    
                    log_debug "完成最通用注入"
                    ((modified_count++))
                fi
            else
                log_info "文件已经被修改过，跳过修改"
            fi
        fi
        
        # 恢复文件权限
        chmod 444 "$file"
    done
    
    if [ "$modified_count" -eq 0 ]; then
        log_error "未能成功修改任何JS文件"
        return 1
    fi
    
    log_info "成功修改了 $modified_count 个JS文件"
    return 0
}

# 禁用自动更新
disable_auto_update() {
    log_info "正在禁用 Cursor 自动更新..."
    
    # 查找可能的更新配置文件
    local update_configs=(
        "$CURSOR_CONFIG_DIR/update-config.json"
        "$HOME/.local/share/cursor/update-config.json"
        "/opt/cursor/resources/app-update.yml"
    )
    
    local disabled=false
    
    for config in "${update_configs[@]}"; do
        if [ -f "$config" ]; then
            log_info "找到更新配置文件: $config"
            
            # 备份并清空配置文件
            cp "$config" "${config}.bak" 2>/dev/null
            echo '{"autoCheck": false, "autoDownload": false}' > "$config"
            chmod 444 "$config"
            
            log_info "已禁用更新配置文件: $config"
            disabled=true
        fi
    done
    
    # 尝试查找updater可执行文件并禁用
    local updater_paths=(
        "$HOME/.config/Cursor/updater"
        "/opt/cursor/updater"
        "/usr/lib/cursor/updater"
    )
    
    for updater in "${updater_paths[@]}"; do
        if [ -f "$updater" ] || [ -d "$updater" ]; then
            log_info "找到更新程序: $updater"
            if [ -f "$updater" ]; then
                mv "$updater" "${updater}.bak" 2>/dev/null
            else
                touch "${updater}.disabled"
            fi
            
            log_info "已禁用更新程序: $updater"
            disabled=true
        fi
    done
    
    if [ "$disabled" = false ]; then
        log_warn "未找到任何更新配置文件或更新程序"
    else
        log_info "成功禁用了自动更新"
    fi
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
    # 检查系统环境
    if [[ $(uname) != "Linux" ]]; then
        log_error "本脚本仅支持 Linux 系统"
        exit 1
    fi
    
    # 初始化日志文件
    initialize_log
    log_info "脚本启动..."
    
    
    # 记录系统信息
    log_info "系统信息: $(uname -a)"
    log_info "当前用户: $CURRENT_USER"
    log_cmd_output "lsb_release -a 2>/dev/null || cat /etc/*release 2>/dev/null || cat /etc/issue" "系统版本信息"
    
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
    echo -e "${GREEN}   Cursor Linux 启动工具     ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    echo -e "${YELLOW}[重要提示]${NC} 本工具优先修改js文件，更加安全可靠"
    echo
    
    # 执行主要功能
    check_permissions
    
    # 查找Cursor路径
    find_cursor_path
    find_cursor_resources
    
    # 检查并关闭Cursor进程
    check_and_kill_cursor
    
    # 备份配置文件
    backup_config
    
    # 询问用户是否需要重置机器码（默认不重置）
    generate_new_config
    
    # 修改JS文件
    log_info "正在修改Cursor JS文件..."
    if modify_cursor_js_files; then
        log_info "JS文件修改成功！"
    else
        log_warn "JS文件修改失败，但配置文件修改可能已成功"
        log_warn "如果重启后 Cursor 仍然提示设备被禁用，请重新运行此脚本"
    fi
    
    # 禁用自动更新
    disable_auto_update
    
    log_info "请重启 Cursor 以应用新的配置"
    
    # 显示最后的提示信息
    echo
    echo -e "${GREEN}================================${NC}"
    echo -e "${YELLOW}  关注公众号【煎饼果子卷AI】一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬) ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    
    # 记录脚本完成信息
    log_info "脚本执行完成"
    echo "========== Cursor ID 修改工具日志结束 $(date) ==========" >> "$LOG_FILE"
    
    # 显示日志文件位置
    echo
    log_info "详细日志已保存到: $LOG_FILE"
    echo "如遇问题请将此日志文件提供给开发者以协助排查"
    echo
}

# 执行主函数
main