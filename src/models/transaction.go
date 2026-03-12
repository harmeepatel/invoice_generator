package model

import "time"

// TransactionType enumerates all valid transaction types.
type TransactionType string

const (
	TransactionTypeQuote      TransactionType = "quote"
	TransactionTypeInvoice    TransactionType = "invoice"
	TransactionTypePurchase   TransactionType = "purchase"
	TransactionTypeAdjustment TransactionType = "adjustment"
)

// Transaction is the persisted record of any stock movement.
// It is immutable once created — no UPDATE or DELETE is ever run on it.
//
// CustomerID and SupplierID are pointers because:
//   - a sale (invoice/quote) links to a Customer, not a Supplier
//   - a purchase links to a Supplier, not a Customer
//   - an adjustment links to neither
//
// QuoteID is set when an invoice is converted from a quote, so the
// original price lock date on the quote can be traced back.
type Transaction struct {
	ID         uint
	Type       TransactionType
	CustomerID *uint // nil for purchase and adjustment
	SupplierID *uint // nil for sale and adjustment
	QuoteID    *uint // nil unless this invoice was converted from a quote

	// GST fields — snapshotted at transaction time
	IsIgst     bool
	IgstRate   float64
	SubTotal   float64
	GstTotal   float64
	Cgst       float64
	Sgst       float64
	IgstAmount float64
	Total      float64

	Remark    string
	CreatedAt time.Time // price lock date — never changes after insert
}

// TransactionItem is a single line item belonging to a Transaction.
// All monetary values are snapshotted at the time of the transaction
// and never change, even if the product price or GST rate changes later.
//
// PurchaseDate is set on items belonging to a purchase transaction.
// It is used for batch tracking (FIFO stock depletion by purchase date).
type TransactionItem struct {
	ID            uint
	TransactionID uint
	ProductID     uint

	// Raw inputs — snapshotted at transaction time
	Quantity int
	Rate     float64
	Discount float64
	Gst      float64

	// Computed amounts — snapshotted at transaction time
	BeforeDisc float64
	DiscAmount float64
	AfterDisc  float64
	GstAmount  float64
	Total      float64

	PurchaseDate *time.Time // non-nil only for purchase transaction items
}
