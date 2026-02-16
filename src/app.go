package main

import (
	"errors"
	"net/http"
	"os"
	"strconv"
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
	Logger.Info("link : localhost" + a.server.Addr)
	Logger.Info("pid  : " + strconv.Itoa(os.Getpid()))

	// run server
	if err := http.ListenAndServe(a.server.Addr, a.server.Handler); !errors.Is(err, http.ErrServerClosed) {
		Logger.Error("HTTP server error: " + err.Error())
		os.Exit(1)
	}
}
