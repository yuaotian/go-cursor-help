package ui

import (
	"fmt"
	"sync"
	"time"

	"github.com/fatih/color"
)

// SpinnerConfig defines spinner configuration
type SpinnerConfig struct {
	Frames []string        // Animation frames for the spinner
	Delay  time.Duration   // Delay between frame updates
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
	stopCh  chan struct{}
	mu      sync.RWMutex
}

// NewSpinner creates a new spinner with the given configuration
func NewSpinner(config *SpinnerConfig) *Spinner {
	if config == nil {
		config = DefaultSpinnerConfig()
	}
	return &Spinner{
		config: config,
		stopCh: make(chan struct{}),
	}
}

// State management

// SetMessage sets the spinner message
func (s *Spinner) SetMessage(message string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.message = message
}

// IsActive returns whether the spinner is currently active
func (s *Spinner) IsActive() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.active
}

// Control methods

// Start begins the spinner animation
func (s *Spinner) Start() {
	s.mu.Lock()
	if s.active {
		s.mu.Unlock()
		return
	}
	s.active = true
	s.mu.Unlock()

	go s.run()
}

// Stop halts the spinner animation
func (s *Spinner) Stop() {
	s.mu.Lock()
	defer s.mu.Unlock()

	if !s.active {
		return
	}

	s.active = false
	close(s.stopCh)
	s.stopCh = make(chan struct{})
	fmt.Print("\r") // Clear the spinner line
}

// Internal methods

func (s *Spinner) run() {
	ticker := time.NewTicker(s.config.Delay)
	defer ticker.Stop()

	cyan := color.New(color.FgCyan, color.Bold)
	message := s.message

	// Print initial state
	fmt.Printf("\r %s %s", cyan.Sprint(s.config.Frames[0]), message)

	for {
		select {
		case <-s.stopCh:
			return
		case <-ticker.C:
			s.mu.RLock()
			if !s.active {
				s.mu.RUnlock()
				return
			}
			frame := s.config.Frames[s.current%len(s.config.Frames)]
			s.current++
			s.mu.RUnlock()

			fmt.Printf("\r %s", cyan.Sprint(frame))
			fmt.Printf("\033[%dG%s", 4, message) // Move cursor and print message
		}
	}
}
