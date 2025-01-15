package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/yuaotian/go-cursor-help/internal/config"
	"github.com/yuaotian/go-cursor-help/internal/errors"
	"github.com/yuaotian/go-cursor-help/internal/lang"
	"github.com/yuaotian/go-cursor-help/internal/platform"
	"github.com/yuaotian/go-cursor-help/internal/process"
	"github.com/yuaotian/go-cursor-help/internal/ui"
	"github.com/yuaotian/go-cursor-help/pkg/idgen"

	"github.com/sirupsen/logrus"
)

var (
	version     = "dev"
	setReadOnly = flag.Bool("r", false, "set storage.json to read-only mode")
	showVersion = flag.Bool("v", false, "show version information")
	log         = logrus.New()
)

func main() {
	errorHandler := errors.NewHandler(log)
	defer errorHandler.HandlePanic(waitForEnter)

	if *showVersion {
		fmt.Printf("Cursor ID Modifier v%s\n", version)
		os.Exit(0)
	}

	setupLogger()

	username, err := platform.GetCurrentUser()
	if err != nil {
		errorHandler.LogFatal(err, "Failed to get current user", waitForEnter)
	}

	display := ui.NewDisplay(nil)
	configManager := initConfigManager(username)
	generator := idgen.NewGenerator()
	processManager := process.NewManager(nil, log)

	if err := ensureAdminPrivileges(display); err != nil {
		return
	}

	setupDisplay(display)

	if err := processManager.HandleCursorProcesses(); err != nil {
		display.ShowError("Failed to close Cursor. Please close it manually and try again.")
		waitForEnter()
		return
	}

	if err := updateConfiguration(display, configManager, generator, lang.GetText()); err != nil {
		return
	}

	showCompletionMessages(display)

	if os.Getenv("AUTOMATED_MODE") != "1" {
		waitForEnter()
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

func initConfigManager(username string) *config.Manager {
	configManager, err := config.NewManager(username)
	if err != nil {
		log.Fatal(err)
	}
	return configManager
}

func ensureAdminPrivileges(display *ui.Display) error {
	isAdmin, err := platform.CheckAdminPrivileges()
	if err != nil {
		log.Error(err)
		waitForEnter()
		return err
	}

	if isAdmin {
		return nil
	}

	if platform.IsWindows() {
		return elevateWindowsPrivileges(display)
	}

	display.ShowPrivilegeError(
		lang.GetText().PrivilegeError,
		lang.GetText().RunWithSudo,
		lang.GetText().SudoExample,
	)
	waitForEnter()
	return fmt.Errorf("insufficient privileges")
}

func elevateWindowsPrivileges(display *ui.Display) error {
	fmt.Println(getPrivilegeMessage())

	if err := selfElevate(); err != nil {
		log.Error(err)
		display.ShowPrivilegeError(
			lang.GetText().PrivilegeError,
			lang.GetText().RunAsAdmin,
			lang.GetText().RunWithSudo,
			lang.GetText().SudoExample,
		)
		waitForEnter()
		return err
	}
	return nil
}

func getPrivilegeMessage() string {
	if lang.GetCurrentLanguage() == lang.CN {
		return "\n请求管理员权限..."
	}
	return "\nRequesting administrator privileges..."
}

func setupDisplay(display *ui.Display) {
	if err := platform.ClearScreen(); err != nil {
		log.Warn("Failed to clear screen:", err)
	}
	display.ShowLogo()
	fmt.Println()
}

func showIdComparison(display *ui.Display, oldConfig, newConfig *config.StorageConfig) {
	fmt.Println("\n[Original IDs / 原始 ID]")
	if oldConfig != nil {
		display.ShowInfo(fmt.Sprintf("Machine ID: %s", oldConfig.TelemetryMachineId))
		display.ShowInfo(fmt.Sprintf("Mac Machine ID: %s", oldConfig.TelemetryMacMachineId))
		display.ShowInfo(fmt.Sprintf("Dev Device ID: %s", oldConfig.TelemetryDevDeviceId))
	} else {
		display.ShowInfo("No previous configuration found / 未找到先前配置")
	}

	fmt.Println("\n[Newly Generated IDs / 新生成 ID]")
	display.ShowInfo(fmt.Sprintf("Machine ID: %s", newConfig.TelemetryMachineId))
	display.ShowInfo(fmt.Sprintf("Mac Machine ID: %s", newConfig.TelemetryMacMachineId))
	display.ShowInfo(fmt.Sprintf("Dev Device ID: %s", newConfig.TelemetryDevDeviceId))
	fmt.Println()
}

func updateConfiguration(display *ui.Display, configManager *config.Manager, generator *idgen.Generator, text lang.TextResource) error {
	oldConfig := readExistingConfig(display, configManager, text)
	newConfig := generateNewConfig(display, generator, text)

	showIdComparison(display, oldConfig, newConfig)

	display.ShowProgress("Saving configuration...")
	if err := configManager.SaveConfig(newConfig, *setReadOnly); err != nil {
		log.Error(err)
		waitForEnter()
		return err
	}
	display.StopProgress()
	fmt.Println()
	return nil
}

func readExistingConfig(display *ui.Display, configManager *config.Manager, text lang.TextResource) *config.StorageConfig {
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

func generateNewConfig(display *ui.Display, generator *idgen.Generator, text lang.TextResource) *config.StorageConfig {
	display.ShowProgress(text.GeneratingIds)
	newConfig := &config.StorageConfig{}

	generateID := func(genFn func() (string, error), field *string, idType string) {
		id, err := genFn()
		if err != nil {
			log.Fatalf("Failed to generate %s: %v", idType, err)
		}
		*field = id
	}

	generateID(generator.GenerateMachineID, &newConfig.TelemetryMachineId, "machine ID")
	generateID(generator.GenerateMacMachineID, &newConfig.TelemetryMacMachineId, "MAC machine ID")
	generateID(generator.GenerateDeviceID, &newConfig.TelemetryDevDeviceId, "device ID")

	display.StopProgress()
	fmt.Println()
	return newConfig
}

func showCompletionMessages(display *ui.Display) {
	text := lang.GetText()
	display.ShowSuccess(text.SuccessMessage, text.RestartMessage)
	fmt.Println()

	message := "Operation completed!"
	if lang.GetCurrentLanguage() == lang.CN {
		message = "操作完成！"
	}
	display.ShowInfo(message)

	if platform.IsLinux() {
		fmt.Println()
		if lang.GetCurrentLanguage() == lang.CN {
			display.ShowInfo("请手动重启 Cursor。")
		} else {
			display.ShowInfo("Please restart Cursor manually.")
		}
	}
}

func waitForEnter() {
	fmt.Print(lang.GetText().PressEnterToExit)
	os.Stdout.Sync()
	bufio.NewReader(os.Stdin).ReadString('\n')
}

func selfElevate() error {
	os.Setenv("AUTOMATED_MODE", "1")
	exe, err := os.Executable()
	if err != nil {
		return err
	}

	if platform.IsWindows() {
		cwd, _ := os.Getwd()
		args := strings.Join(os.Args[1:], " ")
		// Create a batch file to run the elevated command and pause
		batchFile := filepath.Join(os.TempDir(), "cursor_elevate.bat")
		batchContent := fmt.Sprintf(`@echo off
echo Elevating privileges...
powershell -Command "Start-Process '%s' -ArgumentList '%s' -Verb RunAs -Wait"
if %%ERRORLEVEL%% neq 0 (
    echo Failed to elevate privileges
    pause
    exit /b 1
)
`, exe, args)

		if err := os.WriteFile(batchFile, []byte(batchContent), 0700); err != nil {
			return fmt.Errorf("failed to create batch file: %w", err)
		}
		defer os.Remove(batchFile)

		cmd := exec.Command("cmd", "/C", batchFile)
		cmd.Dir = cwd
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}

	cmd := exec.Command("sudo", append([]string{exe}, os.Args[1:]...)...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
