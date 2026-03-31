use dioxus::prelude::*;

use crate::components;

// <main role="main" id="main">
//    <section id="party-info" class="w-full mb-12">
//        <form>
//            <div class="flex w-full gap-4 mt-4">
//                <button
//                    type="submit"
//                    class="grow-8 btn btn-primary btn-lg text-xl disabled:cursor-not-allowed"
//                    data-attr:disabled="$hasError"
//                    disabled
//                >
//                    Generate Invoice
//                </button>
//                <button
//                    class="grow-2 btn btn-primary btn-lg brightness-300 disabled:cursor-not-allowed"
//                    type="button"
//                    data-on:click="@post('/product/add')"
//                    data-target="#products-list"
//                    data-swap="innerHTML"
//                    data-attr:disabled="$productHasError"
//                    disabled
//                >
//                    <svg
//                        xmlns="http://www.w3.org/2000/svg"
//                        height="24px"
//                        viewBox="0 -960 960 960"
//                        width="24px"
//                        fill="#e3e3e3"
//                    >
//                        <path d="M440-120v-320H120v-80h320v-320h80v320h320v80H520v320h-80Z"></path>
//                    </svg>
//                </button>
//            </div>
//        </form>
//    </section>
//    <section id="product-list" class="overflow-x-auto max-h-[640px] lg:max-h-[1024px]">
//        <table class="table table-pin-rows table-pin-cols text-balance">
//            <thead class="text-lg font-light">
//                @tableHeader()
//            </thead>
//            @component.ProductBody()
//            <tfoot class="text-lg font-light">
//                @tableHeader()
//            </tfoot>
//        </table>
//    </section>
//</main>
// Helper macro to cut down boilerplate

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
    const LEGEND_CLASS: &str = "font-light";
    let plus_icon = asset!("/assets/media/plus.svg");

    rsx! {
        document::Title { "{title}" }

        main { class: "max-w-6xl m-auto mb-4 p-4",
            h1 { class: "text-4xl", "Party Information" }
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
                        class: "grow-8 bg-(--color-primary) text-xl disabled:cursor-not-allowed",
                        onclick: move |_| {
                            println!("generate btn clicked");
                        },
                        "Generate Invoice"
                    }
                    button {
                        class: "grow-2 bg-(--color-primary) disabled:cursor-not-allowed",
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
