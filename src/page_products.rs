use crate::models::{format_paise, format_percentage, Product};
use dioxus::prelude::*;

#[derive(Clone, Debug, Default, PartialEq)]
struct ProductForm {
    id: i64,
    serial_number: String,
    name: String,
    hsn: String,
    rate: String,
    gst: String,
    stock_quantity: String,
}

#[derive(Clone, Debug, Default, PartialEq)]
struct ProductErrors {
    serial_number: Option<String>,
    name: Option<String>,
    hsn: Option<String>,
    rate: Option<String>,
    gst: Option<String>,
    stock_quantity: Option<String>,
}

impl ProductErrors {
    fn has_errors(&self) -> bool {
        self.serial_number.is_some()
            || self.name.is_some()
            || self.hsn.is_some()
            || self.rate.is_some()
            || self.gst.is_some()
            || self.stock_quantity.is_some()
    }
}

impl From<Product> for ProductForm {
    fn from(product: Product) -> Self {
        Self {
            id: product.id,
            serial_number: product.serial_number,
            name: product.name,
            hsn: product.hsn,
            rate: format_paise(product.rate_paise as i128),
            gst: format_percentage(product.gst_basis_points),
            stock_quantity: product.stock_quantity.to_string(),
        }
    }
}

fn stock_error(value: &str) -> Option<String> {
    match value.trim().parse::<i64>() {
        Ok(quantity) if quantity >= 0 => None,
        _ => Some("Must be zero or greater".into()),
    }
}

fn validate_form(form: &ProductForm) -> ProductErrors {
    let serial_number = form.serial_number.trim();
    let name = form.name.trim();
    let hsn = form.hsn.trim();

    ProductErrors {
        serial_number: crate::validate::serial_number(serial_number),
        name: crate::validate::product_name(name),
        hsn: crate::validate::hsn(hsn),
        rate: crate::validate::rate(&form.rate),
        gst: crate::validate::gst(&form.gst),
        stock_quantity: stock_error(&form.stock_quantity),
    }
}

fn product_from_form(form: &ProductForm) -> Product {
    Product {
        id: form.id,
        serial_number: form.serial_number.trim().to_string(),
        name: form.name.trim().to_string(),
        hsn: form.hsn.trim().to_string(),
        rate_paise: crate::validate::money_to_paise(&form.rate).unwrap_or_default(),
        gst_basis_points: crate::validate::percent_to_basis_points(&form.gst).unwrap_or_default(),
        stock_quantity: form.stock_quantity.trim().parse().unwrap_or_default(),
    }
}

#[component]
fn InventoryRow(
    product: Product,
    on_edit: EventHandler<Product>,
    on_delete: EventHandler<i64>,
) -> Element {
    let rate = format_paise(product.rate_paise as i128);
    let gst = format_percentage(product.gst_basis_points);
    let edit_product = product.clone();
    let product_id = product.id;

    rsx! {
        tr {
            td { "{product.serial_number}" }
            td { class: "max-w-sm", "{product.name}" }
            td { "{product.hsn}" }
            td { "₹{rate}" }
            td { "{gst}%" }
            td { "{product.stock_quantity}" }
            td { class: "whitespace-nowrap text-right",
                button {
                    class: "mr-2 hover:bg-(--color-hover) hover-fade",
                    onclick: move |_| on_edit.call(edit_product.clone()),
                    "Edit"
                }
                button {
                    class: "hover:bg-(--color-hover) hover-fade",
                    onclick: move |_| on_delete.call(product_id),
                    "Delete"
                }
            }
        }
    }
}

#[component]
pub fn Index(title: String) -> Element {
    let mut products = use_signal(|| crate::database::products().unwrap_or_default());
    let mut form = use_signal(ProductForm::default);
    let mut errors = use_signal(ProductErrors::default);
    let mut database_error = use_signal(|| None::<String>);

    rsx! {
        document::Title { "{title}" }

        main { class: "max-w-6xl m-auto mb-4 p-4",
            h1 { class: "text-4xl mb-4", "Products" }

            section { class: "grid grid-cols-1 md:grid-cols-3 gap-4 mb-4",
                crate::components::Field {
                    id: "productSerialNumber".to_string(),
                    field_type: crate::components::FieldType::Text,
                    placeholder: "A1B2C3".to_string(),
                    legend: "Serial Number".to_string(),
                    value: form.read().serial_number.clone(),
                    error: errors.read().serial_number.clone(),
                    step: "1".to_string(),
                    oninput: move |value: String| {
                        form.write().serial_number = value.clone();
                        errors.write().serial_number =
                            crate::validate::serial_number(value.trim());
                    },
                }
                crate::components::Field {
                    id: "productName".to_string(),
                    field_type: crate::components::FieldType::Text,
                    placeholder: "Bib Cock".to_string(),
                    legend: "Name".to_string(),
                    value: form.read().name.clone(),
                    error: errors.read().name.clone(),
                    step: "1".to_string(),
                    oninput: move |value: String| {
                        form.write().name = value.clone();
                        errors.write().name = crate::validate::product_name(value.trim());
                    },
                }
                crate::components::Field {
                    id: "productHsn".to_string(),
                    field_type: crate::components::FieldType::Text,
                    placeholder: "123456".to_string(),
                    legend: "HSN".to_string(),
                    value: form.read().hsn.clone(),
                    error: errors.read().hsn.clone(),
                    step: "1".to_string(),
                    oninput: move |value: String| {
                        form.write().hsn = value.clone();
                        errors.write().hsn = crate::validate::hsn(value.trim());
                    },
                }
                crate::components::Field {
                    id: "productRate".to_string(),
                    field_type: crate::components::FieldType::Number,
                    placeholder: "256".to_string(),
                    legend: "₹ Rate".to_string(),
                    value: form.read().rate.clone(),
                    error: errors.read().rate.clone(),
                    step: "0.01".to_string(),
                    oninput: move |value: String| {
                        form.write().rate = value.clone();
                        errors.write().rate = crate::validate::rate(&value);
                    },
                }
                crate::components::Field {
                    id: "productGst".to_string(),
                    field_type: crate::components::FieldType::Number,
                    placeholder: "5".to_string(),
                    legend: "GST %".to_string(),
                    value: form.read().gst.clone(),
                    error: errors.read().gst.clone(),
                    step: "0.01".to_string(),
                    oninput: move |value: String| {
                        form.write().gst = value.clone();
                        errors.write().gst = crate::validate::gst(&value);
                    },
                }
                crate::components::Field {
                    id: "productStockQuantity".to_string(),
                    field_type: crate::components::FieldType::Number,
                    placeholder: "0".to_string(),
                    legend: "Stock Quantity".to_string(),
                    value: form.read().stock_quantity.clone(),
                    error: errors.read().stock_quantity.clone(),
                    step: "1".to_string(),
                    oninput: move |value: String| {
                        form.write().stock_quantity = value.clone();
                        errors.write().stock_quantity = stock_error(&value);
                    },
                }
            }

            if let Some(error) = database_error.read().as_deref() {
                p { class: "text-error mb-4", "{error}" }
            }

            div { class: "flex gap-4 mb-6",
                button {
                    class: "grow bg-(--color-primary) text-xl hover-fade",
                    onclick: move |_| {
                        let draft = form.read().clone();
                        let validation_errors = validate_form(&draft);
                        let has_errors = validation_errors.has_errors();
                        errors.set(validation_errors);

                        if has_errors {
                            return;
                        }

                        let product = product_from_form(&draft);
                        let result = crate::database::save_product(&product);

                        match result {
                            Ok(()) => {
                                match crate::database::products() {
                                    Ok(saved_products) => {
                                        products.set(saved_products);
                                        form.set(ProductForm::default());
                                        errors.set(ProductErrors::default());
                                        database_error.set(None);
                                    }
                                    Err(error) => database_error.set(Some(error)),
                                }
                            }
                            Err(error) => {
                                if error.contains("UNIQUE constraint failed") {
                                    errors.write().serial_number = Some("Already exists".to_string());
                                } else {
                                    database_error.set(Some(error));
                                }
                            }
                        }
                    },
                    if form.read().id == 0 {
                        "Add Product"
                    } else {
                        "Update Product"
                    }
                }
                if form.read().id != 0 {
                    button {
                        class: "hover:bg-(--color-hover) hover-fade",
                        onclick: move |_| {
                            form.set(ProductForm::default());
                            errors.set(ProductErrors::default());
                            database_error.set(None);
                        },
                        "Cancel"
                    }
                }
            }

            section { class: "overflow-x-auto",
                table { class: "w-full text-balance",
                    thead { class: "text-lg font-light",
                        tr {
                            th { "Serial #" }
                            th { "Name" }
                            th { "HSN" }
                            th { "Rate" }
                            th { "GST" }
                            th { "Stock" }
                            th {}
                        }
                    }
                    tbody {
                        for product in products.read().iter().cloned() {
                            InventoryRow {
                                key: "{product.id}",
                                product,
                                on_edit: move |product| {
                                    form.set(ProductForm::from(product));
                                    errors.set(ProductErrors::default());
                                    database_error.set(None);
                                },
                                on_delete: move |id| {
                                    match crate::database::delete_product(id) {
                                        Ok(()) => {
                                            match crate::database::products() {
                                                Ok(saved_products) => {
                                                    products.set(saved_products);
                                                    if form.read().id == id {
                                                        form.set(ProductForm::default());
                                                        errors.set(ProductErrors::default());
                                                    }
                                                    database_error.set(None);
                                                }
                                                Err(error) => database_error.set(Some(error)),
                                            }
                                        }
                                        Err(error) => database_error.set(Some(error)),
                                    }
                                },
                            }
                        }
                    }
                }
            }
        }
    }
}
