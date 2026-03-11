## 4-Table Schema Plan

**`suppliers`** — Topsan, Misty, etc. Contact info, nothing complex.

**`products`** — master catalogue. Name, HSN, unit, default GST rate, `current_price`. One primary supplier per product for now.

**`customers`** — name, company, address, GSTIN (optional for B2C).

**`transactions`** — unified table for all stock movements with a `type` field:
- `quote` → price locked, stock not moved
- `invoice` → price locked, stock deducted. Has a `quote_id` reference if converted from a quote, null if direct
- `purchase` → stock added
- `adjustment` → manual correction with a reason

**`transaction_items`** — line items for any transaction. Captures `rate`, `discount`, `gst`, `quantity` as a snapshot at transaction time. Works for all transaction types.

---

## Key Rules Locked In

- Prices snapshot at `quote` creation or direct `invoice` creation — never retroactively change on existing transactions
- `current_price` on `products` is the only price that updates when market price changes
- Stock is always derived: `SUM(purchase qty) - SUM(invoice qty) - SUM(adjustment qty)`
- Batch tracking is quantity-only, not cost-based — just `purchase_date` on incoming `transaction_items`
- Old transactions are fully immutable — corrections go through new `adjustment` or credit transactions
- IGST vs CGST/SGST flag lives on the transaction itself
- B2C customers just have GSTIN left blank

---

## What Gets Built Later Without Schema Changes

- Multi-user → just add `created_by` to `transactions`
- Credit notes → new transaction type `credit` referencing original `invoice_id`
- Multiple suppliers per product → `product_suppliers` junction table added without touching core tables
- Purchase pricing → `rate` field already exists on `transaction_items`, just start using it

---
