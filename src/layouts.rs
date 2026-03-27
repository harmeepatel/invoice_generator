use dioxus::prelude::*;

#[component]
pub fn Base(children: Element) -> Element {
    rsx! {
        body { class: "px-4 py-2",
            crate::components::Nav {}
            {children}
        }
    }
}
