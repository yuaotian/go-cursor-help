package ui

import (
	"fmt"
	"os"
	"strings"

	"github.com/fatih/color"
)

// Display handles UI operations for terminal output
type Display struct {
	spinner *Spinner
	green   *color.Color
	cyan    *color.Color
	red     *color.Color
	yellow  *color.Color
}

// NewDisplay creates a new display instance with an optional spinner.
// If spinner is nil, a default spinner will be created.
func NewDisplay(spinner *Spinner) *Display {
	if spinner == nil {
		spinner = NewSpinner(nil)
	}
	return &Display{
		spinner: spinner,
		green:   color.New(color.FgGreen),
		cyan:    color.New(color.FgCyan),
		red:     color.New(color.FgRed),
		yellow:  color.New(color.FgYellow),
	}
}

// ShowProgress displays a progress message with a spinner.
// The spinner will continue until StopProgress is called.
func (d *Display) ShowProgress(message string) {
	if message == "" {
		message = "Processing..."
	}
	d.spinner.SetMessage(message)
	d.spinner.Start()
}

// StopProgress stops the progress spinner.
// This should be called after ShowProgress to ensure proper cleanup.
func (d *Display) StopProgress() {
	d.spinner.Stop()
}

// ShowSuccess displays success messages in green.
// Each message is printed on a new line.
func (d *Display) ShowSuccess(messages ...string) error {
	for _, msg := range messages {
		if _, err := d.green.Println(msg); err != nil {
			return fmt.Errorf("failed to display success message: %w", err)
		}
	}
	return nil
}

// ShowInfo displays an info message in cyan.
// Returns an error if the message cannot be displayed.
func (d *Display) ShowInfo(message string) error {
	_, err := d.cyan.Println(message)
	if err != nil {
		return fmt.Errorf("failed to display info message: %w", err)
	}
	return nil
}

// ShowError displays an error message in red.
// Returns an error if the message cannot be displayed.
func (d *Display) ShowError(message string) error {
	_, err := d.red.Println(message)
	if err != nil {
		return fmt.Errorf("failed to display error message: %w", err)
	}
	return nil
}

// ShowPrivilegeError displays privilege error messages with instructions.
// The first message is displayed in bold red, followed by instructions in yellow.
// Returns an error if any message cannot be displayed.
func (d *Display) ShowPrivilegeError(messages ...string) error {
	if len(messages) == 0 {
		return fmt.Errorf("no messages provided for privilege error")
	}

	d.red.Add(color.Bold)
	if _, err := d.red.Println(messages[0]); err != nil {
		return fmt.Errorf("failed to display primary error message: %w", err)
	}
	fmt.Println()

	for _, msg := range messages[1:] {
		if strings.Contains(msg, "%s") {
			exe, err := os.Executable()
			if err != nil {
				return fmt.Errorf("failed to get executable path: %w", err)
			}
			if _, err := d.yellow.Printf(msg+"\n", exe); err != nil {
				return fmt.Errorf("failed to display instruction message: %w", err)
			}
		} else {
			if _, err := d.yellow.Println(msg); err != nil {
				return fmt.Errorf("failed to display instruction message: %w", err)
			}
		}
	}
	d.red.Add(color.Reset)
	return nil
}

// ShowLogo displays the application logo.
// Returns an error if the logo cannot be displayed.
func (d *Display) ShowLogo() error {
	_, err := d.cyan.Print(cyberpunkLogo)
	if err != nil {
		return fmt.Errorf("failed to display logo: %w", err)
	}
	return nil
}
