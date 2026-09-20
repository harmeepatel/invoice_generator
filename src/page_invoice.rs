use crate::models::ACTIVE_INVOICE_PREVIEW;
use dioxus::prelude::*;

#[component]
pub fn Index(title: String) -> Element {
    let invoice_html = ACTIVE_INVOICE_PREVIEW.read().clone();

    rsx! {
        document::Title { "{title}" }

        main { class: "h-[calc(100vh-44px)] overflow-auto p-4",
            if let Some(html) = invoice_html.as_ref() {
                div { class: "w-[210mm] min-h-[297mm] mx-auto bg-white p-[10mm] rounded-xl",
                    div { dangerous_inner_html: "{html}" }
                }
            } else {
                div { class: "h-full flex items-center justify-center text-gray-400",
                    "Preview an invoice from Home to view it here."
                }
            }
        }
    }
}
