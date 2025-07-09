# Apple Silicon macOS 15+ 智能设备识别绕过方案

## 🚨 问题背景

在macOS 15.3.1 Apple Silicon环境下，传统的MAC地址修改方法完全失败：
- Apple Silicon芯片硬件层面限制MAC地址修改
- 系统完整性保护(SIP)阻止网络接口底层修改
- 第三方工具(spoof-mac, macchanger)也无法绕过硬件限制

## 🔧 智能解决方案

### 核心策略：双重绕过机制
1. **优先尝试MAC地址修改** - 兼容传统环境
2. **智能切换JS内核修改** - 针对Apple Silicon环境

### 🎯 JS内核修改原理

#### **直接修改Cursor设备检测逻辑**
- 修改Cursor内核JS文件中的设备ID获取函数
- 注入随机设备标识符生成代码
- 绕过IOPlatformUUID、getMachineId等系统调用

#### **修改目标文件**
```
/Applications/Cursor.app/Contents/Resources/app/out/
├── vs/workbench/api/node/extensionHostProcess.js
├── main.js
└── vs/code/node/cliProcessMain.js
```

#### **注入代码示例**
```javascript
// Cursor ID 修改工具注入
const originalRequire = require;
require = function(module) {
    const result = originalRequire.apply(this, arguments);
    if (module === 'crypto' && result.randomUUID) {
        result.randomUUID = function() {
            return 'generated-uuid-here';
        };
    }
    return result;
};

// 覆盖系统ID获取函数
global.getMachineId = function() { return 'auth0|user_randomhex'; };
global.getDeviceId = function() { return 'random-device-id'; };
global.macMachineId = 'random-mac-machine-id';
```

## 🚀 实施方案

### 新增功能：`modify_cursor_js_files()`
- 自动检测JS文件修改状态
- 智能识别不同的函数模式
- 安全备份原始文件
- 多种注入方法兼容不同Cursor版本

### 智能检测逻辑
```bash
if [[ "$HARDWARE_TYPE" == "Apple Silicon" ]]; then
    # 自动切换到JS内核修改（无需用户确认）
    modify_cursor_js_files
    return 0
else
    # 传统MAC地址修改
    if ! change_system_mac_address; then
        # 失败时自动切换到JS内核修改（无需用户确认）
        modify_cursor_js_files
    fi
fi
```

### 用户交互优化
- **Apple Silicon环境完全自动化** - 直接使用JS方案，无需确认
- **MAC地址修改失败自动切换** - 无需用户选择，直接尝试JS方案
- **最小化用户交互** - 智能决策，减少不必要的确认步骤

## 💡 方案优势

### JS内核修改 vs MAC地址修改

| 特性 | JS内核修改 | MAC地址修改 |
|------|------------|-------------|
| **Apple Silicon兼容性** | ✅ 完全兼容 | ❌ 硬件限制 |
| **绕过效果** | ✅ 直接有效 | ⚠️ 间接影响 |
| **持久性** | ✅ 应用级持久 | ⚠️ 重启恢复 |
| **权限要求** | ⚠️ 需要修改应用 | ⚠️ 需要sudo |
| **检测难度** | ✅ 难以检测 | ⚠️ 容易检测 |

### 技术优势
1. **直接绕过** - 修改Cursor内部逻辑，不依赖系统层面
2. **硬件无关** - 不受Apple Silicon硬件限制
3. **效果确定** - 直接控制设备标识符生成
4. **兼容性好** - 支持多种Cursor版本和函数模式

## 🔄 执行流程

### 智能检测流程
1. **环境检测** - 识别macOS版本和硬件类型
2. **工具检测** - 检查第三方MAC修改工具
3. **智能选择** - 根据环境自动选择最佳方案
4. **备选方案** - 失败时提供替代选择

### JS修改流程
1. **文件检查** - 验证目标JS文件存在性
2. **状态检测** - 检查是否已经修改过
3. **安全备份** - 创建原始文件备份
4. **模式识别** - 识别不同的函数模式
5. **代码注入** - 注入设备标识符生成代码
6. **验证完成** - 确认修改成功

## 📋 使用指南

### 完全自动化模式（推荐）
```bash
sudo ./cursor_mac_id_modifier.sh
# 选择"重置环境+修改机器码"
# 脚本会自动检测环境并选择最佳方案
# Apple Silicon环境自动使用JS内核修改
# MAC地址修改失败自动切换到JS方案
```

### 智能决策流程
- **Apple Silicon检测** - 自动使用JS内核修改，无需确认
- **MAC地址修改失败** - 自动切换到JS方案，无需用户选择
- **最小化交互** - 只在必要时询问用户（如重试失败的接口）
- **智能备选** - 双重保障确保设备识别绕过成功

## 🛡️ 安全考虑

### 备份机制
- 自动创建Cursor应用完整备份
- 备份位置：`/tmp/Cursor.app.backup_js_timestamp`
- 支持手动恢复原始状态

### 风险评估
- **低风险** - 仅修改应用层代码，不影响系统
- **可逆性** - 可以通过备份完全恢复
- **兼容性** - 支持多种Cursor版本

## 🎯 预期效果

### 成功指标
- ✅ Cursor试用状态重置成功
- ✅ 设备识别绕过生效
- ✅ 新的设备标识符正常工作
- ✅ 应用功能完全正常

### 故障排除
- 如果JS修改失败，检查Cursor版本兼容性
- 如果应用无法启动，使用备份恢复
- 如果效果不佳，可以结合配置文件修改

## 📈 总结

这个智能方案完美解决了Apple Silicon Mac上MAC地址修改的限制问题：

1. **技术突破** - 绕过硬件限制，实现设备识别绕过
2. **用户友好** - 自动检测，智能选择，无需用户判断
3. **效果确定** - 直接修改Cursor逻辑，绕过效果更好
4. **兼容性强** - 支持多种环境和Cursor版本

现在Apple Silicon Mac用户也可以正常使用Cursor试用重置功能了！
