use dioxus::prelude::*;

use crate::layouts;

#[component]
pub fn Index(title: String) -> Element {
    rsx! {
        document::Title { "{title}" }

        layouts::Base {
            main { "Invoice" }
        }
    }
}
