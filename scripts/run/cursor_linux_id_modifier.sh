#!/bin/bash
set -euo pipefail  # Exit immediately on error, unset variable, or pipeline error

#==============================
# Define Colors for Logging
#==============================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

#==============================
# Logging Functions
#==============================
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

#==============================
# Get the current non-root username
#==============================
get_current_user() {
    if [ "$EUID" -eq 0 ]; then
        echo "${SUDO_USER:-root}"
    else
        echo "$USER"
    fi
}

CURRENT_USER=$(get_current_user)
if [ -z "$CURRENT_USER" ]; then
    log_error "Unable to retrieve username"
    exit 1
fi

#==============================
# Define configuration file path and backup directory (Linux paths)
#==============================
STORAGE_FILE="/home/$CURRENT_USER/.config/Cursor/User/globalStorage/storage.json"
BACKUP_DIR="/home/$CURRENT_USER/.config/Cursor/User/globalStorage/backups"

#==============================
# Check for proper permissions
#==============================
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run this script using sudo"
        echo "Example: sudo $0"
        exit 1
    fi
}

#==============================
# Check for and terminate any running Cursor processes
#==============================
check_and_kill_cursor() {
    log_info "Checking for Cursor processes..."

    local attempt=1
    local max_attempts=5

    # Function: Get process details for a given process name
    get_process_details() {
        local process_name="$1"
        log_debug "Retrieving details for $process_name process:"
        ps aux | grep -E "/[C]ursor|[C]ursor$" || true
    }

    while [ $attempt -le $max_attempts ]; do
        # Use a more precise method to find Cursor processes
        CURSOR_PIDS=$(ps aux | grep -E "/[C]ursor|[C]ursor$" | awk '{print $2}' || true)
        
        if [ -z "$CURSOR_PIDS" ]; then
            log_info "No running Cursor processes found"
            return 0
        fi
        
        log_warn "Found running Cursor process(es)"
        get_process_details "Cursor"
        log_warn "Attempting to close Cursor process(es)..."
        
        # Iterate through each PID and attempt to terminate it
        for pid in $CURSOR_PIDS; do
            if [ $attempt -eq $max_attempts ]; then
                log_warn "Attempting to force terminate process PID: ${pid}..."
                kill -9 "$pid" 2>/dev/null || true
            else
                kill "$pid" 2>/dev/null || true
            fi
        done
        
        sleep 2
        
        # Check if any Cursor processes are still running
        if ! ps aux | grep -E "/[C]ursor|[C]ursor$" > /dev/null; then
            log_info "Cursor processes have been successfully closed"
            return 0
        fi
        
        log_warn "Waiting for processes to close, attempt $attempt/$max_attempts..."
        ((attempt++))
        sleep 1
    done
    
    log_error "Unable to close Cursor processes after $max_attempts attempts"
    get_process_details "Cursor"
    log_error "Please manually close the process(es) and try again"
    exit 1
}

#==============================
# Backup system ID (machine-id and hostname)
#==============================
backup_system_id() {
    log_info "Backing up system ID..."
    local system_id_file="$BACKUP_DIR/system_id.backup_$(date +%Y%m%d_%H%M%S)"
    
    {
        echo "# Original Machine ID Backup" > "$system_id_file"
        echo "## /var/lib/dbus/machine-id:" >> "$system_id_file"
        cat /var/lib/dbus/machine-id 2>/dev/null >> "$system_id_file" || echo "Not found" >> "$system_id_file"
        
        echo -e "\n## /etc/machine-id:" >> "$system_id_file"
        cat /etc/machine-id 2>/dev/null >> "$system_id_file" || echo "Not found" >> "$system_id_file"
        
        echo -e "\n## hostname:" >> "$system_id_file"
        hostname >> "$system_id_file"
        
        chmod 444 "$system_id_file"
        chown "$CURRENT_USER:$CURRENT_USER" "$system_id_file"
        log_info "System ID backed up to: $system_id_file"
    } || {
        log_error "Failed to backup system ID"
        return 1
    }
}

#==============================
# Backup the configuration file
#==============================
backup_config() {
    # Check file write permissions
    if [ -f "$STORAGE_FILE" ] && [ ! -w "$STORAGE_FILE" ]; then
        log_error "Unable to write to configuration file, please check permissions"
        exit 1
    fi
    
    if [ ! -f "$STORAGE_FILE" ]; then
        log_warn "Configuration file does not exist, skipping backup"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/storage.json.backup_$(date +%Y%m%d_%H%M%S)"
    
    if cp "$STORAGE_FILE" "$backup_file"; then
        chmod 644 "$backup_file"
        chown "$CURRENT_USER:$CURRENT_USER" "$backup_file"
        log_info "Configuration backed up to: $backup_file"
    else
        log_error "Backup failed"
        exit 1
    fi
}

#==============================
# Generate a random ID (32 bytes in hex)
#==============================
generate_random_id() {
    head -c 32 /dev/urandom | xxd -p
}

#==============================
# Generate a random UUID (lowercase)
#==============================
generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

#==============================
# Escape replacement strings for sed
#==============================
escape_sed_replacement() {
    # Escape characters /, &, |, and # in the input string
    echo "$1" | sed -e 'g'
}

#==============================
# Update a JSON field in the configuration file.
# If the sed pattern doesn't match, log a warning.
# Parameters:
#   $1 - JSON field name (e.g., telemetry.machineId)
#   $2 - Replacement value (should be pre-escaped if necessary)
#   $3 - File to update
#==============================
update_field() {
    local field="$1"
    local replacement="$2"
    local file="$3"
    local pattern="\"${field}\": *\"[^\"]*\""
    
    if ! grep -q -E "$pattern" "$file"; then
        log_warn "Pattern for ${field} not found in configuration file"
    fi
    
    sed -i "s|${pattern}|\"${field}\": \"${replacement}\"|" "$file"
}

#==============================
# Update the configuration with new IDs
#==============================
generate_new_config() {
    # Ensure required commands exist
    command -v xxd >/dev/null || { log_error "Command xxd not found, please install xxd (e.g., apt-get install xxd)"; exit 1; }
    command -v uuidgen >/dev/null || { log_error "Command uuidgen not found, please install uuidgen (e.g., apt-get install uuid-runtime)"; exit 1; }
    
    if [ ! -f "$STORAGE_FILE" ]; then
        log_error "Configuration file not found: $STORAGE_FILE"
        log_warn "Please install and run Cursor at least once before using this script"
        exit 1
    fi
    
    # Update system machine-id if applicable
    if [ -f "/etc/machine-id" ]; then
        log_info "Modifying system machine-id..."
        local new_machine_id
        new_machine_id=$(uuidgen | tr -d '-')
        
        # Backup original machine-id
        backup_system_id
        
        # Update machine-id
        echo "$new_machine_id" > /etc/machine-id
        if [ -f "/var/lib/dbus/machine-id" ]; then
            ln -sf /etc/machine-id /var/lib/dbus/machine-id
        fi
        log_info "System machine-id has been updated"
    fi
    
    # Convert "auth0|user_" to its hexadecimal representation
    local prefix_hex
    prefix_hex=$(echo -n "auth0|user_" | xxd -p)
    local random_part
    random_part=$(generate_random_id)
    local machine_id="${prefix_hex}${random_part}"
    
    local mac_machine_id
    mac_machine_id=$(generate_random_id)
    local device_id
    device_id=$(generate_uuid)
    local sqm_id
    sqm_id="{$(generate_uuid | tr '[:lower:]' '[:upper:]')}"
    
    # Escape the values for sed replacement
    local machine_id_escaped
    machine_id_escaped=$(escape_sed_replacement "$machine_id")
    local mac_machine_id_escaped
    mac_machine_id_escaped=$(escape_sed_replacement "$mac_machine_id")
    local device_id_escaped
    device_id_escaped=$(escape_sed_replacement "$device_id")
    local sqm_id_escaped
    sqm_id_escaped=$(escape_sed_replacement "$sqm_id")
    
    # Update configuration JSON fields.
    update_field "telemetry.machineId" "${machine_id_escaped}" "$STORAGE_FILE"
    update_field "telemetry.macMachineId" "${mac_machine_id_escaped}" "$STORAGE_FILE"
    update_field "telemetry.devDeviceId" "${device_id_escaped}" "$STORAGE_FILE"
    update_field "telemetry.sqmId" "${sqm_id_escaped}" "$STORAGE_FILE"
    
    # Set configuration file to read-only
    chmod 444 "$STORAGE_FILE"
    chown "$CURRENT_USER:$CURRENT_USER" "$STORAGE_FILE"
    
    # Verify file is no longer writable; if not, try using chattr for extra protection
    if [ -w "$STORAGE_FILE" ]; then
        log_warn "Unable to set file to read-only, trying alternative method..."
        if command -v chattr &>/dev/null; then
            chattr +i "$STORAGE_FILE" 2>/dev/null || log_warn "chattr failed to set attribute"
        fi
    else
        log_info "Successfully set file to read-only"
    fi
    
    echo
    log_info "Configuration updated:"
    log_debug "machineId: $machine_id"
    log_debug "macMachineId: $mac_machine_id"
    log_debug "devDeviceId: $device_id"
    log_debug "sqmId: $sqm_id"
}

#==============================
# Display the file tree structure for the storage folder
#==============================
show_file_tree() {
    local base_dir
    base_dir=$(dirname "$STORAGE_FILE")
    echo
    log_info "File structure:"
    echo -e "${BLUE}$base_dir${NC}"
    echo "├── globalStorage"
    echo "│   ├── storage.json (modified)"
    echo "│   └── backups"
    
    # List backup files
    if [ -d "$BACKUP_DIR" ]; then
        local backup_files=("$BACKUP_DIR"/*)
        if [ ${#backup_files[@]} -gt 0 ] && [ -e "${backup_files[0]}" ]; then
            for file in "${backup_files[@]}"; do
                if [ -f "$file" ]; then
                    echo "│       └── $(basename "$file")"
                fi
            done
        else
            echo "│       └── (empty)"
        fi
    fi
    echo
}

#==============================
# Display follow info (public account message)
#==============================
show_follow_info() {
    echo
    echo -e "${GREEN}================================${NC}"
    echo -e "${YELLOW}  Follow the public account [煎饼果子卷AI] to exchange more Cursor skills and AI knowledge  ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
}

#==============================
# Disable Cursor auto-update by removing/locking the updater directory
#==============================
disable_auto_update() {
    echo
    log_warn "Do you want to disable the Cursor auto-update feature?"
    echo "0) No - Keep default settings (press Enter)"
    echo "1) Yes - Disable auto-update"
    read -r choice
    
    if [ "$choice" = "1" ]; then
        echo
        log_info "Processing auto-update settings..."
        local updater_path="$HOME/.config/cursor-updater"
        
        show_manual_guide() {
            echo
            log_warn "Automatic setup failed, please try manual steps:"
            echo -e "${YELLOW}Manual steps to disable auto-update:${NC}"
            echo "1. Open a terminal"
            echo "2. Copy and paste the following command:"
            echo -e "${BLUE}rm -rf \"$updater_path\" && touch \"$updater_path\" && chmod 444 \"$updater_path\"${NC}"
            echo
            echo -e "${YELLOW}If you encounter insufficient permission errors, try using sudo:${NC}"
            echo -e "${BLUE}sudo rm -rf \"$updater_path\" && sudo touch \"$updater_path\" && sudo chmod 444 \"$updater_path\"${NC}"
            echo
            echo -e "${YELLOW}For additional protection (recommended), execute:${NC}"
            echo -e "${BLUE}sudo chattr +i \"$updater_path\"${NC}"
            echo
            echo -e "${YELLOW}Verification steps:${NC}"
            echo "1. Run: ls -l \"$updater_path\""
            echo "2. Ensure the file permissions are r--r--r--"
            echo "3. Run: lsattr \"$updater_path\""
            echo "4. Verify that the 'i' attribute is present (if chattr was executed)"
            echo
            log_warn "After completing, please restart Cursor"
        }
        
        if [ -d "$updater_path" ]; then
            rm -rf "$updater_path" 2>/dev/null || {
                log_error "Failed to delete cursor-updater directory"
                show_manual_guide
                return 1
            }
            log_info "Successfully deleted cursor-updater directory"
        fi
        
        touch "$updater_path" 2>/dev/null || {
            log_error "Failed to create blocking file"
            show_manual_guide
            return 1
        }
        
        if ! chmod 444 "$updater_path" 2>/dev/null || ! chown "$CURRENT_USER:$CURRENT_USER" "$updater_path" 2>/dev/null; then
            log_error "Failed to set file permissions"
            show_manual_guide
            return 1
        fi
        
        if command -v chattr &>/dev/null; then
            chattr +i "$updater_path" 2>/dev/null || {
                log_warn "chattr failed to set attribute"
                show_manual_guide
                return 1
            }
        fi
        
        if [ ! -f "$updater_path" ] || [ -w "$updater_path" ]; then
            log_error "Verification failed: file permissions may not have taken effect"
            show_manual_guide
            return 1
        fi
        
        log_info "Successfully disabled auto-update"
    else
        log_info "Keeping default settings, no changes made"
    fi
}

#==============================
# Main function to execute all tasks
#==============================
main() {
    clear
    # Display ASCII Logo
    echo -e "
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
    "
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}   Cursor ID Modification Tool          ${NC}"
    echo -e "${YELLOW}  Follow the public account [煎饼果子卷AI] to exchange more Cursor skills and AI knowledge (script is free; follow and join the group for more tips and experts)  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    echo -e "${YELLOW}[IMPORTANT]${NC} This tool supports Cursor v0.45.x"
    echo -e "${YELLOW}[IMPORTANT]${NC} This tool is free. Follow the public account and join the group for more tips and experts"
    echo

    check_permissions
    check_and_kill_cursor
    backup_config
    generate_new_config

    echo
    log_info "Operation completed!"
    show_follow_info
    show_file_tree
    log_info "Please restart Cursor to apply the new configuration"

    disable_auto_update
}

# Execute main function
main
