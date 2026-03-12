package model

import "time"

// Product is a catalogue entry for a unique physical product.
// It is supplier-specific — the same tap from Topsan and Misty are two
// different Product rows.
//
// CurrentPrice is always the latest market price. Updating it does NOT
// affect existing immutable transactions — those have rate snapshotted
// on their TransactionItems.
type Product struct {
	ID           uint
	Name         string
	SerialNumber string
	Hsn          string
	Unit         string  // e.g. "pcs", "set", "pair", "box"
	CurrentPrice float64
	DefaultGst   float64 // default GST % derived from HSN slab
	SupplierID   uint
	ProductKey   string // hash of supplier_id + hsn + serial_number, unique
	CreatedAt    time.Time
}
