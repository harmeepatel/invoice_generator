package model

import "time"

// Supplier represents a brand or company that stock is purchased from.
// e.g. Topsan, Misty
type Supplier struct {
	ID          uint
	Name        string
	ContactName string
	Phone       string
	Email       string
	Gstin       string
	CreatedAt   time.Time
}
