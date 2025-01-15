package config

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"time"

	"github.com/yuaotian/go-cursor-help/internal/platform"
)

// StorageConfig represents the storage configuration
type StorageConfig struct {
	TelemetryMacMachineId string `json:"telemetry.macMachineId"`
	TelemetryMachineId    string `json:"telemetry.machineId"`
	TelemetryDevDeviceId  string `json:"telemetry.devDeviceId"`
	LastModified          string `json:"lastModified"`
	Version               string `json:"version"`
}

// Manager handles configuration operations
type Manager struct {
	configPath string
	mu         sync.RWMutex
}

// NewManager creates a new configuration manager
func NewManager(username string) (*Manager, error) {
	configDir, err := platform.GetConfigDir(username)
	if err != nil {
		return nil, fmt.Errorf("failed to get config directory: %w", err)
	}
	return &Manager{configPath: filepath.Join(configDir, "storage.json")}, nil
}

// ReadConfig reads the existing configuration
func (m *Manager) ReadConfig() (*StorageConfig, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	data, err := os.ReadFile(m.configPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config StorageConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	return &config, nil
}

// SaveConfig saves the configuration
func (m *Manager) SaveConfig(config *StorageConfig, readOnly bool) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	// Create directory with full permissions
	if err := os.MkdirAll(filepath.Dir(m.configPath), 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	// Ensure we have write permissions
	if err := m.ensureWritePermissions(); err != nil {
		return fmt.Errorf("failed to set write permissions: %w", err)
	}

	configMap := map[string]interface{}{
		"telemetry.macMachineId": config.TelemetryMacMachineId,
		"telemetry.machineId":    config.TelemetryMachineId,
		"telemetry.devDeviceId":  config.TelemetryDevDeviceId,
		"lastModified":           time.Now().UTC().Format(time.RFC3339),
	}

	content, err := json.MarshalIndent(configMap, "", "    ")
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	// Write with full permissions first
	if err := os.WriteFile(m.configPath, content, 0666); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	// Set read-only mode after writing if requested
	if readOnly {
		if err := m.setReadOnlyMode(); err != nil {
			return fmt.Errorf("failed to set read-only mode: %w", err)
		}
	}

	return nil
}

// ensureWritePermissions ensures the file is writable
func (m *Manager) ensureWritePermissions() error {
	if _, err := os.Stat(m.configPath); err != nil {
		if os.IsNotExist(err) {
			return nil // File doesn't exist yet, no need to modify permissions
		}
		return err
	}

	if platform.IsWindows() {
		// Use attrib to remove read-only attribute on Windows
		cmd := exec.Command("attrib", "-R", m.configPath)
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to remove read-only attribute: %w", err)
		}
		return nil
	}

	// Unix systems
	return os.Chmod(m.configPath, 0666)
}

// setReadOnlyMode sets the file to read-only
func (m *Manager) setReadOnlyMode() error {
	if platform.IsWindows() {
		// Use attrib to set read-only attribute on Windows
		cmd := exec.Command("attrib", "+R", m.configPath)
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to set read-only attribute: %w", err)
		}
		return nil
	}

	// Unix systems
	return os.Chmod(m.configPath, 0444)
}
