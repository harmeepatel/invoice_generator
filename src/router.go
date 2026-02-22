package main

import (
	"fmt"
	"io/fs"
	"net/http"
	"time"

	"ae_invoice/src/handlers/validate"
	"ae_invoice/src/logger"
	// model "ae_invoice/src/models"
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
	router.GET("/static/*path", bunrouter.HTTPHandler(
		http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("Cache-Control", fmt.Sprintf("public, max-age=%d", 24*int(time.Hour)))

				static := gzipped.FileServer(http.FS(staticFS))
				http.StripPrefix("/static", static).ServeHTTP(w, r)
			},
		),
	))

	router.GET("/", func(w http.ResponseWriter, req bunrouter.Request) error {
		w.Header().Set("Cache-Control", "public, max-age=60")
		templ.Handler(page.Index("Invoice")).ServeHTTP(w, req.Request)
		return nil
	})

	router.WithGroup("/form", func(fg *bunrouter.Group) {
		fg.WithGroup("/validate", func(vg *bunrouter.Group) {
			vg.POST("/name", validate.Name)
			vg.POST("/gstin", validate.Gstin)
			vg.POST("/gst", validate.Gst)
			vg.POST("/email", validate.Email)
			vg.POST("/phone", validate.Phone)
			vg.POST("/remark", validate.Remark)
			vg.POST("/shopNo", validate.ShopNo)
			vg.POST("/line1", validate.Line)
			vg.POST("/line2", validate.Line)
			vg.POST("/line3", validate.Line)
			vg.POST("/city", validate.City)
			vg.POST("/state", validate.State)
			vg.POST("/postalCode", validate.PostalCode)
		})

		fg.POST("/submit", func(w http.ResponseWriter, req bunrouter.Request) error {
			err := req.ParseForm()
			if err != nil {
				logger.Logger.Error("Failed to parse form on /validate/submit")
				return err
			}

			// gst, err := strconv.ParseFloat(req.Form.Get("gst"), 32)
			// if err != nil {
			// 	logger.Logger.Error("Problem parsing string to float for GST: %v", err)
			// }

			// postalCode, err := strconv.Atoi(req.Form.Get("postalCode"))
			// if err != nil {
			// 	logger.Logger.Error("Problem parsing string to Uint for PostalCode: %v", err)
			// }

			// customer := model.CustomerInfo{
			// 	Name:       req.Form.Get("name"),
			// 	GSTIN:      req.Form.Get("gstin"),
			// 	GST:        float32(gst),
			// 	Email:      req.Form.Get("email"),
			// 	Phone:      req.Form.Get("phone"),
			// 	PhoneExt:   req.Form.Get("phoneExt"),
			// 	Remark:     req.Form.Get("remark"),
			// 	ShopNo:     req.Form.Get("shopNo"),
			// 	Line1:      req.Form.Get("line1"),
			// 	Line2:      req.Form.Get("line2"),
			// 	Line3:      req.Form.Get("line3"),
			// 	City:       req.Form.Get("city"),
			// 	State:      req.Form.Get("state"),
			// 	PostalCode: uint(postalCode),
			// }
			//
			// fmt.Println(customer)

			return nil
		})
	})

	return router
}
