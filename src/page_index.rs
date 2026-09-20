use crate::components;
use crate::models;
use crate::models::{ACTIVE_INVOICE, ACTIVE_INVOICE_PREVIEW, ACTIVE_ITEM};
use dioxus::prelude::*;

macro_rules! field {
    ($t:expr, $k:expr, $p:expr, $l:expr, $e:expr) => {
        FieldConfig {
            field_type: $t,
            kind: $k,
            placeholder: $p,
            legend: $l,
            error: $e,
        }
    };
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum FieldKind {
    Name,
    CompanyName,
    Igst,
    Gstin,
    Email,
    PhoneExt,
    Phone,
    Remark,
    ShopNo,
    Line1,
    Line2,
    Line3,
    City,
    State,
    PostalCode,
    Quantity,
    Discount,
}

impl FieldKind {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Name => "name",
            Self::CompanyName => "companyName",
            Self::Igst => "igst",
            Self::Gstin => "gstin",
            Self::Email => "email",
            Self::PhoneExt => "phoneExt",
            Self::Phone => "phone",
            Self::Remark => "remark",
            Self::ShopNo => "shopNo",
            Self::Line1 => "line1",
            Self::Line2 => "line2",
            Self::Line3 => "line3",
            Self::City => "city",
            Self::State => "state",
            Self::PostalCode => "postalCode",
            Self::Quantity => "quantity",
            Self::Discount => "discount",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq)]
struct FieldConfig {
    field_type: components::FieldType,
    kind: FieldKind,
    placeholder: &'static str,
    legend: &'static str,
    error: Signal<Option<String>>,
}

fn invoice_field_value(kind: FieldKind) -> String {
    match kind {
        FieldKind::Name => ACTIVE_INVOICE.read().customer.name.clone(),
        FieldKind::CompanyName => ACTIVE_INVOICE.read().customer.company_name.clone(),
        FieldKind::Igst => ACTIVE_INVOICE
            .read()
            .igst_basis_points
            .map(models::format_percentage)
            .unwrap_or_default(),
        FieldKind::Gstin => ACTIVE_INVOICE.read().customer.gstin.clone(),
        FieldKind::Email => ACTIVE_INVOICE.read().customer.email.clone(),
        FieldKind::PhoneExt => ACTIVE_INVOICE.read().customer.phone_ext.clone(),
        FieldKind::Phone => ACTIVE_INVOICE.read().customer.phone.clone(),
        FieldKind::Remark => ACTIVE_INVOICE.read().customer.remark.clone(),
        FieldKind::ShopNo => ACTIVE_INVOICE.read().customer.shop_no.clone(),
        FieldKind::Line1 => ACTIVE_INVOICE.read().customer.line1.clone(),
        FieldKind::Line2 => ACTIVE_INVOICE.read().customer.line2.clone(),
        FieldKind::Line3 => ACTIVE_INVOICE.read().customer.line3.clone(),
        FieldKind::City => ACTIVE_INVOICE.read().customer.city.clone(),
        FieldKind::State => ACTIVE_INVOICE.read().customer.state.clone(),
        FieldKind::PostalCode => ACTIVE_INVOICE
            .read()
            .customer
            .postal_code
            .map(|value| value.to_string())
            .unwrap_or_default(),
        FieldKind::Quantity => ACTIVE_ITEM
            .read()
            .quantity
            .map(|value| value.to_string())
            .unwrap_or_default(),
        FieldKind::Discount => ACTIVE_ITEM
            .read()
            .discount_basis_points
            .map(models::format_percentage)
            .unwrap_or_default(),
    }
}

#[component]
fn InvoiceField(conf: FieldConfig) -> Element {
    let mut value = use_signal(move || invoice_field_value(conf.kind));

    let mut validate = move |value_text: String| {
        value.set(value_text.clone());
        let mut invoice = ACTIVE_INVOICE.write();
        let mut item = ACTIVE_ITEM.write();

        let error = match conf.kind {
            FieldKind::Name => {
                invoice.customer.name = value_text.clone();
                crate::validate::name(&value_text)
            }
            FieldKind::CompanyName => {
                invoice.customer.company_name = value_text.clone();
                crate::validate::company_name(&value_text)
            }
            FieldKind::Igst => {
                invoice.igst_basis_points = crate::validate::percent_to_basis_points(&value_text);
                crate::validate::igst(&value_text)
            }
            FieldKind::Gstin => {
                invoice.customer.gstin = value_text.clone();
                crate::validate::gstin(&value_text)
            }
            FieldKind::Email => {
                invoice.customer.email = value_text.clone();
                crate::validate::email(&value_text)
            }
            FieldKind::PhoneExt => {
                invoice.customer.phone_ext = value_text.clone();
                None
            }
            FieldKind::Phone => {
                invoice.customer.phone = value_text.clone();
                crate::validate::phone(&value_text)
            }
            FieldKind::Remark => {
                invoice.customer.remark = value_text.clone();
                crate::validate::remark(&value_text)
            }
            FieldKind::ShopNo => {
                invoice.customer.shop_no = value_text.clone();
                crate::validate::shop_no(&value_text)
            }
            FieldKind::Line1 => {
                invoice.customer.line1 = value_text.clone();
                crate::validate::line(&value_text, true)
            }
            FieldKind::Line2 => {
                invoice.customer.line2 = value_text.clone();
                crate::validate::line(&value_text, false)
            }
            FieldKind::Line3 => {
                invoice.customer.line3 = value_text.clone();
                crate::validate::line(&value_text, false)
            }
            FieldKind::City => {
                invoice.customer.city = value_text.clone();
                crate::validate::city(&value_text)
            }
            FieldKind::State => {
                invoice.customer.state = value_text.clone();
                None
            }
            FieldKind::PostalCode => {
                invoice.customer.postal_code = value_text.trim().parse().ok();
                crate::validate::postal_code(&invoice.customer.state, &value_text)
            }
            FieldKind::Quantity => {
                item.quantity = value_text.trim().parse().ok();
                crate::validate::quantity(&value_text)
            }
            FieldKind::Discount => {
                item.discount_basis_points = crate::validate::percent_to_basis_points(&value_text);
                crate::validate::discount(&value_text)
            }
        };

        conf.error.set(error);
    };

    match conf.field_type {
        components::FieldType::Select => rsx! {
            div { class: "min-w-0 pb-3",
                label {
                    class: "py-0 text-xl font-light flex justify-between items-end mb-1",
                    r#for: conf.kind.as_str(),
                    {conf.legend}
                    if let Some(error) = conf.error.read().as_deref() {
                        span { class: "block wrap-break-word max-w-3/5 text-red-400 text-base",
                            "{error}"
                        }
                    }
                }
                select {
                    id: conf.kind.as_str(),
                    name: conf.kind.as_str(),
                    class: "w-full max-w-full text-lg h-auto appearance-none",
                    autocomplete: "address-level1",
                    onchange: move |event: Event<FormData>| validate(event.value()),
                    for state in crate::states::state_names() {
                        option {
                            selected: state == ACTIVE_INVOICE.read().customer.state.as_str(),
                            value: state,
                            {state}
                        }
                    }
                }
            }
        },
        components::FieldType::Phone => rsx! {
            div { class: "min-w-0 pb-3",
                label {
                    class: "py-0 text-xl font-light flex justify-between items-end mb-1",
                    r#for: conf.kind.as_str(),
                    {conf.legend}
                    if let Some(error) = conf.error.read().as_deref() {
                        span { class: "block wrap-break-word max-w-3/5 text-red-400 text-base",
                            "{error}"
                        }
                    }
                }
                div { class: "flex w-full join",
                    select {
                        id: FieldKind::PhoneExt.as_str(),
                        name: FieldKind::PhoneExt.as_str(),
                        class: "join-item text-lg rounded-r-none appearance-none",
                        autocomplete: "tel-country-code",
                        onchange: move |event: Event<FormData>| {
                            ACTIVE_INVOICE.write().customer.phone_ext = event.value();
                        },
                        option {
                            value: "+91",
                            selected: ACTIVE_INVOICE.read().customer.phone_ext == "+91",
                            "🇮🇳 +91"
                        }
                        option {
                            value: "011",
                            selected: ACTIVE_INVOICE.read().customer.phone_ext == "011",
                            "🇮🇳 011"
                        }
                    }
                    input {
                        id: conf.kind.as_str(),
                        r#type: conf.field_type.as_str(),
                        name: conf.kind.as_str(),
                        class: "join-item w-full max-w-full text-lg h-auto rounded-l-none",
                        placeholder: conf.placeholder,
                        value: value.read().clone(),
                        autocomplete: "tel-national",
                        oninput: move |event: Event<FormData>| validate(event.value()),
                    }
                }
            }
        },
        components::FieldType::Text
        | components::FieldType::Number
        | components::FieldType::Email => rsx! {
            components::Field {
                id: conf.kind.as_str().to_string(),
                field_type: conf.field_type,
                placeholder: conf.placeholder.to_string(),
                legend: conf.legend.to_string(),
                value: value.read().clone(),
                error: conf.error.read().clone(),
                step: match conf.kind {
                    FieldKind::Igst | FieldKind::Discount => "0.01".to_string(),
                    _ => "1".to_string(),
                },
                oninput: validate,
            }
        },
    }
}

fn rounded_percentage(value_paise: i128, basis_points: i64) -> i128 {
    let basis_points = basis_points as i128;
    let whole = value_paise / 10_000;
    let remainder = value_paise % 10_000;

    whole * basis_points + (remainder * basis_points + 5_000) / 10_000
}

#[component]
fn TableHeader(border_top: bool) -> Element {
    let class = if border_top {
        "border-t-1 border-white/5 hover:bg-white/5"
    } else {
        "border-b-1 border-white/5 hover:bg-white/5"
    };
    rsx! {
        tr { class,
            th { class: "px-2", "#" }
            td { "Serial #" }
            td { "Name" }
            td { "HSN" }
            td { "Quantity" }
            td { "Rate ₹" }
            td { "Discount %" }
            td { "Gst %" }
            th { class: "w-px py-4 text-center align-middle" }
        }
    }
}

#[component]
fn ProductRow(idx: usize, item: models::InvoiceItem, on_delete: EventHandler<usize>) -> Element {
    let trash_icon = asset!("/assets/media/trash.svg");
    let quantity = item.quantity.unwrap_or_default();
    let rate_paise = item.rate_paise.unwrap_or_default();
    let discount_basis_points = item.discount_basis_points.unwrap_or_default();
    let gst_basis_points = item.gst_basis_points.unwrap_or_default();

    let gross_paise = quantity as i128 * rate_paise as i128;
    let discount_paise = rounded_percentage(gross_paise, discount_basis_points);
    let taxable_paise = gross_paise - discount_paise;
    let gst_paise = rounded_percentage(taxable_paise, gst_basis_points);

    let rate = models::format_paise(rate_paise as i128);
    let discount = models::format_percentage(discount_basis_points);
    let discount_amount = models::format_paise(discount_paise);
    let gst = models::format_percentage(gst_basis_points);
    let gst_amount = models::format_paise(gst_paise);

    let tr_class = if idx & 1 == 0 {
        "bg-white/5 hover:bg-black/40"
    } else {
        "hover:bg-black/40"
    };

    rsx! {
        tr { class: tr_class,
            th { "{idx}" }
            td { "{item.serial_number}" }
            td { class: "max-w-[256px]", "{item.name}" }
            td { "{item.hsn}" }
            td { "{quantity}" }
            td { "{rate}" }
            td {
                "{discount} "
                span { class: "text-xs text-gray-500", "[{discount_amount}]" }
            }
            td {
                "{gst} "
                span { class: "text-xs text-gray-500", "[{gst_amount}]" }
            }
            td { class: "w-px py-4 px-2 text-center align-middle",
                button {
                    class: "mx-auto p-0 w-8 h-8 lg:w-12 lg:h-12 flex items-center justify-center hover-fade",
                    onclick: move |_| on_delete.call(idx),
                    img {
                        src: "{trash_icon}",
                        class: "block w-4 h-4 lg:w-6 lg:h-6",
                    }
                }
            }
        }
    }
}

#[component]
pub fn Index(title: String) -> Element {
    const LEGEND_CLASS: &str = "font-light w-fit";
    let plus_icon = asset!("/assets/media/plus.svg");
    let navigator = use_navigator();

    let mut name_err = use_signal(|| None::<String>);
    let mut company_err = use_signal(|| None::<String>);
    let mut igst_err = use_signal(|| None::<String>);
    let mut gstin_err = use_signal(|| None::<String>);
    let mut email_err = use_signal(|| None::<String>);
    let mut phone_err = use_signal(|| None::<String>);
    let mut remark_err = use_signal(|| None::<String>);
    let mut shop_no_err = use_signal(|| None::<String>);
    let mut line1_err = use_signal(|| None::<String>);
    let mut line2_err = use_signal(|| None::<String>);
    let mut line3_err = use_signal(|| None::<String>);
    let mut city_err = use_signal(|| None::<String>);
    let mut state_err = use_signal(|| None::<String>);
    let mut postal_err = use_signal(|| None::<String>);
    let products = use_signal(|| crate::database::products().unwrap_or_default());
    let mut product_err = use_signal(|| None::<String>);
    let mut qty_err = use_signal(|| None::<String>);
    let mut discount_err = use_signal(|| None::<String>);
    let mut generate_message = use_signal(|| None::<(bool, String)>);
    let mut product_form_reset_key = use_signal(|| 0_u64);
    let product_form_key = *product_form_reset_key.read();

    let mut postal_err_clone = postal_err;
    use_effect(move || {
        let state = ACTIVE_INVOICE.read().customer.state.clone();
        if let Some(postal_code) = ACTIVE_INVOICE.read().customer.postal_code {
            let pc = postal_code.to_string();
            postal_err_clone.set(crate::validate::postal_code(&state, &pc));
        }
    });

    let business_info = [
        field!(
            components::FieldType::Text,
            FieldKind::Name,
            "Rohit Patel",
            "Name",
            name_err
        ),
        field!(
            components::FieldType::Text,
            FieldKind::CompanyName,
            "Achal Enterprise",
            "Company Name",
            company_err
        ),
        field!(
            components::FieldType::Number,
            FieldKind::Igst,
            "",
            "IGST",
            igst_err
        ),
        field!(
            components::FieldType::Text,
            FieldKind::Gstin,
            "24ABCPM1234L1Z5",
            "GSTIN",
            gstin_err
        ),
        field!(
            components::FieldType::Email,
            FieldKind::Email,
            "abc@xyz.com",
            "Email (Optional)",
            email_err
        ),
        field!(
            components::FieldType::Phone,
            FieldKind::Phone,
            "11111 99999",
            "Phone",
            phone_err
        ),
        field!(
            components::FieldType::Text,
            FieldKind::Remark,
            "XYZ Missing in order",
            "Remark (Optional)",
            remark_err
        ),
    ];

    let business_address = [
        field!(
            components::FieldType::Text,
            FieldKind::ShopNo,
            "A123",
            "Shop No",
            shop_no_err
        ),
        field!(
            components::FieldType::Text,
            FieldKind::Line1,
            "Complex / Plaza",
            "Line 1",
            line1_err
        ),
        field!(
            components::FieldType::Text,
            FieldKind::Line2,
            "Landmark",
            "Line 2 (Optional)",
            line2_err
        ),
        field!(
            components::FieldType::Text,
            FieldKind::Line3,
            "Street Name",
            "Line 3 (Optional)",
            line3_err
        ),
        field!(
            components::FieldType::Text,
            FieldKind::City,
            "Ahmedabad",
            "City",
            city_err
        ),
        field!(
            components::FieldType::Select,
            FieldKind::State,
            "Gujarat",
            "State",
            state_err
        ),
        field!(
            components::FieldType::Number,
            FieldKind::PostalCode,
            "382424",
            "Postal Code",
            postal_err
        ),
    ];

    let product_pricing = [
        field!(
            components::FieldType::Number,
            FieldKind::Quantity,
            "4",
            "Quantity",
            qty_err
        ),
        field!(
            components::FieldType::Number,
            FieldKind::Discount,
            "5",
            "Discount",
            discount_err
        ),
    ];

    let is_dev = std::env::var("IS_DEV")
        .unwrap_or_else(|_| "false".to_string())
        .parse::<bool>()
        .unwrap_or(false);
    rsx! {
        document::Title { "{title}" }

        main { class: "max-w-7xl m-auto mb-4 p-4",
            div { class: "flex justify-between",
                h1 { class: "text-4xl mb-4", "Party Information" }
                if is_dev {
                    div { class: "flex gap-2",
                        button {
                            class: "hover:bg-(--color-hover) hover-fade",
                            onclick: move |_| {
                                crate::database::clear_products().expect("Could not clear database!");
                                *ACTIVE_INVOICE.write() = models::Invoice::default();
                                *ACTIVE_ITEM.write() = models::InvoiceItem::default();
                                generate_message.set(None);
                                *product_form_reset_key.write() += 1;
                            },
                            "Clear Data"
                        }
                        button {
                            class: "bg-(--color-primary) hover-fade",
                            onclick: move |_| {
                                *ACTIVE_INVOICE.write() = models::Invoice {
                                    customer: models::Customer {
                                        name: "Harmee Patel".into(),
                                        company_name: "Sample Traders".into(),
                                        gstin: "24ABCPM1234L1Z5".into(),
                                        email: "customer@example.com".into(),
                                        phone: "9834567890".into(),
                                        phone_ext: "+91".into(),
                                        shop_no: "A-123".into(),
                                        line1: "Chanakya Plaza".into(),
                                        line2: "Near Swagat-3".into(),
                                        line3: "New C.G. Road".into(),
                                        city: "Ahmedabad".into(),
                                        state: "Gujarat".into(),
                                        postal_code: Some(382424),
                                        remark: "Sample order".into(),
                                    },
                                    ..Default::default()
                                };

                                *ACTIVE_ITEM.write() = products
                                    .read()
                                    .iter()
                                    .find(|product| product.stock_quantity > 0)
                                    .cloned()
                                    .map(|product| models::InvoiceItem {
                                        product_id: Some(product.id),
                                        serial_number: product.serial_number,
                                        name: product.name,
                                        hsn: product.hsn,
                                        quantity: Some(1),
                                        rate_paise: Some(product.rate_paise),
                                        discount_basis_points: Some(0),
                                        gst_basis_points: Some(product.gst_basis_points),
                                    })
                                    .unwrap_or_default();

                                name_err.set(None);
                                company_err.set(None);
                                igst_err.set(None);
                                gstin_err.set(None);
                                email_err.set(None);
                                phone_err.set(None);
                                remark_err.set(None);
                                shop_no_err.set(None);
                                line1_err.set(None);
                                line2_err.set(None);
                                line3_err.set(None);
                                city_err.set(None);
                                state_err.set(None);
                                postal_err.set(None);
                                product_err.set(None);
                                qty_err.set(None);
                                discount_err.set(None);
                                generate_message.set(None);
                                *product_form_reset_key.write() += 1;
                            },
                            "Fill Dummy Data"
                        }
                    }
                }
            }
            section { key: "{product_form_key}",
                div {
                    id: "party-info",
                    class: "w-full mb-6 sm:mb-3 flex-col sm:flex-row flex gap-8",

                    fieldset { id: "left", class: "w-full min-w-0",
                        legend { class: "{LEGEND_CLASS}", "Business Details" }
                        for field in business_info {
                            InvoiceField { conf: field }
                        }
                    }

                    fieldset { id: "right", class: "w-full min-w-0",
                        legend { class: "{LEGEND_CLASS}", "Billing Address" }
                        for field in business_address {
                            InvoiceField { conf: field }
                        }
                    }
                }

                fieldset {
                    id: "product-info",
                    class: "flex md:gap-8 flex-col md:flex-row",

                    legend { class: "{LEGEND_CLASS}", "Product Details" }
                    div { class: "grow min-w-0 pb-3",
                        label {
                            class: "py-0 text-xl font-light flex justify-between items-end mb-1",
                            r#for: "product",
                            "Product"
                            if let Some(error) = product_err.read().as_deref() {
                                span { class: "block wrap-break-word max-w-3/5 text-red-400 text-base",
                                    "{error}"
                                }
                            }
                        }
                        select {
                            id: "product",
                            name: "product",
                            class: "w-full max-w-full text-lg h-auto appearance-none",
                            onchange: move |event: Event<FormData>| {
                                let product_id = event.value().parse::<i64>().ok();
                                let selected = product_id
                                    .and_then(|id| {
                                        products.read().iter().find(|product| product.id == id).cloned()
                                    });
                                if let Some(product) = selected {
                                    *ACTIVE_ITEM.write() = models::InvoiceItem {
                                        product_id: Some(product.id),
                                        serial_number: product.serial_number,
                                        name: product.name,
                                        hsn: product.hsn,
                                        quantity: None,
                                        rate_paise: Some(product.rate_paise),
                                        discount_basis_points: None,
                                        gst_basis_points: Some(product.gst_basis_points),
                                    };
                                    product_err.set(None);
                                } else {
                                    *ACTIVE_ITEM.write() = models::InvoiceItem::default();
                                }
                            },
                            option {
                                value: "",
                                selected: ACTIVE_ITEM.read().product_id.is_none(),
                                "Select a product"
                            }
                            for product in products.read().iter() {
                                option {
                                    value: "{product.id}",
                                    selected: ACTIVE_ITEM.read().product_id == Some(product.id),
                                    "{product.name} — {product.serial_number} ({product.stock_quantity} in stock)"
                                }
                            }
                        }
                    }
                    div { class: "flex gap-8",
                        for field in product_pricing {
                            InvoiceField { conf: field }
                        }
                    }
                }

                div { class: "flex w-full gap-8 mt-4",
                    button {
                        class: "grow-8 bg-(--color-primary) text-xl disabled:cursor-not-allowed hover-fade",
                        onclick: move |_| {
                            let invoice = ACTIVE_INVOICE.read().clone();
                            match crate::invoice_pdf::generate(&invoice) {
                                Ok(path) => {
                                    generate_message
                                        .set(Some((true, format!("Invoice saved to {}", path.display()))))
                                }
                                Err(error) => generate_message.set(Some((false, error))),
                            }
                        },
                        "Generate Invoice"
                    }
                    button {
                        class: "px-6 bg-(--color-primary) disabled:cursor-not-allowed hover-fade",
                        onclick: move |_| {
                            let invoice = ACTIVE_INVOICE.read().clone();
                            match crate::invoice_pdf::preview_html(&invoice) {
                                Ok(html) => {
                                    *ACTIVE_INVOICE_PREVIEW.write() = Some(html);
                                    generate_message.set(None);
                                    navigator.push(crate::Route::InvoiceView {});
                                }
                                Err(error) => generate_message.set(Some((false, error))),
                            }
                        },
                        "Preview"
                    }
                    button {
                        class: "grow-2 bg-(--color-primary) disabled:cursor-not-allowed hover-fade",
                        onclick: move |_| {
                            let mut item = ACTIVE_ITEM.read().clone();
                            let quantity_error = match item.quantity {
                                Some(quantity) if quantity > 0 => None,
                                _ => Some("Required".into()),
                            };

                            if item.discount_basis_points.is_none() {
                                item.discount_basis_points = Some(0);
                            }
                            let discount_error = match item.discount_basis_points {
                                Some(discount) if discount <= 10_000 => None,
                                _ => Some("Invalid".into()),
                            };

                            let selected_product = item
                                .product_id
                                .and_then(|id| {
                                    products.read().iter().find(|product| product.id == id).cloned()
                                });
                            let mut product_error = if selected_product.is_some() {
                                None
                            } else {
                                Some("Required".into())
                            };
                            if let Some(product) = selected_product {
                                if ACTIVE_INVOICE
                                    .read()
                                    .items
                                    .iter()
                                    .any(|existing| { existing.product_id == Some(product.id) })
                                {
                                    product_error = Some("Product already added".into());
                                } else if item.quantity.unwrap_or_default() > product.stock_quantity {
                                    product_error = Some(
                                        format!("Only {} available in stock", product.stock_quantity),
                                    );
                                }
                            }
                            let is_valid = product_error.is_none() && quantity_error.is_none()
                                && discount_error.is_none();
                            product_err.set(product_error);
                            qty_err.set(quantity_error);
                            discount_err.set(discount_error);
                            if is_valid {
                                ACTIVE_INVOICE.write().items.push(item);
                                *ACTIVE_ITEM.write() = models::InvoiceItem::default();
                                *product_form_reset_key.write() += 1;
                            }
                        },
                        img { class: "m-auto", src: "{plus_icon}" }
                    }
                }

                if let Some((success, message)) = generate_message.read().as_ref() {
                    p { class: if *success { "text-green-400 mt-3" } else { "text-red-400 mt-3" },
                        "{message}"
                    }
                }

                section { class: "overflow-x-auto max-h-[640px] lg:max-h-[1024px] mt-6",
                    table { class: "w-full table-pin-rows table-pin-cols text-balance",
                        thead { class: "text-lg font-light",
                            TableHeader { border_top: false }
                        }
                        tbody { class: "text-base text-gray-300",
                            for (idx, item) in ACTIVE_INVOICE.read().items.iter().enumerate() {
                                ProductRow {
                                    key: "{idx}",
                                    idx: idx + 1,
                                    item: item.clone(),
                                    on_delete: move |i: usize| {
                                        ACTIVE_INVOICE.write().items.remove(i - 1);
                                    },
                                }
                            }
                        }
                        tfoot { class: "text-lg font-light",
                            TableHeader { border_top: true }
                        }
                    }
                }
            }
        }
    }
}
