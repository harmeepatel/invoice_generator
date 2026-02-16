package main

import (
	"fmt"
	"io/fs"
	"net/http"
	"time"

	page "ae_invoice/src/web/pages"

	"github.com/a-h/templ"
	"github.com/lpar/gzipped"
	"github.com/starfederation/datastar-go/datastar"
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
	router.GET("/static/*path", bunrouter.HTTPHandler(
		http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("Cache-Control", fmt.Sprintf("public, max-age=%d", 24*int(time.Hour)))

				static := gzipped.FileServer(http.FS(staticFS))
				http.StripPrefix("/static", static).ServeHTTP(w, r)
			},
		),
	))

	// home
	router.GET("/", func(w http.ResponseWriter, req bunrouter.Request) error {
		w.Header().Set("Cache-Control", "public, max-age=60")

		templ.Handler(page.Index("Invoice")).ServeHTTP(w, req.Request)
		return nil
	})

	// customer details
	type Customer struct {
		Name string `json:"name"`
	}

	router.WithGroup("/form", func(fg *bunrouter.Group) {
		fg.POST("/validate", func(w http.ResponseWriter, req bunrouter.Request) error {
			customer := &Customer{}
			if err := datastar.ReadSignals(req.Request, customer); err != nil {
				err := req.ParseForm()
				if err != nil {
					return err
				}

				fmt.Printf("name: %v\n", req.Form.Get("name"))
				return nil
			}
			fmt.Printf("%+v\n", customer)

			cnlen := len(customer.Name)
			sse := datastar.NewSSE(w, req.Request)
			if cnlen == 0 || cnlen >= 4 {
				fmt.Println(cnlen)
				sse.PatchSignals([]byte(`{hasError: true}`))
				sse.PatchSignals([]byte(`{nameError: "0 < x < 4"}`))
			} else {
				sse.PatchSignals([]byte(`{hasError: false}`))
				sse.PatchSignals([]byte(`{nameError: ""}`))
			}
			return nil
		})
	})

	return router
}
