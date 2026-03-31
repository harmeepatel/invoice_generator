use dioxus::prelude::*;
use dioxus_router::components::Link;

use crate::Route;

#[component]
pub fn Nav() -> Element {
    const LINK_CLASS: &str = "px-4 py-2 block hover:bg-(--color-hover)";
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
}

#[component]
pub fn Field(conf: FieldConfig) -> Element {
    rsx! {
        div { class: "min-w-0 pb-3",
            label {
                class: "py-0 text-xl font-light flex justify-between items-end mb-1",
                r#for: conf.name,

                {conf.legend}

                span { id: conf.name, class: "block wrap-break-word max-w-3/5" }
            }

            match conf.field_type {
                "select" => rsx! {
                    select {
                        id: conf.name,
                        name: conf.name,
                        class: "w-full max-w-full text-lg h-auto px-4 py-2 appearance-none",
                        autocomplete: "address-level1",



                        for state in crate::states::state_names() {
                            option { selected: state == "Gujarat", value: state, {state} }
                        }
                    }
                },
                "tel" => {
                    let phone_ext = format!("{}Ext", conf.name);
                    rsx! {
                        div { class: "join w-full",
                            select {
                                id: phone_ext.clone(),
                                name: phone_ext.clone(),
                                class: "join-item text-lg px-4 py-2 rounded-r-none appearance-none",
                                autocomplete: "tel-country-code",

                                option { value: "91", selected: true, "🇮🇳 +91" }
                                option { value: "011", "🇮🇳 011" }
                            }
                            input {
                                id: conf.name,
                                r#type: conf.field_type,
                                name: conf.name,
                                class: "join-item w-full max-w-full text-lg h-auto px-4 py-2 rounded-l-none",
                                placeholder: conf.placeholder,
                                autocomplete: "tel-national",
                            }
                        }
                    }
                }
                _ => rsx! {
                    input {
                        id: conf.name,
                        r#type: conf.field_type,
                        name: conf.name,
                        class: "w-full max-w-full text-lg h-auto px-4 py-2",
                        placeholder: conf.placeholder,
                        autocomplete: get_autocomplete_token(conf.name),
                    }
                },
            }
        }
    }
}
