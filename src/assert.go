package main

import (
	"os"
)

// EXIT(1) if err != nil
func ExitIfNil(err error, msg string) {
	if err != nil {
		Logger.Error("%s: %v", msg, err)
		os.Exit(1)
	}
}
