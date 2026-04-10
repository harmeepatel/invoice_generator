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
        let mut err = conf.error;
        err.set(match conf.name {
            "name" => crate::validate::name(&val),
            "companyName" => crate::validate::company_name(&val),
            "igst" => crate::validate::igst(&val),
            "gstin" => crate::validate::gstin(&val),
            "email" => crate::validate::email(&val),
            "phone" => crate::validate::phone(&val),
            "remark" => crate::validate::remark(&val),
            "shopNo" => crate::validate::shop_no(&val),
            "line1" => crate::validate::line(&val, true),
            "line2" | "line3" => crate::validate::line(&val, false),
            "city" => crate::validate::city(&val),
            "postalCode" => crate::validate::postal_code("", &val), // state TBD
            "serialNumber" => crate::validate::serial_number(&val),
            "productName" => crate::validate::product_name(&val),
            "hsn" => crate::validate::hsn(&val),
            "gst" => crate::validate::gst(&val),
            "quantity" => crate::validate::quantity(&val),
            "rate" => crate::validate::rate(&val),
            "discount" => crate::validate::discount(&val),
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
                        div { class: "flex w-full",
                            select {
                                id: phone_ext.clone(),
                                name: phone_ext.clone(),
                                class: "text-lg rounded-r-none appearance-none",
                                autocomplete: "tel-country-code",
                                option { value: "91", selected: true, "🇮🇳 +91" }
                                option { value: "011", "🇮🇳 011" }
                            }
                            input {
                                id: conf.name,
                                r#type: conf.field_type,
                                name: conf.name,
                                class: "w-full max-w-full text-lg h-auto rounded-l-none",
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
