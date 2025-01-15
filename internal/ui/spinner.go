package ui

import (
	"fmt"
	"sync"
	"time"

	"github.com/fatih/color"
)

// SpinnerConfig defines spinner configuration
type SpinnerConfig struct {
	Frames []string      // Animation frames for the spinner
	Delay  time.Duration // Delay between frame updates
}

// DefaultSpinnerConfig returns the default spinner configuration
func DefaultSpinnerConfig() *SpinnerConfig {
	return &SpinnerConfig{
		Frames: []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
		Delay:  100 * time.Millisecond,
	}
}

// Spinner represents a progress spinner
type Spinner struct {
	config  *SpinnerConfig
	message string
	current int
	active  bool
	done    chan struct{}
	mu      sync.RWMutex
}

// NewSpinner creates a new spinner with the given configuration
func NewSpinner(config *SpinnerConfig) *Spinner {
	if config == nil {
		config = DefaultSpinnerConfig()
	}
	return &Spinner{
		config: config,
		done:   make(chan struct{}),
	}
}

// SetMessage sets the spinner message
func (s *Spinner) SetMessage(message string) {
	s.mu.Lock()
	s.message = message
	s.mu.Unlock()
}

// Start begins the spinner animation
func (s *Spinner) Start() {
	s.mu.Lock()
	if s.active {
		s.mu.Unlock()
		return
	}
	s.active = true
	s.mu.Unlock()

	go s.animate()
}

// Stop halts the spinner animation
func (s *Spinner) Stop() {
	s.mu.Lock()
	if !s.active {
		s.mu.Unlock()
		return
	}
	s.active = false
	close(s.done)
	s.done = make(chan struct{})
	message := s.message
	s.mu.Unlock()
	
	green := color.New(color.FgGreen, color.Bold)
	fmt.Printf("\r %s %s\n", green.Sprint("✓"), message) // Show green tick and message
}

func (s *Spinner) animate() {
	cyan := color.New(color.FgCyan, color.Bold)
	ticker := time.NewTicker(s.config.Delay)
	defer ticker.Stop()

	for {
		select {
		case <-s.done:
			return
		case <-ticker.C:
			s.mu.RLock()
			if !s.active {
				s.mu.RUnlock()
				return
			}
			frame := s.config.Frames[s.current%len(s.config.Frames)]
			s.current++
			message := s.message
			s.mu.RUnlock()

			fmt.Printf("\r %s %s", cyan.Sprint(frame), message)
		}
	}
}
