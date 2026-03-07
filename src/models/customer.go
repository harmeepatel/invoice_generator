package model

import (
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

type ShippingAddr struct {
}
type BillingAddr struct {
}

var Customer = &CustomerInfo{}
var Product = &ProductInfo{}
