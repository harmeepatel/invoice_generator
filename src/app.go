package main

import (
	"ae_invoice/src/logger"
	"errors"
	"net/http"
	"os"
)

type App struct {
	server *http.Server
	// db      *bun.DB
}

func NewApp() *App {
	srv := &http.Server{
		Addr:    PORT,
		Handler: newRouter(),
	}

	return &App{server: srv}
}

func (a *App) RunApp() {
	logger.Logger.Info("link : localhost" + a.server.Addr)
	// log.Info("pid  : " + strconv.Itoa(os.Getpid()))

	// run server
	if err := http.ListenAndServe(a.server.Addr, a.server.Handler); !errors.Is(err, http.ErrServerClosed) {
		// log.Error("HTTP server error: " + err.Error())
		os.Exit(1)
	}
}
