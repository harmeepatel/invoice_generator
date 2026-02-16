package main

import (
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/andybalholm/brotli"
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

func setupLogging() {
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

	// Initialize the GLOBAL logger
	Logger = log.NewWithOptions(logFile,
		log.Options{
			ReportCaller:    true,
			ReportTimestamp: true,
			TimeFormat:      "02 15:04:05.000000000",
		},
	)

	fmt.Printf("Logging to: %s\n", logFilePath)
	Logger.Info("--------------------------------INIT---------------------------------")
}

func init() {
	setupLogging()

	// compress static assets with brotli
	staticDir := "src/web/static"
	filepath.WalkDir(staticDir, func(path string, info fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if info.Type().IsDir() || strings.HasSuffix(info.Name(), ".br") {
			Logger.Warn("Skipping Compression...")
			return nil
		}

		var compressFileBrotliIfNotExist = func(src string, quality int) error {
			_, err := os.Stat(src + ".br")
			if !errors.Is(err, os.ErrNotExist) {
				return nil
			}

			in, err := os.Open(src)
			if err != nil {
				return err
			}
			defer in.Close()

			out, err := os.Create(src + ".br")
			if err != nil {
				return err
			}
			defer out.Close()

			bw := brotli.NewWriterLevel(out, quality)
			defer bw.Close()
			Logger.Info("Compressed Static Files...")

			_, err = io.Copy(bw, in)
			return err
		}

		abs, err := filepath.Abs(path)
		if err != nil {
			return err
		}

		compressFileBrotliIfNotExist(abs, brotli.BestCompression)
		return nil
	})
}
