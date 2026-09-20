use crate::config;
use crate::models::{self, Invoice, InvoiceItem};
use base64::{engine::general_purpose::STANDARD, Engine};
use chrono::{Duration, Local};
use directories::UserDirs;
use std::fmt::Write;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Copy)]
struct ItemAmount {
    discount: i128,
    taxable: i128,
    tax: i128,
    tax_basis_points: i64,
}

pub fn generate(invoice: &Invoice) -> Result<PathBuf, String> {
    let now = Local::now();
    let file_date = now.format("%Y-%m-%d").to_string();
    let year = now.format("%Y").to_string();
    let month = now.format("%m").to_string();
    let html = preview_html(invoice)?;
    let pdf = render_pdf(&html)?;

    let output_dir = invoice_directory(&year, &month)?;
    fs::create_dir_all(&output_dir).map_err(|error| error.to_string())?;
    let customer_name = safe_file_name(&invoice.customer.name);
    let path = available_invoice_path(&output_dir, &customer_name, &file_date);
    fs::write(&path, pdf).map_err(|error| error.to_string())?;
    Ok(path)
}

pub fn preview_html(invoice: &Invoice) -> Result<String, String> {
    validate_invoice(invoice)?;

    let now = Local::now();
    let invoice_number = now.format("%Y%m%d%H%M%S").to_string();
    let date = now.format("%d-%m-%Y").to_string();
    let due_date = (now + Duration::days(15)).format("%Y-%m-%d").to_string();
    Ok(invoice_html(invoice, &invoice_number, &date, &due_date))
}

fn render_pdf(html: &str) -> Result<Vec<u8>, String> {
    ironpress::HtmlConverter::new()
        .add_font(
            "Cascadia",
            include_bytes!("../assets/fonts/Cascadia.ttf").to_vec(),
        )
        .convert(html)
        .map_err(|error| error.to_string())
}

fn invoice_html(invoice: &Invoice, invoice_number: &str, date: &str, due_date: &str) -> String {
    let amounts = invoice
        .items
        .iter()
        .map(|item| item_amount(invoice, item))
        .collect::<Vec<_>>();
    let subtotal: i128 = amounts.iter().map(|amount| amount.taxable).sum();
    let tax_total: i128 = amounts.iter().map(|amount| amount.tax).sum();
    let total = subtotal + tax_total;
    let is_igst = invoice.is_igst || invoice.igst_basis_points.unwrap_or_default() > 0;
    let cgst = if is_igst { 0 } else { tax_total / 2 };
    let sgst = if is_igst { 0 } else { tax_total - cgst };
    let cgst_text = if is_igst { "---".into() } else { money(cgst) };
    let sgst_text = if is_igst { "---".into() } else { money(sgst) };
    let igst_text = if is_igst {
        money(tax_total)
    } else {
        "---".into()
    };
    let igst_label = format!(
        "IGST [{}%]",
        percent_text(invoice.igst_basis_points.unwrap_or_default())
    );
    let customer = &invoice.customer;
    let customer_phone = format!("{} {}", customer.phone_ext, customer.phone);
    let company_phone = format!("{} / {}", config::COMPANY_PHONE_1, config::COMPANY_PHONE_2);
    let logo = format!(
        "data:image/png;base64,{}",
        STANDARD.encode(include_bytes!("../assets/icon.png"))
    );

    let mut html = String::from(
        r#"<style>
@page { size: A4; margin: 10mm 10mm 12mm; }
.invoice, .invoice * { box-sizing: border-box; }
.invoice {
    width: 100%;
    margin: 0;
    color: #111318;
    font-family: "Cascadia", monospace;
    font-size: 8.5pt;
    line-height: 1.35;
}
.invoice .top {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 180pt;
    align-items: center;
    gap: 24pt;
    margin-bottom: 18pt;
}
.invoice .brand {
    display: flex;
    align-items: center;
    gap: 16pt;
}
.invoice .logo {
    width: 52pt;
    height: 52pt;
    display: block;
    object-fit: contain;
}
.invoice h1 { margin: 0; font-size: 39pt; line-height: 1.15; }
.invoice .meta { width: 180pt; }
.invoice .row {
    display: grid;
    grid-template-columns: 64pt minmax(0, 1fr);
    gap: 8pt;
    margin: 2pt 0;
}
.invoice .label { color: #898b92; font-size: 7.5pt; }
.invoice .value { min-width: 0; text-align: right; overflow-wrap: anywhere; }
.invoice .strong { font-weight: 700; }
.invoice .parties {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    align-items: stretch;
    gap: 14pt;
    margin-bottom: 18pt;
}
.invoice .party {
    min-width: 0;
    min-height: 128pt;
    padding: 10pt 12pt;
    border: 0.8pt solid #c2ceff;
    border-radius: 9pt;
    break-inside: avoid;
}
.invoice .party.to { background: #f4f6ff; }
.invoice .party-title {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    gap: 10pt;
    margin-bottom: 16pt;
}
.invoice .party-title span:first-child { font-size: 12pt; font-weight: 400; }
.invoice .party-name {
    max-width: 72%;
    text-align: right;
    font-size: 11pt;
    font-weight: 700;
    overflow-wrap: anywhere;
    justify-self: end;
}
.invoice .address .value { line-height: 1.45; }
.invoice table { width: 100%; border-collapse: collapse; table-layout: fixed; font-size: 7.5pt; }
.invoice thead { display: table-header-group; }
.invoice th { padding: 4pt 3pt; border-bottom: 0.8pt solid #1c1d22; text-align: left; font-size: 8pt; }
.invoice td { padding: 4pt 3pt; vertical-align: top; overflow-wrap: anywhere; }
.invoice tbody tr { break-inside: avoid; }
.invoice tbody tr:nth-child(even) td { background: #f1f1f1; }
.invoice tbody tr:nth-child(even) td:first-child { border-radius: 5pt 0 0 5pt; }
.invoice tbody tr:nth-child(even) td:last-child { border-radius: 0 5pt 5pt 0; }
.invoice .number { text-align: right; white-space: nowrap; }
.invoice .muted { color: #70737a; font-size: 4.5pt; }
.invoice .summary { padding-top: 18pt; }
.invoice .summary-top {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    gap: 18pt;
    margin-bottom: 16pt;
    break-inside: avoid;
}
.invoice .section-label {
    margin: 0 0 8pt;
    color: #92949b;
    font-size: 7pt;
    font-weight: 700;
    text-transform: uppercase;
}
.invoice .terms ol { margin: 0; padding-left: 14pt; color: #6f7178; font-size: 6.7pt; }
.invoice .terms li { margin: 2pt 0; padding-left: 2pt; }
.invoice .total-row { display: flex; justify-content: space-between; gap: 12pt; margin: 5pt 0; }
.invoice .summary-bottom {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    align-items: stretch;
    gap: 14pt;
    break-inside: avoid;
}
.invoice .bank, .invoice .grand-total {
    min-height: 86pt;
    padding: 10pt 12pt;
    border: 0.8pt solid #c2ceff;
    border-radius: 9pt;
}
.invoice .bank h2 { margin: 0 0 8pt; font-size: 9pt; font-weight: 500; }
.invoice .bank .row { grid-template-columns: 46pt minmax(0, 1fr); }
.invoice .grand-total {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    align-items: flex-end;
    background: #f4f6ff;
    color: #073df5;
}
.invoice .grand-total .caption { font-size: 8pt; font-weight: 700; }
.invoice .grand-total .amount { font-size: 21pt; font-weight: 700; }
.invoice .signature {
    margin: 42pt 0 0 auto;
    width: 130pt;
    padding-top: 5pt;
    border-top: 0.7pt solid #222;
    text-align: center;
    font-size: 7pt;
}
</style>
<main class="invoice">
"#,
    );

    let _ = write!(
        html,
        r#"<header class="top">
  <div class="brand"><img class="logo" src="{}" alt="" width="52" height="52"><h1>Invoice</h1></div>
  <div class="meta">{}{}{}{}</div>
</header>
<section class="parties">
  <div class="party to">
    <div class="party-title"><span>TO</span><span class="party-name">{}</span></div>
    {}{}{}{}
    <div class="row address"><span class="label">Address</span><span class="value">{}</span></div>
  </div>
  <div class="party">
    <div class="party-title"><span>FROM</span><span class="party-name">{}</span></div>
    {}{}{}{}
    <div class="row address"><span class="label">Address</span><span class="value">{}</span></div>
  </div>
</section>
"#,
        escape_html(&logo),
        info_row("Invoice No.", invoice_number, true),
        info_row("Date", date, false),
        info_row("Due Date", due_date, false),
        info_row("Remark", value_or_dash(&customer.remark), false),
        escape_html(&customer.company_name),
        info_row("Name", &customer.name, true),
        info_row("GSTIN", &customer.gstin, false),
        info_row("Email", value_or_dash(&customer.email), false),
        info_row("Phone", &customer_phone, false),
        escape_html(&customer_address(invoice)),
        escape_html(config::COMPANY_NAME),
        info_row("Name", config::COMPANY_OWNER, true),
        info_row("GSTIN", config::COMPANY_GSTIN, false),
        info_row("Email", config::COMPANY_EMAIL, false),
        info_row("Phone", &company_phone, false),
        escape_html(config::COMPANY_ADDRESS),
    );

    html.push_str(
        r#"<table>
<colgroup>
  <col style="width:4%"><col style="width:9%"><col style="width:23%">
  <col style="width:9%"><col style="width:7%"><col style="width:10%">
  <col style="width:13%"><col style="width:13%"><col style="width:12%">
</colgroup>
<thead><tr>
  <th>#</th><th>S/N</th><th>Item Name</th><th>HSN</th><th class="number">Qty</th>
  <th class="number">Rate</th><th class="number">Disc</th><th class="number">GST</th><th class="number">Amt</th>
</tr></thead><tbody>
"#,
    );

    for (index, (item, amount)) in invoice.items.iter().zip(&amounts).enumerate() {
        let _ = write!(
            html,
            r#"<tr>
  <td>{}</td><td>{}</td><td>{}</td><td>{}</td>
  <td class="number">{}</td><td class="number">{}</td>
  <td class="number">{}% <span class="muted">[{}]</span></td>
  <td class="number">{}% <span class="muted">[{}]</span></td>
  <td class="number">{}</td>
</tr>
"#,
            index + 1,
            escape_html(&item.serial_number),
            escape_html(&item.name),
            escape_html(&item.hsn),
            item.quantity.unwrap_or_default(),
            money(item.rate_paise.unwrap_or_default() as i128),
            percent_text(item.discount_basis_points.unwrap_or_default()),
            money(amount.discount),
            percent_text(amount.tax_basis_points),
            money(amount.tax),
            money(amount.taxable),
        );
    }

    let _ = write!(
        html,
        r#"</tbody></table>
<section class="summary">
  <div class="summary-top">
    <div class="terms">
      <h2 class="section-label">Terms &amp; Conditions</h2>
      <ol>
        <li>We are not responsible for breakage, color or size variation.</li>
        <li>Responsibility ceases after delivery from our shop.</li>
        <li>24% interest applies to payments delayed beyond 15 days.</li>
        <li>Goods once sold will not be taken back.</li>
        <li>Subject to Gandhinagar Jurisdiction only.</li>
      </ol>
    </div>
    <div class="totals">{}{}{}{}{}</div>
  </div>
  <div class="summary-bottom">
    <div class="bank">
      <h2>Bank Details</h2>
      {}{}{}{}
    </div>
    <div class="grand-total"><span class="caption">TOTAL</span><span class="amount">&#8377;{}</span></div>
  </div>
  <div class="signature">{}</div>
</section>
</main>"#,
        total_row("Sub Total", &money(subtotal), true),
        total_row("GST", &money(tax_total), true),
        total_row("CGST", &cgst_text, false),
        total_row("SGST", &sgst_text, false),
        total_row(&igst_label, &igst_text, false),
        info_row("Bank", config::BANK_NAME, false),
        info_row("Branch", config::BANK_BRANCH, false),
        info_row("A/C", config::BANK_ACCOUNT, false),
        info_row("IFSC", config::BANK_IFSC, false),
        money(total),
        escape_html(config::COMPANY_NAME),
    );

    html
}

fn info_row(label: &str, value: &str, strong: bool) -> String {
    let class = if strong { "value strong" } else { "value" };
    format!(
        "<div class=\"row\"><span class=\"label\">{}</span><span class=\"{}\">{}</span></div>",
        escape_html(label),
        class,
        escape_html(value)
    )
}

fn total_row(label: &str, value: &str, strong: bool) -> String {
    let class = if strong {
        "total-row strong"
    } else {
        "total-row"
    };
    let rs = if value == "---" { "" } else { "&#8377;" };

    format!(
        "<div class=\"{}\"><span>{}</span><span>{}{}</span></div>",
        class,
        escape_html(label),
        rs,
        escape_html(value)
    )
}

fn validate_invoice(invoice: &Invoice) -> Result<(), String> {
    let customer = &invoice.customer;
    let postal_code = customer
        .postal_code
        .map(|value| value.to_string())
        .unwrap_or_default();
    let invalid_customer = crate::validate::name(&customer.name).is_some()
        || crate::validate::company_name(&customer.company_name).is_some()
        || crate::validate::gstin(&customer.gstin).is_some()
        || crate::validate::email(&customer.email).is_some()
        || crate::validate::phone(&customer.phone).is_some()
        || crate::validate::remark(&customer.remark).is_some()
        || crate::validate::shop_no(&customer.shop_no).is_some()
        || crate::validate::line(&customer.line1, true).is_some()
        || crate::validate::line(&customer.line2, false).is_some()
        || crate::validate::line(&customer.line3, false).is_some()
        || crate::validate::city(&customer.city).is_some()
        || crate::validate::postal_code(&customer.state, &postal_code).is_some();

    if invalid_customer {
        return Err("Fix the customer details before generating the invoice".into());
    }
    if invoice.items.is_empty() {
        return Err("Add at least one product before generating the invoice".into());
    }
    if invoice.items.iter().any(|item| {
        item.quantity.unwrap_or_default() <= 0
            || item.rate_paise.unwrap_or_default() <= 0
            || item.discount_basis_points.is_none()
            || item.gst_basis_points.is_none()
    }) {
        return Err("One or more invoice items are incomplete".into());
    }
    Ok(())
}

fn item_amount(invoice: &Invoice, item: &InvoiceItem) -> ItemAmount {
    let quantity = item.quantity.unwrap_or_default() as i128;
    let rate = item.rate_paise.unwrap_or_default() as i128;
    let discount_basis_points = item.discount_basis_points.unwrap_or_default();
    let igst_basis_points = invoice.igst_basis_points.unwrap_or_default();
    let tax_basis_points = if invoice.is_igst || igst_basis_points > 0 {
        igst_basis_points
    } else {
        item.gst_basis_points.unwrap_or_default()
    };
    let gross = quantity * rate;
    let discount = percentage(gross, discount_basis_points);
    let taxable = gross - discount;
    let tax = percentage(taxable, tax_basis_points);

    ItemAmount {
        discount,
        taxable,
        tax,
        tax_basis_points,
    }
}

fn percentage(value: i128, basis_points: i64) -> i128 {
    (value * basis_points as i128 + 5_000) / 10_000
}

fn customer_address(invoice: &Invoice) -> String {
    let customer = &invoice.customer;
    let mut parts = [
        customer.shop_no.as_str(),
        customer.line1.as_str(),
        customer.line2.as_str(),
        customer.line3.as_str(),
        customer.city.as_str(),
        customer.state.as_str(),
    ]
    .into_iter()
    .filter(|part| !part.trim().is_empty())
    .map(str::trim)
    .collect::<Vec<_>>();

    let postal_code = customer.postal_code.map(|value| value.to_string());
    if let Some(postal_code) = postal_code.as_deref() {
        parts.push(postal_code);
    }
    parts.join(", ")
}

fn invoice_directory(year: &str, month: &str) -> Result<PathBuf, String> {
    let user_dirs =
        UserDirs::new().ok_or_else(|| "Could not locate your Documents folder".to_string())?;
    let base = user_dirs
        .document_dir()
        .unwrap_or_else(|| user_dirs.home_dir());
    Ok(base
        .join(format!("{} Invoices", config::APP_NAME))
        .join(year)
        .join(month))
}

fn safe_file_name(value: &str) -> String {
    let name = value
        .trim()
        .chars()
        .map(|character| {
            if character.is_ascii_alphanumeric() {
                character
            } else {
                '-'
            }
        })
        .collect::<String>()
        .split('-')
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>()
        .join("-");

    if name.is_empty() {
        "customer".to_string()
    } else {
        name
    }
}

fn available_invoice_path(directory: &Path, customer_name: &str, date: &str) -> PathBuf {
    let stem = format!("{customer_name}-{date}");
    let path = directory.join(format!("{stem}.pdf"));
    if !path.exists() {
        return path;
    }

    let mut copy = 2;
    loop {
        let path = directory.join(format!("{stem}-{copy}.pdf"));
        if !path.exists() {
            return path;
        }
        copy += 1;
    }
}

fn value_or_dash(value: &str) -> &str {
    if value.trim().is_empty() {
        "---"
    } else {
        value
    }
}

fn money(value: i128) -> String {
    models::format_paise(value)
}

fn percent_text(value: i64) -> String {
    let formatted = models::format_percentage(value);
    formatted
        .strip_suffix(".00")
        .unwrap_or(&formatted)
        .to_string()
}

fn escape_html(value: &str) -> String {
    value
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}
