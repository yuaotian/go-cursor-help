package platform

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// PrivilegeHandler manages privilege-related operations
type PrivilegeHandler struct {
	logger Logger
}

// Logger interface for dependency injection
type Logger interface {
	Error(args ...interface{})
}

// NewPrivilegeHandler creates a new privilege handler
func NewPrivilegeHandler(logger Logger) *PrivilegeHandler {
	return &PrivilegeHandler{logger: logger}
}

// ElevatePrivileges ensures the process has admin privileges
func (h *PrivilegeHandler) ElevatePrivileges() error {
	isAdmin, err := CheckAdminPrivileges()
	if err != nil {
		h.logger.Error(err)
		return err
	}

	if !isAdmin {
		if IsWindows() {
			return h.elevateWindowsPrivileges()
		}
		return fmt.Errorf("insufficient privileges: please run with sudo")
	}
	return nil
}

// elevateWindowsPrivileges handles Windows-specific privilege elevation
func (h *PrivilegeHandler) elevateWindowsPrivileges() error {
	os.Setenv("AUTOMATED_MODE", "1")
	exe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get executable path: %w", err)
	}

	cwd, _ := os.Getwd()
	args := strings.Join(os.Args[1:], " ")
	cmd := exec.Command("cmd", "/C", "start", "runas", exe, args)
	cmd.Dir = cwd
	return cmd.Run()
}

// ElevateSudo elevates privileges using sudo on Unix systems
func (h *PrivilegeHandler) ElevateSudo() error {
	exe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get executable path: %w", err)
	}

	cmd := exec.Command("sudo", append([]string{exe}, os.Args[1:]...)...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
