use crate::components;
use dioxus::prelude::*;

macro_rules! field {
    ($t:expr, $n:expr, $p:expr, $l:expr, $e:expr) => {
        crate::components::FieldConfig {
            field_type: $t,
            name: $n,
            placeholder: $p,
            legend: $l,
            error: $e,
        }
    };
}

#[component]
pub fn Index(title: String) -> Element {
    const LEGEND_CLASS: &str = "font-light w-fit";
    let plus_icon = asset!("/assets/media/plus.svg");

    let name_err = use_signal(|| None::<String>);
    let company_err = use_signal(|| None::<String>);
    let igst_err = use_signal(|| None::<String>);
    let gstin_err = use_signal(|| None::<String>);
    let email_err = use_signal(|| None::<String>);
    let phone_err = use_signal(|| None::<String>);
    let remark_err = use_signal(|| None::<String>);
    let shop_no_err = use_signal(|| None::<String>);
    let line1_err = use_signal(|| None::<String>);
    let line2_err = use_signal(|| None::<String>);
    let line3_err = use_signal(|| None::<String>);
    let city_err = use_signal(|| None::<String>);
    let state_err = use_signal(|| None::<String>);
    let postal_err = use_signal(|| None::<String>);
    let serial_err = use_signal(|| None::<String>);
    let prod_name_err = use_signal(|| None::<String>);
    let hsn_err = use_signal(|| None::<String>);
    let qty_err = use_signal(|| None::<String>);
    let rate_err = use_signal(|| None::<String>);
    let discount_err = use_signal(|| None::<String>);
    let gst_err = use_signal(|| None::<String>);

    let business_info = [
        field!("text", "name", "Rohit Patel", "Name", name_err),
        field!(
            "text",
            "companyName",
            "Achal Enterprise",
            "Company Name",
            company_err
        ),
        field!("number", "igst", "", "IGST", igst_err),
        field!("text", "gstin", "24ABCPM1234L1Z5", "GSTIN", gstin_err),
        field!(
            "email",
            "email",
            "abc@xyz.com",
            "Email (Optional)",
            email_err
        ),
        field!("tel", "phone", "11111 99999", "Phone", phone_err),
        field!(
            "text",
            "remark",
            "XYZ Missing in order",
            "Remark (Optional)",
            remark_err
        ),
    ];

    let business_address = [
        field!("text", "shopNo", "A123", "Shop No", shop_no_err),
        field!("text", "line1", "Complex / Plaza", "Line 1", line1_err),
        field!("text", "line2", "Landmark", "Line 2 (Optional)", line2_err),
        field!(
            "text",
            "line3",
            "Street Name",
            "Line 3 (Optional)",
            line3_err
        ),
        field!("text", "city", "Ahmedabad", "City", city_err),
        field!("select", "state", "Gujarat", "State", state_err),
        field!("number", "postalCode", "382424", "Postal Code", postal_err),
    ];

    let product_info = [
        field!("text", "serialNumber", "A1B2C3", "Serial #", serial_err),
        field!("text", "productName", "Bib Cock", "Name", prod_name_err),
        field!("text", "hsn", "123456", "HSN", hsn_err),
    ];

    let product_pricing = [
        field!("number", "quantity", "4", "Quantity", qty_err),
        field!("number", "rate", "256", "₹ Rate", rate_err),
        field!("number", "discount", "5", "Discount", discount_err),
        field!("number", "gst", "5.0", "GST", gst_err),
    ];

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
                        for field in business_info {
                            components::Field { conf: field }
                        }
                    }

                    fieldset { id: "right", class: "w-full min-w-0",
                        legend { class: "{LEGEND_CLASS}", "Billing Address" }
                        for field in business_address {
                            components::Field { conf: field }
                        }
                    }
                }

                fieldset {
                    id: "product-info",
                    class: "flex md:gap-4 flex-col md:flex-row",

                    legend { class: "{LEGEND_CLASS}", "Product Details" }
                    div { class: "flex gap-4",
                        for field in product_info {
                            components::Field { conf: field }
                        }
                    }
                    div { class: "flex gap-4",
                        for field in product_pricing {
                            components::Field { conf: field }
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
