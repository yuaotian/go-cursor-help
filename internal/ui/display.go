package ui

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/fatih/color"
)

// Display handles UI operations for terminal output
type Display struct {
	spinner *Spinner
}

// NewDisplay creates a new display instance with an optional spinner
func NewDisplay(spinner *Spinner) *Display {
	if spinner == nil {
		spinner = NewSpinner(nil)
	}
	return &Display{spinner: spinner}
}

// Terminal Operations

// ClearScreen clears the terminal screen based on OS
func (d *Display) ClearScreen() error {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("cmd", "/c", "cls")
	default:
		cmd = exec.Command("clear")
	}
	cmd.Stdout = os.Stdout
	return cmd.Run()
}

// Progress Indicator

// ShowProgress displays a progress message with a spinner
func (d *Display) ShowProgress(message string) {
	d.spinner.SetMessage(message)
	d.spinner.Start()
}

// StopProgress stops the progress spinner
func (d *Display) StopProgress() {
	d.spinner.Stop()
}

// Message Display

// ShowSuccess displays success messages in green
func (d *Display) ShowSuccess(messages ...string) {
	green := color.New(color.FgGreen)
	for _, msg := range messages {
		green.Println(msg)
	}
}

// ShowInfo displays an info message in cyan
func (d *Display) ShowInfo(message string) {
	cyan := color.New(color.FgCyan)
	cyan.Println(message)
}

// ShowError displays an error message in red
func (d *Display) ShowError(message string) {
	red := color.New(color.FgRed)
	red.Println(message)
}

// ShowPrivilegeError displays privilege error messages with instructions
func (d *Display) ShowPrivilegeError(messages ...string) {
	red := color.New(color.FgRed, color.Bold)
	yellow := color.New(color.FgYellow)

	// Main error message
	red.Println(messages[0])
	fmt.Println()

	// Additional instructions
	for _, msg := range messages[1:] {
		if strings.Contains(msg, "%s") {
			exe, _ := os.Executable()
			yellow.Printf(msg+"\n", exe)
		} else {
			yellow.Println(msg)
		}
	}
}
