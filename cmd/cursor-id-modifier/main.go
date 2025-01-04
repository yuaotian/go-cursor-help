package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"runtime"
	"runtime/debug"
	"strings"

	"github.com/yuaotian/go-cursor-help/internal/config"
	"github.com/yuaotian/go-cursor-help/internal/lang"
	"github.com/yuaotian/go-cursor-help/internal/process"
	"github.com/yuaotian/go-cursor-help/internal/ui"
	"github.com/yuaotian/go-cursor-help/pkg/idgen"

	"github.com/sirupsen/logrus"
)

// Global variables
var (
	version     = "dev"
	setReadOnly = flag.Bool("r", false, "set storage.json to read-only mode")
	showVersion = flag.Bool("v", false, "show version information")
	log         = logrus.New()
)

func main() {
	setupErrorRecovery()
	handleFlags()
	setupLogger()

	username := getCurrentUser()
	log.Debug("Running as user:", username)

	// Initialize components
	display := ui.NewDisplay(nil)
	configManager := initConfigManager(username)
	generator := idgen.NewGenerator()
	processManager := process.NewManager(nil, log)

	// Check and handle privileges
	if err := handlePrivileges(display); err != nil {
		return
	}

	// Setup display
	setupDisplay(display)

	text := lang.GetText()

	// Handle Cursor processes
	if err := handleCursorProcesses(display, processManager); err != nil {
		return
	}

	// Handle configuration
	oldConfig := readExistingConfig(display, configManager, text)
	newConfig := generateNewConfig(display, generator, oldConfig, text)

	if err := saveConfiguration(display, configManager, newConfig); err != nil {
		return
	}

	// Show completion messages
	showCompletionMessages(display)

	if os.Getenv("AUTOMATED_MODE") != "1" {
		waitExit()
	}
}

func setupErrorRecovery() {
	defer func() {
		if r := recover(); r != nil {
			log.Errorf("Panic recovered: %v\n", r)
			debug.PrintStack()
			waitExit()
		}
	}()
}

func handleFlags() {
	flag.Parse()
	if *showVersion {
		fmt.Printf("Cursor ID Modifier v%s\n", version)
		os.Exit(0)
	}
}

func setupLogger() {
	log.SetFormatter(&logrus.TextFormatter{
		FullTimestamp:          true,
		DisableLevelTruncation: true,
		PadLevelText:           true,
	})
	log.SetLevel(logrus.InfoLevel)
}

func getCurrentUser() string {
	if username := os.Getenv("SUDO_USER"); username != "" {
		return username
	}

	user, err := user.Current()
	if err != nil {
		log.Fatal(err)
	}
	return user.Username
}

func initConfigManager(username string) *config.Manager {
	configManager, err := config.NewManager(username)
	if err != nil {
		log.Fatal(err)
	}
	return configManager
}

func handlePrivileges(display *ui.Display) error {
	isAdmin, err := checkAdminPrivileges()
	if err != nil {
		log.Error(err)
		waitExit()
		return err
	}

	if !isAdmin {
		if runtime.GOOS == "windows" {
			return handleWindowsPrivileges(display)
		}
		display.ShowPrivilegeError(
			lang.GetText().PrivilegeError,
			lang.GetText().RunWithSudo,
			lang.GetText().SudoExample,
		)
		waitExit()
		return fmt.Errorf("insufficient privileges")
	}
	return nil
}

func handleWindowsPrivileges(display *ui.Display) error {
	message := "\nRequesting administrator privileges..."
	if lang.GetCurrentLanguage() == lang.CN {
		message = "\n请求管理员权限..."
	}
	fmt.Println(message)

	if err := selfElevate(); err != nil {
		log.Error(err)
		display.ShowPrivilegeError(
			lang.GetText().PrivilegeError,
			lang.GetText().RunAsAdmin,
			lang.GetText().RunWithSudo,
			lang.GetText().SudoExample,
		)
		waitExit()
		return err
	}
	return nil
}

func setupDisplay(display *ui.Display) {
	if err := display.ClearScreen(); err != nil {
		log.Warn("Failed to clear screen:", err)
	}
	display.ShowLogo()
	fmt.Println()
}

func handleCursorProcesses(display *ui.Display, processManager *process.Manager) error {
	if os.Getenv("AUTOMATED_MODE") == "1" {
		log.Debug("Running in automated mode, skipping Cursor process closing")
		return nil
	}

	display.ShowProgress("Closing Cursor...")
	log.Debug("Attempting to close Cursor processes")

	if err := processManager.KillCursorProcesses(); err != nil {
		log.Error("Failed to close Cursor:", err)
		display.StopProgress()
		display.ShowError("Failed to close Cursor. Please close it manually and try again.")
		waitExit()
		return err
	}

	if processManager.IsCursorRunning() {
		log.Error("Cursor processes still detected after closing")
		display.StopProgress()
		display.ShowError("Failed to close Cursor completely. Please close it manually and try again.")
		waitExit()
		return fmt.Errorf("cursor still running")
	}

	log.Debug("Successfully closed all Cursor processes")
	display.StopProgress()
	fmt.Println()
	return nil
}

func readExistingConfig(display *ui.Display, configManager *config.Manager, text lang.TextResource) *config.StorageConfig {
	fmt.Println()
	display.ShowProgress(text.ReadingConfig)
	oldConfig, err := configManager.ReadConfig()
	if err != nil {
		log.Warn("Failed to read existing config:", err)
		oldConfig = nil
	}
	display.StopProgress()
	fmt.Println()
	return oldConfig
}

func generateNewConfig(display *ui.Display, generator *idgen.Generator, oldConfig *config.StorageConfig, text lang.TextResource) *config.StorageConfig {
	display.ShowProgress(text.GeneratingIds)
	newConfig := &config.StorageConfig{}

	if machineID, err := generator.GenerateMachineID(); err != nil {
		log.Fatal("Failed to generate machine ID:", err)
	} else {
		newConfig.TelemetryMachineId = machineID
	}

	if macMachineID, err := generator.GenerateMacMachineID(); err != nil {
		log.Fatal("Failed to generate MAC machine ID:", err)
	} else {
		newConfig.TelemetryMacMachineId = macMachineID
	}

	if deviceID, err := generator.GenerateDeviceID(); err != nil {
		log.Fatal("Failed to generate device ID:", err)
	} else {
		newConfig.TelemetryDevDeviceId = deviceID
	}

	if oldConfig != nil && oldConfig.TelemetrySqmId != "" {
		newConfig.TelemetrySqmId = oldConfig.TelemetrySqmId
	} else if sqmID, err := generator.GenerateSQMID(); err != nil {
		log.Fatal("Failed to generate SQM ID:", err)
	} else {
		newConfig.TelemetrySqmId = sqmID
	}

	display.StopProgress()
	fmt.Println()
	return newConfig
}

func saveConfiguration(display *ui.Display, configManager *config.Manager, newConfig *config.StorageConfig) error {
	display.ShowProgress("Saving configuration...")
	if err := configManager.SaveConfig(newConfig, *setReadOnly); err != nil {
		log.Error(err)
		waitExit()
		return err
	}
	display.StopProgress()
	fmt.Println()
	return nil
}

func showCompletionMessages(display *ui.Display) {
	display.ShowSuccess(lang.GetText().SuccessMessage, lang.GetText().RestartMessage)
	fmt.Println()

	message := "Operation completed!"
	if lang.GetCurrentLanguage() == lang.CN {
		message = "操作完成！"
	}
	display.ShowInfo(message)
}

func waitExit() {
	fmt.Print(lang.GetText().PressEnterToExit)
	os.Stdout.Sync()
	bufio.NewReader(os.Stdin).ReadString('\n')
}

func checkAdminPrivileges() (bool, error) {
	switch runtime.GOOS {
	case "windows":
		cmd := exec.Command("net", "session")
		return cmd.Run() == nil, nil

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

func selfElevate() error {
	os.Setenv("AUTOMATED_MODE", "1")

	switch runtime.GOOS {
	case "windows":
		verb := "runas"
		exe, _ := os.Executable()
		cwd, _ := os.Getwd()
		args := strings.Join(os.Args[1:], " ")

		cmd := exec.Command("cmd", "/C", "start", verb, exe, args)
		cmd.Dir = cwd
		return cmd.Run()

	case "darwin", "linux":
		exe, err := os.Executable()
		if err != nil {
			return err
		}

		cmd := exec.Command("sudo", append([]string{exe}, os.Args[1:]...)...)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()

	default:
		return fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
}
