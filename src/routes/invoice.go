package route

import (
	"ae_invoice/src/logger"
	model "ae_invoice/src/models"
	"ae_invoice/src/util"
	page "ae_invoice/src/web/pages"
	"fmt"
	"net/http"
	"time"

	"github.com/a-h/templ"
	"github.com/uptrace/bunrouter"
)

// base: /invoice
func Invoice(fg *bunrouter.Group) {
	if util.IsDev {
		fg.GET("/", func(w http.ResponseWriter, req bunrouter.Request) error {
			w.Header().Set("Cache-Control", fmt.Sprintf("public, max-age=%d", 24*int(time.Hour)))
			templ.Handler(page.Invoice("AE Invoice")).ServeHTTP(w, req.Request)
			return nil
		})
	}

	fg.WithGroup("/validate", Validate)

	fg.POST("/submit", func(w http.ResponseWriter, req bunrouter.Request) error {
		err := req.ParseForm()
		if err != nil {
			logger.Logger.Error("Failed to parse form on /invoice/submit")
			return err
		}

		model.ActiveInvoice.GenerateAmounts()

		return nil
	})
}
