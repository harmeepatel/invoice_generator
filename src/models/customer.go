package model

import (
	"fmt"
	"strings"
	"time"
)

// Customer holds identity and address information for a buyer.
// B2C customers may have Gstin left empty.
// A Customer exists independently of any invoice — one customer can have
// many transactions over time.
type Customer struct {
	ID          uint
	Name        string
	CompanyName string
	Gstin       string
	Email       string
	Phone       string
	PhoneExt    string
	ShopNo      string
	Line1       string
	Line2       string
	Line3       string
	City        string
	State       string // used to determine IGST vs CGST+SGST
	PostalCode  uint
	Remark      string
	CreatedAt   time.Time
}

func (c *Customer) Address() string {
	parts := []string{}
	for _, s := range []string{c.ShopNo, c.Line1, c.Line2, c.Line3, c.City, c.State} {
		if s != "" {
			parts = append(parts, s)
		}
	}
	addr := strings.Join(parts, ", ")
	addr += fmt.Sprintf(" - %d", c.PostalCode)
	return addr
}
