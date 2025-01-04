package process

import (
	"fmt"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

// Config holds process manager configuration
type Config struct {
	MaxAttempts     int           // Maximum number of attempts to kill processes
	RetryDelay      time.Duration // Delay between retry attempts
	ProcessPatterns []string      // Process names to look for
}

// DefaultConfig returns the default configuration
func DefaultConfig() *Config {
	return &Config{
		MaxAttempts: 3,
		RetryDelay:  2 * time.Second,
		ProcessPatterns: []string{
			"Cursor.exe", // Windows executable
			"Cursor ",    // Linux/macOS executable with space
			"cursor ",    // Linux/macOS executable lowercase with space
			"cursor",     // Linux/macOS executable lowercase
			"Cursor",     // Linux/macOS executable
			"*cursor*",   // Any process containing cursor
			"*Cursor*",   // Any process containing Cursor
		},
	}
}

// Manager handles process-related operations
type Manager struct {
	config *Config
	log    *logrus.Logger
}

// NewManager creates a new process manager with optional config and logger
func NewManager(config *Config, log *logrus.Logger) *Manager {
	if config == nil {
		config = DefaultConfig()
	}
	if log == nil {
		log = logrus.New()
	}
	return &Manager{
		config: config,
		log:    log,
	}
}

// IsCursorRunning checks if any Cursor process is currently running
func (m *Manager) IsCursorRunning() bool {
	processes, err := m.getCursorProcesses()
	if err != nil {
		m.log.Warn("Failed to get Cursor processes:", err)
		return false
	}
	return len(processes) > 0
}

// KillCursorProcesses attempts to kill all running Cursor processes
func (m *Manager) KillCursorProcesses() error {
	for attempt := 1; attempt <= m.config.MaxAttempts; attempt++ {
		processes, err := m.getCursorProcesses()
		if err != nil {
			return fmt.Errorf("failed to get processes: %w", err)
		}

		if len(processes) == 0 {
			return nil
		}

		// Try graceful shutdown first on Windows
		if runtime.GOOS == "windows" {
			for _, pid := range processes {
				exec.Command("taskkill", "/PID", pid).Run()
				time.Sleep(500 * time.Millisecond)
			}
		}

		// Force kill remaining processes
		remainingProcesses, _ := m.getCursorProcesses()
		for _, pid := range remainingProcesses {
			m.killProcess(pid)
		}

		time.Sleep(m.config.RetryDelay)

		if processes, _ := m.getCursorProcesses(); len(processes) == 0 {
			return nil
		}
	}

	return nil
}

// getCursorProcesses returns PIDs of running Cursor processes
func (m *Manager) getCursorProcesses() ([]string, error) {
	cmd := m.getProcessListCommand()
	if cmd == nil {
		return nil, fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to execute command: %w", err)
	}

	return m.parseProcessList(string(output)), nil
}

// getProcessListCommand returns the appropriate command to list processes based on OS
func (m *Manager) getProcessListCommand() *exec.Cmd {
	switch runtime.GOOS {
	case "windows":
		return exec.Command("tasklist", "/FO", "CSV", "/NH")
	case "darwin":
		return exec.Command("ps", "-ax")
	case "linux":
		return exec.Command("ps", "-A")
	default:
		return nil
	}
}

// parseProcessList extracts Cursor process PIDs from process list output
func (m *Manager) parseProcessList(output string) []string {
	var processes []string
	for _, line := range strings.Split(output, "\n") {
		lowerLine := strings.ToLower(line)

		if m.isOwnProcess(lowerLine) {
			continue
		}

		if pid := m.findCursorProcess(line, lowerLine); pid != "" {
			processes = append(processes, pid)
		}
	}
	return processes
}

// isOwnProcess checks if the process belongs to this application
func (m *Manager) isOwnProcess(line string) bool {
	return strings.Contains(line, "cursor-id-modifier") ||
		strings.Contains(line, "cursor-helper")
}

// findCursorProcess checks if a process line matches Cursor patterns and returns its PID
func (m *Manager) findCursorProcess(line, lowerLine string) string {
	for _, pattern := range m.config.ProcessPatterns {
		if m.matchPattern(lowerLine, strings.ToLower(pattern)) {
			return m.extractPID(line)
		}
	}
	return ""
}

// matchPattern checks if a line matches a pattern, supporting wildcards
func (m *Manager) matchPattern(line, pattern string) bool {
	switch {
	case strings.HasPrefix(pattern, "*") && strings.HasSuffix(pattern, "*"):
		search := pattern[1 : len(pattern)-1]
		return strings.Contains(line, search)
	case strings.HasPrefix(pattern, "*"):
		return strings.HasSuffix(line, pattern[1:])
	case strings.HasSuffix(pattern, "*"):
		return strings.HasPrefix(line, pattern[:len(pattern)-1])
	default:
		return line == pattern
	}
}

// extractPID extracts process ID from a process list line based on OS format
func (m *Manager) extractPID(line string) string {
	switch runtime.GOOS {
	case "windows":
		parts := strings.Split(line, ",")
		if len(parts) >= 2 {
			return strings.Trim(parts[1], "\"")
		}
	case "darwin", "linux":
		parts := strings.Fields(line)
		if len(parts) >= 1 {
			return parts[0]
		}
	}
	return ""
}

// killProcess forcefully terminates a process by PID
func (m *Manager) killProcess(pid string) error {
	cmd := m.getKillCommand(pid)
	if cmd == nil {
		return fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
	return cmd.Run()
}

// getKillCommand returns the appropriate command to kill a process based on OS
func (m *Manager) getKillCommand(pid string) *exec.Cmd {
	switch runtime.GOOS {
	case "windows":
		return exec.Command("taskkill", "/F", "/PID", pid)
	case "darwin", "linux":
		return exec.Command("kill", "-9", pid)
	default:
		return nil
	}
}
