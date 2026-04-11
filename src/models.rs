use dioxus::prelude::*;

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
    pub postal_code: u32,
    pub remark: String,
}

#[derive(Clone, Debug, Default)]
pub struct InvoiceItem {
    pub name: String,
    pub serial_number: String,
    pub hsn: String,
    pub quantity: i64,
    pub rate: f64,
    pub discount: f64,
    pub gst: f64,
}

#[derive(Clone, Debug, Default)]
pub struct Invoice {
    pub customer: Customer,
    pub items: Vec<InvoiceItem>,
    pub is_igst: bool,
    pub igst_rate: f64,
}

pub static ACTIVE_INVOICE: GlobalSignal<Invoice> = Signal::global(|| Invoice {
    customer: Customer {
        state: "Gujarat".to_string(),
        ..Default::default()
    },
    ..Default::default()
});
pub static ACTIVE_ITEM: GlobalSignal<InvoiceItem> = Signal::global(|| InvoiceItem::default());
