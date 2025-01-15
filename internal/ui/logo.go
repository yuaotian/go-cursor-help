package ui

import (
	"github.com/fatih/color"
)

// cyberpunkLogo is the ASCII art logo for the application.
// It uses Unicode box-drawing characters to create a stylized "CURSOR" text.
const cyberpunkLogo = `
   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
`

// LogoConfig holds configuration for logo display
type LogoConfig struct {
	// Color specifies the color to use for the logo
	Color *color.Color
	// DisableColor disables color output
	DisableColor bool
}

// DefaultLogoConfig returns the default logo configuration
func DefaultLogoConfig() *LogoConfig {
	return &LogoConfig{
		Color:        color.New(color.FgCyan, color.Bold),
		DisableColor: false,
	}
}

// RenderLogo returns the logo as a string with optional color formatting.
// If config is nil, default configuration will be used.
func RenderLogo(config *LogoConfig) string {
	if config == nil {
		config = DefaultLogoConfig()
	}

	if config.DisableColor {
		return cyberpunkLogo
	}

	if config.Color == nil {
		config.Color = DefaultLogoConfig().Color
	}

	return config.Color.Sprint(cyberpunkLogo)
}
