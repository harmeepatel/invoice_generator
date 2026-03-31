use dioxus::prelude::*;

#[component]
pub fn Base(children: Element) -> Element {
    rsx! {
        body {
            crate::components::Nav {}
            {children}
        }
    }
}
