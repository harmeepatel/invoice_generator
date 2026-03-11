package main

import (
	"ae_invoice/src/logger"
	"ae_invoice/src/util"
	"database/sql"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strconv"
)

type App struct {
	server *http.Server
	db     *sql.DB
}

func NewApp() *App {
	srv := &http.Server{
		Addr:    PORT,
		Handler: newRouter(),
	}

	db, err := sql.Open("duckdb", fmt.Sprintf("%v?access_mode=READ_WRITE", util.DbPath))
	if err != nil {
		panic(fmt.Sprintf("Cannot open database: %v\n%+v", util.DbPath, err))
	}

	err = db.Ping()
	if err != nil {
		panic(err)
	}

	return &App{
		server: srv,
		db:     db,
	}
}

func (a *App) RunApp() {
	logger.Logger.Info("link : localhost" + a.server.Addr)
	logger.Logger.Info("pid  : " + strconv.Itoa(os.Getpid()))

	// run server
	if err := http.ListenAndServe(a.server.Addr, a.server.Handler); !errors.Is(err, http.ErrServerClosed) {
		logger.Logger.Error("HTTP server error: " + err.Error())
		os.Exit(1)
	}
}

func (a *App) CloseDb() {
	logger.Logger.Info("Closing Database")
	if err := a.db.Close(); err != nil {
		panic(fmt.Sprintf("Cannot close database: %v\n%+v", util.DbPath, err))
	}
}
