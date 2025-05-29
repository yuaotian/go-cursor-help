# -*- coding: utf-8 -*-
"""
AppImage instructions:
mkdir -p ~/Downloads/Cursor
cd ~/Downloads/Cursor
cd Cursor && ./Cursor-0.50.5-x86_64.AppImage --appimage-extract
mkdir -p ~/.local
rsync -rt ~/Downloads/Cursor/squashfs-root/usr/ ~/.local
# ^ copy the subfolders not usr itself, so the resulting executable should be ~/.local/bin/cursor
"""
import subprocess
import os

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
# repo_dir = os.path.dirname(SCRIPTS_DIR)
repo_dir = SCRIPTS_DIR
locales_dir = os.path.join(repo_dir, 'locales')
t_domain = "cursor_id_modifier"

def compile_messages():
    global _
    languages = ['en_US', 'zh_CN']
    for lang in languages:
        lang_dir = os.path.join(locales_dir, lang, 'LC_MESSAGES')
        if os.path.isdir(lang_dir):
            # Change the directory to the LC_MESSAGES folder
            os.chdir(lang_dir)
            # Run msgfmt command
            out_name = 'cursor_id_modifier.mo'
            subprocess.run(['msgfmt', '-o', out_name, 'cursor_id_modifier.po'], check=True)
            print(os.path.abspath(out_name))
        else:
            print(f"Directory not found: {lang_dir}")

import sys
import subprocess
import datetime
import tempfile
import shutil
import uuid
import hashlib
import re
import getpass
import time
import select
import tty
import termios
import signal
import json
from pathlib import Path
import glob
import pwd

import gettext

# 设置语言环境
# Set language environment

# lang = 'zh' if '--en' not in sys.argv else 'en'
lang = 'en'

assert os.path.isdir(locales_dir)
# gettext.bindtextdomain(t_domain, localedir=locales_dir)
if lang == 'zh':
    translation = gettext.translation(
        t_domain,
        localedir=locales_dir,
        languages=['en_US', 'zh_CN'],
    )
else:
    translation = gettext.NullTranslations()
translation.install()
_ = translation.gettext

# 设置错误处理
# Set error handling
def set_error_handling():
    global _
    # 在 Python 中，我们使用 try/except 来处理错误，而不是 bash 的 set -e
    # In Python, we use try/except to handle errors instead of bash's set -e
    pass

set_error_handling()

# 定义日志文件路径
# Define log file path
LOG_FILE = "/tmp/cursor_linux_id_modifier.log"

# 初始化日志文件
# Initialize log file
def initialize_log():
    with open(LOG_FILE, 'w') as f:
        f.write(_("========== Cursor ID modification tool log start {} ==========").format(datetime.datetime.now()) + "\n")
    os.chmod(LOG_FILE, 0o644)

# 颜色定义
# Color definitions
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color

# 日志函数 - 同时输出到终端和日志文件
# Log functions - output to terminal and log file simultaneously
def log_info(message):
    global _
    print(f"{GREEN}[INFO]{NC} {_(message)}")
    with open(LOG_FILE, 'a') as f:
        f.write(_("[INFO] {} {}").format(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), _(message)) + "\n")

def log_warn(message):
    global _
    print(f"{YELLOW}[WARN]{NC} {_(message)}")
    with open(LOG_FILE, 'a') as f:
        f.write(_("[WARN] {} {}").format(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), _(message)) + "\n")

def log_error(message):
    global _
    print(f"{RED}[ERROR]{NC} {_(message)}")
    with open(LOG_FILE, 'a') as f:
        f.write(_("[ERROR] {} {}").format(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), _(message)) + "\n")

def log_debug(message):
    global _
    print(f"{BLUE}[DEBUG]{NC} {_(message)}")
    with open(LOG_FILE, 'a') as f:
        f.write(_("[DEBUG] {} {}").format(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), _(message)) + "\n")

# 记录命令输出到日志文件
# Log command output to log file
def log_cmd_output(cmd, msg):
    global _
    with open(LOG_FILE, 'a') as f:
        f.write(_("[CMD] {} Executing command: {}").format(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), cmd) + "\n")
        f.write(_("[CMD] {}:").format(_(msg)) + "\n")
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    with open(LOG_FILE, 'a') as f:
        for line in process.stdout:
            print(line, end='')
            f.write(line)
    process.wait()
    with open(LOG_FILE, 'a') as f:
        f.write("\n")

# 获取当前用户
# Get current user
def get_current_user():
    global _
    if os.geteuid() == 0:
        return os.environ.get('SUDO_USER', '')
    return getpass.getuser()

CURRENT_USER = get_current_user()
if not CURRENT_USER:
    log_error(_("Unable to get username"))
    sys.exit(1)

# 定义Linux下的Cursor路径
# Define Cursor paths on Linux
CURSOR_CONFIG_DIR = os.path.expanduser("~/.config/Cursor")
STORAGE_FILE = os.path.join(CURSOR_CONFIG_DIR, "User/globalStorage/storage.json")
BACKUP_DIR = os.path.join(CURSOR_CONFIG_DIR, "User/globalStorage/backups")

# 可能的Cursor二进制路径
# Possible Cursor binary paths
CURSOR_BIN_PATHS = [
    "/usr/bin/cursor",
    "/usr/local/bin/cursor",
    os.path.expanduser("~/.local/bin/cursor"),
    "/opt/cursor/cursor",
    "/snap/bin/cursor",
]

# 找到Cursor安装路径
# Find Cursor installation path
def find_cursor_path():
    global _
    log_info(_("Finding Cursor installation path..."))

    for path in CURSOR_BIN_PATHS:
        if os.path.isfile(path):
            log_info(_("Found Cursor installation path: {}").format(path))
            os.environ['CURSOR_PATH'] = path
            return True

    # 尝试通过which命令定位
    # Try locating via which command
    try:
        result = subprocess.run(['which', 'cursor'], capture_output=True, text=True)
        if result.returncode == 0:
            os.environ['CURSOR_PATH'] = result.stdout.strip()
            log_info(_("Found Cursor via which: {}").format(os.environ['CURSOR_PATH']))
            return True
    except subprocess.CalledProcessError:
        pass

    # 尝试查找可能的安装路径
    # Try finding possible installation paths
    search_dirs = ['/usr', '/opt', os.path.expanduser('~/.local')]
    for dir in search_dirs:
        try:
            for root, _1, files in os.walk(dir):
                if 'cursor' in files:
                    path = os.path.join(root, 'cursor')
                    if os.access(path, os.X_OK):
                        os.environ['CURSOR_PATH'] = path
                        log_info(_("Found Cursor via search: {}").format(os.environ['CURSOR_PATH']))
                        return True
        except PermissionError:
            continue
    log_warn(_("Cursor executable not found, will try using config directory"))
    return False

# 查找并定位Cursor资源文件目录
# Find and locate Cursor resource directory
def find_cursor_resources():
    global _
    log_info(_("Finding Cursor resource directory..."))

    # 可能的资源目录路径
    # Possible resource directory paths
    resource_paths = [
        "/usr/lib/cursor",
        "/usr/share/cursor",
        "/opt/cursor",
        os.path.expanduser("~/.local/share/cursor"),
    ]

    for path in resource_paths:
        if os.path.isdir(path):
            log_info(_("Found Cursor resource directory: {}").format(path))
            os.environ['CURSOR_RESOURCES'] = path
            return True

    # 如果有CURSOR_PATH，尝试从它推断
    # If CURSOR_PATH exists, try to infer from it
    if os.environ.get('CURSOR_PATH'):
        base_dir = os.path.dirname(os.environ['CURSOR_PATH'])
        resource_dir = os.path.join(base_dir, 'resources')
        if os.path.isdir(resource_dir):
            os.environ['CURSOR_RESOURCES'] = resource_dir
            log_info(_("Found resource directory via binary path: {}").format(os.environ['CURSOR_RESOURCES']))
            return True

    log_warn(_("Cursor resource directory not found"))
    return False

# 检查权限
# Check permissions
def check_permissions():
    global _
    if os.geteuid() != 0:
        log_error(_("Please run this script with sudo"))
        print(_("Example: sudo {}").format(sys.argv[0]))
        sys.exit(1)

# 检查并关闭 Cursor 进程
# Check and kill Cursor processes
def check_and_kill_cursor():
    global _
    log_info(_("Checking Cursor processes..."))

    attempt = 1
    max_attempts = 5

    # 函数：获取进程详细信息
    # Function: Get process details
    def get_process_details(process_name):
        log_debug(_("Getting process details for {}:").format(process_name))
        try:
            result = subprocess.run(
                'ps aux | grep -i "cursor" | grep -v grep | grep -v "cursor_id_modifier.py"',
                shell=True, capture_output=True, text=True
            )
            print(result.stdout)
        except subprocess.CalledProcessError:
            pass

    while attempt <= max_attempts:
        # 使用更精确的匹配来获取 Cursor 进程，排除当前脚本和grep进程
        # Use more precise matching to get Cursor processes, excluding current script and grep
        try:
            result = subprocess.run(
                'ps aux | grep -i "cursor" | grep -v "grep" | grep -v "cursor_id_modifier.py" | awk \'{print $2}\'',
                shell=True, capture_output=True, text=True
            )
            CURSOR_PIDS = result.stdout.strip().split('\n')
            CURSOR_PIDS = [pid for pid in CURSOR_PIDS if pid]
        except subprocess.CalledProcessError:
            CURSOR_PIDS = []

        if not CURSOR_PIDS:
            log_info(_("No running Cursor processes found"))
            return True

        log_warn(_("Found running Cursor processes"))
        get_process_details("cursor")

        log_warn(_("Attempting to terminate Cursor processes..."))

        for pid in CURSOR_PIDS:
            try:
                if attempt == max_attempts:
                    log_warn(_("Attempting to forcefully terminate processes..."))
                    os.kill(int(pid), signal.SIGKILL)
                else:
                    os.kill(int(pid), signal.SIGTERM)
            except (OSError, ValueError):
                continue

        time.sleep(1)

        # 再次检查进程是否还在运行
        # Check again if processes are still running
        try:
            result = subprocess.run(
                'ps aux | grep -i "cursor" | grep -v "grep" | grep -v "cursor_id_modifier.py"',
                shell=True, capture_output=True, text=True
            )
            if not result.stdout.strip():
                log_info(_("Cursor processes successfully terminated"))
                return True
        except subprocess.CalledProcessError:
            log_info(_("Cursor processes successfully terminated"))
            return True

        log_warn(_("Waiting for processes to terminate, attempt {}/{}...").format(attempt, max_attempts))
        attempt += 1

    log_error(_("Unable to terminate Cursor processes after {} attempts").format(max_attempts))
    get_process_details("cursor")
    log_error(_("Please manually terminate the processes and try again"))
    sys.exit(1)

# 备份配置文件
# Backup configuration file
def backup_config():
    global _
    if not os.path.isfile(STORAGE_FILE):
        log_warn(_("Configuration file does not exist, skipping backup"))
        return True

    os.makedirs(BACKUP_DIR, exist_ok=True)
    backup_file = os.path.join(BACKUP_DIR, "storage.json.backup_{}".format(datetime.datetime.now().strftime('%Y%m%d_%H%M%S')))

    try:
        shutil.copy(STORAGE_FILE, backup_file)
        os.chmod(backup_file, 0o644)
        os.chown(backup_file, pwd.getpwnam(CURRENT_USER).pw_uid, -1)
        log_info(_("Configuration backed up to: {}").format(backup_file))
    except (OSError, shutil.Error):
        log_error(_("Backup failed"))
        sys.exit(1)

# 生成随机 ID
# Generate random ID
def generate_random_id():
    global _
    # 生成32字节(64个十六进制字符)的随机数
    # Generate 32 bytes (64 hexadecimal characters) of random data
    return hashlib.sha256(os.urandom(32)).hexdigest()

# 生成随机 UUID
# Generate random UUID
def generate_uuid():
    global _
    # 在Linux上使用uuid模块生成UUID
    # Use uuid module to generate UUID on Linux
    try:
        return str(uuid.uuid1()).lower()
    except Exception:
        # 备选方案：生成类似UUID的字符串
        # Fallback: Generate UUID-like string
        rand_bytes = os.urandom(16)
        rand_hex = rand_bytes.hex()
        return f"{rand_hex[:8]}-{rand_hex[8:12]}-{rand_hex[12:16]}-{rand_hex[16:20]}-{rand_hex[20:]}"

# 修改现有文件
# Modify or add to configuration file
def modify_or_add_config(key, value, file):
    global _
    if not os.path.isfile(file):
        log_error(_("File does not exist: {}").format(file))
        return False

    # 确保文件可写
    # Ensure file is writable
    try:
        os.chmod(file, 0o644)
    except OSError:
        log_error(_("Unable to modify file permissions: {}").format(file))
        return False

    # 创建临时文件
    # Create temporary file
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
        temp_path = temp_file.name

    # 读取原始文件
    # Read original file
    with open(file, 'r') as f:
        content = f.read()

    # 检查key是否存在
    # Check if key exists
    if f'"{key}":' in content:
        # key存在，执行替换
        # Key exists, perform replacement
        pattern = f'"{key}":\\s*"[^"]*"'
        replacement = f'"{key}": "{value}"'
        new_content = re.sub(pattern, replacement, content)
    else:
        # key不存在，添加新的key-value对
        # Key does not exist, add new key-value pair
        new_content = content.rstrip('}\n') + f',\n    "{key}": "{value}"\n}}'

    # 写入临时文件
    # Write to temporary file
    with open(temp_path, 'w') as f:
        f.write(new_content)

    # 检查临时文件是否为空
    # Check if temporary file is empty
    if os.path.getsize(temp_path) == 0:
        log_error(_("Generated temporary file is empty"))
        os.unlink(temp_path)
        return False

    # 替换原文件
    # Replace original file
    try:
        shutil.move(temp_path, file)
    except OSError:
        log_error(_("Unable to write to file: {}").format(file))
        os.unlink(temp_path)
        return False

    # 恢复文件权限
    # Restore file permissions
    os.chmod(file, 0o444)
    return True

# 生成新的配置
# Generate new configuration
def generate_new_config():
    global _
    print()
    log_warn(_("Machine code reset options"))

    # 使用菜单选择函数询问用户是否重置机器码
    # Use menu selection function to ask user whether to reset machine code
    reset_choice = select_menu_option(
        _("Do you need to reset the machine code? (Usually, modifying JS files is sufficient):"),
        [_("Don't reset - only modify JS files"), _("Reset - modify both config file and machine code")],
        0
    )

    # 记录日志以便调试
    # Log for debugging
    with open(LOG_FILE, 'a') as f:
        f.write(_("[INPUT_DEBUG] Machine code reset option selected: {}").format(reset_choice) + "\n")

    # 处理用户选择
    # Handle user selection
    if reset_choice == 1:
        log_info(_("You chose to reset the machine code"))

        # 确保配置文件目录存在
        # Ensure configuration file directory exists
        if os.path.isfile(STORAGE_FILE):
            log_info(_("Found existing configuration file: {}").format(STORAGE_FILE))

            # 备份现有配置
            # Backup existing configuration
            backup_config()

            # 生成并设置新的设备ID
            # Generate and set new device ID
            new_device_id = generate_uuid()
            new_machine_id = "auth0|user_{}".format(hashlib.sha256(os.urandom(16)).hexdigest()[:32])

            log_info(_("Setting new device and machine IDs..."))
            log_debug(_("New device ID: {}").format(new_device_id))
            log_debug(_("New machine ID: {}").format(new_machine_id))

            # 修改配置文件
            # Modify configuration file
            if (modify_or_add_config("deviceId", new_device_id, STORAGE_FILE) and
                modify_or_add_config("machineId", new_machine_id, STORAGE_FILE)):
                log_info(_("Configuration file modified successfully"))
            else:
                log_error(_("Configuration file modification failed"))
        else:
            log_warn(_("Configuration file not found, this is normal, skipping ID modification"))
    else:
        log_info(_("You chose not to reset the machine code, will only modify JS files"))

        # 确保配置文件目录存在
        # Ensure configuration file directory exists
        if os.path.isfile(STORAGE_FILE):
            log_info(_("Found existing configuration file: {}").format(STORAGE_FILE))

            # 备份现有配置
            # Backup existing configuration
            backup_config()
        else:
            log_warn(_("Configuration file not found, this is normal, skipping ID modification"))

    print()
    log_info(_("Configuration processing completed"))

# 查找Cursor的JS文件
# Find Cursor's JS files
def find_cursor_js_files():
    global _
    log_info(_("Finding Cursor's JS files..."))

    js_files = []
    found = False

    # 如果找到了资源目录，在资源目录中搜索
    # If resource directory is found, search in it
    if os.environ.get('CURSOR_RESOURCES'):
        log_debug(_("Searching for JS files in resource directory: {}").format(os.environ['CURSOR_RESOURCES']))

        # 在资源目录中递归搜索特定JS文件
        # Recursively search for specific JS files in resource directory
        js_patterns = [
            "*/extensionHostProcess.js",
            "*/main.js",
            "*/cliProcessMain.js",
            "*/app/out/vs/workbench/api/node/extensionHostProcess.js",
            "*/app/out/main.js",
            "*/app/out/vs/code/node/cliProcessMain.js",
        ]

        for pattern in js_patterns:
            try:
                files = glob.glob(os.path.join(os.environ['CURSOR_RESOURCES'], pattern), recursive=True)
                for file in files:
                    log_info(_("Found JS file: {}").format(file))
                    js_files.append(file)
                    found = True
            except Exception:
                continue

    # 如果还没找到，尝试在/usr和$HOME目录下搜索
    # If not found, try searching in /usr and $HOME directories
    if not found:
        log_warn(_("No JS files found in resource directory, trying other directories..."))

        search_dirs = [
            "/usr/lib/cursor",
            "/usr/share/cursor",
            "/opt/cursor",
            os.path.expanduser("~/.config/Cursor"),
            os.path.expanduser("~/.local/share/cursor"),
        ]

        for dir in search_dirs:
            if os.path.isdir(dir):
                log_debug(_("Searching directory: {}").format(dir))
                try:
                    for root, _1, files in os.walk(dir):
                        for file in files:
                            if file.endswith('.js'):
                                file_path = os.path.join(root, file)
                                with open(file_path, 'r', errors='ignore') as f:
                                    content = f.read()
                                    if "IOPlatformUUID" in content or "x-cursor-checksum" in content:
                                        log_info(_("Found JS file: {}").format(file_path))
                                        js_files.append(file_path)
                                        found = True
                except Exception:
                    continue

    if not found:
        log_error(_("No modifiable JS files found"))
        return False, []

    # 保存找到的文件列表到环境变量
    # Save found files to environment variable
    os.environ['CURSOR_JS_FILES'] = json.dumps(js_files)
    log_info(_("Found {} JS files to modify").format(len(js_files)))
    return True, js_files

# 修改Cursor的JS文件
# Modify Cursor's JS files
def modify_cursor_js_files():
    global _
    log_info(_("Starting to modify Cursor's JS files..."))

    # 先查找需要修改的JS文件
    # First find JS files to modify
    success, js_files = find_cursor_js_files()
    if not success:
        log_error(_("Unable to find modifiable JS files"))
        return False

    modified_count = 0

    for file in js_files:
        log_info(_("Processing file: {}").format(file))

        # 创建文件备份
        # Create file backup
        backup_file = f"{file}.backup_{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
        try:
            shutil.copy(file, backup_file)
        except OSError:
            log_error(_("Unable to create backup for file: {}").format(file))
            continue

        # 确保文件可写
        # Ensure file is writable
        try:
            os.chmod(file, 0o644)
        except OSError:
            log_error(_("Unable to modify file permissions: {}").format(file))
            continue

        # 读取文件内容
        # Read file content
        with open(file, 'r', errors='ignore') as f:
            content = f.read()

        # 检查文件内容并进行相应修改
        # Check file content and make appropriate modifications
        if 'i.header.set("x-cursor-checksum' in content:
            log_debug(_("Found x-cursor-checksum setting code"))
            new_content = content.replace(
                'i.header.set("x-cursor-checksum",e===void 0?`${p}${t}`:`${p}${t}/${e}`)',
                'i.header.set("x-cursor-checksum",e===void 0?`${p}${t}`:`${p}${t}/${p}`)'
            )
            if new_content != content:
                with open(file, 'w') as f:
                    f.write(new_content)
                log_info(_("Successfully modified x-cursor-checksum setting code"))
                modified_count += 1
            else:
                log_error(_("Failed to modify x-cursor-checksum setting code"))
                shutil.copy(backup_file, file)
        elif "IOPlatformUUID" in content:
            log_debug(_("Found IOPlatformUUID keyword"))
            if "function a$" in content and "return crypto.randomUUID()" not in content:
                new_content = content.replace(
                    "function a$(t){switch",
                    "function a$(t){return crypto.randomUUID(); switch"
                )
                if new_content != content:
                    with open(file, 'w') as f:
                        f.write(new_content)
                    log_debug(_("Successfully injected randomUUID call into a$ function"))
                    modified_count += 1
                else:
                    log_error(_("Failed to modify a$ function"))
                    shutil.copy(backup_file, file)
            elif "async function v5" in content and "return crypto.randomUUID()" not in content:
                new_content = content.replace(
                    "async function v5(t){let e=",
                    "async function v5(t){return crypto.randomUUID(); let e="
                )
                if new_content != content:
                    with open(file, 'w') as f:
                        f.write(new_content)
                    log_debug(_("Successfully injected randomUUID call into v5 function"))
                    modified_count += 1
                else:
                    log_error(_("Failed to modify v5 function"))
                    shutil.copy(backup_file, file)
            else:
                # 通用注入方法
                # Universal injection method
                if "// Cursor ID 修改工具注入" not in content:
                    timestamp = datetime.datetime.now().strftime('%s')
                    datetime_s = datetime.datetime.now().strftime('%Y%m%d%H%M%S')
                    inject_code = f"""
// Cursor ID 修改工具注入 - {datetime_s}
// 随机设备ID生成器注入 - {timestamp}
const randomDeviceId_{timestamp} = () => {{
    try {{
        return require('crypto').randomUUID();
    }} catch (e) {{
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {{
            const r = Math.random() * 16 | 0;
            return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
        }});
    }}
}};
"""
                    # NOTE: double {{ or }} is literal, so code matches:
                    old_bash_inject_code = """
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
"""
                    new_content = inject_code + content
                    new_content = new_content.replace(f"await v5(!1)", f"randomDeviceId_{timestamp}()")
                    new_content = new_content.replace(f"a$(t)", f"randomDeviceId_{timestamp}()")
                    with open(file, 'w') as f:
                        f.write(new_content)
                    log_debug(_("Completed universal modification"))
                    modified_count += 1
                else:
                    log_info(_("File already contains custom injection code, skipping modification"))
        else:
            # 未找到关键字，尝试通用方法
            # No keywords found, try universal method
            if "return crypto.randomUUID()" not in content and "// Cursor ID 修改工具注入" not in content:
                if "function t$()" in content or "async function y5" in content:
                    new_content = content
                    if "function t$()" in new_content:
                        new_content = new_content.replace(
                            "function t$(){",
                            'function t$(){return "00:00:00:00:00:00";'
                        )
                    if "async function y5" in new_content:
                        new_content = new_content.replace(
                            "async function y5(t){",
                            "async function y5(t){return crypto.randomUUID();"
                        )
                    if new_content != content:
                        with open(file, 'w') as f:
                            f.write(new_content)
                        modified_count += 1
                else:
                    # 最通用的注入方法
                    # Most universal injection method
                    new_uuid = generate_uuid()
                    machine_id = f"auth0|user_{hashlib.sha256(os.urandom(16)).hexdigest()[:32]}"
                    device_id = generate_uuid()
                    mac_machine_id = hashlib.sha256(os.urandom(32)).hexdigest()
                    timestamp = datetime.datetime.now().strftime('%s')
                    datetime_s = datetime.datetime.now().strftime('%Y%m%d%H%M%S')
                    inject_universal_code = f"""
// Cursor ID 修改工具注入 - {datetime_s}
// 全局拦截设备标识符 - {timestamp}
const originalRequire_{timestamp} = require;
require = function(module) {{
    const result = originalRequire_{timestamp}(module);
    if (module === 'crypto' && result.randomUUID) {{
        const originalRandomUUID_{timestamp} = result.randomUUID;
        result.randomUUID = function() {{
            return '{new_uuid}';
        }};
    }}
    return result;
}};

// 覆盖所有可能的系统ID获取函数
global.getMachineId = function() {{ return '{machine_id}'; }};
global.getDeviceId = function() {{ return '{device_id}'; }};
global.macMachineId = '{mac_machine_id}';
"""
                    # NOTE: Double {{ or }} is literal, so matches:
                    old_bash_inject_code = """
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
"""
                    new_content = inject_universal_code + content
                    with open(file, 'w') as f:
                        f.write(new_content)
                    log_debug(_("Completed most universal injection"))
                    modified_count += 1
            else:
                log_info(_("File has already been modified, skipping modification"))

        # 恢复文件权限
        # Restore file permissions
        os.chmod(file, 0o444)

    if modified_count == 0:
        log_error(_("Failed to modify any JS files"))
        return False

    log_info(_("Successfully modified {} JS files").format(modified_count))
    return True

# 禁用自动更新
# Disable auto-update
def disable_auto_update():
    global _
    log_info(_("Disabling Cursor auto-update..."))

    # 查找可能的更新配置文件
    # Find possible update configuration files
    update_configs = [
        os.path.join(CURSOR_CONFIG_DIR, "update-config.json"),
        os.path.expanduser("~/.local/share/cursor/update-config.json"),
        "/opt/cursor/resources/app-update.yml",
    ]

    disabled = False

    for config in update_configs:
        if os.path.isfile(config):
            log_info(_("Found update configuration file: {}").format(config))
            try:
                shutil.copy(config, f"{config}.bak")
                with open(config, 'w') as f:
                    json.dump({"autoCheck": False, "autoDownload": False}, f)
                os.chmod(config, 0o444)
                log_info(_("Disabled update configuration file: {}").format(config))
                disabled = True
            except (OSError, shutil.Error):
                continue

    # 尝试查找updater可执行文件并禁用
    # Try to find and disable updater executable
    updater_paths = [
        os.path.join(CURSOR_CONFIG_DIR, "updater"),
        "/opt/cursor/updater",
        "/usr/lib/cursor/updater",
    ]

    for updater in updater_paths:
        if os.path.exists(updater):
            log_info(_("Found updater: {}").format(updater))
            try:
                if os.path.isfile(updater):
                    shutil.move(updater, f"{updater}.bak")
                else:
                    Path(f"{updater}.disabled").touch()
                log_info(_("Disabled updater: {}").format(updater))
                disabled = True
            except (OSError, shutil.Error):
                continue

    if not disabled:
        log_warn(_("No update configuration files or updaters found"))
    else:
        log_info(_("Successfully disabled auto-update"))

# 新增：通用菜单选择函数
# New: Universal menu selection function
def select_menu_option(prompt, options, default_index=0):
    global _
    # 保存终端设置
    # Save terminal settings
    old_settings = termios.tcgetattr(sys.stdin)
    selected_index = default_index

    try:
        # 设置终端为非缓冲模式
        # Set terminal to non-buffered mode
        tty.setcbreak(sys.stdin.fileno())

        # 显示提示信息
        # Display prompt
        print(_(prompt))

        # 第一次显示菜单
        # Display menu initially
        for i, option in enumerate(options):
            if i == selected_index:
                print(f" {GREEN}►{NC} {_(option)}")
            else:
                print(f"   {_(option)}")

        while True:
            # 读取键盘输入
            # Read keyboard input
            rlist, _1, _2 = select.select([sys.stdin], [], [], 0.1)
            if rlist:
                key = sys.stdin.read(1)
                # 上箭头键
                # Up arrow key
                if key == '\033':
                    next_char = sys.stdin.read(2)
                    if next_char == '[A' and selected_index > 0:
                        selected_index -= 1
                    # 下箭头键
                    # Down arrow key
                    elif next_char == '[B' and selected_index < len(options) - 1:
                        selected_index += 1
                # Enter键
                # Enter key
                elif key == '\n':
                    print()
                    log_info(_("You selected: {}").format(options[selected_index]))
                    return selected_index

                # 清除当前菜单
                # Clear current menu
                sys.stdout.write('\033[{}A\033[J'.format(len(options) + 1))
                sys.stdout.flush()

                # 重新显示提示和菜单
                # Redisplay prompt and menu
                print(_(prompt))
                for i, option in enumerate(options):
                    if i == selected_index:
                        print(f" {GREEN}►{NC} {_(option)}")
                    else:
                        print(f"   {_(option)}")
                sys.stdout.flush()

    finally:
        # 恢复终端设置
        # Restore terminal settings
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)

# 主函数
# Main function
def main():
    global _
    # 检查系统环境
    # Check system environment
    if sys.platform != "linux":
        log_error(_("This script only supports Linux systems"))
        sys.exit(1)

    # 初始化日志文件
    # Initialize log file
    initialize_log()
    log_info(_("Script started..."))

    # 记录系统信息
    # Log system information
    log_info(_("System information: {}").format(subprocess.getoutput("uname -a")))
    log_info(_("Current user: {}").format(CURRENT_USER))
    log_cmd_output(
        "lsb_release -a 2>/dev/null || cat /etc/*release 2>/dev/null || cat /etc/issue",
        _("System version information")
    )

    # 清除终端
    # Clear terminal
    os.system('clear')

    # 显示 Logo
    # Display Logo
    print("""
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
    """)
    print(f"{BLUE}================================{NC}")
    print(f"{GREEN}   {_('Cursor Linux startup tool')}     {NC}")
    print(f"{BLUE}================================{NC}")
    print()
    print(f"{YELLOW}[{_('Important notice')}] {NC} {_('This tool prioritizes modifying JS files, which is safer and more reliable')}")
    print()

    # 执行主要功能
    # Execute main functions
    check_permissions()
    find_cursor_path()
    find_cursor_resources()
    check_and_kill_cursor()
    backup_config()
    generate_new_config()

    # 修改JS文件
    # Modify JS files
    log_info(_("Modifying Cursor JS files..."))
    if modify_cursor_js_files():
        log_info(_("JS files modified successfully!"))
    else:
        log_warn(_("JS file modification failed, but configuration file modification may have succeeded"))
        log_warn(_("If Cursor still indicates the device is disabled after restarting, please rerun this script"))

    # 禁用自动更新
    # Disable auto-update
    disable_auto_update()

    log_info(_("Please restart Cursor to apply the new configuration"))

    # 显示最后的提示信息
    # Display final prompt
    print()
    print(f"{GREEN}================================{NC}")
    print(f"{YELLOW} {_('Follow the WeChat public account [Pancake AI] to discuss more Cursor tips and AI knowledge (script is free, join the group via the public account for more tips and experts)')} {NC}")
    print("WeChat account: [煎饼果子卷AI]")
    print(f"{GREEN}================================{NC}")
    print()

    # 记录脚本完成信息
    # Log script completion information
    log_info(_("Script execution completed"))
    with open(LOG_FILE, 'a') as f:
        f.write(_("========== Cursor ID modification tool log end {} ==========").format(datetime.datetime.now()) + "\n")

    # 显示日志文件位置
    # Display log file location
    print()
    log_info(_("Detailed log saved to: {}").format(LOG_FILE))
    print(_("If you encounter issues, please provide this log file to the developer for troubleshooting"))
    print()

if __name__ == "__main__":
    main()