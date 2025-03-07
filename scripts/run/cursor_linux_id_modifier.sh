#!/bin/bash

# 设置错误处理
set -e

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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
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
if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME="$HOME"
fi
STORAGE_FILE="$USER_HOME/.config/Cursor/User/globalStorage/storage.json"
BACKUP_DIR="$USER_HOME/.config/Cursor/User/globalStorage/backups"

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
        ps aux | grep -i "$process_name" | grep -v grep
    }
    
    while [ $attempt -le $max_attempts ]; do
        CURSOR_PIDS=$(pgrep -i "cursor" || true)
        
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
        
        if ! pgrep -i "cursor" > /dev/null; then
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

# 备份系统 ID
backup_system_id() {
    log_info "正在备份系统 ID..."
    local system_id_file="$BACKUP_DIR/system_id.backup_$(date +%Y%m%d_%H%M%S)"
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    {
        echo "# Original System ID Backup - $(date)" > "$system_id_file"
        echo "## Machine ID:" >> "$system_id_file"
        cat /etc/machine-id >> "$system_id_file"
        echo -e "\n## DMI System UUID:" >> "$system_id_file"
        dmidecode -s system-uuid >> "$system_id_file" 2>/dev/null || echo "N/A"
        
        chmod 444 "$system_id_file"
        chown "$CURRENT_USER" "$system_id_file"
        log_info "系统 ID 已备份到: $system_id_file"
    } || {
        log_error "备份系统 ID 失败"
        return 1
    }
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
    # 生成32字节(64个十六进制字符)的随机数，并确保一行输出
    head -c 32 /dev/urandom | xxd -p -c 32
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
    
    # 转义特殊字符
    local key_escaped=$(sed 's/[\/&]/\\&/g' <<< "$key")
    local value_escaped=$(sed 's/[\/&]/\\&/g' <<< "$value")
    
    if [ ! -f "$file" ]; then
        log_error "文件不存在: $file"
        return 1
    fi
    
    # 检查并移除chattr只读属性（如果存在）
    if lsattr "$file" 2>/dev/null | grep -q '^....i'; then
        log_debug "移除文件不可变属性..."
        sudo chattr -i "$file" || {
            log_error "无法移除文件不可变属性"
            return 1
        }
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
        # 使用#作为分隔符避免冲突，并转义特殊字符
        sed "s#\"${key_escaped}\":[[:space:]]*\"[^\"]*\"#\"${key_escaped}\": \"${value_escaped}\"#" "$file" > "$temp_file" || {
            log_error "修改配置失败: $key"
            rm -f "$temp_file"
            return 1
        }
    else
        # 添加新键值对时转义特殊字符
        sed "s/}$/,\n    \"${key_escaped}\": \"${value_escaped}\"\n}/" "$file" > "$temp_file" || {
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
    # 修改系统 ID
    log_info "正在修改系统 ID..."
    
    # 备份当前系统 ID
    backup_system_id
    
    # 生成新的 machine-id
    local new_machine_id=$(generate_random_id | cut -c1-32)
    
    # 备份并修改 machine-id
    if [ -f "/etc/machine-id" ]; then
        cp /etc/machine-id /etc/machine-id.backup
        echo "$new_machine_id" > /etc/machine-id
        log_info "系统 machine-id 已更新"
    fi
    
    # 将 auth0|user_ 转换为字节数组的十六进制
    local prefix_hex=$(echo -n "auth0|user_" | xxd -p)
    local random_part=$(generate_random_id)
    local machine_id="${prefix_hex}${random_part}"
    
    local mac_machine_id=$(generate_random_id)
    local device_id=$(generate_uuid | tr '[:upper:]' '[:lower:]')
    local sqm_id="{$(generate_uuid | tr '[:lower:]' '[:upper:]')}"
    
    log_info "正在修改配置文件..."
    # 检查配置文件是否存在
    if [ ! -f "$STORAGE_FILE" ]; then
        log_error "未找到配置文件: $STORAGE_FILE"
        log_warn "请先安装并运行一次 Cursor 后再使用此脚本"
        exit 1
    fi
    
    # 确保配置文件目录存在
    mkdir -p "$(dirname "$STORAGE_FILE")" || {
        log_error "无法创建配置目录"
        exit 1
    }
    
    # 如果文件不存在，创建一个基本的 JSON 结构
    if [ ! -s "$STORAGE_FILE" ]; then
        echo '{}' > "$STORAGE_FILE" || {
            log_error "无法初始化配置文件"
            exit 1
        }
    fi
    
    # 修改现有文件
    modify_or_add_config "telemetry.machineId" "$machine_id" "$STORAGE_FILE" || exit 1
    modify_or_add_config "telemetry.macMachineId" "$mac_machine_id" "$STORAGE_FILE" || exit 1
    modify_or_add_config "telemetry.devDeviceId" "$device_id" "$STORAGE_FILE" || exit 1
    modify_or_add_config "telemetry.sqmId" "$sqm_id" "$STORAGE_FILE" || exit 1
    
    # 设置文件权限和所有者
    chmod 444 "$STORAGE_FILE"  # 改为只读权限
    chown "$CURRENT_USER" "$STORAGE_FILE"
    
    # 验证权限设置
    if [ -w "$STORAGE_FILE" ]; then
        log_warn "无法设置只读权限，尝试使用其他方法..."
        chattr +i "$STORAGE_FILE" 2>/dev/null || true
    else
        log_info "成功设置文件只读权限"
    fi
    
    echo
    log_info "已更新配置: $STORAGE_FILE"
    log_debug "machineId: $machine_id"
    log_debug "macMachineId: $mac_machine_id"
    log_debug "devDeviceId: $device_id"
    log_debug "sqmId: $sqm_id"
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

# 修改 disable_auto_update 函数,在失败处理时添加手动教程
disable_auto_update() {
    echo
    log_warn "是否要禁用 Cursor 自动更新功能？"
    echo "0) 否 - 保持默认设置 (按回车键)"
    echo "1) 是 - 禁用自动更新"
    read -r choice
    
    if [ "$choice" = "1" ]; then
        echo
        log_info "正在处理自动更新..."
        local updater_path="$HOME/.config/cursor-updater"
        
        # 定义手动设置教程
        show_manual_guide() {
            echo
            log_warn "自动设置失败,请尝试手动操作："
            echo -e "${YELLOW}手动禁用更新步骤：${NC}"
            echo "1. 打开终端"
            echo "2. 复制粘贴以下命令："
            echo -e "${BLUE}rm -rf \"$updater_path\" && touch \"$updater_path\" && chmod 444 \"$updater_path\"${NC}"
            echo
            echo -e "${YELLOW}如果上述命令提示权限不足，请使用 sudo：${NC}"
            echo -e "${BLUE}sudo rm -rf \"$updater_path\" && sudo touch \"$updater_path\" && sudo chmod 444 \"$updater_path\"${NC}"
            echo
            echo -e "${YELLOW}如果要添加额外保护（推荐），请执行：${NC}"
            echo -e "${BLUE}sudo chattr +i \"$updater_path\"${NC}"
            echo
            echo -e "${YELLOW}验证方法：${NC}"
            echo "1. 运行命令：ls -l \"$updater_path\""
            echo "2. 确认文件权限为 r--r--r--"
            echo "3. 运行命令：lsattr \"$updater_path\""
            echo "4. 确认有 'i' 属性（如果执行了 chattr 命令）"
            echo
            log_warn "完成后请重启 Cursor"
        }
        
        if [ -d "$updater_path" ]; then
            rm -rf "$updater_path" 2>/dev/null || {
                log_error "删除 cursor-updater 目录失败"
                show_manual_guide
                return 1
            }
            log_info "成功删除 cursor-updater 目录"
        fi
        
        touch "$updater_path" 2>/dev/null || {
            log_error "创建阻止文件失败"
            show_manual_guide
            return 1
        }
        
        if ! chmod 444 "$updater_path" 2>/dev/null || ! chown "$CURRENT_USER:$CURRENT_USER" "$updater_path" 2>/dev/null; then
            log_error "设置文件权限失败"
            show_manual_guide
            return 1
        fi
        
        # 尝试设置不可修改属性
        if command -v chattr &> /dev/null; then
            chattr +i "$updater_path" 2>/dev/null || {
                log_warn "chattr 设置失败"
                show_manual_guide
                return 1
            }
        fi
        
        # 验证设置是否成功
        if [ ! -f "$updater_path" ] || [ -w "$updater_path" ]; then
            log_error "验证失败：文件权限设置可能未生效"
            show_manual_guide
            return 1
        fi
        
        log_info "成功禁用自动更新"
    else
        log_info "保持默认设置，不进行更改"
    fi
}

# 主函数
main() {
    # 检查是否为 Linux 系统
    if [[ $(uname) != "Linux" ]]; then
        log_error "本脚本仅支持 Linux 系统"
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
    echo -e "${GREEN}   Cursor 设备ID 修改工具 (Linux版)  ${NC}"
    echo -e "${YELLOW}  关注公众号【煎饼果子卷AI】     ${NC}"
    echo -e "${YELLOW}  一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    echo -e "${YELLOW}[重要提示]${NC} 本工具支持 Cursor v0.45.x"
    echo -e "${YELLOW}[重要提示]${NC} 本工具免费，如果对您有帮助，请关注公众号【煎饼果子卷AI】"
    echo
    
    check_permissions
    check_and_kill_cursor
    backup_config
    generate_new_config
    show_file_tree
    show_follow_info
    
    # 添加禁用自动更新功能
    disable_auto_update
    
    log_info "请重启 Cursor 以应用新的配置"
    show_follow_info
}

# 执行主函数
main
