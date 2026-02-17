package main

import (
	"ae_invoice/src/logger"
	"os"
)

// EXIT(1) if err != nil
func ExitIfNil(err error, msg string) {
	if err != nil {
		logger.Logger.Error("%s: %v", msg, err)
		os.Exit(1)
	}
}
