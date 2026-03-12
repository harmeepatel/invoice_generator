package model

import "ae_invoice/src/util"

// Amount holds computed monetary values for a single line item.
// This is a pure computation struct — it is never stored directly in the DB.
// It is always derived from raw inputs (qty, rate, discount, gst).
type Amount struct {
	BeforeDisc float64
	DiscAmount float64
	AfterDisc  float64
	GstAmount  float64
	Total      float64
}

func NewAmount(qty int, rate, disc, gst float64) Amount {
	beforeDisc := rate * float64(qty)
	discAmount := beforeDisc * (disc * 0.01)
	afterDisc := beforeDisc - discAmount
	gstAmount := afterDisc * (gst * 0.01)
	total := afterDisc + gstAmount
	return Amount{
		BeforeDisc: util.RoundFloat(beforeDisc),
		DiscAmount: util.RoundFloat(discAmount),
		AfterDisc:  util.RoundFloat(afterDisc),
		GstAmount:  util.RoundFloat(gstAmount),
		Total:      util.RoundFloat(total),
	}
}

// Amounts holds invoice-level totals.
// This is a pure computation struct — it is never stored directly in the DB.
// The individual fields (SubTotal, GstTotal etc.) are snapshotted onto the
// Transaction row in the DB after computation.
type Amounts struct {
	Map      map[string]Amount
	SubTotal float64
	GstTotal float64
	Cgst     float64
	Sgst     float64
	Igst     float64
	Total    float64
}
