#!/bin/bash

# ========================================
# 🐧 Cursor Linux ID Modifier Script 🚀
# ========================================
# Purpose: Reset Cursor trial by modifying device identifiers
# Platform: Linux (all distributions)
# Requirements: sudo privileges, Cursor installed
# ========================================

set -e

# ========================================
# CONFIGURATION
# ========================================

readonly SCRIPT_NAME="Cursor Linux ID Modifier"
readonly LOG_FILE="/tmp/cursor_linux_id_modifier.log"
readonly CURSOR_CONFIG_DIR="$HOME/.config/Cursor"
readonly STORAGE_FILE="$CURSOR_CONFIG_DIR/User/globalStorage/storage.json"
readonly BACKUP_DIR="$CURSOR_CONFIG_DIR/User/globalStorage/backups"

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

# Get current user (handle sudo)
get_current_user() {
    if [ "$EUID" -eq 0 ]; then
        echo "${SUDO_USER:-$USER}"
    else
        echo "$USER"
    fi
}

# Generate random UUID
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
    else
        openssl rand -hex 16 | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-\9\10-\11\12\13\14\15\16/'
    fi
}

# Generate random hex string
generate_random_hex() {
    local length=${1:-32}
    openssl rand -hex $((length / 2))
}

# ========================================
# CURSOR DETECTION
# ========================================

# Find Cursor installation
find_cursor_installation() {
    log_info "🔍 Searching for Cursor installation..."
    
    local cursor_paths=(
        "/usr/bin/cursor"
        "/usr/local/bin/cursor"
        "/opt/Cursor/cursor"
        "$HOME/.local/bin/cursor"
        "/snap/bin/cursor"
    )
    
    # Check predefined paths
    for path in "${cursor_paths[@]}"; do
        if [ -f "$path" ] && [ -x "$path" ]; then
            log_info "🎯 Found Cursor at: $path"
            echo "$path"
            return 0
        fi
    done
    
    # Try which command
    if command -v cursor &> /dev/null; then
        local cursor_path=$(which cursor)
        log_info "🎯 Found Cursor via which: $cursor_path"
        echo "$cursor_path"
        return 0
    fi
    
    # Search in common directories
    local found_path=$(find /usr /opt "$HOME/.local" -name "cursor" -type f -executable 2>/dev/null | head -1)
    if [ -n "$found_path" ]; then
        log_info "🎯 Found Cursor via search: $found_path"
        echo "$found_path"
        return 0
    fi
    
    log_error "❌ Cursor installation not found"
    return 1
}

# Find Cursor resources directory
find_cursor_resources() {
    log_info "Searching for Cursor resources..."
    
    local resource_paths=(
        "/opt/Cursor"
        "/usr/lib/cursor"
        "/usr/share/cursor"
        "$HOME/.local/share/cursor"
    )
    
    for path in "${resource_paths[@]}"; do
        if [ -d "$path/resources" ] || [ -d "$path/app" ]; then
            log_info "Found Cursor resources at: $path"
            echo "$path"
            return 0
        fi
    done
    
    log_error "Cursor resources not found"
    return 1
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
        local cursor_pids=$(pgrep -i cursor | grep -v $$ || true)
        
        if [ -z "$cursor_pids" ]; then
            log_info "All Cursor processes stopped"
            return 0
        fi
        
        log_warn "Found running Cursor processes, stopping... (attempt $attempt/$max_attempts)"
        
        if [ $attempt -eq $max_attempts ]; then
            kill -9 $cursor_pids 2>/dev/null || true
        else
            kill $cursor_pids 2>/dev/null || true
        fi
        
        sleep 2
        ((attempt++))
    done
    
    log_error "Failed to stop all Cursor processes"
    return 1
}

# ========================================
# CONFIGURATION MANAGEMENT
# ========================================

# Create backup of configuration
backup_config() {
    if [ ! -f "$STORAGE_FILE" ]; then
        log_warn "Configuration file not found, skipping backup"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/storage.json.backup_$(date +%Y%m%d_%H%M%S)"
    
    if cp "$STORAGE_FILE" "$backup_file"; then
        chmod 644 "$backup_file"
        chown "$(get_current_user):$(id -g -n "$(get_current_user)")" "$backup_file" 2>/dev/null || true
        log_info "Configuration backed up to: $(basename "$backup_file")"
        return 0
    else
        log_error "Failed to backup configuration"
        return 1
    fi
}

# Modify configuration file
modify_config() {
    local key="$1"
    local value="$2"
    local file="$3"
    
    if [ ! -f "$file" ]; then
        log_error "Configuration file not found: $file"
        return 1
    fi
    
    # Create temporary file
    local temp_file=$(mktemp)
    
    # Update or add key-value pair
    if grep -q "\"$key\":" "$file"; then
        sed "s/\"$key\":[[:space:]]*\"[^\"]*\"/\"$key\": \"$value\"/" "$file" > "$temp_file"
        log_debug "Updated existing key: $key"
    else
        sed '$ s/}/,\n    "'$key'": "'$value'"\n}/' "$file" > "$temp_file"
        log_debug "Added new key: $key"
    fi
    
    # Verify temporary file
    if [ ! -s "$temp_file" ]; then
        log_error "Failed to modify configuration"
        rm -f "$temp_file"
        return 1
    fi
    
    # Replace original file
    if cat "$temp_file" > "$file"; then
        rm -f "$temp_file"
        chown "$(get_current_user):$(id -g -n "$(get_current_user)")" "$file" 2>/dev/null || true
        chmod 644 "$file" 2>/dev/null || true
        return 0
    else
        log_error "Failed to write configuration"
        rm -f "$temp_file"
        return 1
    fi
}

# Generate new configuration
generate_new_config() {
    log_info "Generating new device identifiers..."
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$STORAGE_FILE")"
    chown "$(get_current_user):$(id -g -n "$(get_current_user)")" "$(dirname "$STORAGE_FILE")" 2>/dev/null || true
    
    if [ -f "$STORAGE_FILE" ]; then
        log_info "Found existing configuration file"
        backup_config || return 1
        
        # Generate new IDs
        local new_device_id=$(generate_uuid)
        local new_machine_id=$(generate_uuid)
        
        log_info "Updating device identifiers..."
        
        if modify_config "telemetry.deviceId" "$new_device_id" "$STORAGE_FILE" && \
           modify_config "telemetry.machineId" "$new_machine_id" "$STORAGE_FILE"; then
            log_info "Configuration updated successfully"
            return 0
        else
            log_error "Failed to update configuration"
            return 1
        fi
    else
        log_warn "Configuration file not found: $STORAGE_FILE"
        log_info "This is normal for first-time installations"
        return 0
    fi
}

# ========================================
# JAVASCRIPT MODIFICATION
# ========================================

# Find Cursor JS files
find_cursor_js_files() {
    log_info "Searching for Cursor JS files..."
    
    local resources_dir
    if ! resources_dir=$(find_cursor_resources); then
        return 1
    fi
    
    local js_patterns=(
        "resources/app/out/vs/workbench/api/node/extensionHostProcess.js"
        "resources/app/out/main.js"
        "resources/app/out/vs/code/node/cliProcessMain.js"
        "app/out/vs/workbench/api/node/extensionHostProcess.js"
        "app/out/main.js"
        "app/out/vs/code/node/cliProcessMain.js"
    )
    
    local js_files=()
    for pattern in "${js_patterns[@]}"; do
        local files=$(find "$resources_dir" -path "*/$pattern" -type f 2>/dev/null)
        if [ -n "$files" ]; then
            while IFS= read -r file; do
                js_files+=("$file")
                log_info "Found JS file: $file"
            done <<< "$files"
        fi
    done
    
    if [ ${#js_files[@]} -eq 0 ]; then
        log_error "No JS files found for modification"
        return 1
    fi
    
    printf '%s\n' "${js_files[@]}"
    return 0
}

# Modify Cursor JS files
modify_cursor_js_files() {
    log_info "Modifying Cursor JS files..."
    
    local js_files
    if ! js_files=($(find_cursor_js_files)); then
        return 1
    fi
    
    local modified_count=0
    local new_uuid=$(generate_uuid)
    local machine_id=$(generate_uuid)
    local device_id=$(generate_uuid)
    local mac_machine_id=$(generate_random_hex 64)
    
    for file in "${js_files[@]}"; do
        log_info "Processing: $(basename "$file")"
        
        if [ ! -f "$file" ]; then
            log_warn "File not found: $file"
            continue
        fi
        
        # Create backup
        local backup_file="${file}.backup_$(date +%Y%m%d_%H%M%S)"
        if ! cp "$file" "$backup_file"; then
            log_error "Failed to backup: $file"
            continue
        fi
        
        # Check if already modified
        if grep -q "Cursor ID Modifier" "$file"; then
            log_info "File already modified: $(basename "$file")"
            rm -f "$backup_file"
            ((modified_count++))
            continue
        fi
        
        # Create injection code
        local inject_code="
// Cursor ID Modifier Injection - $(date)
const originalRequire = typeof require === 'function' ? require : null;
if (originalRequire) {
  require = function(module) {
    try {
      const result = originalRequire(module);
      if (module === 'crypto' && result && result.randomUUID) {
        result.randomUUID = function() { return '$new_uuid'; };
      }
      return result;
    } catch (e) {
      return originalRequire(module);
    }
  };
}

// Override global functions
try { if (typeof global !== 'undefined' && global.getMachineId) global.getMachineId = function() { return '$machine_id'; }; } catch(e){}
try { if (typeof global !== 'undefined' && global.getDeviceId) global.getDeviceId = function() { return '$device_id'; }; } catch(e){}
try { if (typeof process !== 'undefined' && process.env) process.env.VSCODE_MACHINE_ID = '$machine_id'; } catch(e){}

console.log('Cursor ID Modifier: Patches applied');
// End Cursor ID Modifier Injection

"
        
        # Inject code at beginning of file
        local temp_file=$(mktemp)
        echo "$inject_code" > "$temp_file"
        cat "$file" >> "$temp_file"
        
        if mv "$temp_file" "$file"; then
            log_info "Successfully modified: $(basename "$file")"
            chown "$(get_current_user):$(id -g -n "$(get_current_user)")" "$file" 2>/dev/null || true
            chmod 644 "$file" 2>/dev/null || true
            rm -f "$backup_file"
            ((modified_count++))
        else
            log_error "Failed to modify: $file"
            cp "$backup_file" "$file" 2>/dev/null || true
            rm -f "$temp_file" "$backup_file"
        fi
    done
    
    if [ "$modified_count" -gt 0 ]; then
        log_info "Successfully modified $modified_count JS files"
        return 0
    else
        log_error "Failed to modify any JS files"
        return 1
    fi
}

# ========================================
# MAIN EXECUTION
# ========================================

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [ "$EUID" -ne 0 ]; then
        log_error "This script requires sudo privileges"
        echo "Usage: sudo $0"
        exit 1
    fi
    
    if ! find_cursor_installation >/dev/null; then
        log_error "Cursor installation not found"
        log_info "Please install Cursor first: https://cursor.sh/"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
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
    echo "  🐧 $SCRIPT_NAME"
    echo "========================================="
    echo
    
    init_log
    check_prerequisites
    
    log_info "🚀 Starting Cursor ID modification process..."
    
    # Stop Cursor processes
    if ! stop_cursor_processes; then
        log_error "Failed to stop Cursor processes"
        exit 1
    fi
    
    # Generate new configuration
    if ! generate_new_config; then
        log_error "Failed to generate new configuration"
        exit 1
    fi
    
    # Modify JS files
    if ! modify_cursor_js_files; then
        log_error "Failed to modify JS files"
        exit 1
    fi
    
    echo
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                              ║"
    echo "║    🎉 SUCCESS! CURSOR ID MODIFICATION COMPLETED! 🎉                         ║"
    echo "║                                                                              ║"
    echo "║    ✅ Device identifiers have been reset                                    ║"
    echo "║    ✅ JavaScript patches applied                                            ║"
    echo "║    ✅ Configuration files updated                                           ║"
    echo "║                                                                              ║"
    echo "║    🚀 You can now restart Cursor to use the reset trial!                   ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo
    log_info "📄 Log file saved to: $LOG_FILE"
    echo
}

# Execute main function
main "$@"