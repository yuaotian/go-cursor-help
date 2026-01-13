/**
 * Cursor 设备标识符 Hook 模块
 * 
 * 🎯 功能：从底层拦截所有设备标识符的生成，实现一劳永逸的机器码修改
 * 
 * 🔧 Hook 点：
 * 1. child_process.execSync - 拦截 REG.exe 查询 MachineGuid
 * 2. crypto.createHash - 拦截 SHA256 哈希计算
 * 3. @vscode/deviceid - 拦截 devDeviceId 获取
 * 4. @vscode/windows-registry - 拦截注册表读取
 * 5. os.networkInterfaces - 拦截 MAC 地址获取
 * 
 * 📦 使用方式：
 * 将此代码注入到 main.js 文件顶部（Sentry 初始化之后）
 * 
 * ⚙️ 配置方式：
 * 1. 环境变量：CURSOR_MACHINE_ID, CURSOR_MAC_MACHINE_ID, CURSOR_DEV_DEVICE_ID, CURSOR_SQM_ID
 * 2. 配置文件：~/.cursor_ids.json
 * 3. 自动生成：如果没有配置，则自动生成并持久化
 */

// ==================== 配置区域 ====================
// 使用 var 确保在 ES Module 环境中也能正常工作
var __cursor_hook_config__ = {
    // 是否启用 Hook（设置为 false 可临时禁用）
    enabled: true,
    // 是否输出调试日志（设置为 true 可查看详细日志）
    debug: false,
    // 配置文件路径（相对于用户目录）
    configFileName: '.cursor_ids.json',
    // 标记：防止重复注入
    injected: false
};

// ==================== Hook 实现 ====================
// 使用 IIFE 确保代码立即执行
(function() {
    'use strict';

    // 防止重复注入
    if (globalThis.__cursor_patched__ || __cursor_hook_config__.injected) {
        return;
    }
    globalThis.__cursor_patched__ = true;
    __cursor_hook_config__.injected = true;

    // 调试日志函数
    const log = (...args) => {
        if (__cursor_hook_config__.debug) {
            console.log('[CursorHook]', ...args);
        }
    };

    // ==================== ID 生成和管理 ====================

    // 生成 UUID v4
    const generateUUID = () => {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    };

    // 生成 64 位十六进制字符串（用于 machineId）
    const generateHex64 = () => {
        let hex = '';
        for (let i = 0; i < 64; i++) {
            hex += Math.floor(Math.random() * 16).toString(16);
        }
        return hex;
    };

    // 生成 MAC 地址格式的字符串
    const generateMacAddress = () => {
        const hex = '0123456789ABCDEF';
        let mac = '';
        for (let i = 0; i < 6; i++) {
            if (i > 0) mac += ':';
            mac += hex[Math.floor(Math.random() * 16)];
            mac += hex[Math.floor(Math.random() * 16)];
        }
        return mac;
    };

    // 加载或生成 ID 配置
    // 注意：使用 createRequire 来支持 ES Module 环境
    const loadOrGenerateIds = () => {
        // 在 ES Module 环境中，需要使用 createRequire 来加载 CommonJS 模块
        let fs, path, os;
        try {
            // 尝试使用 Node.js 内置模块
            const { createRequire } = require('module');
            const require2 = createRequire(import.meta?.url || __filename);
            fs = require2('fs');
            path = require2('path');
            os = require2('os');
        } catch (e) {
            // 回退到直接 require
            fs = require('fs');
            path = require('path');
            os = require('os');
        }

        const configPath = path.join(os.homedir(), __cursor_hook_config__.configFileName);

        let ids = null;

        // 尝试从环境变量读取
        if (process.env.CURSOR_MACHINE_ID) {
            ids = {
                machineId: process.env.CURSOR_MACHINE_ID,
                // machineGuid 用于模拟注册表 MachineGuid/IOPlatformUUID
                machineGuid: process.env.CURSOR_MACHINE_GUID || generateUUID(),
                macMachineId: process.env.CURSOR_MAC_MACHINE_ID || generateHex64(),
                devDeviceId: process.env.CURSOR_DEV_DEVICE_ID || generateUUID(),
                sqmId: process.env.CURSOR_SQM_ID || `{${generateUUID().toUpperCase()}}`,
                macAddress: process.env.CURSOR_MAC_ADDRESS || generateMacAddress(),
                sessionId: process.env.CURSOR_SESSION_ID || generateUUID(),
                firstSessionDate: process.env.CURSOR_FIRST_SESSION_DATE || new Date().toISOString()
            };
            log('从环境变量加载 ID 配置');
            return ids;
        }

        // 尝试从配置文件读取
        try {
            if (fs.existsSync(configPath)) {
                const content = fs.readFileSync(configPath, 'utf8');
                ids = JSON.parse(content);
                // 补全缺失字段，保持向后兼容
                let updated = false;
                if (!ids.machineGuid) {
                    ids.machineGuid = generateUUID();
                    updated = true;
                }
                if (!ids.macAddress) {
                    ids.macAddress = generateMacAddress();
                    updated = true;
                }
                if (!ids.sessionId) {
                    ids.sessionId = generateUUID();
                    updated = true;
                }
                if (!ids.firstSessionDate) {
                    ids.firstSessionDate = new Date().toISOString();
                    updated = true;
                }
                if (updated) {
                    try {
                        fs.writeFileSync(configPath, JSON.stringify(ids, null, 2), 'utf8');
                        log('已补全并更新 ID 配置:', configPath);
                    } catch (e) {
                        log('补全配置文件失败:', e.message);
                    }
                }
                log('从配置文件加载 ID 配置:', configPath);
                return ids;
            }
        } catch (e) {
            log('读取配置文件失败:', e.message);
        }

        // 生成新的 ID
        ids = {
            machineId: generateHex64(),
            machineGuid: generateUUID(),
            macMachineId: generateHex64(),
            devDeviceId: generateUUID(),
            sqmId: `{${generateUUID().toUpperCase()}}`,
            macAddress: generateMacAddress(),
            sessionId: generateUUID(),
            firstSessionDate: new Date().toISOString(),
            createdAt: new Date().toISOString()
        };

        // 保存到配置文件
        try {
            fs.writeFileSync(configPath, JSON.stringify(ids, null, 2), 'utf8');
            log('已生成并保存新的 ID 配置:', configPath);
        } catch (e) {
            log('保存配置文件失败:', e.message);
        }

        return ids;
    };

    // 加载 ID 配置
    const __cursor_ids__ = loadOrGenerateIds();
    // 统一获取 MachineGuid，缺失时回退到 machineId 的前 36 位
    const getMachineGuid = () => __cursor_ids__.machineGuid || __cursor_ids__.machineId.substring(0, 36);
    log('当前 ID 配置:', __cursor_ids__);
    
    // ==================== Module Hook ====================
    
    const Module = require('module');
    const originalRequire = Module.prototype.require;
    
    // 缓存已 Hook 的模块
    const hookedModules = new Map();
    
    Module.prototype.require = function(id) {
        // 兼容 node: 前缀
        const normalizedId = (typeof id === 'string' && id.startsWith('node:')) ? id.slice(5) : id;
        const result = originalRequire.apply(this, arguments);
        
        // 如果已经 Hook 过，直接返回缓存
        if (hookedModules.has(normalizedId)) {
            return hookedModules.get(normalizedId);
        }
        
        let hooked = result;
        
        // Hook child_process 模块
        if (normalizedId === 'child_process') {
            hooked = hookChildProcess(result);
        }
        // Hook os 模块
        else if (normalizedId === 'os') {
            hooked = hookOs(result);
        }
        // Hook crypto 模块
        else if (normalizedId === 'crypto') {
            hooked = hookCrypto(result);
        }
        // Hook @vscode/deviceid 模块
        else if (normalizedId === '@vscode/deviceid') {
            hooked = hookDeviceId(result);
        }
        // Hook @vscode/windows-registry 模块
        else if (normalizedId === '@vscode/windows-registry') {
            hooked = hookWindowsRegistry(result);
        }

        // 缓存 Hook 结果
        if (hooked !== result) {
            hookedModules.set(normalizedId, hooked);
            log(`已 Hook 模块: ${normalizedId}`);
        }
        
        return hooked;
    };

    // ==================== child_process Hook ====================

    function hookChildProcess(cp) {
        const originalExecSync = cp.execSync;
        const originalExecFileSync = cp.execFileSync;

        cp.execSync = function(command, options) {
            const cmdStr = String(command).toLowerCase();

            // 拦截 MachineGuid 查询
            if (cmdStr.includes('reg') && cmdStr.includes('machineguid')) {
                log('拦截 MachineGuid 查询');
                // 返回格式化的注册表输出
                return Buffer.from(`\r\n    MachineGuid    REG_SZ    ${getMachineGuid()}\r\n`);
            }

            // 拦截 ioreg 命令 (macOS)
            if (cmdStr.includes('ioreg') && cmdStr.includes('ioplatformexpertdevice')) {
                log('拦截 IOPlatformUUID 查询');
                return Buffer.from(`"IOPlatformUUID" = "${getMachineGuid().toUpperCase()}"`);
            }

            // 拦截 machine-id 读取 (Linux)
            if (cmdStr.includes('machine-id') || cmdStr.includes('hostname')) {
                log('拦截 machine-id 查询');
                return Buffer.from(__cursor_ids__.machineId.substring(0, 32));
            }

            return originalExecSync.apply(this, arguments);
        };

        // 兼容 execFileSync（部分版本会直接调用可执行文件）
        if (typeof originalExecFileSync === 'function') {
            cp.execFileSync = function(file, args, options) {
                const cmdStr = [file].concat(args || []).join(' ').toLowerCase();

                if (cmdStr.includes('reg') && cmdStr.includes('machineguid')) {
                    log('拦截 MachineGuid 查询(execFileSync)');
                    return Buffer.from(`\r\n    MachineGuid    REG_SZ    ${getMachineGuid()}\r\n`);
                }

                if (cmdStr.includes('ioreg') && cmdStr.includes('ioplatformexpertdevice')) {
                    log('拦截 IOPlatformUUID 查询(execFileSync)');
                    return Buffer.from(`"IOPlatformUUID" = "${getMachineGuid().toUpperCase()}"`);
                }

                if (cmdStr.includes('machine-id') || cmdStr.includes('hostname')) {
                    log('拦截 machine-id 查询(execFileSync)');
                    return Buffer.from(__cursor_ids__.machineId.substring(0, 32));
                }

                return originalExecFileSync.apply(this, arguments);
            };
        }

        return cp;
    }

    // ==================== os Hook ====================

    function hookOs(os) {
        const originalNetworkInterfaces = os.networkInterfaces;

        os.networkInterfaces = function() {
            log('拦截 networkInterfaces 调用');
            // 返回虚拟的网络接口，使用固定的 MAC 地址
            return {
                'Ethernet': [{
                    address: '192.168.1.100',
                    netmask: '255.255.255.0',
                    family: 'IPv4',
                    mac: __cursor_ids__.macAddress || '00:00:00:00:00:00',
                    internal: false
                }]
            };
        };

        return os;
    }

    // ==================== crypto Hook ====================

    function hookCrypto(crypto) {
        const originalCreateHash = crypto.createHash;
        const originalRandomUUID = crypto.randomUUID;

        // Hook createHash - 用于拦截 machineId 的 SHA256 计算
        crypto.createHash = function(algorithm) {
            const hash = originalCreateHash.apply(this, arguments);

            if (algorithm.toLowerCase() === 'sha256') {
                const originalUpdate = hash.update.bind(hash);
                const originalDigest = hash.digest.bind(hash);

                let inputData = '';

                hash.update = function(data, encoding) {
                    inputData += String(data);
                    return originalUpdate(data, encoding);
                };

                hash.digest = function(encoding) {
                    // 检查是否是 machineId 相关的哈希计算
                    if (inputData.includes('MachineGuid') ||
                        inputData.includes('IOPlatformUUID') ||
                        inputData.length === 32 ||
                        inputData.length === 36) {
                        log('拦截 SHA256 哈希计算，返回固定 machineId');
                        if (encoding === 'hex') {
                            return __cursor_ids__.machineId;
                        }
                        return Buffer.from(__cursor_ids__.machineId, 'hex');
                    }
                    return originalDigest(encoding);
                };
            }

            return hash;
        };

        // Hook randomUUID - 用于拦截 devDeviceId 生成
        if (originalRandomUUID) {
            let uuidCallCount = 0;
            crypto.randomUUID = function() {
                uuidCallCount++;
                // 第一次调用返回固定的 devDeviceId
                if (uuidCallCount <= 2) {
                    log('拦截 randomUUID 调用，返回固定 devDeviceId');
                    return __cursor_ids__.devDeviceId;
                }
                return originalRandomUUID.apply(this, arguments);
            };
        }

        return crypto;
    }

    // ==================== @vscode/deviceid Hook ====================

    function hookDeviceId(deviceIdModule) {
        log('Hook @vscode/deviceid 模块');

        return {
            ...deviceIdModule,
            getDeviceId: async function() {
                log('拦截 getDeviceId 调用');
                return __cursor_ids__.devDeviceId;
            }
        };
    }

    // ==================== @vscode/windows-registry Hook ====================

    function hookWindowsRegistry(registryModule) {
        log('Hook @vscode/windows-registry 模块');

        const originalGetStringRegKey = registryModule.GetStringRegKey;

        return {
            ...registryModule,
            GetStringRegKey: function(hive, path, name) {
                // 拦截 MachineId 读取
                if (name === 'MachineId' || path.includes('SQMClient')) {
                    log('拦截注册表 MachineId/SQMClient 读取');
                    return __cursor_ids__.sqmId;
                }
                // 拦截 MachineGuid 读取
                if (name === 'MachineGuid' || path.includes('Cryptography')) {
                    log('拦截注册表 MachineGuid 读取');
                    return getMachineGuid();
                }
                return originalGetStringRegKey?.apply(this, arguments) || '';
            }
        };
    }

    // ==================== 动态 import Hook ====================

    // Cursor 使用动态 import() 加载模块，我们需要 Hook 这些模块
    // 由于 ES Module 的限制，我们通过 Hook 全局对象来实现

    // 存储已 Hook 的动态导入模块
    const hookedDynamicModules = new Map();

    // Hook crypto 模块的动态导入
    const hookDynamicCrypto = (cryptoModule) => {
        if (hookedDynamicModules.has('crypto')) {
            return hookedDynamicModules.get('crypto');
        }

        const hooked = { ...cryptoModule };

        // Hook createHash
        if (cryptoModule.createHash) {
            const originalCreateHash = cryptoModule.createHash;
            hooked.createHash = function(algorithm) {
                const hash = originalCreateHash.apply(this, arguments);

                if (algorithm.toLowerCase() === 'sha256') {
                    const originalDigest = hash.digest.bind(hash);
                    let inputData = '';

                    const originalUpdate = hash.update.bind(hash);
                    hash.update = function(data, encoding) {
                        inputData += String(data);
                        return originalUpdate(data, encoding);
                    };

                    hash.digest = function(encoding) {
                        // 检测 machineId 相关的哈希
                        if (inputData.includes('MachineGuid') ||
                            inputData.includes('IOPlatformUUID') ||
                            (inputData.length >= 32 && inputData.length <= 40)) {
                            log('动态导入: 拦截 SHA256 哈希');
                            return encoding === 'hex' ? __cursor_ids__.machineId : Buffer.from(__cursor_ids__.machineId, 'hex');
                        }
                        return originalDigest(encoding);
                    };
                }
                return hash;
            };
        }

        hookedDynamicModules.set('crypto', hooked);
        return hooked;
    };

    // Hook @vscode/deviceid 模块的动态导入
    const hookDynamicDeviceId = (deviceIdModule) => {
        if (hookedDynamicModules.has('@vscode/deviceid')) {
            return hookedDynamicModules.get('@vscode/deviceid');
        }

        const hooked = {
            ...deviceIdModule,
            getDeviceId: async () => {
                log('动态导入: 拦截 getDeviceId');
                return __cursor_ids__.devDeviceId;
            }
        };

        hookedDynamicModules.set('@vscode/deviceid', hooked);
        return hooked;
    };

    // Hook @vscode/windows-registry 模块的动态导入
    const hookDynamicWindowsRegistry = (registryModule) => {
        if (hookedDynamicModules.has('@vscode/windows-registry')) {
            return hookedDynamicModules.get('@vscode/windows-registry');
        }

        const originalGetStringRegKey = registryModule.GetStringRegKey;
        const hooked = {
            ...registryModule,
            GetStringRegKey: function(hive, path, name) {
                if (name === 'MachineId' || path?.includes('SQMClient')) {
                    log('动态导入: 拦截 SQMClient');
                    return __cursor_ids__.sqmId;
                }
                if (name === 'MachineGuid' || path?.includes('Cryptography')) {
                    log('动态导入: 拦截 MachineGuid');
                    return getMachineGuid();
                }
                return originalGetStringRegKey?.apply(this, arguments) || '';
            }
        };

        hookedDynamicModules.set('@vscode/windows-registry', hooked);
        return hooked;
    };

    // 将 Hook 函数暴露到全局，供后续使用
    globalThis.__cursor_hook_dynamic__ = {
        crypto: hookDynamicCrypto,
        deviceId: hookDynamicDeviceId,
        windowsRegistry: hookDynamicWindowsRegistry,
        ids: __cursor_ids__
    };

    log('Cursor Hook 初始化完成');
    log('machineId:', __cursor_ids__.machineId.substring(0, 16) + '...');
    log('machineGuid:', getMachineGuid().substring(0, 16) + '...');
    log('devDeviceId:', __cursor_ids__.devDeviceId);
    log('sqmId:', __cursor_ids__.sqmId);

})();

// ==================== 导出配置（供外部使用） ====================
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { __cursor_hook_config__ };
}

// ==================== ES Module 兼容性 ====================
// 如果在 ES Module 环境中，也暴露配置
if (typeof globalThis !== 'undefined') {
    globalThis.__cursor_hook_config__ = __cursor_hook_config__;
}
