package model

import (
	"ae_invoice/src/util"
	"fmt"
	"strings"
)

type ProductInfo struct {
	Quantity     int     `json:"quantity"`
	Rate         float64 `json:"rate"`
	Discount     float64 `json:"discount"`
	GST          float64 `json:"gst"`
	SerialNumber string  `json:"serialNumber"`
	Name         string  `json:"productName"`
	Hsn          string  `json:"hsn"`
}

type CustomerInfo struct {
	Name        string        `json:"name"`
	CompanyName string        `json:"companyName"`
	GSTIN       string        `json:"gstin"`
	Email       string        `json:"email"`
	Phone       string        `json:"phone"`
	PhoneExt    string        `json:"phoneExt"`
	Remark      string        `json:"remark"`
	ShopNo      string        `json:"shopNo"`
	Line1       string        `json:"line1"`
	Line2       string        `json:"line2"`
	Line3       string        `json:"line3"`
	City        string        `json:"city"`
	State       string        `json:"state"`
	PostalCode  uint          `json:"postalCode"`
	Products    []ProductInfo `json:"productList"`
	Amount      Amounts
}

func (c *CustomerInfo) Address() string {
	parts := []string{}

	for _, s := range []string{c.ShopNo, c.Line1, c.Line2, c.Line3, c.City, c.State} {
		if s != "" {
			parts = append(parts, s)
		}
	}

	addr := strings.Join(parts, ", ")
	addr += fmt.Sprintf(" - %d", c.PostalCode)

	// if c.State != "" && c.PostalCode != 0 {
	// 	addr += fmt.Sprintf(", %s - %d", strings.ToUpper(c.State), c.PostalCode)
	// } else if c.State != "" {
	// 	addr += ", " + strings.ToUpper(c.State)
	// } else if c.PostalCode != 0 {
	// 	addr += fmt.Sprintf(" - %d", c.PostalCode)
	// }

	return addr
}

type Amount struct {
	BeforeDisc float64
	DiscAmount float64
	AfterDisc  float64
	GstAmount  float64
	Total      float64
}

func newAmounts(qty int, rate, disc, gst float64) Amount {
	beforeDisc := (rate * float64(qty))
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

type Amounts struct {
	Map      map[string]Amount
	SubTotal float64
	GstTotal float64
	Cgst     float64
	Sgst     float64
	Igst     float64
	Total    float64
}

func (ci *CustomerInfo) GenerateAmounts() {
	ci.Amount = Amounts{
		Map: make(map[string]Amount),
	}
	for idx, item := range ci.Products {
		key := strings.ToLower(item.SerialNumber)
		if util.IsDev {
			key = fmt.Sprintf("%v%v", key, idx)
		}
		ci.Amount.Map[key] = newAmounts(item.Quantity, item.Rate, item.Discount, item.GST)
		ci.Amount.GstTotal += ci.Amount.Map[key].GstAmount
		ci.Amount.SubTotal += ci.Amount.Map[key].AfterDisc
		ci.Amount.Total += ci.Amount.Map[key].Total
	}

	ci.Amount.Cgst = ci.Amount.GstTotal / 2
	ci.Amount.Sgst = ci.Amount.GstTotal / 2

	ci.Amount.SubTotal = util.RoundFloat(ci.Amount.SubTotal)
	ci.Amount.GstTotal = util.RoundFloat(ci.Amount.GstTotal)
	ci.Amount.Cgst = util.RoundFloat(ci.Amount.Cgst)
	ci.Amount.Sgst = util.RoundFloat(ci.Amount.Sgst)
	ci.Amount.Igst = util.RoundFloat(ci.Amount.Igst)
	ci.Amount.Total = util.RoundFloat(ci.Amount.Total)
}

var Customer = &CustomerInfo{}
var Product = &ProductInfo{}
