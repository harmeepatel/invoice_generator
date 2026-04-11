use crate::models::{ACTIVE_INVOICE, ACTIVE_ITEM};
use crate::Route;
use dioxus::prelude::*;
use dioxus_router::components::Link;

#[component]
pub fn Nav() -> Element {
    const LINK_CLASS: &str = "px-4 py-2 block hover:bg-(--color-hover) hover-fade";
    rsx! {
        nav { class: "sticky top-0 m-auto bg-transparent backdrop-blur-lg z-999",
            ul { class: "flex",
                li {
                    Link { class: "{LINK_CLASS}", to: Route::Home {}, "Home" }
                }
                li {
                    Link { class: "{LINK_CLASS}", to: Route::InvoiceView {}, "Invoice" }
                }
            }
        }
    }
}

fn get_autocomplete_token(input_name: &str) -> &'static str {
    match input_name {
        _ => "off",
    }
}
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct FieldConfig {
    pub field_type: &'static str,
    pub name: &'static str,
    pub placeholder: &'static str,
    pub legend: &'static str,
    pub error: Signal<Option<String>>,
}

#[component]
pub fn Field(conf: FieldConfig) -> Element {
    let validate = move |evt: Event<FormData>| {
        let val = evt.value();
        let mut inv = ACTIVE_INVOICE.write();
        let mut item = ACTIVE_ITEM.write();

        conf.error.set(match conf.name {
            "name" => crate::validate::name(&val).or_else(|| {
                inv.customer.name = val.clone();
                None
            }),
            "companyName" => crate::validate::company_name(&val).or_else(|| {
                inv.customer.company_name = val.clone();
                None
            }),
            "igst" => crate::validate::igst(&val).or_else(|| {
                inv.igst_rate = val.parse().unwrap_or(0.0);
                None
            }),
            "gstin" => crate::validate::gstin(&val).or_else(|| {
                inv.customer.gstin = val.clone();
                None
            }),
            "email" => crate::validate::email(&val).or_else(|| {
                inv.customer.email = val.clone();
                None
            }),
            "phone" => crate::validate::phone(&val).or_else(|| {
                inv.customer.phone = val.clone();
                None
            }),
            "remark" => crate::validate::remark(&val).or_else(|| {
                inv.customer.remark = val.clone();
                None
            }),
            "shopNo" => crate::validate::shop_no(&val).or_else(|| {
                inv.customer.shop_no = val.clone();
                None
            }),
            "line1" => crate::validate::line(&val, true).or_else(|| {
                inv.customer.line1 = val.clone();
                None
            }),
            "line2" => crate::validate::line(&val, false).or_else(|| {
                inv.customer.line2 = val.clone();
                None
            }),
            "line3" => crate::validate::line(&val, false).or_else(|| {
                inv.customer.line3 = val.clone();
                None
            }),
            "city" => crate::validate::city(&val).or_else(|| {
                inv.customer.city = val.clone();
                None
            }),
            "state" => {
                inv.customer.state = val.clone();
                None
            }
            "postalCode" => crate::validate::postal_code(&inv.customer.state, &val).or_else(|| {
                inv.customer.postal_code = val.parse().unwrap_or(0);
                None
            }),
            "serialNumber" => crate::validate::serial_number(&val).or_else(|| {
                item.serial_number = val.clone();
                None
            }),
            "productName" => crate::validate::product_name(&val).or_else(|| {
                item.name = val.clone();
                None
            }),
            "hsn" => crate::validate::hsn(&val).or_else(|| {
                item.hsn = val.clone();
                None
            }),
            "gst" => crate::validate::gst(&val).or_else(|| {
                item.gst = val.parse().unwrap_or(0.0);
                None
            }),
            "quantity" => crate::validate::quantity(&val).or_else(|| {
                item.quantity = val.parse().unwrap_or(0);
                None
            }),
            "rate" => crate::validate::rate(&val).or_else(|| {
                item.rate = val.parse().unwrap_or(0.0);
                None
            }),
            "discount" => crate::validate::discount(&val).or_else(|| {
                item.discount = val.parse().unwrap_or(0.0);
                None
            }),
            _ => None,
        });
    };

    rsx! {
        div { class: "min-w-0 pb-3",
            label {
                class: "py-0 text-xl font-light flex justify-between items-end mb-1",
                r#for: conf.name,
                {conf.legend}
                if let Some(err) = conf.error.read().as_deref() {
                    span { class: "block wrap-break-word max-w-3/5 text-red-400 text-base",
                        {err}
                    }
                }
            }

            match conf.field_type {
                "select" => rsx! {
                    select {
                        id: conf.name,
                        name: conf.name,
                        class: "w-full max-w-full text-lg h-auto appearance-none",
                        autocomplete: "address-level1",
                        onchange: validate,
                        for state in crate::states::state_names() {
                            option { selected: state == "Gujarat", value: state, {state} }
                        }
                    }
                },

                "tel" => {
                    let phone_ext = format!("{}Ext", conf.name);
                    rsx! {
                        div { class: "flex w-full join",
                            select {
                                id: phone_ext.clone(),
                                name: phone_ext.clone(),
                                class: "join-item text-lg rounded-r-none appearance-none",
                                autocomplete: "tel-country-code",
                                option { value: "91", selected: true, "🇮🇳 +91" }
                                option { value: "011", "🇮🇳 011" }
                            }
                            input {
                                id: conf.name,
                                r#type: conf.field_type,
                                name: conf.name,
                                class: "join-item w-full max-w-full text-lg h-auto rounded-l-none",
                                placeholder: conf.placeholder,
                                autocomplete: "tel-national",
                                oninput: validate,
                            }
                        }
                    }
                }

                _ => rsx! {
                    input {
                        id: conf.name,
                        r#type: conf.field_type,
                        name: conf.name,
                        class: "w-full max-w-full text-lg h-auto",
                        placeholder: conf.placeholder,
                        autocomplete: get_autocomplete_token(conf.name),
                        oninput: validate,
                    }
                },
            }
        }
    }
}
