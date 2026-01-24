# Invoice Application UI Structure

## 1. Overall Component Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                     InvoiceApp (Root)                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   Header Component                    │  │
│  │  - Title: "Achal Enterprise Invoice"                  │  │
│  │  - Invoice Number Display: "29.06348"                 │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              InvoiceForm Component                    │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         Left Column (Business Info)             │  │  │
│  │  │  - GSTIN Input                                  │  │  │
│  │  │  - GST % Input                                  │  │  │
│  │  │  - Email Input (Optional)                       │  │  │
│  │  │  - Phone Input                                  │  │  │
│  │  │  - Remark Input (Optional)                      │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         Right Column (Address Info)             │  │  │
│  │  │  - Address Line 1                               │  │  │
│  │  │  - Address Line 2 (Optional)                    │  │  │
│  │  │  - Address Line 3 (Optional)                    │  │  │
│  │  │  - State                                        │  │  │
│  │  │  - City                                         │  │  │
│  │  │  - Postal Code                                  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          LineItemsTable Component                     │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │     Table Header Row                            │  │  │
│  │  │  Serial | Item | HSN | Qty | Rate | Discount    │  │  │
│  │  ├─────────────────────────────────────────────────┤  │  │
│  │  │     LineItem Component (Row 1)                  │  │  │
│  │  │  [input][input][input][input][input][input]     │  │  │
│  │  ├─────────────────────────────────────────────────┤  │  │
│  │  │     LineItem Component (Row 2)                  │  │  │
│  │  │  [input][input][input][input][input][input]     │  │  │
│  │  ├─────────────────────────────────────────────────┤  │  │
│  │  │              Add Button [+]                     │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │            Actions/Summary Component                  │  │
│  │  - Calculate Total                                    │  │
│  │  - Submit/Save Button                                 │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 2. Data Flow Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        State Management                      │
│                      (Parent Component)                      │
│                                                              │
│  invoiceData = {                                             │
│    invoiceNumber: "29.06348",                                │
│    businessInfo: { gstin, gst%, email, phone, remark },      │
│    addressInfo: { line1, line2, line3, state, city, zip },   │
│    lineItems: [ {...}, {...}, ... ]                          │
│  }                                                           │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ├─────────────┐
                            │             │
                            v             v
                  ┌──────────────┐  ┌──────────────┐
                  │   FormLeft   │  │  FormRight   │
                  │  Component   │  │  Component   │
                  │              │  │              │
                  │  Props:      │  │  Props:      │
                  │  - data      │  │  - data      │
                  │  - onChange  │  │  - onChange  │
                  └──────────────┘  └──────────────┘
                            
                            │
                            v
                  ┌──────────────────┐
                  │  LineItemsTable  │
                  │    Component     │
                  │                  │
                  │  Props:          │
                  │  - items[]       │
                  │  - onAdd         │
                  │  - onUpdate      │
                  │  - onDelete      │
                  └────────┬─────────┘
                           │
                ┌──────────┼──────────┐
                │          │          │
                v          v          v
         ┌─────────┐ ┌─────────┐ ┌─────────┐
         │LineItem │ │LineItem │ │LineItem │
         │  Row 1  │ │  Row 2  │ │  Row 3  │
         └─────────┘ └─────────┘ └─────────┘
```

## 3. Layout Grid Structure

```
┌────────────────────────────────────────────────────────────────┐
│                         HEADER (Full Width)                    │
│                    [Invoice Title + Number]                    │
└────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────┬──────────────────────────────┐
│                                 │                              │
│      LEFT COLUMN (50%)          │    RIGHT COLUMN (50%)        │
│                                 │                              │
│  ┌───────────────────────────┐  │  ┌────────────────────────┐  │
│  │ GSTIN Input               │  │  │ Address Line 1         │  │
│  └───────────────────────────┘  │  └────────────────────────┘  │
│                                 │                              │
│  ┌───────────────────────────┐  │  ┌────────────────────────┐  │
│  │ GST % Input               │  │  │ Address Line 2         │  │
│  └───────────────────────────┘  │  └────────────────────────┘  │
│                                 │                              │
│  ┌───────────────────────────┐  │  ┌────────────────────────┐  │
│  │ Email Input               │  │  │ Address Line 3         │  │
│  └───────────────────────────┘  │  └────────────────────────┘  │
│                                 │                              │
│  ┌───────────────────────────┐  │  ┌────────────────────────┐  │
│  │ Phone Input               │  │  │ State Input            │  │
│  └───────────────────────────┘  │  └────────────────────────┘  │
│                                 │                              │
│  ┌───────────────────────────┐  │  ┌────────────────────────┐  │
│  │ Remark Input              │  │  │ City Input             │  │
│  └───────────────────────────┘  │  └────────────────────────┘  │
│                                 │                              │
│                                 │  ┌────────────────────────┐  │
│                                 │  │ Postal Code Input      │  │
│                                 │  └────────────────────────┘  │
└─────────────────────────────────┴──────────────────────────────┘
┌────────────────────────────────────────────────────────────────┐
│              LINE ITEMS TABLE (Full Width)                     │
│ ┌────┬──────────┬─────────┬──────┬──────────┬─────────────┐    │
│ │Ser │Item Name │HSN Code │ Qty  │Sale Rate │  Discount % │    │
│ ├────┼──────────┼─────────┼──────┼──────────┼─────────────┤    │
│ │[  ]│[       ] │[      ] │[   ] │[       ] │[          ] │    │
│ ├────┼──────────┼─────────┼──────┼──────────┼─────────────┤    │
│ │                    [+ Add Row]                          │    │
│ └─────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────┘
```

## 4. Component Breakdown

```
InvoiceApp
├── Header
│   ├── Title (static text)
│   └── InvoiceNumber (display/input)
│
├── InvoiceFormSection
│   ├── BusinessInfoColumn (Left)
│   │   ├── InputField (GSTIN)
│   │   ├── InputField (GST %)
│   │   ├── InputField (Email)
│   │   ├── InputField (Phone)
│   │   └── InputField (Remark)
│   │
│   └── AddressInfoColumn (Right)
│       ├── InputField (Address Line 1)
│       ├── InputField (Address Line 2)
│       ├── InputField (Address Line 3)
│       ├── InputField (State)
│       ├── InputField (City)
│       └── InputField (Postal Code)
│
├── LineItemsSection
│   ├── TableHeader
│   ├── LineItemRow (repeatable)
│   │   ├── InputField (Serial Number)
│   │   ├── InputField (Item Name)
│   │   ├── InputField (HSN Code)
│   │   ├── InputField (Quantity)
│   │   ├── InputField (Sale Rate)
│   │   └── InputField (Discount %)
│   └── AddRowButton
│
└── ActionSection
    └── SubmitButton
```

## 5. State Structure

```
invoiceState
├── meta
│   └── invoiceNumber: string
│
├── businessInfo
│   ├── gstin: string
│   ├── gstPercentage: number
│   ├── email: string (optional)
│   ├── phone: string
│   └── remark: string (optional)
│
├── addressInfo
│   ├── line1: string
│   ├── line2: string (optional)
│   ├── line3: string (optional)
│   ├── state: string
│   ├── city: string
│   └── postalCode: string
│
└── lineItems: Array
    └── [
        {
          serialNumber: string,
          itemName: string,
          hsnCode: string,
          quantity: number,
          saleRate: number,
          discountPercent: number
        }
      ]
```

## 6. Event Flow

```
User Action                    Component               State Update
    │                              │                        │
    │  Types in GSTIN              │                        │
    ├─────────────────────────────>│                        │
    │                              │  onChange event        │
    │                              ├───────────────────────>│
    │                              │                        │
    │                              │              Update businessInfo.gstin
    │                              │                        │
    │  Clicks [+] Add Row          │                        │
    ├──────────────────────────────┼───────────────────────>│
    │                              │                        │
    │                              │         Push new item to lineItems[]
    │                              │                        │
    │  Updates Quantity in Row 2   │                        │
    ├─────────────────────────────>│                        │
    │                              │  onChange event        │
    │                              ├───────────────────────>│
    │                              │                        │
    │                              │         Update lineItems[1].quantity
    │                              │                        │
```

## Key Structural Concepts

1. **Two-Column Layout**: Form splits into business info (left) and address (right)
2. **Dynamic Table**: Line items can be added/removed dynamically
3. **Controlled Inputs**: All form fields are controlled by state
4. **Unique IDs**: Each input has a unique identifier for data binding
5. **Validation Layer**: Each field should validate on blur/change
6. **Calculation Logic**: Total amounts calculated from line items
