package main

import (
	"log/slog"
	"os"
)

// EXIT(1) if err != nil
func ExitIfNil(err error, msg string) {
	if err != nil {
		slog.Error("%s: %v", msg, err)
		os.Exit(1)
	}
}
