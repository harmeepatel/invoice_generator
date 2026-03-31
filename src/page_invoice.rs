use dioxus::prelude::*;

#[component]
pub fn Index(title: String) -> Element {
    rsx! {
        document::Title { "{title}" }

        main { "Invoice" }
    }
}
