package platform

import (
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"runtime"
)

// GetConfigDir returns the OS-specific configuration directory for Cursor.
// The directory path is constructed based on the operating system:
// - Windows: %APPDATA%\Cursor\User\globalStorage
// - macOS: ~/Library/Application Support/Cursor/User/globalStorage
// - Linux: ~/.config/Cursor/User/globalStorage
// Parameters:
//   - username: The username to use for constructing the path
//
// Returns:
//   - string: The full path to the configuration directory
//   - error: An error if the OS is not supported or if there's a path construction error
func GetConfigDir(username string) (string, error) {
	switch runtime.GOOS {
	case "windows":
		return filepath.Join(os.Getenv("APPDATA"), "Cursor", "User", "globalStorage"), nil
	case "darwin":
		return filepath.Join("/Users", username, "Library", "Application Support", "Cursor", "User", "globalStorage"), nil
	case "linux":
		return filepath.Join("/home", username, ".config", "Cursor", "User", "globalStorage"), nil
	default:
		return "", fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
}

// ClearScreen clears the terminal screen using the appropriate command for the current OS.
// On Windows, it uses 'cls', while on Unix-based systems it uses 'clear'.
// Returns an error if the clear command fails to execute.
func ClearScreen() error {
	cmd := exec.Command("clear")
	if runtime.GOOS == "windows" {
		cmd = exec.Command("cmd", "/c", "cls")
	}
	cmd.Stdout = os.Stdout
	return cmd.Run()
}

// CheckAdminPrivileges verifies if the current process has administrator/root privileges.
// The check is performed differently based on the OS:
// - Windows: Attempts to access the session list (requires admin rights)
// - Unix: Checks if the effective user ID is 0 (root)
// Returns:
//   - bool: true if the process has admin privileges, false otherwise
//   - error: an error if the privilege check fails
func CheckAdminPrivileges() (bool, error) {
	switch runtime.GOOS {
	case "windows":
		return exec.Command("net", "session").Run() == nil, nil
	case "darwin", "linux":
		currentUser, err := user.Current()
		if err != nil {
			return false, fmt.Errorf("failed to get current user: %w", err)
		}
		return currentUser.Uid == "0", nil
	default:
		return false, fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
}

// GetCurrentUser retrieves the current user's username.
// It first checks for SUDO_USER environment variable to handle sudo cases,
// then falls back to the current user information from the OS.
// Returns:
//   - string: The username of the current user
//   - error: An error if user information cannot be retrieved
func GetCurrentUser() (string, error) {
	if username := os.Getenv("SUDO_USER"); username != "" {
		return username, nil
	}

	user, err := user.Current()
	if err != nil {
		return "", fmt.Errorf("failed to get current user: %w", err)
	}
	return user.Username, nil
}

// IsLinux returns true if the current operating system is Linux.
// This is a convenience function for platform-specific code paths.
func IsLinux() bool {
	return runtime.GOOS == "linux"
}

// IsWindows returns true if the current operating system is Windows.
// This is a convenience function for platform-specific code paths.
func IsWindows() bool {
	return runtime.GOOS == "windows"
}

// IsDarwin returns true if the current operating system is macOS (Darwin).
// This is a convenience function for platform-specific code paths.
func IsDarwin() bool {
	return runtime.GOOS == "darwin"
}
