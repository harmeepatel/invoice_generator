# AE Invoice — Project Context Handoff

## What This Is

Complete context for the `ae_invoice` Go application after a full architecture planning and model refactoring session. Build on top of this — do not redesign what is decided.

---

## Business

Wholesale bathroom supplies distributor in India (taps, showers, spare parts). Stocks from multiple brands (Topsan, Misty etc.). Primarily B2B, some B2C.

```
Supplier → [Purchase] → Inventory → [Quote] → [Invoice] → Customer
```

---

## Tech Stack

| Concern | Choice |
|---|---|
| Language | Go |
| Database | DuckDB |
| Router | `bunrouter` |
| Frontend | `templ` + `datastar` (SSE/signals) |
| State | Single-user for now, multi-user later |

### DuckDB Rules
- `RETURNING id` + `QueryRow().Scan()` for insert IDs — `LastInsertId()` unsupported
- `*sql.DB` passed as parameter everywhere — no global DB variable
- Types: `DECIMAL` for money, `UINTEGER` for unsigned ints, `TIMESTAMPTZ` for timestamps, `VARCHAR` for strings, `BOOLEAN` for flags

---

## Project Structure

```
ae_invoice/
├── main.go
├── app.go                     # App struct, server + DB lifecycle
├── src/
│   ├── logger/
│   ├── util/
│   ├── validate/
│   │   └── validation.go
│   ├── models/
│   │   ├── amounts.go         # Amount, Amounts, NewAmount()
│   │   ├── customer.go        # Customer, Address()
│   │   ├── invoice.go         # Invoice, InvoiceItem, ActiveInvoice, ActiveItem
│   │   ├── product.go         # Product (catalogue)
│   │   ├── supplier.go        # Supplier
│   │   └── transaction.go     # Transaction, TransactionItem, TransactionType
│   ├── db/                    # ← NOT YET BUILT — next task
│   │   ├── db.go
│   │   ├── customer.go
│   │   ├── product.go
│   │   ├── supplier.go
│   │   └── transaction.go
│   ├── routes/
│   │   ├── invoice.go
│   │   ├── product.go
│   │   └── validation.go
│   └── web/
│       ├── components/
│       │   └── product_table.templ
│       └── pages/
│           └── invoice.templ
```

---

## Model Layer — Completed

### Key Globals (replaces old globals)

| Old | New | Purpose |
|---|---|---|
| `model.Customer` | `model.ActiveInvoice.Customer` | Customer being filled in form |
| `model.Product` | `model.ActiveItem` | Line item being staged in form |

`ActiveInvoice` is the single in-memory invoice being built. `ActiveItem` is the staging struct for a product line item before it gets appended to `ActiveInvoice.Items`.

```go
var ActiveInvoice = &Invoice{Customer: &Customer{}}
var ActiveItem = &InvoiceItem{}
```

---

### Struct Summary

**`Amount`** — computed per-line-item: BeforeDisc, DiscAmount, AfterDisc, GstAmount, Total. Never stored directly, always recomputed via `NewAmount(qty, rate, disc, gst)`.

**`Amounts`** — invoice-level totals: SubTotal, GstTotal, Cgst, Sgst, Igst, Total + a `map[string]Amount` keyed by serial number. Never stored directly.

**`Customer`** — identity + address only. GSTIN optional (B2C). State field drives IGST vs CGST+SGST. No products, no amounts.

**`InvoiceItem`** — a line item on the in-memory invoice form. Has ProductID, Name, SerialNumber, Hsn, Quantity, Rate, Discount, Gst. This is what old `ProductInfo` was — renamed to reflect what it actually is.

**`Invoice`** — in-memory working invoice. Has `*Customer`, `[]InvoiceItem`, `IsIgst bool`, `IgstRate float64`, `Amount Amounts`. Has `GenerateAmounts()`. Never stored directly — persisted as `Transaction` + `TransactionItem` rows.

**`Product`** — DB catalogue entry. Has CurrentPrice (single source of truth for pricing), DefaultGst, Hsn, Unit, SupplierID, ProductKey (hash of supplier+hsn+serial for dedup).

**`Supplier`** — brand/company stock is purchased from. Name, contact info, GSTIN.

**`Transaction`** — unified DB record for all stock movements. Has Type, CustomerID `*uint`, SupplierID `*uint`, QuoteID `*uint`, IsIgst, IgstRate, all amount snapshots, CreatedAt (price lock date — immutable).

**`TransactionItem`** — DB line item. Snapshots all raw inputs (Rate, Discount, Gst, Quantity) and all computed amounts at transaction time. Has `PurchaseDate *time.Time` for batch tracking on purchases.

---

### Full Rename Map

| Old | New |
|---|---|
| `model.CustomerInfo` | `model.Customer` |
| `model.ProductInfo` | `model.InvoiceItem` |
| `model.Customer` (global var) | `model.ActiveInvoice.Customer` |
| `model.Product` (global var) | `model.ActiveItem` |
| `model.Customer.Products` | `model.ActiveInvoice.Items` |
| `model.Customer.Amount` | `model.ActiveInvoice.Amount` |
| `model.Customer.Igst` | `model.ActiveInvoice.IgstRate` |
| `newAmounts()` | `NewAmount()` (exported) |
| `CustomerInfo.GenerateAmounts()` | `Invoice.GenerateAmounts()` |

All routes, validators, and templ files have been updated to use the new names.

---

## Database Design

### Schema Diagram

```
suppliers ──────────────────────────── products
                                           │
customers ──< transactions ──< transaction_items >── products
suppliers ──<      │
                   └── type: quote | invoice | purchase | adjustment
```

### Transaction Types

| Type | Stock moves? | Price locked? | Links to |
|---|---|---|---|
| `quote` | No | Yes, at creation | Customer |
| `invoice` | Yes, out | Yes, at creation or inherited from quote | Customer + optional Quote |
| `purchase` | Yes, in | Optional | Supplier |
| `adjustment` | Yes, +/- | N/A | Neither |

---

## Business Rules (must not be violated)

### Pricing
- `products.current_price` is always the current market price
- Price updates are retroactive for **unsold inventory only** — existing transactions are never touched
- A `quote` locks price at creation time
- Converting a quote to an invoice uses the quote's locked price, not current price
- A direct invoice (no quote) locks price at invoice creation time

### Immutability
- **No `UPDATE` or `DELETE` ever runs on `transactions` or `transaction_items`**
- Corrections are new transactions (future `credit` type referencing original invoice)
- Required for GST compliance in India

### Inventory
Stock is always derived — never stored as a standalone field:
```
stock = SUM(purchase qty) - SUM(invoice qty) +/- SUM(adjustment qty)
```

### Batch Tracking
- Quantity-only, not cost-based — pricing is not FIFO
- `PurchaseDate` on `transaction_items` identifies the intake batch
- FIFO depletion is automatic by ordering on `PurchaseDate`

### GST
- IGST applies for interstate sales (customer state ≠ business state)
- CGST + SGST applies for intrastate sales
- `is_igst` flag on transaction records which applied
- IGST rate is at the transaction level; product GST is at the line item level
- All GST amounts snapshotted on transaction at creation time

---

## What Is Left Flexible (no schema changes needed to add these later)

| Feature | How to add |
|---|---|
| Multi-user | Add `created_by` column to `transactions` |
| Credit notes | Add `credit` as a new TransactionType referencing original invoice ID |
| Multiple suppliers per product | Add `product_suppliers` junction table |
| Purchase pricing | `rate` already exists on `transaction_items` — just start populating it |

---

## What To Build Next — `src/db/` Package

All functions take `*sql.DB` as first parameter. No global state.

1. **`db.go`** — `Init(*sql.DB)` calls all table creation functions in order: suppliers → products → customers → transactions → transaction_items
2. **`supplier.go`** — Insert, GetByID, List
3. **`product.go`** — Insert, GetByID, UpdatePrice (only field that updates), List, GetByKey
4. **`customer.go`** — Insert, GetByID, List, Update
5. **`transaction.go`** — CreateWithItems (wraps insert of transaction + all items in a single `BEGIN`/`COMMIT`), GetByID (joins items), ListByType, ListByDateRange

Table creation uses `CREATE TABLE IF NOT EXISTS`. Schema uses native DuckDB types. Computed amount fields on `transaction_items` are stored as snapshots even though they are derivable, for immutability and query performance.
