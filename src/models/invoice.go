package model

import (
	"ae_invoice/src/util"
	"fmt"
	"strings"
)

// InvoiceItem is a line item on an in-memory invoice.
// This is what the invoice form works with before anything is persisted.
// It maps to what ProductInfo used to be, renamed to reflect what it
// actually represents.
//
// Rate can be manually overridden per line item — it defaults to the
// product's CurrentPrice at the time the invoice is created but can
// be changed before submission.
type InvoiceItem struct {
	ProductID    uint    // reference to Product in the catalogue
	Name         string  `json:"productName"`
	SerialNumber string  `json:"serialNumber"`
	Hsn          string  `json:"hsn"`
	Quantity     int     `json:"quantity"`
	Rate         float64 `json:"rate"`
	Discount     float64 `json:"discount"`
	Gst          float64 `json:"gst"`
}

// Invoice is the in-memory working representation of an invoice being
// built. It is used by the form flow, PDF generation, and validation.
// It is NOT stored directly — once submitted it is persisted as a
// Transaction + TransactionItems in the DB.
type Invoice struct {
	Customer *Customer
	Items    []InvoiceItem
	IsIgst   bool    // true = interstate (IGST), false = intrastate (CGST+SGST)
	IgstRate float64 // additional IGST % applied at invoice level
	Amount   Amounts
}

func (inv *Invoice) GenerateAmounts() {
	inv.Amount = Amounts{
		Map: make(map[string]Amount),
	}

	for idx, item := range inv.Items {
		key := strings.ToLower(item.SerialNumber)
		if util.IsDev {
			key = fmt.Sprintf("%v%v", key, idx)
		}
		inv.Amount.Map[key] = NewAmount(item.Quantity, item.Rate, item.Discount, item.Gst)
		inv.Amount.GstTotal += inv.Amount.Map[key].GstAmount
		inv.Amount.SubTotal += inv.Amount.Map[key].AfterDisc
		inv.Amount.Total += inv.Amount.Map[key].Total
	}

	inv.Amount.Cgst = inv.Amount.GstTotal / 2
	inv.Amount.Sgst = inv.Amount.GstTotal / 2
	inv.Amount.Igst = inv.Amount.SubTotal * (inv.IgstRate * 0.01)

	inv.Amount.SubTotal = util.RoundFloat(inv.Amount.SubTotal)
	inv.Amount.GstTotal = util.RoundFloat(inv.Amount.GstTotal)
	inv.Amount.Cgst = util.RoundFloat(inv.Amount.Cgst)
	inv.Amount.Sgst = util.RoundFloat(inv.Amount.Sgst)
	inv.Amount.Igst = util.RoundFloat(inv.Amount.Igst)
	inv.Amount.Total = util.RoundFloat(inv.Amount.Total)
}

// ActiveInvoice is the single in-memory invoice being built in the current
// session. Replaces the old model.Customer global.
var ActiveInvoice = &Invoice{
	Customer: &Customer{},
}

// ActiveItem is the single in-memory invoice item currently being filled
// in the form, before it is appended to ActiveInvoice.Items on submission.
// Replaces the old model.Product global.
var ActiveItem = &InvoiceItem{}
