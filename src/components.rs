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
                    Link { class: LINK_CLASS, to: Route::Home {}, "Home" }
                }
                li {
                    Link { class: LINK_CLASS, to: Route::InvoiceView {}, "Invoice" }
                }
                li {
                    Link { class: LINK_CLASS, to: Route::Products {}, "Products" }
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

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FieldType {
    Select,
    Phone,
    Text,
    Number,
    Email,
}

impl FieldType {
    pub fn as_str(&self) -> &'static str {
        match self {
            FieldType::Select => "select",
            FieldType::Phone => "tel",
            FieldType::Text => "text",
            FieldType::Number => "number",
            FieldType::Email => "email",
        }
    }
}

#[component]
pub fn Field(
    id: String,
    field_type: FieldType,
    placeholder: String,
    legend: String,
    value: String,
    error: Option<String>,
    step: String,
    oninput: EventHandler<String>,
) -> Element {
    rsx! {
        div { class: "min-w-0 pb-3",
            label {
                class: "py-0 text-xl font-light flex justify-between items-end mb-1",
                r#for: "{id}",
                "{legend}"
                if let Some(error) = error.as_deref() {
                    span { class: "block wrap-break-word max-w-3/5 text-red-400 text-base",
                        "{error}"
                    }
                }
            }
            input {
                id: "{id}",
                r#type: field_type.as_str(),
                name: "{id}",
                class: "w-full max-w-full text-lg h-auto",
                placeholder: "{placeholder}",
                value: "{value}",
                step: "{step}",
                autocomplete: get_autocomplete_token(&id),
                oninput: move |event| oninput.call(event.value()),
            }
        }
    }
}
