package lang

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"sync"
)

// Language represents a supported language code
type Language string

const (
	// CN represents Chinese language
	CN Language = "cn"
	// EN represents English language
	EN Language = "en"
)

// TextResource contains all translatable text resources
type TextResource struct {
	// Success messages
	SuccessMessage string
	RestartMessage string

	// Progress messages
	ReadingConfig     string
	GeneratingIds     string
	CheckingProcesses string
	ClosingProcesses  string
	ProcessesClosed   string
	PleaseWait        string

	// Error messages
	ErrorPrefix    string
	PrivilegeError string

	// Instructions
	RunAsAdmin         string
	RunWithSudo        string
	SudoExample        string
	PressEnterToExit   string
	SetReadOnlyMessage string

	// Info messages
	ConfigLocation string
}

var (
	currentLanguage Language
	languageMutex   sync.RWMutex
)

// GetCurrentLanguage returns the current language, detecting it if not already set.
// The detection process follows this order:
// 1. Check environment variables (LANG, LANGUAGE, LC_ALL)
// 2. Check OS-specific locale settings
// 3. Fall back to English if detection fails
func GetCurrentLanguage() Language {
	languageMutex.RLock()
	if currentLanguage != "" {
		defer languageMutex.RUnlock()
		return currentLanguage
	}
	languageMutex.RUnlock()

	languageMutex.Lock()
	defer languageMutex.Unlock()
	if currentLanguage == "" {
		var err error
		currentLanguage, err = detectLanguage()
		if err != nil {
			// Log error but continue with English as fallback
			fmt.Fprintf(os.Stderr, "Language detection failed: %v, falling back to English\n", err)
			currentLanguage = EN
		}
	}
	return currentLanguage
}

// SetLanguage sets the current language.
// This is thread-safe and can be called from multiple goroutines.
func SetLanguage(lang Language) {
	languageMutex.Lock()
	defer languageMutex.Unlock()
	currentLanguage = lang
}

// GetText returns the TextResource for the current language.
// This is thread-safe and can be called from multiple goroutines.
func GetText() TextResource {
	return texts[GetCurrentLanguage()]
}

// detectLanguage detects the system language.
// Returns an error if the detection process fails.
func detectLanguage() (Language, error) {
	// Check environment variables first
	for _, envVar := range []string{"LANG", "LANGUAGE", "LC_ALL"} {
		if lang := os.Getenv(envVar); lang != "" {
			if strings.Contains(strings.ToLower(lang), "zh") {
				return CN, nil
			}
		}
	}

	// Check OS-specific locale
	if os.Getenv("OS") == "Windows_NT" {
		isZH, err := isWindowsChineseLocale()
		if err != nil {
			return EN, fmt.Errorf("failed to detect Windows locale: %w", err)
		}
		if isZH {
			return CN, nil
		}
	} else {
		output, err := exec.Command("locale").Output()
		if err != nil {
			return EN, fmt.Errorf("failed to get system locale: %w", err)
		}
		if strings.Contains(strings.ToLower(string(output)), "zh_cn") {
			return CN, nil
		}
	}

	return EN, nil
}

// isWindowsChineseLocale checks if the Windows system locale is Chinese.
// Returns an error if the locale check fails.
func isWindowsChineseLocale() (bool, error) {
	// Check Windows UI culture
	cmd := exec.Command("powershell", "-Command",
		"[System.Globalization.CultureInfo]::CurrentUICulture.Name")
	output, err := cmd.Output()
	if err == nil && strings.HasPrefix(strings.ToLower(strings.TrimSpace(string(output))), "zh") {
		return true, nil
	}
	if err != nil {
		// Don't return error here, try the next method
		fmt.Fprintf(os.Stderr, "Failed to get Windows UI culture: %v\n", err)
	}

	// Check Windows locale as fallback
	cmd = exec.Command("wmic", "os", "get", "locale")
	output, err = cmd.Output()
	if err != nil {
		return false, fmt.Errorf("failed to get Windows locale: %w", err)
	}
	return strings.Contains(string(output), "2052"), nil
}

// texts contains all translations
var texts = map[Language]TextResource{
	CN: {
		// Success messages
		SuccessMessage: "[√] 配置文件已成功更新！",
		RestartMessage: "[!] 请手动重启 Cursor 以使更新生效",

		// Progress messages
		ReadingConfig:     "正在读取配置文件...",
		GeneratingIds:     "正在生成新的标识符...",
		CheckingProcesses: "正在检查运行中的 Cursor 实例...",
		ClosingProcesses:  "正在关闭 Cursor 实例...",
		ProcessesClosed:   "所有 Cursor 实例已关闭",
		PleaseWait:        "请稍候...",

		// Error messages
		ErrorPrefix:    "程序发生严重错误: %v",
		PrivilegeError: "\n[!] 错误：需要管理员权限",

		// Instructions
		RunAsAdmin:         "请右键点击程序，选择「以管理员身份运行」",
		RunWithSudo:        "请使用 sudo 命令运行此程序",
		SudoExample:        "示例: sudo %s",
		PressEnterToExit:   "\n按回车键退出程序...",
		SetReadOnlyMessage: "设置 storage.json 为只读模式, 这将导致 workspace 记录信息丢失等问题",

		// Info messages
		ConfigLocation: "配置文件位置:",
	},
	EN: {
		// Success messages
		SuccessMessage: "[√] Configuration file updated successfully!",
		RestartMessage: "[!] Please restart Cursor manually for changes to take effect",

		// Progress messages
		ReadingConfig:     "Reading configuration file...",
		GeneratingIds:     "Generating new identifiers...",
		CheckingProcesses: "Checking for running Cursor instances...",
		ClosingProcesses:  "Closing Cursor instances...",
		ProcessesClosed:   "All Cursor instances have been closed",
		PleaseWait:        "Please wait...",

		// Error messages
		ErrorPrefix:    "Program encountered a serious error: %v",
		PrivilegeError: "\n[!] Error: Administrator privileges required",

		// Instructions
		RunAsAdmin:         "Please right-click and select 'Run as Administrator'",
		RunWithSudo:        "Please run this program with sudo",
		SudoExample:        "Example: sudo %s",
		PressEnterToExit:   "\nPress Enter to exit...",
		SetReadOnlyMessage: "Set storage.json to read-only mode, which will cause issues such as lost workspace records",

		// Info messages
		ConfigLocation: "Config file location:",
	},
}
