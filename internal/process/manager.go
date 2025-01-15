package process

import (
	"fmt"
	"os/exec"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/yuaotian/go-cursor-help/internal/platform"
)

// Config holds process manager configuration
type Config struct {
	MaxAttempts     int
	RetryDelay      time.Duration
	ProcessPatterns []string
}

// DefaultConfig returns the default configuration
func DefaultConfig() *Config {
	return &Config{
		MaxAttempts: 3,
		RetryDelay:  2 * time.Second,
		ProcessPatterns: []string{
			"Cursor.exe",
			"Cursor",
			"cursor",
		},
	}
}

// Manager handles process-related operations
type Manager struct {
	config *Config
	log    *logrus.Logger
}

// NewManager creates a new process manager
func NewManager(config *Config, log *logrus.Logger) *Manager {
	if config == nil {
		config = DefaultConfig()
	}
	if log == nil {
		log = logrus.New()
	}
	return &Manager{config: config, log: log}
}

// HandleCursorProcesses manages Cursor processes
func (m *Manager) HandleCursorProcesses() error {
	if platform.IsLinux() {
		m.log.Debug("Skipping Cursor process closing on Linux")
		return nil
	}

	m.log.Debug("Attempting to close Cursor processes")
	if err := m.KillCursorProcesses(); err != nil {
		return fmt.Errorf("failed to close Cursor: %w", err)
	}

	if m.IsCursorRunning() {
		return fmt.Errorf("cursor processes still detected after closing")
	}

	m.log.Debug("Successfully closed all Cursor processes")
	return nil
}

// IsCursorRunning checks if any Cursor process is running
func (m *Manager) IsCursorRunning() bool {
	processes, _ := m.getCursorProcesses()
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

		for _, pid := range processes {
			if err := m.killProcess(pid); err != nil {
				m.log.Warnf("Failed to kill process %s: %v", pid, err)
			}
		}

		time.Sleep(m.config.RetryDelay)

		if !m.IsCursorRunning() {
			return nil
		}
	}

	return fmt.Errorf("failed to kill all Cursor processes after %d attempts", m.config.MaxAttempts)
}

// getCursorProcesses returns PIDs of running Cursor processes
func (m *Manager) getCursorProcesses() ([]string, error) {
	if platform.IsLinux() {
		return nil, nil
	}

	cmd := m.getListProcessesCmd()
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list processes: %w", err)
	}

	return m.parsePIDsFromOutput(string(output)), nil
}

func (m *Manager) getListProcessesCmd() *exec.Cmd {
	if platform.IsWindows() {
		return exec.Command("tasklist", "/FO", "CSV", "/NH")
	}
	return exec.Command("ps", "-A")
}

func (m *Manager) parsePIDsFromOutput(output string) []string {
	var pids []string
	for _, line := range strings.Split(output, "\n") {
		if m.isOwnProcess(line) {
			continue
		}

		if pid := m.findMatchingPID(line); pid != "" {
			pids = append(pids, pid)
		}
	}
	return pids
}

func (m *Manager) isOwnProcess(line string) bool {
	return strings.Contains(line, "cursor-id-modifier") || strings.Contains(line, "cursor-helper")
}

func (m *Manager) findMatchingPID(line string) string {
	lowerLine := strings.ToLower(line)
	for _, pattern := range m.config.ProcessPatterns {
		if strings.Contains(lowerLine, strings.ToLower(pattern)) {
			return m.extractPID(line)
		}
	}
	return ""
}

// extractPID extracts process ID from a process list line
func (m *Manager) extractPID(line string) string {
	if platform.IsWindows() {
		parts := strings.Split(line, ",")
		if len(parts) >= 2 {
			return strings.Trim(parts[1], "\"")
		}
	} else {
		parts := strings.Fields(line)
		if len(parts) >= 1 {
			return parts[0]
		}
	}
	return ""
}

// killProcess forcefully terminates a process
func (m *Manager) killProcess(pid string) error {
	cmd := m.getKillProcessCmd(pid)
	return cmd.Run()
}

func (m *Manager) getKillProcessCmd(pid string) *exec.Cmd {
	if platform.IsWindows() {
		return exec.Command("taskkill", "/F", "/PID", pid)
	}
	return exec.Command("kill", "-9", pid)
}
