package main

import (
	"fmt"
	"io/fs"
	"net/http"

	page "ae_invoice/src/web/pages"

	"github.com/a-h/templ"
	"github.com/lpar/gzipped"
	"github.com/uptrace/bunrouter"
)

func notFoundHandler(w http.ResponseWriter, req bunrouter.Request) error {
	w.WriteHeader(http.StatusNotFound)
	fmt.Fprintf(
		w,
		"<html>BunRouter can't find a route that matches <strong>%s</strong></html>",
		req.URL.Path,
	)
	return nil
}

func newRouter() *bunrouter.Router {
	router := bunrouter.New(
		bunrouter.WithNotFoundHandler(notFoundHandler),
	)

	// static file server
	staticFS, err := fs.Sub(assets, "web/static")
	if err != nil {
		panic(err)
	}
	static := gzipped.FileServer(http.FS(staticFS))
	router.GET("/static/*path", bunrouter.HTTPHandler(http.StripPrefix("/static", static)))

	// echo test
	router.GET("/echo/:msg", func(w http.ResponseWriter, req bunrouter.Request) error {
		w.WriteHeader(http.StatusOK)
		w.Header().Add("Custom-Header", "my_custom_header")
		fmt.Fprintf(
			w,
			"<html style='width: 64%%; margin: auto; padding-top: 4rem'><h1>%s</h1></html>",
			req.Params().ByName("msg"),
		)
		return nil
	})

	// home
	router.GET("/", func(w http.ResponseWriter, req bunrouter.Request) error {
		templ.Handler(page.Index("Invoice")).ServeHTTP(w, req.Request)
		return nil
	})

	return router
}
