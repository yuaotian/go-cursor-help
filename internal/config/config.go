package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"sync"
	"time"
)

// StorageConfig represents the storage configuration
type StorageConfig struct {
	TelemetryMacMachineId string `json:"telemetry.macMachineId"`
	TelemetryMachineId    string `json:"telemetry.machineId"`
	TelemetryDevDeviceId  string `json:"telemetry.devDeviceId"`
	TelemetrySqmId        string `json:"telemetry.sqmId"`
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
	configPath, err := getConfigPath(username)
	if err != nil {
		return nil, fmt.Errorf("failed to get config path: %w", err)
	}

	return &Manager{
		configPath: configPath,
	}, nil
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

	// Ensure parent directories exist
	if err := os.MkdirAll(filepath.Dir(m.configPath), 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	// Set file permissions
	if err := os.Chmod(m.configPath, 0666); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to set file permissions: %w", err)
	}

	// Read existing config to preserve other fields
	var originalFile map[string]interface{}
	originalFileContent, err := os.ReadFile(m.configPath)
	if err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to read original file: %w", err)
	} else if err == nil {
		if err := json.Unmarshal(originalFileContent, &originalFile); err != nil {
			return fmt.Errorf("failed to parse original file: %w", err)
		}
	} else {
		originalFile = make(map[string]interface{})
	}

	// Update fields
	originalFile["telemetry.sqmId"] = config.TelemetrySqmId
	originalFile["telemetry.macMachineId"] = config.TelemetryMacMachineId
	originalFile["telemetry.machineId"] = config.TelemetryMachineId
	originalFile["telemetry.devDeviceId"] = config.TelemetryDevDeviceId
	originalFile["lastModified"] = time.Now().UTC().Format(time.RFC3339)
	originalFile["version"] = "1.0.1"

	// Marshal with indentation
	newFileContent, err := json.MarshalIndent(originalFile, "", "    ")
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	// Write to temporary file
	tmpPath := m.configPath + ".tmp"
	if err := os.WriteFile(tmpPath, newFileContent, 0666); err != nil {
		return fmt.Errorf("failed to write temporary file: %w", err)
	}

	// Set final permissions
	fileMode := os.FileMode(0666)
	if readOnly {
		fileMode = 0444
	}

	if err := os.Chmod(tmpPath, fileMode); err != nil {
		os.Remove(tmpPath)
		return fmt.Errorf("failed to set temporary file permissions: %w", err)
	}

	// Atomic rename
	if err := os.Rename(tmpPath, m.configPath); err != nil {
		os.Remove(tmpPath)
		return fmt.Errorf("failed to rename file: %w", err)
	}

	// Sync directory
	if dir, err := os.Open(filepath.Dir(m.configPath)); err == nil {
		dir.Sync()
		dir.Close()
	}

	return nil
}

// getConfigPath returns the path to the configuration file
func getConfigPath(username string) (string, error) {
	var configDir string
	switch runtime.GOOS {
	case "windows":
		configDir = filepath.Join(os.Getenv("APPDATA"), "Cursor", "User", "globalStorage")
	case "darwin":
		configDir = filepath.Join("/Users", username, "Library", "Application Support", "Cursor", "User", "globalStorage")
	case "linux":
		configDir = filepath.Join("/home", username, ".config", "Cursor", "User", "globalStorage")
	default:
		return "", fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
	return filepath.Join(configDir, "storage.json"), nil
}