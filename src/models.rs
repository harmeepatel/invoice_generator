use dioxus::prelude::*;

pub fn format_paise(value: i128) -> String {
    format!("{}.{:02}", value / 100, value % 100)
}

pub fn format_percentage(basis_points: i64) -> String {
    format!("{}.{:02}", basis_points / 100, basis_points % 100)
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct Product {
    pub id: i64,
    pub serial_number: String,
    pub name: String,
    pub hsn: String,
    pub rate_paise: i64,
    pub gst_basis_points: i64,
    pub stock_quantity: i64,
}

#[derive(Clone, Debug, Default)]
pub struct Customer {
    pub name: String,
    pub company_name: String,
    pub gstin: String,
    pub email: String,
    pub phone: String,
    pub phone_ext: String,
    pub shop_no: String,
    pub line1: String,
    pub line2: String,
    pub line3: String,
    pub city: String,
    pub state: String,
    pub postal_code: Option<u32>,
    pub remark: String,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct InvoiceItem {
    pub product_id: Option<i64>,
    pub name: String,
    pub serial_number: String,
    pub hsn: String,
    pub quantity: Option<i64>,
    pub rate_paise: Option<i64>,
    pub discount_basis_points: Option<i64>,
    pub gst_basis_points: Option<i64>,
}

#[derive(Clone, Debug, Default)]
pub struct Invoice {
    pub customer: Customer,
    pub items: Vec<InvoiceItem>,
    pub is_igst: bool,
    pub igst_basis_points: Option<i64>,
}

pub static ACTIVE_INVOICE: GlobalSignal<Invoice> = Signal::global(|| Invoice {
    customer: Customer {
        state: "Gujarat".to_string(),
        phone_ext: "+91".to_string(),
        ..Default::default()
    },
    ..Default::default()
});
pub static ACTIVE_ITEM: GlobalSignal<InvoiceItem> = Signal::global(|| InvoiceItem::default());
pub static ACTIVE_INVOICE_PREVIEW: GlobalSignal<Option<String>> = Signal::global(|| None);
