use dioxus::{html::script::defer, prelude::*};

#[component]
pub fn Base(children: Element) -> Element {
    rsx! {
        body {
            crate::components::Nav {}
            {children}
        }
    }
}
