package main

import (
	"errors"
	"io"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/andybalholm/brotli"
)

func init() {
	// compress static assets with brotli
	slog.Info("Compressing static files...")
	staticDir := "src/web/static"
	filepath.WalkDir(staticDir, func(path string, info fs.DirEntry, err error) error {
		if err != nil {
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

			_, err = io.Copy(bw, in)
			return err
		}

		if info.Type().IsDir() || strings.HasSuffix(info.Name(), ".br") {
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
