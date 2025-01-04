package idgen

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
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

// Constants for ID generation
const (
	machineIDPrefix = "auth0|user_"
	uuidFormat      = "%s-%s-%s-%s-%s"
)

// generateRandomHex generates a random hex string of specified length
func (g *Generator) generateRandomHex(length int) (string, error) {
	buffer := g.bufferPool.Get().([]byte)
	defer g.bufferPool.Put(buffer)

	if _, err := rand.Read(buffer[:length]); err != nil {
		return "", fmt.Errorf("failed to generate random bytes: %w", err)
	}
	return hex.EncodeToString(buffer[:length]), nil
}

// GenerateMachineID generates a new machine ID with auth0|user_ prefix
func (g *Generator) GenerateMachineID() (string, error) {
	randomPart, err := g.generateRandomHex(32) // 生成64字符的十六进制
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("%x%s", []byte(machineIDPrefix), randomPart), nil
}

// GenerateMacMachineID generates a new 64-byte MAC machine ID
func (g *Generator) GenerateMacMachineID() (string, error) {
	return g.generateRandomHex(32) // 生成64字符的十六进制
}

// GenerateDeviceID generates a new device ID in UUID format
func (g *Generator) GenerateDeviceID() (string, error) {
	id, err := g.generateRandomHex(16)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf(uuidFormat,
		id[0:8], id[8:12], id[12:16], id[16:20], id[20:32]), nil
}

// GenerateSQMID generates a new SQM ID in UUID format (with braces)
func (g *Generator) GenerateSQMID() (string, error) {
	id, err := g.GenerateDeviceID()
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("{%s}", id), nil
}

// ValidateID validates the format of various ID types
func (g *Generator) ValidateID(id string, idType string) bool {
	switch idType {
	case "machineID", "macMachineID":
		return len(id) == 64 && isHexString(id)
	case "deviceID":
		return isValidUUID(id)
	case "sqmID":
		if len(id) < 2 || id[0] != '{' || id[len(id)-1] != '}' {
			return false
		}
		return isValidUUID(id[1 : len(id)-1])
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
		if !((r >= '0' && r <= '9') || (r >= 'a' && r <= 'f') || (r >= 'A' && r <= 'F')) {
			return false
		}
	}
	return true
}
