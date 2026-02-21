package logger

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/charmbracelet/log"
)

var Logger *log.Logger

func getLogDir() string {
	var logDir string
	const programName = "ae_invoice"

	switch runtime.GOOS {
	case "windows":
		programData := os.Getenv("PROGRAMDATA")
		if programData == "" {
			programData = "C:\\ProgramData"
		}
		logDir = filepath.Join(programData, programName, "logs")

	case "darwin":
		if os.Geteuid() == 0 {
			logDir = "/Library/Logs/" + programName
		} else {
			homeDir, err := os.UserHomeDir()
			if err != nil {
				panic(err)
			}
			logDir = filepath.Join(homeDir, "Library", "Logs", programName)
		}

	case "linux":
		if os.Geteuid() == 0 {
			logDir = "/var/log/" + programName
		} else {
			stateDir := os.Getenv("XDG_STATE_HOME")
			if stateDir == "" {
				homeDir, err := os.UserHomeDir()
				if err != nil {
					panic(err)
				}
				stateDir = filepath.Join(homeDir, ".local", "state")
			}
			logDir = filepath.Join(stateDir, programName, "logs")
		}

	default:
		panic(fmt.Sprintf("unsupported platform: %s", runtime.GOOS))
	}

	return logDir
}

func SetupLogger() {
	logDir := getLogDir()

	err := os.MkdirAll(logDir, 0755)
	if err != nil {
		panic(fmt.Sprintf("error creating log directory: %v", err))
	}

	logFileName := strings.ReplaceAll(fmt.Sprintf("%d_%s.log", time.Now().Year(), time.Now().Month()), " ", "_")
	logFilePath := filepath.Join(logDir, logFileName)

	// Open log file - DON'T close it, it needs to stay open for the lifetime of the program
	logFile, err := os.OpenFile(logFilePath, os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0644)
	if err != nil {
		panic(fmt.Sprintf("failed to open log file: %v", err))
	}

	// Initialize the GLOBAL Logger
	Logger = log.NewWithOptions(logFile,
		log.Options{
			ReportCaller:    true,
			ReportTimestamp: true,
			TimeFormat:      "02 15:04:05.000000000",
		},
	)

	fmt.Printf("Logging to: %s\n", logFilePath)
	Logger.Info("--------------------------------Æ---------------------------------")
}
