package idgen

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"strings"
	"sync"
)

// Generator handles secure ID generation for machines and devices
type Generator struct {
	bufferPool sync.Pool
}

// NewGenerator creates a new ID generator
func NewGenerator() *Generator {
	return &Generator{
		bufferPool: sync.Pool{
			New: func() interface{} {
				return make([]byte, 64)
			},
		},
	}
}

const (
	machineIDPrefix = "auth0|user_"
	uuidFormat      = "%s-%s-%s-%s-%s"
	hexChars        = "0123456789abcdef"
)

// generateRandomHex generates a random hex string of specified length
func (g *Generator) generateRandomHex(length int) (string, error) {
	buffer := g.bufferPool.Get().([]byte)
	defer g.bufferPool.Put(buffer)

	// Clear the buffer to avoid leaking previous data
	for i := range buffer {
		buffer[i] = 0
	}

	// We need length/2 bytes to generate length hex chars
	if _, err := rand.Read(buffer[:length/2]); err != nil {
		return "", fmt.Errorf("failed to generate random bytes: %w", err)
	}

	// Use the buffer directly for hex encoding
	dst := make([]byte, length)
	hex.Encode(dst, buffer[:length/2])
	return string(dst), nil
}

// GenerateMachineID generates a new machine ID with auth0|user_ prefix
func (g *Generator) GenerateMachineID() (string, error) {
	hex, err := g.generateRandomHex(64)
	if err != nil {
		return "", err
	}
	return machineIDPrefix + hex, nil
}

// GenerateMacMachineID generates a new 64-byte MAC machine ID
func (g *Generator) GenerateMacMachineID() (string, error) {
	return g.generateRandomHex(64)
}

// GenerateDeviceID generates a new device ID in UUID v4 format
func (g *Generator) GenerateDeviceID() (string, error) {
	hex, err := g.generateRandomHex(32)
	if err != nil {
		return "", err
	}

	uuid := []byte(hex)
	uuid[12] = '4' // Version 4

	// Set variant 1 (8,9,a,b)
	variant := make([]byte, 1)
	if _, err := rand.Read(variant); err != nil {
		return "", fmt.Errorf("failed to generate UUID variant: %w", err)
	}
	uuid[16] = hexChars[variant[0]%4+8]

	return fmt.Sprintf(uuidFormat,
		string(uuid[0:8]),
		string(uuid[8:12]),
		string(uuid[12:16]),
		string(uuid[16:20]),
		string(uuid[20:32])), nil
}

// ValidateID validates the format of various ID types
func (g *Generator) ValidateID(id string, idType string) bool {
	switch idType {
	case "machineID":
		if !strings.HasPrefix(id, machineIDPrefix) {
			return false
		}
		return isHexString(id[len(machineIDPrefix):])
	case "macMachineID":
		return len(id) == 64 && isHexString(id)
	case "deviceID":
		return isValidUUID(id)
	default:
		return false
	}
}

// Helper functions
func isHexString(s string) bool {
	_, err := hex.DecodeString(s)
	return err == nil
}

func isValidUUID(uuid string) bool {
	if len(uuid) != 36 {
		return false
	}

	for i, r := range uuid {
		if i == 8 || i == 13 || i == 18 || i == 23 {
			if r != '-' {
				return false
			}
			continue
		}
		if !strings.ContainsRune(hexChars, r) {
			return false
		}
	}
	return true
}
