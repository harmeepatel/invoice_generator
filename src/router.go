package main

import (
	"bytes"
	"embed"
	"fmt"
	"io/fs"
	"net/http"
	"slices"
	"strconv"
	"time"

	"ae_invoice/src/handlers/validate"
	"ae_invoice/src/logger"
	model "ae_invoice/src/models"
	"ae_invoice/src/util"

	component "ae_invoice/src/web/components"
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

//go:embed web/*
var webFS embed.FS

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

	router.WithGroup("/invoice", func(fg *bunrouter.Group) {
		if util.IsDev {
			fg.GET("/", func(w http.ResponseWriter, req bunrouter.Request) error {
				fs := http.FS(webFS)
				file, _ := fs.Open("web/invoice.html")
				http.ServeContent(w, req.Request, "invoice.html", time.Now(), file)
				return nil
			})
		}

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
			vg.POST("/serialNumber", validate.SerialNumber)
			vg.POST("/productName", validate.ProductName)
			vg.POST("/hsn", validate.Hsn)
			vg.POST("/quantity", validate.Quantity)
			vg.POST("/sellPrice", validate.SellPrice)
			vg.POST("/discount", validate.Discount)

			vg.GET("/all", func(w http.ResponseWriter, req bunrouter.Request) error {
				err := req.ParseForm()
				if err != nil {
					logger.Logger.Error("Failed to parse form on /invoice/validate/all")
					return err
				}

				gst, _ := strconv.ParseFloat(req.Form.Get("gst"), 32)
				postalCode, _ := strconv.ParseUint(req.Form.Get("postalCode"), 10, 64)
				model.Customer = &model.CustomerInfo{
					Name:       req.Form.Get("name"),
					GSTIN:      req.Form.Get("gstin"),
					GST:        float32(gst),
					Email:      req.Form.Get("email"),
					Phone:      req.Form.Get("phone"),
					PhoneExt:   req.Form.Get("phoneExt"),
					Remark:     req.Form.Get("remark"),
					ShopNo:     req.Form.Get("shopNo"),
					Line1:      req.Form.Get("line1"),
					Line2:      req.Form.Get("line2"),
					Line3:      req.Form.Get("line3"),
					City:       req.Form.Get("city"),
					State:      req.Form.Get("state"),
					PostalCode: uint(postalCode),
				}

				qty, _ := strconv.Atoi(req.Form.Get("quantity"))
				sellPrice, _ := strconv.ParseFloat(req.Form.Get("sellPrice"), 32)
				discount, _ := strconv.ParseFloat(req.Form.Get("discount"), 32)
				model.Product = &model.ProductInfo{
					Quantity:     qty,
					SellPrice:    float32(sellPrice),
					Discount:     float32(discount),
					SerialNumber: req.Form.Get("serialNumber"),
					Name:         req.Form.Get("productName"),
					Hsn:          req.Form.Get("hsn"),
				}

				type Signals struct {
					HasError        bool `json:"hasError"`
					ProductHasError bool `json:"productHasError"`
				}
				signals := &Signals{}

				signals.HasError = !validate.AllCustomerValid()
				signals.ProductHasError = !validate.AllProductValid()

				sse := datastar.NewSSE(w, req.Request)
				if err := sse.MarshalAndPatchSignals(signals); err != nil {
					logger.Logger.Error(fmt.Sprintf("Failed to Marshal %+v with error: %+v", signals, err.Error()))
					return err
				}
				return nil

			})
		})

		fg.POST("/submit", func(w http.ResponseWriter, req bunrouter.Request) error {
			err := req.ParseForm()
			if err != nil {
				logger.Logger.Error("Failed to parse form on /invoice/submit")
				return err
			}

			fmt.Printf("customer: %+v\n", model.Customer)

			return nil
		})

		router.WithGroup("/product", func(pg *bunrouter.Group) {
			pg.POST("/add", func(w http.ResponseWriter, req bunrouter.Request) error {
				productInput := &model.ProductInfo{}
				if err := datastar.ReadSignals(req.Request, productInput); err != nil {
					logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", productInput, err.Error()))
					return err
				}

				model.Customer.Products = append(model.Customer.Products, *productInput)

				newIndex := len(model.Customer.Products)
				var buf bytes.Buffer
				if err := component.ProductRow(newIndex, *productInput).Render(req.Context(), &buf); err != nil {
					return err
				}

				sse := datastar.NewSSE(w, req.Request)
				sse.PatchElements(buf.String(),
					datastar.WithSelector("#product-tbody"),
					datastar.WithMode("append"),
				)

				if err := sse.MarshalAndPatchSignals(productInput); err != nil {
					logger.Logger.Error(fmt.Sprintf("Failed to MarshalAndPatchSignals %+v with error: %+v", productInput, err.Error()))
					return err
				}

				return nil
			})

			pg.DELETE("/:id", func(w http.ResponseWriter, req bunrouter.Request) error {
				id, err := strconv.Atoi(req.Param("id"))
				if err != nil {
					logger.Logger.Error("Failed to convert param id to int")
				}
				id = id - 1

				model.Customer.Products = slices.Delete(model.Customer.Products, id, id+1)

				var buf bytes.Buffer
				if err := component.ProductBody().Render(req.Context(), &buf); err != nil {
					return err
				}

				sse := datastar.NewSSE(w, req.Request)
				sse.PatchElements(buf.String(),
					datastar.WithSelector("#product-tbody"),
					datastar.WithMode("replace"),
				)

				if err := sse.MarshalAndPatchSignals(model.Customer.Products); err != nil {
					logger.Logger.Error(fmt.Sprintf("Failed to MarshalAndPatchSignals %+v with error: %+v", model.Customer.Products, err.Error()))
					return err
				}

				return nil
			})

		})

	})

	return router
}
