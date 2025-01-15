package errors

import (
	"fmt"
	"runtime/debug"

	"github.com/sirupsen/logrus"
)

// Handler provides centralized error handling
type Handler struct {
	log *logrus.Logger
}

// NewHandler creates a new error handler
func NewHandler(log *logrus.Logger) *Handler {
	if log == nil {
		log = logrus.New()
	}
	return &Handler{log: log}
}

// HandlePanic recovers from panics and logs them
func (h *Handler) HandlePanic(onPanic func()) {
	if r := recover(); r != nil {
		h.log.Errorf("Panic recovered: %v\n", r)
		debug.PrintStack()
		if onPanic != nil {
			onPanic()
		}
	}
}

// LogAndReturn logs an error and returns it
func (h *Handler) LogAndReturn(err error, msg string) error {
	if err != nil {
		h.log.Errorf("%s: %v", msg, err)
	}
	return fmt.Errorf("%s: %w", msg, err)
}

// LogFatal logs a fatal error and calls the provided callback
func (h *Handler) LogFatal(err error, msg string, onFatal func()) {
	if err != nil {
		h.log.Fatalf("%s: %v", msg, err)
		if onFatal != nil {
			onFatal()
		}
	}
}
