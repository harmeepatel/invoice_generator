use dioxus::prelude::*;

use crate::components;

/// Generate components::FieldConfig
/// ARGS:
/// field_type
/// name
/// placeholder
/// legend
macro_rules! field {
    ($t:expr, $n:expr, $p:expr, $l:expr) => {
        crate::components::FieldConfig {
            field_type: $t,
            name: $n,
            placeholder: $p,
            legend: $l,
        }
    };
}

const BUSINESS_INFO: &[crate::components::FieldConfig] = &[
    field!("text", "name", "Rohit Patel", "Name"),
    field!("text", "companyName", "Achal Enterprise", "Company Name"),
    field!("number", "igst", "", "IGST"),
    field!("text", "gstin", "24ABCPM1234L1Z5", "GSTIN"),
    field!("email", "email", "abc@xyz.com", "Email (Optional)"),
    field!("tel", "phone", "11111 99999", "Phone"),
    field!(
        "text",
        "remark",
        "XYZ Missing in this order",
        "Remark (Optional)"
    ),
];

const BUSINESS_ADDRESS: &[crate::components::FieldConfig] = &[
    field!("text", "shopNo", "A123", "Shop No"),
    field!("text", "line1", "Complex / Plaza", "Line 1"),
    field!("text", "line2", "Landmark", "Line 2 (Optional)"),
    field!("text", "line3", "Street Name", "Line 3 (Optional)"),
    field!("text", "city", "Ahmedabad", "City"),
    field!("select", "state", "Gujarat", "State"),
    field!("number", "postalCode", "382424", "Postal Code"),
];

const PRODUCT_INFO: &[crate::components::FieldConfig] = &[
    field!("text", "serialNumber", "A1B2C3", "Serial #"),
    field!("text", "productName", "Bib Cock", "Name"),
    field!("text", "hsn", "123456", "HSN"),
];

const PRODUCT_PRICING: &[crate::components::FieldConfig] = &[
    field!("number", "quantity", "4", "Quantity"),
    field!("number", "rate", "256", "₹ Rate"),
    field!("number", "discount", "5", "Discount"),
    field!("number", "gst", "5.0", "GST"),
];

#[component]
pub fn Index(title: String) -> Element {
    const LEGEND_CLASS: &str = "font-light w-fit";
    let plus_icon = asset!("/assets/media/plus.svg");

    rsx! {
        document::Title { "{title}" }

        main { class: "max-w-6xl m-auto mb-4 p-4",
            h1 { class: "text-4xl mb-4", "Party Information" }
            section {
                div {
                    id: "party-info",
                    class: "w-full mb-6 sm:mb-3 flex-col sm:flex-row flex gap-4",

                    fieldset { id: "left", class: "w-full min-w-0",
                        legend { class: "{LEGEND_CLASS}", "Business Details" }
                        for field in BUSINESS_INFO {
                            components::Field { conf: *field }
                        }
                    }

                    fieldset { id: "right", class: "w-full min-w-0",
                        legend { class: "{LEGEND_CLASS}", "Billing Address" }
                        for field in BUSINESS_ADDRESS {
                            components::Field { conf: *field }
                        }
                    }
                }

                fieldset {
                    id: "product-info",
                    class: "flex md:gap-4 flex-col md:flex-row",

                    legend { class: "{LEGEND_CLASS}", "Product Details" }
                    div { class: "flex gap-4",
                        for field in PRODUCT_INFO {
                            components::Field { conf: *field }
                        }
                    }
                    div { class: "flex gap-4",
                        for field in PRODUCT_PRICING {
                            components::Field { conf: *field }
                        }
                    }
                }
                div { class: "flex w-full gap-4 mt-4",
                    button {
                        class: "grow-8 bg-(--color-primary) text-xl disabled:cursor-not-allowed hover-fade",
                        onclick: move |_| {
                            println!("generate btn clicked");
                        },
                        "Generate Invoice"
                    }
                    button {
                        class: "grow-2 bg-(--color-primary) disabled:cursor-not-allowed hover-fade",
                        onclick: move |_| {
                            println!("plus");
                        },
                        img { class: "m-auto", src: "{plus_icon}" }
                    }
                }
            }
        }
    }
}
