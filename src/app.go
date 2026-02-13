package main

import (
	"errors"
	"log/slog"
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
	slog.Info("link : localhost" + a.server.Addr)
	slog.Info("pid  : " + strconv.Itoa(os.Getpid()))

	// run server
	if err := http.ListenAndServe(a.server.Addr, a.server.Handler); !errors.Is(err, http.ErrServerClosed) {
		slog.Error("HTTP server error: " + err.Error())
		os.Exit(1)
	}
}
