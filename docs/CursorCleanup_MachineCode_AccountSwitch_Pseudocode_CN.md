# Cursor 清理环境、修改机器码、换号 全面指南（含伪代码）

本指南对项目中涉及 Cursor 的“清理环境”“修改机器码”“换号”等能力进行系统化总结，基于本仓库已有的 Go CLI 与跨平台脚本（Windows PowerShell、macOS/Linux Bash）的实现思路，整理为可复用的伪代码与操作流程，便于嵌入到任何自动化工具或二次开发中。

适用范围：
- 系统：Windows / macOS / Linux（x64/ARM）
- Cursor 版本：1.0.x 系列（以及多数相近结构版本）
- 能力：
  - 自动关闭 Cursor 进程
  - 清理缓存与配置目录（可选分级：轻度清理/重置试用/彻底清理）
  - 修改/刷新“机器码”（storage.json 内的 telemetry.* 字段）
  - Windows 额外支持 MachineGuid 注册表备份与修改（脚本实现）
  - 可选：通过内核 JS 注入方式劫持设备指纹读取路径
  - 账号切换（换号）流程与注意事项

----------------------------------------

## 一、关键路径与文件

- 配置文件（storage.json）：
  - Windows: %APPDATA%\Cursor\User\globalStorage\storage.json
  - macOS: ~/Library/Application Support/Cursor/User/globalStorage/storage.json
  - Linux: ~/.config/Cursor/User/globalStorage/storage.json

- 可能的本地目录（清理对象）：
  - Windows: 
    - %APPDATA%\Cursor
    - %USERPROFILE%\.cursor
    - %LOCALAPPDATA%\cursor-updater（可删除并创建同名空文件阻止更新）
  - macOS:
    - ~/Library/Application Support/Cursor
    - ~/.cursor
    - 可选：~/Library/Caches/Cursor（若存在）
  - Linux:
    - ~/.config/Cursor
    - ~/.cursor

- 可选的应用资源（用于 JS 注入劫持，版本差异较大）：
  - Windows: %LOCALAPPDATA%\Programs\Cursor\resources\app\out\...
  - macOS: /Applications/Cursor.app/Contents/Resources/app/out/...
  - Linux: 通常在安装目录下的 resources/app/out/...

- storage.json 需关注的字段：
  - telemetry.machineId
  - telemetry.macMachineId
  - telemetry.devDeviceId
  - telemetry.sqmId

----------------------------------------

## 二、跨平台统一主流程伪代码

```pseudocode
function main(mode):
  ensure_admin_or_sudo()
  ui.clear_screen_and_logo()
  kill_cursor_processes()          # 多次重试 + 温和关闭 -> 强杀

  if mode.includes("CLEAN"):
    cleanup_environment(level=mode.cleanup_level)
    repair_permissions_if_needed() # macOS 常见

  config_path = resolve_storage_json_path()
  old_config = try_read_json(config_path) or {}

  new_ids = {
    machineId:     gen_machine_id(),      # "auth0|user_" + 64 hex
    macMachineId:  gen_hex(64),
    devDeviceId:   gen_uuid(),
    sqmId:         old_config.get('telemetry.sqmId') or gen_uuid_braced()
  }

  backup_file = backup(config_path)       # 写前备份
  merged = merge(old_config, new_ids, lastModified=now_rfc3339())
  atomic_write(config_path, json_indent(merged))

  if mode.readonly:
    chmod_readonly(config_path)

  show_success_and_restart_tips()
```

说明：
- gen_machine_id/devDeviceId 等可直接参考 pkg/idgen 的实现逻辑（本仓库已提供）。
- atomic_write：先写 .tmp，再 chmod，最后 rename 保证落盘原子性（internal/config 中已有实现）。
- Windows 可选：在清理/重置环节增加注册表 MachineGuid 备份与替换（仅脚本实现，不在 Go 中直接做）。

----------------------------------------

## 三、环境清理（分级可选）

根据目标不同，可以设计三种强度：
- 轻度：仅关闭 Cursor + 刷新 storage.json 的 telemetry.* 字段
- 中度：附加删除试用状态关联目录（“防掉试用Pro”目录清理）
- 重度：全面清理 Cursor 相关用户目录与缓存，必要时恢复权限并重新冷启动一次以再生成配置

### 3.1 Windows 清理伪代码
```pseudocode
function cleanup_windows(level):
  dirs = [
    "%APPDATA%/Cursor",
    "%USERPROFILE%/.cursor"
  ]
  if level == "HEAVY":
    dirs += [
      "%LOCALAPPDATA%/cursor-updater"  # 删除后可创建同名空文件阻止自动更新
    ]

  for d in dirs:
    if exists(d): rm -rf d

  if level == "HEAVY":
    # 可选：阻止自动更新
    ensure_file("%LOCALAPPDATA%/cursor-updater")

  # 可选：刷新 DNS（网络相关问题）
  run("ipconfig /flushdns")
```

### 3.2 macOS 清理与权限修复伪代码
```pseudocode
function cleanup_macos(level):
  dirs = [
    "~/Library/Application Support/Cursor",
    "~/.cursor"
  ]
  if level == "HEAVY":
    dirs += ["~/Library/Caches/Cursor"]

  for d in dirs:
    if exists(d): rm -rf d

  # 常见：权限修复（避免 EACCES 等问题）
  sudo_chown_recursive("~/Library/Application Support/Cursor", whoami)
  sudo_chown_recursive("~/.cursor", whoami)
  chmod_u_plus_w_recursive("~/Library/Application Support/Cursor")
  chmod_u_plus_w_recursive("~/.cursor/extensions")

  # 可选：重启 Cursor 一次并等待 15–30s 让 storage.json 生成，再立刻关闭
  # restart_cursor_and_wait_generate_config()
```

### 3.3 Linux 清理伪代码
```pseudocode
function cleanup_linux(level):
  dirs = [
    "~/.config/Cursor",
    "~/.cursor"
  ]

  for d in dirs:
    if exists(d): rm -rf d

  # 可选：重启 Cursor 并等待生成配置
  # restart_cursor_and_wait_generate_config()
```

----------------------------------------

## 四、机器码（telemetry.*）刷新伪代码

```pseudocode
function refresh_machine_ids(config_path):
  cfg = try_read_json(config_path) or {}

  new_machine_id    = "auth0|user_" + random_hex(64)      # 与脚本一致
  new_mac_machineId = random_hex(64)
  new_device_id     = uuid_v4()                            # xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  new_sqm_id        = cfg.get('telemetry.sqmId') or "{" + uuid_v4().upper() + "}"

  cfg['telemetry.machineId']    = new_machine_id
  cfg['telemetry.macMachineId'] = new_mac_machineId
  cfg['telemetry.devDeviceId']  = new_device_id
  cfg['telemetry.sqmId']        = new_sqm_id
  cfg['lastModified']           = now_rfc3339()

  atomic_write(config_path, json_indent(cfg))
```

备注：
- 与本仓库 pkg/idgen 的实现保持一致即可（Go 版本已提供；Shell/PS 在脚本中也有实现）。

----------------------------------------

## 五、Windows 额外项：注册表 MachineGuid（可选，脚本实现）

某些环境下，应用会读取 Windows 的 MachineGuid 进行设备识别。脚本可选提供如下流程：

```pseudocode
function windows_modify_machine_guid():
  key = "HKLM\\SOFTWARE\\Microsoft\\Cryptography"
  name = "MachineGuid"

  old = reg_query(key, name)
  backup_path = "%APPDATA%/Cursor/User/globalStorage/backups/MachineGuid.backup_yyyyMMdd_HHmmss"
  write_file(backup_path, old)

  new_guid = uuid_v4().lower()
  reg_set(key, name, new_guid)

  # 回滚示例
  # reg_set(key, name, read_file(backup_path))
```

注意：
- 需要管理员运行（UAC 提升）。
- 修改 MachineGuid 可能影响依赖该标识的部分软件授权或系统行为，务必先备份。

----------------------------------------

## 六、可选策略：内核 JS 注入劫持（进阶）

脚本中提供了通过修改应用 resources/app/out/*.js 的方式，注入代码来覆盖 crypto.randomUUID、设备 ID/MAC 读取函数，达到“临时劫持设备指纹”的目的。不同版本构建输出不同，需做兼容性判断与备份。

```pseudocode
function patch_cursor_js(resources_root):
  targets = [
    "out/vs/workbench/api/node/extensionHostProcess.js",
    "out/main.js",
    "out/vs/code/node/cliProcessMain.js"
  ]
  new_uuid = uuid_v4().lower()
  machineId = "auth0|user_" + random_base62(32)
  deviceId  = uuid_v4().lower()
  macId     = random_hex(64)

  inject = """
  // injected by Cursor helper
  import crypto from 'crypto';
  const orig = crypto.randomUUID;
  crypto.randomUUID = () => '""" + new_uuid + """';
  globalThis.getMachineId = ()=>'""" + machineId + """';
  globalThis.getDeviceId  = ()=>'""" + deviceId  + """';
  globalThis.macMachineId = '""" + macId     + """';
  console.log('Cursor device id hijacked');
  """

  for file in targets:
    path = resources_root + "/resources/app/" + file
    if exists(path):
      content = read_file(path)
      if not contains(content, "randomUUID()"): # 仅作为示例判定
        backup(file)
        write_file(path, inject + content)
```

注意：
- 该策略依赖构建产物形式，需注意版本差异并做好失败回滚。
- 不推荐作为首选，仅在“telemetry.* 刷新 + 彻底清理”仍无法满足时再考虑。

----------------------------------------

## 七、换号（账号切换）建议流程

```pseudocode
function switch_account_flow():
  in_app_sign_out()                 # 应用内退出登录
  kill_cursor_processes()
  cleanup_environment(level='MEDIUM')
  refresh_machine_ids(resolve_storage_json_path())

  # 网络侧建议（可选）：更换干净IP节点、刷新 DNS
  if on_windows(): run("ipconfig /flushdns")
  if on_macos():   run("sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder")
  if on_linux():   run("resolvectl flush-caches || systemd-resolve --flush-caches || true")

  reopen_and_login_with_new_account()
```

要点：
- 最简可行路径：退出登录 + 刷新 telemetry.* + 重新登录。
- 若仍被限制，采用“中度/重度清理 + 刷新 telemetry.* + （可选）Windows MachineGuid + 更换网络”。

----------------------------------------

## 八、自动化脚本与模块化建议

本仓库已提供：
- Go CLI：关闭进程、读取与原子写入 storage.json、生成各类 ID、国际化文案与 TUI 反馈
- PowerShell（Windows）：进程关闭、环境清理、storage.json 修改、MachineGuid 备份与写入、JS 注入
- Bash（macOS/Linux）：进程关闭、权限修复、环境清理、storage.json 修改与回滚、AppImage 安装（Linux）

模块化拆分建议：
- process: 进程发现与关闭，带重试
- config: storage.json 解析、字段合并、原子写入、备份
- idgen: 生成 machineId/macMachineId/devDeviceId/sqmId
- platform: 按 OS 抽象路径与特权提升
- patches: 可选 JS 注入、禁用自动更新的策略

----------------------------------------

## 九、常见问题与排查

- storage.json 不存在：
  - 冷启动 Cursor 一次并等待 15–30s，关闭后再写入
- EACCES/权限错误（macOS 常见）：
  - 参考上文权限修复四连：chown 两处 + chmod 两处
- 仍提示已达试用上限：
  - 确认已重度清理 + 刷新 telemetry.* +（Windows）考虑 MachineGuid + 切换干净网络
- Cursor 自动更新导致回退失效：
  - Windows 删除 %LOCALAPPDATA%/cursor-updater 并创建同名空文件

----------------------------------------

## 十、安全与回滚

- 所有修改均建议先备份（storage.json、MachineGuid 等）
- 配置写入采用原子写，避免部分写入导致损坏
- 提供回滚入口：
  - storage.json：backups 目录保留历史
  - Windows MachineGuid：注册表备份文件可手动恢复

----------------------------------------

## 参考实现位置（本仓库）
- Go 主程序：cmd/cursor-id-modifier/main.go
- 配置读写：internal/config/config.go（原子写、路径解析）
- 进程管理：internal/process/manager.go
- ID 生成：pkg/idgen/generator.go
- 脚本：scripts/run/
  - Windows: cursor_win_id_modifier.ps1（含注册表、JS 注入、目录清理）
  - macOS: cursor_mac_id_modifier.sh（含权限修复、目录清理、重启等待）
  - Linux: cursor_linux_id_modifier.sh（含安装、目录清理）
