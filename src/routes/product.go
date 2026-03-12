package route

import (
	"ae_invoice/src/logger"
	model "ae_invoice/src/models"
	component "ae_invoice/src/web/components"
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"slices"
	"strconv"

	"github.com/starfederation/datastar-go/datastar"
	"github.com/uptrace/bunrouter"
)

// base: /product
func Product(pg *bunrouter.Group) {
	pg.GET("/", func(w http.ResponseWriter, req bunrouter.Request) error {
		productJson, _ := json.MarshalIndent(model.ActiveInvoice.Items, "", "  ")
		w.Write(productJson)
		return nil
	})

	pg.POST("/add", func(w http.ResponseWriter, req bunrouter.Request) error {
		if err := datastar.ReadSignals(req.Request, model.ActiveItem); err != nil {
			logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.ActiveItem, err.Error()))
			return err
		}

		model.ActiveInvoice.Items = append(model.ActiveInvoice.Items, *model.ActiveItem)
		model.ActiveInvoice.GenerateAmounts()

		newIndex := len(model.ActiveInvoice.Items)
		var buf bytes.Buffer
		if err := component.ProductRow(newIndex, *model.ActiveItem).Render(req.Context(), &buf); err != nil {
			return err
		}

		sse := datastar.NewSSE(w, req.Request)
		sse.PatchElements(buf.String(),
			datastar.WithSelector("#product-tbody"),
			datastar.WithMode("append"),
		)

		if err := sse.MarshalAndPatchSignals(model.ActiveItem); err != nil {
			logger.Logger.Error(fmt.Sprintf("Failed to MarshalAndPatchSignals %+v with error: %+v", model.ActiveItem, err.Error()))
			return err
		}

		return nil
	})

	pg.GET("/:id", func(w http.ResponseWriter, req bunrouter.Request) error {
		id, err := strconv.Atoi(req.Param("id"))
		if err != nil {
			logger.Logger.Error("Failed to convert param id to int")
		}
		if id <= 0 {
			w.Write([]byte("Invalid Id"))
			return nil
		}
		if len(model.ActiveInvoice.Items) == 0 {
			w.Write([]byte("Nothing to show"))
			return nil
		}
		id = id - 1
		fmt.Println(model.ActiveInvoice.Items[id])
		var buf bytes.Buffer
		if err := component.ProductBody().Render(req.Context(), &buf); err != nil {
			return err
		}

		sse := datastar.NewSSE(w, req.Request)
		sse.PatchElements(buf.String(),
			datastar.WithSelector("#product-tbody"),
			datastar.WithMode("replace"),
		)

		if err := sse.MarshalAndPatchSignals(model.ActiveInvoice.Items); err != nil {
			logger.Logger.Error(fmt.Sprintf("Failed to MarshalAndPatchSignals %+v with error: %+v", model.ActiveInvoice.Items, err.Error()))
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

		model.ActiveInvoice.Items = slices.Delete(model.ActiveInvoice.Items, id, id+1)
		model.ActiveInvoice.GenerateAmounts()

		var buf bytes.Buffer
		if err := component.ProductBody().Render(req.Context(), &buf); err != nil {
			return err
		}

		sse := datastar.NewSSE(w, req.Request)
		sse.PatchElements(buf.String(),
			datastar.WithSelector("#product-tbody"),
			datastar.WithMode("replace"),
		)

		if err := sse.MarshalAndPatchSignals(model.ActiveInvoice.Items); err != nil {
			logger.Logger.Error(fmt.Sprintf("Failed to MarshalAndPatchSignals %+v with error: %+v", model.ActiveInvoice.Items, err.Error()))
			return err
		}

		return nil
	})
}
