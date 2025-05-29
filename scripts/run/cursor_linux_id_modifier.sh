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

# --- 新增：安装相关变量 ---
APPIMAGE_SEARCH_DIR="/opt/CursorInstall" # AppImage 搜索目录，可按需修改
APPIMAGE_PATTERN="Cursor-*.AppImage"     # AppImage 文件名模式
INSTALL_DIR="/opt/Cursor"                # Cursor 最终安装目录
ICON_PATH="/usr/share/icons/cursor.png"
DESKTOP_FILE="/usr/share/applications/cursor-cursor.desktop"
# --- 结束：安装相关变量 ---

# 可能的Cursor二进制路径 - 添加了标准安装路径
CURSOR_BIN_PATHS=(
    "/usr/bin/cursor"
    "/usr/local/bin/cursor"
    "$INSTALL_DIR/cursor"               # 添加标准安装路径
    "$HOME/.local/bin/cursor"
    "/snap/bin/cursor"
)

# 找到Cursor安装路径
find_cursor_path() {
    log_info "查找Cursor安装路径..."
    
    for path in "${CURSOR_BIN_PATHS[@]}"; do
        if [ -f "$path" ] && [ -x "$path" ]; then # 确保文件存在且可执行
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
    
    # 尝试查找可能的安装路径 (限制搜索范围和类型)
    local cursor_paths=$(find /usr /opt $HOME/.local -path "$INSTALL_DIR/cursor" -o -name "cursor" -type f -executable 2>/dev/null)
    if [ -n "$cursor_paths" ]; then
        # 优先选择标准安装路径
        local standard_path=$(echo "$cursor_paths" | grep "$INSTALL_DIR/cursor" | head -1)
        if [ -n "$standard_path" ]; then
            CURSOR_PATH="$standard_path"
        else
            CURSOR_PATH=$(echo "$cursor_paths" | head -1)
        fi
        log_info "通过查找找到Cursor: $CURSOR_PATH"
        return 0
    fi
    
    log_warn "未找到Cursor可执行文件"
    return 1
}

# 查找并定位Cursor资源文件目录
find_cursor_resources() {
    log_info "查找Cursor资源目录..."
    
    # 可能的资源目录路径 - 添加了标准安装目录
    local resource_paths=(
        "$INSTALL_DIR" # 添加标准安装路径
        "/usr/lib/cursor"
        "/usr/share/cursor"
        "$HOME/.local/share/cursor"
    )
    
    for path in "${resource_paths[@]}"; do
        if [ -d "$path/resources" ]; then # 检查是否存在 resources 子目录
            log_info "找到Cursor资源目录: $path"
            CURSOR_RESOURCES="$path"
            return 0
        fi
         if [ -d "$path/app" ]; then # 有些版本可能直接是 app 目录
             log_info "找到Cursor资源目录 (app): $path"
             CURSOR_RESOURCES="$path"
             return 0
         fi
    done
    
    # 如果有CURSOR_PATH，尝试从它推断
    if [ -n "$CURSOR_PATH" ]; then
        local base_dir=$(dirname "$CURSOR_PATH")
        # 检查常见的相对路径
        if [ -d "$base_dir/resources" ]; then
            CURSOR_RESOURCES="$base_dir"
            log_info "通过二进制路径找到资源目录: $CURSOR_RESOURCES"
            return 0
        elif [ -d "$base_dir/../resources" ]; then # 例如在 bin 目录内
            CURSOR_RESOURCES=$(realpath "$base_dir/..")
            log_info "通过二进制路径找到资源目录: $CURSOR_RESOURCES"
            return 0
        elif [ -d "$base_dir/../lib/cursor/resources" ]; then # 另一种常见结构
            CURSOR_RESOURCES=$(realpath "$base_dir/../lib/cursor")
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
        log_error "请使用 sudo 运行此脚本 (安装和修改系统文件需要权限)"
        echo "示例: sudo $0"
        exit 1
    fi
}

# --- 新增/重构：从本地 AppImage 安装 Cursor ---
install_cursor_appimage() {
    log_info "开始尝试从本地 AppImage 安装 Cursor..."
    local found_appimage_path=""

    # 确保搜索目录存在
    mkdir -p "$APPIMAGE_SEARCH_DIR"

    # 查找 AppImage 文件
    find_appimage() {
        found_appimage_path=$(find "$APPIMAGE_SEARCH_DIR" -maxdepth 1 -name "$APPIMAGE_PATTERN" -print -quit)
        if [ -z "$found_appimage_path" ]; then
            return 1
        else
            return 0
        fi
    }

    if ! find_appimage; then
        log_warn "在 '$APPIMAGE_SEARCH_DIR' 目录下未找到 '$APPIMAGE_PATTERN' 文件。"
        # --- 新增：添加文件名格式提醒 ---
        log_info "请确保 AppImage 文件名格式类似: Cursor-版本号-架构.AppImage (例如: Cursor-0.49.6-aarch64.AppImage 或 Cursor-x.y.z-x86_64.AppImage)"
        # --- 结束：添加文件名格式提醒 ---
        # 等待用户放置文件
        read -p $"请将 Cursor AppImage 文件放入 '$APPIMAGE_SEARCH_DIR' 目录，然后按 Enter 键继续..."

        # 再次查找
        if ! find_appimage; then
            log_error "在 '$APPIMAGE_SEARCH_DIR' 中仍然找不到 '$APPIMAGE_PATTERN' 文件。安装中止。"
            return 1
        fi
    fi

    log_info "找到 AppImage 文件: $found_appimage_path"
    local appimage_filename=$(basename "$found_appimage_path")

    # 进入搜索目录操作，避免路径问题
    local current_dir=$(pwd)
    cd "$APPIMAGE_SEARCH_DIR" || { log_error "无法进入目录: $APPIMAGE_SEARCH_DIR"; return 1; }

    log_info "设置 '$appimage_filename' 可执行权限..."
    chmod +x "$appimage_filename" || {
        log_error "设置可执行权限失败: $appimage_filename"
        cd "$current_dir"
        return 1
    }

    log_info "解压 AppImage 文件 '$appimage_filename'..."
    # 创建临时解压目录
    local extract_dir="squashfs-root"
    rm -rf "$extract_dir" # 清理旧的解压目录（如果存在）
    
    # 执行解压，将输出重定向避免干扰
    if ./"$appimage_filename" --appimage-extract > /dev/null; then
        log_info "AppImage 解压成功到 '$extract_dir'"
    else
        log_error "解压 AppImage 失败: $appimage_filename"
        rm -rf "$extract_dir" # 清理失败的解压
        cd "$current_dir"
        return 1
    fi

    # 检查解压后的预期目录结构
    local cursor_source_dir=""
    if [ -d "$extract_dir/usr/share/cursor" ]; then
       cursor_source_dir="$extract_dir/usr/share/cursor"
    elif [ -d "$extract_dir" ]; then # 有些 AppImage 可能直接在根目录
       # 进一步检查是否存在关键文件/目录
       if [ -f "$extract_dir/cursor" ] && [ -d "$extract_dir/resources" ]; then
           cursor_source_dir="$extract_dir"
       fi
    fi

    if [ -z "$cursor_source_dir" ]; then
        log_error "解压后的目录 '$extract_dir' 中未找到预期的 Cursor 文件结构 (例如 'usr/share/cursor' 或直接包含 'cursor' 和 'resources')。"
        rm -rf "$extract_dir"
        cd "$current_dir"
        return 1
    fi
     log_info "找到 Cursor 源文件在: $cursor_source_dir"


    log_info "安装 Cursor 到 '$INSTALL_DIR'..."
    # 如果安装目录已存在，先删除 (确保全新安装)
    if [ -d "$INSTALL_DIR" ]; then
        log_warn "发现已存在的安装目录 '$INSTALL_DIR'，将先移除..."
        rm -rf "$INSTALL_DIR" || { log_error "移除旧安装目录失败: $INSTALL_DIR"; cd "$current_dir"; return 1; }
    fi
    
    # 创建安装目录的父目录（如果需要）并设置权限
    mkdir -p "$(dirname "$INSTALL_DIR")"
    
    # 移动解压后的内容到安装目录
    if mv "$cursor_source_dir" "$INSTALL_DIR"; then
        log_info "成功将文件移动到 '$INSTALL_DIR'"
        # 确保安装目录及其内容归属当前用户（如果需要）
        chown -R "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$INSTALL_DIR" || log_warn "设置 '$INSTALL_DIR' 文件所有权失败，可能需要手动调整"
        chmod -R u+rwX,go+rX,go-w "$INSTALL_DIR" || log_warn "设置 '$INSTALL_DIR' 文件权限失败，可能需要手动调整"
    else
        log_error "移动文件到安装目录 '$INSTALL_DIR' 失败"
        rm -rf "$extract_dir" # 确保清理
        rm -rf "$INSTALL_DIR" # 清理部分移动的文件
        cd "$current_dir"
        return 1
    fi

    # 处理图标和桌面快捷方式 (从脚本执行的原始目录查找)
    cd "$current_dir" # 返回原始目录查找图标等文件

    local icon_source="./cursor.png"
    local desktop_source="./cursor-cursor.desktop"

    if [ -f "$icon_source" ]; then
        log_info "安装图标..."
        mkdir -p "$(dirname "$ICON_PATH")"
        cp "$icon_source" "$ICON_PATH" || log_warn "无法复制图标文件 '$icon_source' 到 '$ICON_PATH'"
        chmod 644 "$ICON_PATH" || log_warn "设置图标文件权限失败: $ICON_PATH"
    else
        log_warn "图标文件 '$icon_source' 在脚本当前目录不存在，跳过图标安装。"
        log_warn "请将 'cursor.png' 文件放置在脚本目录 '$current_dir' 下并重新运行安装（如果需要图标）。"
    fi

    if [ -f "$desktop_source" ]; then
        log_info "安装桌面快捷方式..."
         mkdir -p "$(dirname "$DESKTOP_FILE")"
        cp "$desktop_source" "$DESKTOP_FILE" || log_warn "无法创建桌面快捷方式 '$desktop_source' 到 '$DESKTOP_FILE'"
        chmod 644 "$DESKTOP_FILE" || log_warn "设置桌面文件权限失败: $DESKTOP_FILE"

        # 更新桌面数据库
        log_info "更新桌面数据库..."
        update-desktop-database "$(dirname "$DESKTOP_FILE")" &> /dev/null || log_warn "无法更新桌面数据库，快捷方式可能不会立即显示"
    else
        log_warn "桌面文件 '$desktop_source' 在脚本当前目录不存在，跳过快捷方式安装。"
         log_warn "请将 'cursor-cursor.desktop' 文件放置在脚本目录 '$current_dir' 下并重新运行安装（如果需要快捷方式）。"
    fi

    # 创建符号链接到 /usr/local/bin
    log_info "创建命令行启动链接..."
    ln -sf "$INSTALL_DIR/cursor" /usr/local/bin/cursor || log_warn "无法创建命令行链接 '/usr/local/bin/cursor'"

    # 清理临时文件
    log_info "清理临时文件..."
    cd "$APPIMAGE_SEARCH_DIR" # 返回搜索目录清理
    rm -rf "$extract_dir"
    log_info "正在删除原始 AppImage 文件: $found_appimage_path"
    rm -f "$appimage_filename" # 删除 AppImage 文件

    cd "$current_dir" # 确保返回最终目录

    log_info "Cursor 安装成功！安装目录: $INSTALL_DIR"
    return 0
}
# --- 结束：安装函数 ---

# 检查并关闭 Cursor 进程
check_and_kill_cursor() {
    log_info "检查 Cursor 进程..."
    
    local attempt=1
    local max_attempts=5
    
    # 函数：获取进程详细信息
    get_process_details() {
        local process_name="$1"
        log_debug "正在获取 $process_name 进程详细信息："
        ps aux | grep -i "cursor" | grep -v grep | grep -v "cursor_linux_id_modifier.sh"
    }
    
    while [ $attempt -le $max_attempts ]; do
        # 使用更精确的匹配来获取 Cursor 进程，排除当前脚本和grep进程
        CURSOR_PIDS=$(ps aux | grep -i "cursor" | grep -v "grep" | grep -v "cursor_linux_id_modifier.sh" | awk '{print $2}' || true)
        
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
        
        # 再次检查进程是否还在运行，排除当前脚本和grep进程
        if ! ps aux | grep -i "cursor" | grep -v "grep" | grep -v "cursor_linux_id_modifier.sh" > /dev/null; then
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
        log_warn "配置文件 '$STORAGE_FILE' 不存在，跳过备份"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/storage.json.backup_$(date +%Y%m%d_%H%M%S)"
    
    if cp "$STORAGE_FILE" "$backup_file"; then
        chmod 644 "$backup_file"
        # 确保备份文件归属正确用户
        chown "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$backup_file" || log_warn "设置备份文件所有权失败: $backup_file"
        log_info "配置已备份到: $backup_file"
    else
        log_error "备份失败: $STORAGE_FILE"
        exit 1
    fi
    return 0 # 明确返回成功
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
            openssl rand -hex 16 | sed 's/\\(..\\)\\(..\\)\\(..\\)\\(..\\)\\(..\\)\\(..\\)\\(..\\)\\(..\\)/\\1\\2\\3\\4-\\5\\6-\\7\\8-\\9\\10-\\11\\12\\13\\14\\15\\16/'
        fi
    fi
}

# 修改现有文件
modify_or_add_config() {
    local key="$1"
    local value="$2"
    local file="$3"
    
    if [ ! -f "$file" ]; then
        log_error "配置文件不存在: $file"
        return 1
    fi
    
    # 确保文件对当前执行用户（root）可写
    chmod u+w "$file" || {
        log_error "无法修改文件权限（写）: $file"
        return 1
    }
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 检查key是否存在
    if grep -q "\"$key\":[[:space:]]*\"[^\"]*\"" "$file"; then
        # key存在,执行替换 (更精确的匹配)
        sed "s/\\(\"$key\"\\):[[:space:]]*\"[^\"]*\"/\\1: \"$value\"/" "$file" > "$temp_file" || {
            log_error "修改配置失败 (替换): $key in $file"
            rm -f "$temp_file"
            chmod u-w "$file" # 恢复权限
            return 1
        }
         log_debug "已替换 key '$key' 在文件 '$file' 中"
    elif grep -q "}" "$file"; then
         # key不存在, 在最后一个 '}' 前添加新的key-value对
         # 注意：这种方式比较脆弱，如果 JSON 格式不标准或最后一行不是 '}' 会失败
         sed '$ s/}/,\n    "'$key'\": "'$value'\"\n}/' "$file" > "$temp_file" || {
             log_error "添加配置失败 (注入): $key to $file"
             rm -f "$temp_file"
             chmod u-w "$file" # 恢复权限
             return 1
         }
         log_debug "已添加 key '$key' 到文件 '$file' 中"
    else
         log_error "无法确定如何添加配置: $key to $file (文件结构可能不标准)"
         rm -f "$temp_file"
         chmod u-w "$file" # 恢复权限
         return 1
    fi

    # 检查临时文件是否有效
    if [ ! -s "$temp_file" ]; then
        log_error "修改或添加配置后生成的临时文件为空: $key in $file"
        rm -f "$temp_file"
        chmod u-w "$file" # 恢复权限
        return 1
    fi
    
    # 使用 cat 替换原文件内容
    cat "$temp_file" > "$file" || {
        log_error "无法写入更新后的配置到文件: $file"
        rm -f "$temp_file"
        # 尝试恢复权限（如果失败也无大碍）
        chmod u-w "$file" || true
        return 1
    }
    
    rm -f "$temp_file"
    
    # 设置所有者和基础权限（root执行时目标文件是用户家目录下的）
    chown "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$file" || log_warn "设置文件所有权失败: $file"
    chmod 644 "$file" || log_warn "设置文件权限失败: $file" # 用户读写，组和其他读
    
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
    
    # 确保配置文件目录存在
    mkdir -p "$(dirname "$STORAGE_FILE")"
    chown "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$(dirname "$STORAGE_FILE")" || log_warn "设置配置目录所有权失败: $(dirname "$STORAGE_FILE")"
    chmod 755 "$(dirname "$STORAGE_FILE")" || log_warn "设置配置目录权限失败: $(dirname "$STORAGE_FILE")"

    # 处理用户选择 - 索引0对应"不重置"选项，索引1对应"重置"选项
    if [ "$reset_choice" = "1" ]; then
        log_info "您选择了重置机器码"
        
        # 检查配置文件是否存在
        if [ -f "$STORAGE_FILE" ]; then
            log_info "发现已有配置文件: $STORAGE_FILE"
            
            # 备份现有配置
            if ! backup_config; then # 如果备份失败，不继续修改
                 log_error "配置文件备份失败，中止机器码重置。"
                 return 1 # 返回错误状态
            fi
            
            # 生成并设置新的设备ID
            local new_device_id=$(generate_uuid)
            local new_machine_id=$(generate_uuid) # 使用 UUID 作为 Machine ID 更常见

            log_info "正在设置新的设备和机器ID..."
            log_debug "新设备ID: $new_device_id"
            log_debug "新机器ID: $new_machine_id"
            
            # 修改配置文件
            if modify_or_add_config "deviceId" "$new_device_id" "$STORAGE_FILE" && \
               modify_or_add_config "machineId" "$new_machine_id" "$STORAGE_FILE"; then
                log_info "配置文件中的 deviceId 和 machineId 修改成功"
            else
                log_error "配置文件中的 deviceId 或 machineId 修改失败"
                # 注意：即使失败，备份仍在，但配置文件可能已部分修改
                return 1 # 返回错误状态
            fi
        else
            log_warn "未找到配置文件 '$STORAGE_FILE'，无法重置机器码。如果这是首次安装，这是正常的。"
            # 即使文件不存在，也认为此步骤（不执行）是"成功"的，允许继续
        fi
    else
        log_info "您选择了不重置机器码，将仅修改js文件"
        
        # 检查配置文件是否存在并备份（如果存在）
        if [ -f "$STORAGE_FILE" ]; then
            log_info "发现已有配置文件: $STORAGE_FILE"
            if ! backup_config; then
                 log_error "配置文件备份失败，中止操作。"
                 return 1 # 返回错误状态
            fi
        else
            log_warn "未找到配置文件 '$STORAGE_FILE'，跳过备份。"
        fi
    fi
    
    echo
    log_info "配置处理完成"
    return 0 # 明确返回成功
}

# 查找Cursor的JS文件
find_cursor_js_files() {
    log_info "查找Cursor的JS文件..."
    
    local js_files=()
    local found=false
    
    # 确保 CURSOR_RESOURCES 已设置
    if [ -z "$CURSOR_RESOURCES" ] || [ ! -d "$CURSOR_RESOURCES" ]; then
        log_error "Cursor 资源目录未找到或无效 ($CURSOR_RESOURCES)，无法查找 JS 文件。"
        return 1
    fi

    log_debug "在资源目录中搜索JS文件: $CURSOR_RESOURCES"
    
    # 在资源目录中递归搜索特定JS文件
    # 注意：这些模式可能需要根据 Cursor 版本更新
    local js_patterns=(
        "resources/app/out/vs/workbench/api/node/extensionHostProcess.js"
        "resources/app/out/main.js"
        "resources/app/out/vs/code/node/cliProcessMain.js"
        # 添加其他可能的路径模式
        "app/out/vs/workbench/api/node/extensionHostProcess.js" # 如果资源目录是 app 的父目录
        "app/out/main.js"
        "app/out/vs/code/node/cliProcessMain.js"
    )
    
    for pattern in "${js_patterns[@]}"; do
        # 使用 find 在 CURSOR_RESOURCES 下查找完整路径
        local files=$(find "$CURSOR_RESOURCES" -path "*/$pattern" -type f 2>/dev/null)
        if [ -n "$files" ]; then
            while IFS= read -r file; do
                # 检查文件是否已添加
                if [[ ! " ${js_files[@]} " =~ " ${file} " ]]; then
                    log_info "找到JS文件: $file"
                    js_files+=("$file")
                    found=true
                fi
            done <<< "$files"
        fi
    done
    
    # 如果还没找到，尝试更通用的搜索（可能误报）
    if [ "$found" = false ]; then
        log_warn "在标准路径模式中未找到JS文件，尝试在资源目录 '$CURSOR_RESOURCES' 中进行更广泛的搜索..."
        # 查找包含特定关键字的 JS 文件
        local files=$(find "$CURSOR_RESOURCES" -name "*.js" -type f -exec grep -lE 'IOPlatformUUID|x-cursor-checksum|getMachineId' {} \; 2>/dev/null)
        if [ -n "$files" ]; then
            while IFS= read -r file; do
                 if [[ ! " ${js_files[@]} " =~ " ${file} " ]]; then
                     log_info "通过关键字找到可能的JS文件: $file"
                     js_files+=("$file")
                     found=true
                 fi
            done <<< "$files"
        else
             log_warn "在资源目录 '$CURSOR_RESOURCES' 中通过关键字也未能找到 JS 文件。"
        fi
    fi

    if [ "$found" = false ]; then
        log_error "在资源目录 '$CURSOR_RESOURCES' 中未找到任何可修改的JS文件。"
        log_error "请检查 Cursor 安装是否完整，或脚本中的 JS 路径模式是否需要更新。"
        return 1
    fi
    
    # 去重（理论上上面的检查已经处理，但以防万一）
    IFS=" " read -r -a CURSOR_JS_FILES <<< "$(echo "${js_files[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
    
    log_info "找到 ${#CURSOR_JS_FILES[@]} 个唯一的JS文件需要处理。"
    return 0
}

# 修改Cursor的JS文件
modify_cursor_js_files() {
    log_info "开始修改Cursor的JS文件..."
    
    # 先查找需要修改的JS文件
    if ! find_cursor_js_files; then
        # find_cursor_js_files 内部会打印错误日志
        return 1
    fi
    
    if [ ${#CURSOR_JS_FILES[@]} -eq 0 ]; then
        log_error "JS 文件列表为空，无法继续修改。"
        return 1
    fi

    local modified_count=0
    local file_modification_status=() # 记录每个文件的修改状态

    for file in "${CURSOR_JS_FILES[@]}"; do
        log_info "处理文件: $file"
        
        if [ ! -f "$file" ]; then
            log_error "文件不存在: $file，跳过处理。"
            file_modification_status+=("'$file': Not Found")
            continue
        fi

        # 创建文件备份
        local backup_file="${file}.backup_$(date +%Y%m%d_%H%M%S)"
        if ! cp "$file" "$backup_file"; then
            log_error "无法创建文件备份: $file"
            file_modification_status+=("'$file': Backup Failed")
            continue
        fi
        chown "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$backup_file" || log_warn "设置备份文件所有权失败: $backup_file"
        chmod 444 "$backup_file" || log_warn "设置备份文件权限失败: $backup_file"


        # 确保文件对当前执行用户（root）可写
        chmod u+w "$file" || {
            log_error "无法修改文件权限（写）: $file"
            file_modification_status+=("'$file': Permission Error (Write)")
            # 尝试恢复备份（如果可能）
            cp "$backup_file" "$file" 2>/dev/null || true
            continue
        }
        
        local modification_applied=false

        # --- 开始尝试各种修改模式 ---
        
        # 模式1：精确修改 x-cursor-checksum (最常见的目标之一)
        if grep -q 'i.header.set("x-cursor-checksum' "$file"; then
            log_debug "找到 x-cursor-checksum 设置代码，尝试修改..."
            # 使用更健壮的 sed，处理不同的空格和变量名可能性
            if sed -i -E 's/(i|[\w$]+)\.header\.set\("x-cursor-checksum",\s*e\s*===\s*void 0\s*\?\s*`\$\{p\}(\$\{t\})`\s*:\s*`\$\{p\}\2\/(\$\{e\})`/i.header.set("x-cursor-checksum",e===void 0?`${p}${t}`:`${p}${t}\/${p}`)/' "$file"; then
                # 验证修改是否真的发生 (避免 sed 没匹配但返回0)
                if ! grep -q 'i.header.set("x-cursor-checksum",e===void 0?`${p}${t}`:`${p}${t}\/${e}`)' "$file"; then
                    log_info "成功修改 x-cursor-checksum 设置代码"
                    modification_applied=true
                else
                     log_warn "sed 命令执行成功，但似乎未修改 x-cursor-checksum (可能模式不匹配当前版本)"
                fi
            else
                log_error "修改 x-cursor-checksum 设置代码失败 (sed 命令执行错误)"
            fi
        fi

        # 模式2：注入 randomUUID 到特定函数 (如果模式1未应用)
        if [ "$modification_applied" = false ] && grep -q "IOPlatformUUID" "$file"; then
             log_debug "未修改 checksum 或未找到，尝试注入 randomUUID..."
             # 尝试注入 a$ 函数
             if grep -q "function a\$(" "$file" && ! grep -q "return crypto.randomUUID()" "$file"; then
                 if sed -i 's/function a\$(t){switch/function a\$(t){try { return require("crypto").randomUUID(); } catch(e){} switch/' "$file"; then
                     # 验证修改
                     if grep -q "return require(\"crypto\").randomUUID()" "$file"; then
                         log_info "成功注入 randomUUID 调用到 a\$ 函数"
                         modification_applied=true
                     else
                          log_warn "sed 注入 a$ 失败（可能模式不匹配）"
                     fi
                 else
                     log_error "修改 a\$ 函数失败 (sed 命令执行错误)"
                 fi
             # 尝试注入 v5 函数 (如果 a$ 没成功)
             elif [ "$modification_applied" = false ] && grep -q "async function v5(" "$file" && ! grep -q "return crypto.randomUUID()" "$file"; then
                 if sed -i 's/async function v5(t){let e=/async function v5(t){try { return require("crypto").randomUUID(); } catch(e){} let e=/' "$file"; then
                     # 验证修改
                     if grep -q "return require(\"crypto\").randomUUID()" "$file"; then
                         log_info "成功注入 randomUUID 调用到 v5 函数"
                         modification_applied=true
                      else
                          log_warn "sed 注入 v5 失败（可能模式不匹配）"
                      fi
                 else
                     log_error "修改 v5 函数失败 (sed 命令执行错误)"
                 fi
             fi
        fi

        # 模式3：通用注入 (如果上述模式都未应用，并且没有标记)
        if [ "$modification_applied" = false ] && ! grep -q "// Cursor ID Modifier Injection" "$file"; then
             log_debug "特定修改模式未生效或不适用，尝试通用注入..."
             # 生成唯一标识符以避免冲突
             local timestamp=$(date +%s)
             local new_uuid=$(generate_uuid)
             local machine_id=$(generate_uuid) # 使用 UUID
             local device_id=$(generate_uuid)
             local mac_machine_id=$(openssl rand -hex 32) # 伪造 MAC 相关 ID

             # 创建注入代码块
             local inject_universal_code="
// Cursor ID Modifier Injection - $timestamp
const originalRequire_$timestamp = typeof require === 'function' ? require : null;
if (originalRequire_$timestamp) {
  require = function(module) {
    try {
      const result = originalRequire_$timestamp(module);
      if (module === 'crypto' && result && result.randomUUID) {
        const originalRandomUUID_$timestamp = result.randomUUID;
        result.randomUUID = function() { return '$new_uuid'; };
        console.log('Cursor Modifier: Patched crypto.randomUUID');
      }
      if (module === 'os' && result && result.networkInterfaces) {
         const originalNI_$timestamp = result.networkInterfaces;
         result.networkInterfaces = function() { return { lo: [{ address: '127.0.0.1', netmask: '255.0.0.0', family: 'IPv4', mac: '00:00:00:00:00:00', internal: true, cidr: '127.0.0.1/8' }]}; };
         console.log('Cursor Modifier: Patched os.networkInterfaces');
      }
      return result;
    } catch (e) {
      console.error('Cursor Modifier: Error in require patch for module:', module, e);
      // 如果原始 require 失败，可能需要返回一个空对象或抛出异常
      // 尝试调用原始 require，即使它可能已在 try 块中失败
      try { return originalRequire_$timestamp(module); } catch (innerE) { return {}; }
    }
  };
} else { console.warn('Cursor Modifier: Original require not found.'); }

// Override potential global functions or properties if they exist
try { if (typeof global !== 'undefined' && global.getMachineId) global.getMachineId = function() { return '$machine_id'; }; } catch(e){}
try { if (typeof global !== 'undefined' && global.getDeviceId) global.getDeviceId = function() { return '$device_id'; }; } catch(e){}
try { if (typeof global !== 'undefined' && global.macMachineId) global.macMachineId = '$mac_machine_id'; } catch(e){}
try { if (typeof process !== 'undefined' && process.env) process.env.VSCODE_MACHINE_ID = '$machine_id'; } catch(e){}

console.log('Cursor Modifier: Universal patches applied (UUID: $new_uuid)');
// End Cursor ID Modifier Injection - $timestamp

"
            # 将变量替换进代码
            inject_universal_code=${inject_universal_code//\$new_uuid/$new_uuid}
            inject_universal_code=${inject_universal_code//\$machine_id/$machine_id}
            inject_universal_code=${inject_universal_code//\$device_id/$device_id}
            inject_universal_code=${inject_universal_code//\$mac_machine_id/$mac_machine_id}
            inject_universal_code=${inject_universal_code//\$timestamp/$timestamp} # 确保时间戳替换

            # 将代码注入到文件开头
            local temp_inject_file=$(mktemp)
            echo "$inject_universal_code" > "$temp_inject_file"
            cat "$file" >> "$temp_inject_file"
            
            if mv "$temp_inject_file" "$file"; then
                 log_info "完成通用注入修改"
                 modification_applied=true
            else
                 log_error "通用注入失败 (无法移动临时文件)"
                 rm -f "$temp_inject_file" # 清理注入文件
            fi
        elif [ "$modification_applied" = false ]; then
             log_info "文件 '$file' 似乎已被修改过 (包含注入标记)，跳过通用注入。"
             # 即使未应用新修改，也认为"成功"处理（避免恢复备份）
             modification_applied=true # 标记为已处理，防止恢复备份
        fi

        # --- 结束修改尝试 ---

        # 根据修改结果处理
        if [ "$modification_applied" = true ]; then
            ((modified_count++))
            file_modification_status+=("'$file': Success")
            # 恢复文件权限为只读
            chmod u-w,go-w "$file" || log_warn "设置文件只读权限失败: $file"
            # 设置文件所有者
             chown "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$file" || log_warn "设置 JS 文件所有权失败: $file"
        else
            log_error "未能成功应用任何修改到文件: $file"
            file_modification_status+=("'$file': Failed")
            # 恢复备份
            log_info "正在从备份恢复文件: $file"
            if cp "$backup_file" "$file"; then
                 chmod u-w,go-w "$file" || log_warn "恢复备份后设置只读权限失败: $file"
                 chown "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$file" || log_warn "恢复备份后设置所有权失败: $file"
            else
                 log_error "从备份恢复文件失败: $file"
                 # 文件可能处于不确定状态
            fi
        fi
        
        # 清理备份文件
        rm -f "$backup_file"

    done # 文件循环结束
    
    # 报告每个文件的状态
    log_info "JS 文件处理状态汇总:"
    for status in "${file_modification_status[@]}"; do
        log_info "- $status"
    done

    if [ "$modified_count" -eq 0 ]; then
        log_error "未能成功修改任何JS文件。请检查日志以获取详细信息。"
        return 1
    fi
    
    log_info "成功修改或确认了 $modified_count 个JS文件。"
    return 0
}

# 禁用自动更新
disable_auto_update() {
    log_info "正在尝试禁用 Cursor 自动更新..."
    
    # 查找可能的更新配置文件
    local update_configs=()
    # 用户配置目录下的
    if [ -d "$CURSOR_CONFIG_DIR" ]; then
        update_configs+=("$CURSOR_CONFIG_DIR/update-config.json")
        update_configs+=("$CURSOR_CONFIG_DIR/settings.json") # 有些设置可能在这里
    fi
    # 安装目录下的 (如果资源目录确定)
    if [ -n "$CURSOR_RESOURCES" ] && [ -d "$CURSOR_RESOURCES" ]; then
        update_configs+=("$CURSOR_RESOURCES/resources/app-update.yml")
         update_configs+=("$CURSOR_RESOURCES/app-update.yml") # 可能的位置
    fi
     # 标准安装目录下的
     if [ -d "$INSTALL_DIR" ]; then
          update_configs+=("$INSTALL_DIR/resources/app-update.yml")
          update_configs+=("$INSTALL_DIR/app-update.yml")
     fi
     # $HOME/.local/share
     update_configs+=("$HOME/.local/share/cursor/update-config.json")


    local disabled_count=0
    
    # 处理 JSON 配置文件
    local json_config_pattern='update-config.json|settings.json'
    for config in "${update_configs[@]}"; do
       if [[ "$config" =~ $json_config_pattern ]] && [ -f "$config" ]; then
           log_info "找到可能的更新配置文件: $config"
           
           # 备份
           cp "$config" "${config}.bak_$(date +%Y%m%d%H%M%S)" 2>/dev/null
           
           # 尝试修改 JSON (如果存在且是 settings.json)
           if [[ "$config" == *settings.json ]]; then
               # 尝试添加或修改 "update.mode": "none"
                if grep -q '"update.mode"' "$config"; then
                    sed -i 's/"update.mode":[[:space:]]*"[^"]*"/"update.mode": "none"/' "$config" || log_warn "修改 settings.json 中的 update.mode 失败"
                elif grep -q "}" "$config"; then # 尝试注入
                     sed -i '$ s/}/,\n    "update.mode": "none"\n}/' "$config" || log_warn "注入 update.mode 到 settings.json 失败"
                else
                    log_warn "无法修改 settings.json 以禁用更新（结构未知）"
                fi
                # 确保权限正确
                 chown "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$config" || log_warn "设置所有权失败: $config"
                 chmod 644 "$config" || log_warn "设置权限失败: $config"
                 ((disabled_count++))
                 log_info "已尝试在 '$config' 中设置 'update.mode' 为 'none'"
           elif [[ "$config" == *update-config.json ]]; then
                # 直接覆盖 update-config.json
                echo '{"autoCheck": false, "autoDownload": false}' > "$config"
                chown "$CURRENT_USER":"$(id -g -n "$CURRENT_USER")" "$config" || log_warn "设置所有权失败: $config"
                chmod 644 "$config" || log_warn "设置权限失败: $config"
                ((disabled_count++))
                log_info "已覆盖更新配置文件: $config"
            fi
       fi
    done

    # 处理 YAML 配置文件
     local yml_config_pattern='app-update.yml'
     for config in "${update_configs[@]}"; do
        if [[ "$config" =~ $yml_config_pattern ]] && [ -f "$config" ]; then
            log_info "找到可能的更新配置文件: $config"
            # 备份
            cp "$config" "${config}.bak_$(date +%Y%m%d%H%M%S)" 2>/dev/null
            # 清空或修改内容 (简单起见，直接清空或写入禁用标记)
             echo "# Automatic updates disabled by script $(date)" > "$config"
             # echo "provider: generic" > "$config" # 或者尝试修改 provider
             # echo "url: http://127.0.0.1" >> "$config"
             chmod 444 "$config" # 设置为只读
             ((disabled_count++))
             log_info "已修改/清空更新配置文件: $config"
        fi
     done

    # 尝试查找updater可执行文件并禁用（重命名或移除权限）
    local updater_paths=()
     if [ -n "$CURSOR_RESOURCES" ] && [ -d "$CURSOR_RESOURCES" ]; then
        updater_paths+=($(find "$CURSOR_RESOURCES" -name "updater" -type f -executable 2>/dev/null))
        updater_paths+=($(find "$CURSOR_RESOURCES" -name "CursorUpdater" -type f -executable 2>/dev/null)) # macOS 风格？
     fi
      if [ -d "$INSTALL_DIR" ]; then
          updater_paths+=($(find "$INSTALL_DIR" -name "updater" -type f -executable 2>/dev/null))
          updater_paths+=($(find "$INSTALL_DIR" -name "CursorUpdater" -type f -executable 2>/dev/null))
      fi
      updater_paths+=("$HOME/.config/Cursor/updater") # 旧位置？

    for updater in "${updater_paths[@]}"; do
        if [ -f "$updater" ] && [ -x "$updater" ]; then
            log_info "找到更新程序: $updater"
            local bak_updater="${updater}.bak_$(date +%Y%m%d%H%M%S)"
            if mv "$updater" "$bak_updater"; then
                 log_info "已重命名更新程序为: $bak_updater"
                 ((disabled_count++))
            else
                 log_warn "重命名更新程序失败: $updater，尝试移除执行权限..."
                 if chmod a-x "$updater"; then
                      log_info "已移除更新程序执行权限: $updater"
                      ((disabled_count++))
                 else
                     log_error "无法禁用更新程序: $updater"
                 fi
            fi
        # elif [ -d "$updater" ]; then # 如果是目录，尝试禁用
        #     log_info "找到更新程序目录: $updater"
        #     touch "${updater}.disabled_by_script"
        #     log_info "已标记禁用更新程序目录: $updater"
        #     ((disabled_count++))
        fi
    done
    
    if [ "$disabled_count" -eq 0 ]; then
        log_warn "未能找到或禁用任何已知的自动更新机制。"
        log_warn "如果 Cursor 仍然自动更新，可能需要手动查找并禁用相关文件或设置。"
    else
        log_info "成功禁用或尝试禁用了 $disabled_count 个自动更新相关的文件/程序。"
    fi
     return 0 # 即使没找到，也认为函数执行成功
}

# 新增：通用菜单选择函数
select_menu_option() {
    local prompt="$1"
    IFS='|' read -ra options <<< "$2"
    local default_index=${3:-0}
    local selected_index=$default_index
    local key_input
    local cursor_up=$'\e[A' # 更标准的 ANSI 码
    local cursor_down=$'\e[B'
    local enter_key=$'\n'

    # 隐藏光标
    tput civis
    # 清除可能存在的旧菜单行 (假设菜单最多 N 行)
    local num_options=${#options[@]}
    for ((i=0; i<num_options+1; i++)); do echo -e "\033[K"; done # 清除行
     tput cuu $((num_options + 1)) # 光标移回顶部


    # 显示提示信息
    echo -e "$prompt"
    
    # 绘制菜单函数
    draw_menu() {
        # 光标移到菜单开始行下方一行
        tput cud 1 
        for i in "${!options[@]}"; do
             tput el # 清除当前行
            if [ $i -eq $selected_index ]; then
                echo -e " ${GREEN}►${NC} ${options[$i]}"
            else
                echo -e "   ${options[$i]}"
            fi
        done
         # 将光标移回提示行下方
        tput cuu "$num_options"
    }
    
    # 第一次显示菜单
    draw_menu

    # 循环处理键盘输入
    while true; do
        # 读取按键 (使用 -sn1 或 -sn3 取决于系统对箭头键的处理)
        # -N 1 读取单个字符，可能需要多次读取箭头键
        # -N 3 一次读取3个字符，通常用于箭头键
        read -rsn1 key_press_1 # 读取第一个字符
         if [[ "$key_press_1" == $'\e' ]]; then # 如果是 ESC，读取后续字符
             read -rsn2 key_press_2 # 读取 '[' 和 A/B
             key_input="$key_press_1$key_press_2"
         elif [[ "$key_press_1" == "" ]]; then # 如果是 Enter
             key_input=$enter_key
         else
             key_input="$key_press_1" # 其他按键
         fi

        # 检测按键
        case "$key_input" in
            # 上箭头键
            "$cursor_up")
                if [ $selected_index -gt 0 ]; then
                    ((selected_index--))
                    draw_menu
                fi
                ;;
            # 下箭头键
            "$cursor_down")
                if [ $selected_index -lt $((${#options[@]}-1)) ]; then
                    ((selected_index++))
                    draw_menu
                fi
                ;;
            # Enter键
            "$enter_key")
                 # 清除菜单区域
                 tput cud 1 # 下移一行开始清除
                 for i in "${!options[@]}"; do tput el; tput cud 1; done
                 tput cuu $((num_options + 1)) # 移回提示行
                 tput el # 清除提示行本身
                 echo -e "$prompt ${GREEN}${options[$selected_index]}${NC}" # 显示最终选择

                 # 恢复光标
                 tput cnorm
                 # 返回选择的索引
                 return $selected_index
                ;;
             *)
                 # 忽略其他按键
                 ;;
        esac
    done
}

# 新增 Cursor 初始化清理函数
cursor_initialize_cleanup() {
    log_info "正在执行 Cursor 初始化清理..."
    # CURSOR_CONFIG_DIR 在脚本全局已定义: $HOME/.config/Cursor
    local USER_CONFIG_BASE_PATH="$CURSOR_CONFIG_DIR/User"

    log_debug "用户配置基础路径: $USER_CONFIG_BASE_PATH"

    local files_to_delete=(
        "$USER_CONFIG_BASE_PATH/globalStorage/state.vscdb"
        "$USER_CONFIG_BASE_PATH/globalStorage/state.vscdb.backup"
    )
    
    local folder_to_clean_contents="$USER_CONFIG_BASE_PATH/History"
    local folder_to_delete_completely="$USER_CONFIG_BASE_PATH/workspaceStorage"

    # 删除指定文件
    for file_path in "${files_to_delete[@]}"; do
        log_debug "检查文件: $file_path"
        if [ -f "$file_path" ]; then
            if rm -f "$file_path"; then
                log_info "已删除文件: $file_path"
            else
                log_error "删除文件 $file_path 失败"
            fi
        else
            log_warn "文件不存在，跳过删除: $file_path"
        fi
    done

    # 清空指定文件夹内容
    log_debug "检查待清空文件夹: $folder_to_clean_contents"
    if [ -d "$folder_to_clean_contents" ]; then
        if find "$folder_to_clean_contents" -mindepth 1 -delete; then
            log_info "已清空文件夹内容: $folder_to_clean_contents"
        else
            if [ -z "$(ls -A "$folder_to_clean_contents")" ]; then
                 log_info "文件夹 $folder_to_clean_contents 现在为空。"
            else
                 log_error "清空文件夹 $folder_to_clean_contents 内容失败 (部分或全部)。请检查权限或手动删除。"
            fi
        fi
    else
        log_warn "文件夹不存在，跳过清空: $folder_to_clean_contents"
    fi

    # 删除指定文件夹及其内容
    log_debug "检查待删除文件夹: $folder_to_delete_completely"
    if [ -d "$folder_to_delete_completely" ]; then
        if rm -rf "$folder_to_delete_completely"; then
            log_info "已删除文件夹: $folder_to_delete_completely"
        else
            log_error "删除文件夹 $folder_to_delete_completely 失败"
        fi
    else
        log_warn "文件夹不存在，跳过删除: $folder_to_delete_completely"
    fi

    log_info "Cursor 初始化清理完成。"
}

# 主函数
main() {
    # 初始化日志文件
    initialize_log
    log_info "脚本启动..."
    log_info "运行用户: $CURRENT_USER (脚本以 EUID=$EUID 运行)"

    # 检查权限 (必须在脚本早期)
    check_permissions # 需要 root 权限进行安装和修改系统文件

    # 记录系统信息
    log_info "系统信息: $(uname -a)"
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
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${GREEN}         Cursor Linux 启动与修改工具            ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo
    echo -e "${YELLOW}[提示]${NC} 本工具旨在修改 Cursor 以解决可能的启动问题或设备限制。"
    echo -e "${YELLOW}[提示]${NC} 它将优先修改 JS 文件，并可选择重置设备ID和禁用自动更新。"
    echo -e "${YELLOW}[提示]${NC} 如果未找到 Cursor，将尝试从 '$APPIMAGE_SEARCH_DIR' 目录安装。"
    echo

    # 查找 Cursor 路径
    if ! find_cursor_path; then
        log_warn "系统中未找到现有的 Cursor 安装。"
        select_menu_option "是否尝试从 '$APPIMAGE_SEARCH_DIR' 目录中的 AppImage 文件安装 Cursor？" "是，安装 Cursor|否，退出脚本" 0
        install_choice=$?
        
        if [ "$install_choice" -eq 0 ]; then
            if ! install_cursor_appimage; then
                log_error "Cursor 安装失败，请检查上面的日志。脚本将退出。"
                exit 1
            fi
            # 安装成功后，重新查找路径
            if ! find_cursor_path || ! find_cursor_resources; then
                 log_error "安装后仍然无法找到 Cursor 的可执行文件或资源目录。请检查 '$INSTALL_DIR' 和 '/usr/local/bin/cursor'。脚本退出。"
                 exit 1
            fi
            log_info "Cursor 安装成功，继续执行修改步骤..."
        else
            log_info "用户选择不安装 Cursor，脚本退出。"
            exit 0
        fi
    else
        # 如果找到了 Cursor，也要确保找到资源目录
        if ! find_cursor_resources; then
            log_error "找到了 Cursor 可执行文件 ($CURSOR_PATH)，但未能定位资源目录。"
            log_error "无法继续修改 JS 文件。请检查 Cursor 安装是否完整。脚本退出。"
            exit 1
        fi
        log_info "发现已安装的 Cursor ($CURSOR_PATH)，资源目录 ($CURSOR_RESOURCES)。"
    fi

    # 到这里，Cursor 应该已安装并且路径已知

    # 检查并关闭Cursor进程
    if ! check_and_kill_cursor; then
         # check_and_kill_cursor 内部会记录错误并退出，但以防万一
         exit 1
    fi
    
    # 执行 Cursor 初始化清理
    cursor_initialize_cleanup

    # 备份并处理配置文件 (机器码重置选项)
    if ! generate_new_config; then
         log_error "处理配置文件时出错，脚本中止。"
         # 此处可能需要考虑是否回滚JS修改（如果已执行）？目前不回滚。
         exit 1
    fi
    
    # 修改JS文件
    log_info "正在修改 Cursor JS 文件..."
    if ! modify_cursor_js_files; then
        log_error "JS 文件修改过程中发生错误。"
        log_warn "配置文件可能已被修改，但 JS 文件修改失败。"
        log_warn "如果重启后 Cursor 行为异常或仍有问题，请检查日志并考虑手动恢复备份或重新运行脚本。"
        # 决定是否继续执行禁用更新？通常建议继续
        # exit 1 # 或者选择退出
    else
        log_info "JS 文件修改成功！"
    fi
    
    # 禁用自动更新
    if ! disable_auto_update; then
        # disable_auto_update 内部会记录警告，不视为致命错误
        log_warn "尝试禁用自动更新时遇到问题（详见日志），但脚本将继续。"
    fi
    
    log_info "所有修改步骤已完成！"
    log_info "请启动 Cursor 以应用更改。"
    
    # 显示最后的提示信息
    echo
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${YELLOW}  请关注公众号【煎饼果子卷AI】获取更多技巧和交流 ${NC}"
    echo -e "${GREEN}=====================================================${NC}"
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

exit 0 # 确保最后返回成功状态码
