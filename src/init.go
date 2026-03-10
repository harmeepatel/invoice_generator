package main

import (
	"ae_invoice/src/logger"
	"ae_invoice/src/util"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/andybalholm/brotli"
)

func generateDb() (string, error) {
	configDir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("Could not find user config dir: %w", err)
	}

	appDir := filepath.Join(configDir, "AE_invoice")

	err = os.MkdirAll(appDir, 0744)
	if err != nil {
		return "", fmt.Errorf("Could not create app directory: %w", err)
	}

	dbPath := filepath.Join(appDir, "ae.db")

	return dbPath, nil
}

func init() {
	dbPath, err := generateDb()
	util.DbPath = dbPath

	if err != nil {
		panic(err)
	}
	// compress static assets with brotli
	logger.SetupLogger()
	log := logger.Logger

	flag.BoolVar(&util.IsDev, "is-dev", true, "Bool: production level [DEV, PROD]")
	flag.Parse()

	staticDir := "src/web/static"

	// pass 1 - delete compressed files if last modified time is > 1sec
	log.Info(fmt.Sprintf("Pass 1 @ %v", staticDir))
	filepath.WalkDir(staticDir, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			fmt.Printf("WalkDir failed with err: %+v\n", err.Error())
			return err
		}

		if strings.HasSuffix(entry.Name(), ".br") {
			fileEntryInfo, err := entry.Info()
			if err != nil {
				return err
			}
			if time.Since(fileEntryInfo.ModTime()) < time.Second {
				log.Warn("Skipping Compression...")
				return nil
			}
			err = os.Remove(path)
			if err != nil {
				return err
			}
		}

		return nil
	})

	// pass 2 - only after removing stale files, recompress them
	log.Info(fmt.Sprintf("Pass 2 @ %v", staticDir))
	filepath.WalkDir(staticDir, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			fmt.Printf("WalkDir failed with err: %+v\n", err.Error())
			return err
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
			log.Info("Compressed Static Files...")

			_, err = io.Copy(bw, in)
			return err
		}

		if entry.Type().IsDir() {
			return nil
		}

		abs, err := filepath.Abs(path)
		if err != nil {
			return err
		}

		compressFileBrotliIfNotExist(abs, brotli.BestCompression)
		return nil
	})
}
