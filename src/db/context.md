# AE Invoice — Project Context & Architecture Plan

## What This Document Is

This is a context handoff document for an LLM to continue building the `ae_invoice` application. It contains business context, technical decisions already made, schema design, and rules that must be respected. Do not redesign what is already decided — build on top of it.

---

## Business Context

A **wholesale bathroom supplies distributor** in India (taps, showers, internal spare parts). Stocks products from multiple brands/suppliers (e.g. Topsan, Misty). Sells primarily B2B, occasionally B2C walk-in customers.

**The core flow:**
```
Supplier → [Purchase] → Inventory → [Quote] → [Invoice] → Customer
```

---

## Tech Stack

- **Language:** Go
- **Database:** DuckDB (not SQLite, not Postgres — DuckDB specifically)
- **HTTP:** Go standard `net/http`
- **Current state:** Working HTTP server with invoice PDF generation. Database layer is being built fresh.

### DuckDB-specific rules to follow
- Use `RETURNING id` with `QueryRow().Scan()` for insert IDs — `LastInsertId()` is unsupported
- `*sql.DB` is owned by the `App` struct and passed as a parameter to all db functions — no global DB variable
- Use proper DuckDB types: `DECIMAL` for money, `UINTEGER` for unsigned integers, `TIMESTAMPTZ` for timestamps, `VARCHAR` for strings — avoid `JSON` columns

---

## Project Structure

```
ae_invoice/
├── main.go
├── app.go              # App struct, server lifecycle, DB connection
├── src/
│   ├── logger/
│   ├── util/
│   ├── model/          # Go structs (CustomerInfo, ProductInfo, Amounts etc.)
│   └── db/             # All database logic lives here
│       ├── db.go       # Init() and table creation only
│       ├── customer.go
│       ├── product.go
│       ├── supplier.go
│       └── transaction.go
```

---

## Existing Go Models (already in codebase)

These structs exist and should not be changed. The database schema must accommodate them.

- `CustomerInfo` — customer identity, address, GSTIN, contact info, plus a slice of `ProductInfo` and an `Amounts` value
- `ProductInfo` — quantity, rate, discount, GST%, serial number, name, HSN code
- `Amount` — per-product computed amounts: before discount, discount amount, after discount, GST amount, total
- `Amounts` — invoice-level totals: subtotal, GST total, CGST, SGST, IGST, grand total. Also contains a `map[string]Amount` keyed by product serial number

**Important:** `Amounts` is fully computed in memory from raw inputs. It is never stored directly. The raw inputs are stored, and amounts are recomputed when needed.

---

## Database Design

### 5 Tables

```
suppliers ──────────────────────────── products
                                           │
customers ──< transactions ──< transaction_items >── products
suppliers ──<      │
                   └── type: quote | invoice | purchase | adjustment
```

### Table Responsibilities

**`suppliers`**
Brands and companies stock is purchased from. Simple identity and contact info.

**`products`**
Master product catalogue. One row per unique product. Holds the `current_price` which reflects the latest market price. Also holds default GST rate (derived from HSN code) and which supplier it primarily comes from. A `product_key` (hash of supplier + HSN + serial number) ensures deduplication.

**`customers`**
Buyer identity and address. GSTIN is optional — B2C customers may not have one. State field is important for IGST vs CGST+SGST determination.

**`transactions`**
The single unified table for all stock movements. Has a `type` field. Holds invoice-level computed totals as a snapshot. Has a `created_at` timestamp which is the price lock date and must never be changed.

**`transaction_items`**
Line items belonging to a transaction. Stores a full snapshot of rate, discount, GST%, and all computed amounts at the time of the transaction.

---

## Critical Business Rules

### Pricing
- `products.current_price` is the single source of truth for current pricing
- When market price changes, `current_price` is updated — this is retroactive for unsold inventory but does NOT affect any existing transaction
- When a `quote` is created, the price is snapshotted from `current_price` at that moment and locked
- When a `quote` is converted to an `invoice`, the price from the quote is used — not the current price
- When an `invoice` is created directly (no quote), price is snapshotted from `current_price` at that moment

### Transaction Types
| Type | Stock moves? | Price locked? | Links to |
|------|-------------|---------------|----------|
| `quote` | No | Yes, at creation | Customer |
| `invoice` | Yes, out | Yes, at creation or from quote | Customer, optionally a Quote |
| `purchase` | Yes, in | Optional (flexible) | Supplier |
| `adjustment` | Yes, +/- | N/A | Neither |

### Immutability
- **No UPDATE or DELETE ever runs on `transactions` or `transaction_items`**
- Corrections are new transactions (e.g. a future `credit` type as a negative invoice)
- This is both a business rule and a GST compliance requirement in India

### Inventory
Stock level is always derived, never stored as a standalone number:
```
current stock = SUM(purchase qty) - SUM(invoice qty) +/- SUM(adjustment qty)
```

### Batch Tracking
- Batch tracking is **quantity-only**, not cost-based (pricing is not FIFO)
- A `purchase_date` on `transaction_items` identifies which intake batch a purchase belongs to
- Stock depletion follows FIFO automatically by ordering on `purchase_date`

### GST
- Whether IGST or CGST+SGST applies is determined by comparing customer state vs business state
- A boolean flag `is_igst` on the transaction records which was applied
- IGST is an additional rate applied at the transaction level (not per product)
- CGST and SGST are each half of the product-level GST total
- All GST amounts are stored as a snapshot on the transaction

---

## What Is Explicitly Left Flexible (build later, no schema changes needed)

- **Multi-user:** add `created_by` column to `transactions`
- **Credit notes / returns:** add `credit` as a new transaction type with a reference to the original invoice id
- **Multiple suppliers per product:** add a `product_suppliers` junction table without touching core tables
- **Purchase pricing:** `rate` field already exists on `transaction_items`, just start populating it for purchases

---

## What To Build Next

The immediate next task is implementing the `src/db/` package:

1. `db.go` — `Init(*sql.DB)` that calls all table creation functions
2. `supplier.go` — CRUD for suppliers
3. `product.go` — CRUD for products, including price update logic
4. `customer.go` — CRUD for customers
5. `transaction.go` — create transaction + items together in a single DB transaction (use `BEGIN`/`COMMIT`), read invoice by ID with all items joined, list transactions by type and date range

All functions take `*sql.DB` as their first parameter. No global state.
