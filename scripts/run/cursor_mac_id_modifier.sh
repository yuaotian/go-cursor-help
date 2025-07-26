#!/bin/bash

# ========================================
# 🍎 Cursor macOS ID Modifier Script 🚀
# ========================================
# Purpose: Reset Cursor trial by modifying device identifiers
# Platform: macOS (Intel & Apple Silicon)
# Requirements: sudo privileges, Cursor installed
# ========================================

set -e

# ========================================
# CONFIGURATION
# ========================================

readonly SCRIPT_NAME="Cursor macOS ID Modifier"
readonly LOG_FILE="/tmp/cursor_mac_id_modifier.log"
readonly CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor"
readonly STORAGE_FILE="$CURSOR_CONFIG_DIR/User/globalStorage/storage.json"
readonly BACKUP_DIR="$CURSOR_CONFIG_DIR/User/globalStorage/backups"
readonly CURSOR_APP_PATH="/Applications/Cursor.app"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ========================================
# UTILITY FUNCTIONS
# ========================================

# Initialize logging
init_log() {
    echo "========== $SCRIPT_NAME Log Start $(date) ==========" > "$LOG_FILE"
    chmod 644 "$LOG_FILE"
}

# Logging functions with emojis
log_info() {
    echo -e "${GREEN}✅ [INFO]${NC} $1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}⚠️  [WARN]${NC} $1"
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_debug() {
    echo -e "${BLUE}🔍 [DEBUG]${NC} $1"
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Generate UUID
generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# Generate random hex string
generate_random_hex() {
    local length=${1:-32}
    openssl rand -hex $((length / 2))
}

# ========================================
# PERMISSION MANAGEMENT
# ========================================

# Fix Cursor directory permissions
fix_cursor_permissions() {
    log_info "Fixing Cursor directory permissions..."
    
    local cursor_support_dir="$HOME/Library/Application Support/Cursor"
    local cursor_home_dir="$HOME/.cursor"
    
    # Ensure directories exist
    mkdir -p "$cursor_support_dir" 2>/dev/null || true
    mkdir -p "$cursor_home_dir/extensions" 2>/dev/null || true
    
    # Fix ownership and permissions
    if sudo chown -R "$(whoami)" "$cursor_support_dir" 2>/dev/null; then
        log_info "Fixed ownership for Application Support/Cursor"
    else
        log_warn "Failed to fix ownership for Application Support/Cursor"
    fi
    
    if sudo chown -R "$(whoami)" "$cursor_home_dir" 2>/dev/null; then
        log_info "Fixed ownership for .cursor"
    else
        log_warn "Failed to fix ownership for .cursor"
    fi
    
    if chmod -R u+w "$cursor_support_dir" 2>/dev/null; then
        log_info "Fixed permissions for Application Support/Cursor"
    else
        log_warn "Failed to fix permissions for Application Support/Cursor"
    fi
    
    if chmod -R u+w "$cursor_home_dir/extensions" 2>/dev/null; then
        log_info "Fixed permissions for .cursor/extensions"
    else
        log_warn "Failed to fix permissions for .cursor/extensions"
    fi
    
    log_info "Permission fix completed"
}

# ===========
EMENT
# ==================


stop_cursor_
    log_info "Stopping Cursor 
    
    local max_attempts=5
    local attempt=1
    
s ]; do
        local cursor_pids=$(pgrep -i 
        
        
            log_info "All Cursor processes stopped"
      n 0
        fi
       
mpts)"
        
        if [ $attempt -eq $hen
        e
        else

        fi
        
        sleep 2
      ttempt++))

    
s"
    return 1
}

# ===========
GEMENT
# ================

# Remove Cursor trial folders
 {
    log_info "s..."
    
    local folders_to_delete=(
        "$HOME/Li/Cursor"

    )
    
nt=0
    local skippe
    
    for folder in "${]}"; do
        log_debug older"
     
        if [ -d "$folder" ]; then
            log_warn "Found folder, removing: $folder"
            if ; then
                log_info "Succ"
        )

                log_error "Failed 
            fi
  else
            log_info "Folder not flder"
            ((skipped_count++))
        i
    done
  
    log_info "Folder removal ced_count"
    
    # al

    
    return 0
}

# =======

# =========================

 config
start_cursor_for_config() {
    log_info
    
"
    
    if [ ! -f "$cursor_exec" ]; then
        log_error "Cursor ele"
eturn 1
    fi
    
rting
    fix_cursor_permissions
    
    # Start Cursor
    "$cursor_execut1 &

    log_info "Cursor startedid"
    
    # Wait for config file generation
    local config_path="$STORAGE_FILE"
    locat=60
    local waited=0
    
.."
    while [ do
        sleep 2
        waited=$((waited + 2))
        en
            log_innds)"
        fi
    done
    
    if [ -f "$config_path" ]; then
        loy"
      ation
missions
        return 0
    else
        log_warn "Configuration file not generated wi
      rn 1
fi
}

# ========================================
# CONFIGT
# ========================================

e
check_python3() {
    if ! command -v python3 >/dev/null 2>&1; then
        log_error "Python3 is required but not found"
      
n 1
    fi
    return 0
}

# Backupfiguration
backup_config() {
    if [ ! -f "$STORAGE_FILE" ]; then
        log_warn "Configuration file not fo backup"
        retu
    fi
    
 IR"
%S)"
    
    if cp "$STORAGE_FILE" "$backup_n
        chmod 644 "$backup_file"
"
        return 0
    else
ion"
        return 1
    fi
}

ion
modify_machine_code_config() {
..."
    
    if ! check_python3; then
 1
    fi
    
    local config_path="_FILE"
    
s
    if [ ! -f "$config_path" ]; then
        log_error "Configuration file not f
"
        
        if start_cursor_for_config; then
            log_info 
        else
"
            return 1
        fi
    fi
    
    # Verify JSON format
    if ! p
        
turn 1
    fi
    
    log_info "Configuration file format is val"
    
    # Baion
    if ! backup_config; then
        return 1
    fi
    
 s
uid)
    local UUID=$(gen
    local MACHINE_ID="auth0|user_$(gene)"
    local SQM_ID="{$(uuidgen | tr '[:lo"
  
    log_info "Generated new device identifiers"
    
ython
    local py"
import json
import sys

try:
    with open('$config_path', 'r', enc8') as f:
d(f)

    # Update properties
    properties_to_update = {
        ID',
        'telemetry.macMachineId': '$MAC_MACHINE_ID',
      ID',
QM_ID'
    }

    for key, value in properties_to_update.items():
        alue

    wi
se)

    print('SUCCESS')
except Exception as e:
    prin
    sys.exit(1)
" 2>&1

    if echo "$python_result" | grep -q "SUCC
        log_info "Configuration updated successfully"
        
        ssions
        chmod 644 "$config_path" 2>/dev/null || true
      sions
 
        log_info "Machine code conpleted"
        log_"
 
INE_ID"
        echo "  •D"
        echo "  • sqmId: $SQM_ID"
        
        return 0
 
tion"
        log_debug "Pytho"
        return 1
    fi
}


CUTION


ites
check_prerequisite{
    log_info "Checking prerequ.."
    
nstalled
    if [hen
        log_error "Cursor applicationH"
sh/"
        exit 1
i
    
    # Check Python3
    if ! check_python3; then
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Show menu
show_menu() {
    echo
    echo "Please select an option:"
    echo "1.ed)"

    echo "3. Resy"
    echo "4. Exit"
    echo
}

# Main function
main() {
    echo "===="
E"
    echo "======"
    eco
    
    init_log
    check_prerequisites
    
    while true; do
        show_menu
        read -p " choice
        
        case $choice in
        1)
                log_
                
                esses
           l_folders
     
                if modify_machine_code_config; then
                    echo
====="
                    log_info "Full reset completed successfully!"
                    log_inf"
                    log_inal"
                    break
                else
                    log_error "Machine code modifiled"
             it 1
                fi
                ;;
            2)
 .."
          
_processes
              
                if modify_machine_code_chen

            ="
                    log_info "Machine code modification completed!"
                    log_info "========================
                    log_info "You can now restart Cursor"
                    break
   else
                    log_error "Machin"

                fi

            3)
                log_info "Starting trial folder reset only..."
                
                stop_cursor_processes
                lders
              

                log_info "========================================"
                log_info "Trial folder reset com!"
======="
                log_info "You can nowrsor"
                break
                ;;
            4)
      "
 0
              
            *)
                log_warn "Invalid choice. Please en"
                ;;
        esac
    done
    
    echo
    log_inLE"
    echo
}

# Exec
" "$@ainmlo
g_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Generate UUID
generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# Generate random hex string
generate_random_hex() {
    local length=${1:-32}
    openssl rand -hex $((length / 2))
}

# ========================================
# PERMISSION MANAGEMENT
# ========================================

# Fix Cursor directory permissions
fix_cursor_permissions() {
    log_info "Fixing Cursor directory permissions..."
    
    local cursor_support_dir="$HOME/Library/Application Support/Cursor"
    local cursor_home_dir="$HOME/.cursor"
    
    # Ensure directories exist
    mkdir -p "$cursor_support_dir" 2>/dev/null || true
    mkdir -p "$cursor_home_dir/extensions" 2>/dev/null || true
    
    # Fix ownership and permissions
    if sudo chown -R "$(whoami)" "$cursor_support_dir" 2>/dev/null; then
        log_info "Fixed ownership for Application Support/Cursor"
    else
        log_warn "Failed to fix ownership for Application Support/Cursor"
    fi
    
    if sudo chown -R "$(whoami)" "$cursor_home_dir" 2>/dev/null; then
        log_info "Fixed ownership for .cursor"
    else
        log_warn "Failed to fix ownership for .cursor"
    fi
    
    if chmod -R u+w "$cursor_support_dir" 2>/dev/null; then
        log_info "Fixed permissions for Application Support/Cursor"
    else
        log_warn "Failed to fix permissions for Application Support/Cursor"
    fi
    
    if chmod -R u+w "$cursor_home_dir/extensions" 2>/dev/null; then
        log_info "Fixed permissions for .cursor/extensions"
    else
        log_warn "Failed to fix permissions for .cursor/extensions"
    fi
    
    log_info "Permission fix completed"
}

# ========================================
# PROCESS MANAGEMENT
# ========================================

# Stop all Cursor processes
stop_cursor_processes() {
    log_info "Stopping Cursor processes..."
    
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local cursor_pids=$(pgrep -i cursor 2>/dev/null || true)
        
        if [ -z "$cursor_pids" ]; then
            log_info "All Cursor processes stopped"
            return 0
        fi
        
        log_warn "Found running Cursor processes, stopping... (attempt $attempt/$max_attempts)"
        
        if [ $attempt -eq $max_attempts ]; then
            pkill -9 -i cursor 2>/dev/null || true
        else
            pkill -i cursor 2>/dev/null || true
        fi
        
        sleep 2
        ((attempt++))
    done
    
    log_error "Failed to stop all Cursor processes"
    return 1
}

# ========================================
# FOLDER MANAGEMENT
# ========================================

# Remove Cursor trial folders
remove_cursor_trial_folders() {
    log_info "Removing Cursor trial folders..."
    
    local folders_to_delete=(
        "$HOME/Library/Application Support/Cursor"
        "$HOME/.cursor"
    )
    
    local deleted_count=0
    local skipped_count=0
    
    for folder in "${folders_to_delete[@]}"; do
        log_debug "Checking folder: $folder"
        
        if [ -d "$folder" ]; then
            log_warn "Found folder, removing: $folder"
            if rm -rf "$folder"; then
                log_info "Successfully removed: $folder"
                ((deleted_count++))
            else
                log_error "Failed to remove: $folder"
            fi
        else
            log_info "Folder not found (skipping): $folder"
            ((skipped_count++))
        fi
    done
    
    log_info "Folder removal completed - Deleted: $deleted_count, Skipped: $skipped_count"
    
    # Fix permissions after folder removal
    fix_cursor_permissions
    
    return 0
}

# ========================================
# CURSOR MANAGEMENT
# ========================================

# Start Cursor to generate config
start_cursor_for_config() {
    log_info "Starting Cursor to generate configuration..."
    
    local cursor_executable="$CURSOR_APP_PATH/Contents/MacOS/Cursor"
    
    if [ ! -f "$cursor_executable" ]; then
        log_error "Cursor executable not found: $cursor_executable"
        return 1
    fi
    
    # Fix permissions before starting
    fix_cursor_permissions
    
    # Start Cursor
    "$cursor_executable" > /dev/null 2>&1 &
    local cursor_pid=$!
    log_info "Cursor started with PID: $cursor_pid"
    
    # Wait for config file generation
    local config_path="$STORAGE_FILE"
    local max_wait=60
    local waited=0
    
    log_info "Waiting for configuration file generation..."
    while [ ! -f "$config_path" ] && [ $waited -lt $max_wait ]; do
        sleep 2
        waited=$((waited + 2))
        if [ $((waited % 10)) -eq 0 ]; then
            log_info "Still waiting... ($waited/$max_wait seconds)"
        fi
    done
    
    if [ -f "$config_path" ]; then
        log_info "Configuration file generated successfully"
        # Fix permissions after generation
        fix_cursor_permissions
        return 0
    else
        log_warn "Configuration file not generated within timeout"
        return 1
    fi
}

# ========================================
# CONFIGURATION MANAGEMENT
# ========================================

# Check if Python3 is available
check_python3() {
    if ! command -v python3 >/dev/null 2>&1; then
        log_error "Python3 is required but not found"
        log_info "Please install Python3: brew install python3"
        return 1
    fi
    return 0
}

# Backup configuration
backup_config() {
    if [ ! -f "$STORAGE_FILE" ]; then
        log_warn "Configuration file not found, skipping backup"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/storage.json.backup_$(date +%Y%m%d_%H%M%S)"
    
    if cp "$STORAGE_FILE" "$backup_file"; then
        chmod 644 "$backup_file"
        log_info "Configuration backed up to: $(basename "$backup_file")"
        return 0
    else
        log_error "Failed to backup configuration"
        return 1
    fi
}

# Modify machine code configuration
modify_machine_code_config() {
    log_info "Modifying machine code configuration..."
    
    if ! check_python3; then
        return 1
    fi
    
    local config_path="$STORAGE_FILE"
    
    # Check if config file exists
    if [ ! -f "$config_path" ]; then
        log_error "Configuration file not found: $config_path"
        log_info "Attempting to generate configuration file..."
        
        if start_cursor_for_config; then
            log_info "Configuration file generated, continuing..."
        else
            log_error "Failed to generate configuration file"
            return 1
        fi
    fi
    
    # Verify JSON format
    if ! python3 -c "import json; json.load(open('$config_path'))" 2>/dev/null; then
        log_error "Configuration file format is invalid"
        return 1
    fi
    
    log_info "Configuration file format is valid"
    
    # Backup original configuration
    if ! backup_config; then
        return 1
    fi
    
    # Generate new IDs
    local MAC_MACHINE_ID=$(generate_uuid)
    local UUID=$(generate_uuid)
    local MACHINE_ID="auth0|user_$(generate_random_hex 64)"
    local SQM_ID="{$(uuidgen | tr '[:lower:]' '[:upper:]')}"
    
    log_info "Generated new device identifiers"
    
    # Update configuration using Python
    local python_result=$(python3 -c "
import json
import sys

try:
    with open('$config_path', 'r', encoding='utf-8') as f:
        config = json.load(f)

    # Update properties
    properties_to_update = {
        'telemetry.machineId': '$MACHINE_ID',
        'telemetry.macMachineId': '$MAC_MACHINE_ID',
        'telemetry.devDeviceId': '$UUID',
        'telemetry.sqmId': '$SQM_ID'
    }

    for key, value in properties_to_update.items():
        config[key] = value

    with open('$config_path', 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

    print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
" 2>&1)

    if echo "$python_result" | grep -q "SUCCESS"; then
        log_info "Configuration updated successfully"
        
        # Set proper permissions
        chmod 644 "$config_path" 2>/dev/null || true
        fix_cursor_permissions
        
        log_info "Machine code configuration completed"
        log_info "Updated identifiers:"
        echo "  • machineId: ${MACHINE_ID:0:20}..."
        echo "  • macMachineId: $MAC_MACHINE_ID"
        echo "  • devDeviceId: $UUID"
        echo "  • sqmId: $SQM_ID"
        
        return 0
    else
        log_error "Failed to update configuration"
        log_debug "Python output: $python_result"
        return 1
    fi
}

# ========================================
# MAIN EXECUTION
# ========================================

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Cursor is installed
    if [ ! -d "$CURSOR_APP_PATH" ]; then
        log_error "Cursor application not found at: $CURSOR_APP_PATH"
        log_info "Please install Cursor first: https://cursor.sh/"
        exit 1
    fi
    
    # Check Python3
    if ! check_python3; then
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Show menu
show_menu() {
    echo
    echo "🎯 Please select an option:"
    echo
    echo "   1️⃣  🔥 Reset trial folders + Modify machine code (Recommended)"
    echo "   2️⃣  ⚙️  Modify machine code only"
    echo "   3️⃣  🗂️  Reset trial folders only"
    echo "   4️⃣  🚪 Exit"
    echo
}

# Main function
main() {
    echo"
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
    ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
    ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
    ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝"
    echo
    echo "========================================="
    echo "  🍎 $SCRIPT_NAME"
    echo "========================================="
    echo
    
    init_log
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Enter your choice (1-4): " choice
        
        case $choice in
            1)
                log_info "Starting full reset (folders + machine code)..."
                
                stop_cursor_processes
                remove_cursor_trial_folders
                
                if modify_machine_code_config; then
                    echo
                    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
                    echo "║                                                                              ║"
                    echo "║    🎉 SUCCESS! FULL RESET COMPLETED! 🎉                                    ║"
                    echo "║                                                                              ║"
                    echo "║    ✅ Trial folders removed                                                 ║"
                    echo "║    ✅ Machine code configuration updated                                    ║"
                    echo "║    ✅ Permissions fixed                                                     ║"
                    echo "║                                                                              ║"
                    echo "║    🚀 You can now restart Cursor to use the reset trial!                   ║"
                    echo "║                                                                              ║"
                    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
                    break
                else
                    log_error "Machine code modification failed"
                    exit 1
                fi
                ;;
            2)
                log_info "Starting machine code modification only..."
                
                stop_cursor_processes
                
                if modify_machine_code_config; then
                    echo
                    log_info "========================================="
                    log_info "Machine code modification completed!"
                    log_info "========================================="
                    log_info "You can now restart Cursor"
                    break
                else
                    log_error "Machine code modification failed"
                    exit 1
                fi
                ;;
            3)
                log_info "Starting trial folder reset only..."
                
                stop_cursor_processes
                remove_cursor_trial_folders
                
                echo
                log_info "========================================="
                log_info "Trial folder reset completed!"
                log_info "========================================="
                log_info "You can now restart Cursor"
                break
                ;;
            4)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_warn "Invalid choice. Please enter 1-4."
                ;;
        esac
    done
    
    echo
    log_info "Log file: $LOG_FILE"
    echo
}

# Execute main function
main "$@"