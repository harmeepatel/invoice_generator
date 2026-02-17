package validate

import (
	"ae_invoice/src/logger"
	"fmt"
	"net/http"

	"github.com/starfederation/datastar-go/datastar"
	"github.com/uptrace/bunrouter"
)

// customer details
type Customer struct {
	Name   string `json:"name"`
	ShopNo string `json:"shopNo"`
}

func Name(w http.ResponseWriter, req bunrouter.Request) error {
	customer := &Customer{}
	if err := datastar.ReadSignals(req.Request, customer); err != nil {
		return err
	}
	fmt.Printf("name   : %+v\n", customer)

	type Signals = struct {
		HasError  bool   `json:"hasError"`
		NameError string `json:"nameError"`
	}
	signals := &Signals{}

	cnlen := len(customer.Name)
	// first
	if cnlen == 0 || cnlen > 4 {
		signals.HasError = true
		signals.NameError = "0 < x < 4"
	}
	// second
	if cnlen > 5 {
		signals.HasError = true
		signals.NameError = "too long"
	}

	sse := datastar.NewSSE(w, req.Request)
	if err := sse.MarshalAndPatchSignals(signals); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to Marshal %+v with err: %+v", signals, err.Error()))
		return err
	}
	return nil
}

func ShopNo(w http.ResponseWriter, req bunrouter.Request) error {
	customer := &Customer{}

	if err := datastar.ReadSignals(req.Request, customer); err != nil {
		return err
	}

	type Signals = struct {
		HasError    bool   `json:"hasError"`
		ShopNoError string `json:"shopNoError"`
	}
	signals := &Signals{}

	cnlen := len(customer.ShopNo)
	// first
	if cnlen == 0 || cnlen >= 4 {
		signals.HasError = true
		signals.ShopNoError = "0 < x < 4"
	}
	// second
	if cnlen > 5 {
		signals.HasError = true
		signals.ShopNoError = "too long"
	}

	sse := datastar.NewSSE(w, req.Request)
	if err := sse.MarshalAndPatchSignals(signals); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to Marshal %+v with err: %+v", signals, err.Error()))
		return err
	}
	return nil
}
