package main

import (
	"ae_invoice/src/logger"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/andybalholm/brotli"
)

func init() {
	// compress static assets with brotli
	logger.SetupLogger()
	log := logger.Logger

	staticDir := "src/web/static"

	// pass 1
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

	// pass 2
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
