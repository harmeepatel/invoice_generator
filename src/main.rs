#[allow(dead_code)]
mod components;
mod config;
mod layouts;
mod page_index;
mod page_invoice;
mod states;

use dioxus::prelude::*;
use dioxus_desktop::{Config, LogicalSize, WindowBuilder};

#[derive(Clone, Routable, Debug, PartialEq)]
enum Route {
    #[route("/")]
    Home {},
    #[route("/invoice")]
    InvoiceView {},
}

fn main() {
    let window = WindowBuilder::new()
        .with_min_inner_size(LogicalSize::new(160 * 4, 100 * 4))
        .with_always_on_top(false)
        .with_title(config::APP_NAME.to_uppercase());

    let config = Config::default().with_window(window.with_background_color((0, 0, 0, 0)));
    dioxus::LaunchBuilder::new().with_cfg(config).launch(App);
}

#[component]
fn App() -> Element {
    rsx! {
        document::Stylesheet { href: asset!("/assets/css/tailwind.css") }
        Router::<Route> {}
    }
}

#[component]
fn Home() -> Element {
    rsx! {
        page_index::Index { title: config::APP_NAME.to_uppercase() + " - Home" }
    }
}

#[component]
fn InvoiceView() -> Element {
    rsx! {
        page_invoice::Index { title: config::APP_NAME.to_uppercase() + " - Invoice" }
    }
}
