mod components;
mod config;
mod database;
mod invoice_pdf;
mod layouts;
mod models;
mod page_index;
mod page_invoice;
mod page_products;
mod states;
mod validate;

use dioxus::prelude::*;
use dioxus_desktop::{Config, LogicalSize, WindowBuilder};

#[derive(Clone, Routable, Debug, PartialEq)]
enum Route {
    #[route("/")]
    Home {},
    #[route("/invoice")]
    InvoiceView {},
    #[route("/products")]
    Products {},
}

fn main() {
    database::initialize().expect("Could not initialize the local database");

    let window = WindowBuilder::new()
        .with_min_inner_size(LogicalSize::new(160 * 4, 100 * 4))
        .with_always_on_top(false)
        .with_title(config::APP_NAME.to_uppercase());

    let roboto = asset!("/assets/fonts/RobotoMono.ttf");
    let cascadia = asset!("/assets/fonts/Cascadia.ttf");
    let config = Config::default()
        .with_window(window.with_background_color((0, 0, 0, 0)))
        .with_custom_head(format!(
            r#"
                <style>
                    @font-face {{
                        font-family: "RobotoMono";
                        src: url({roboto}) format("truetype");
                        font-weight: 50 1000;
                        font-stretch: 20% 200%;
                    }}

                    @font-face {{
                        font-family: "Cascadia";
                        src: url({cascadia}) format("truetype");
                        font-weight: 50 1000;
                        font-stretch: 20% 200%;
                    }}
                </style>
            "#
        ));
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
        layouts::Base {
            page_index::Index { title: config::APP_NAME.to_uppercase() + " - Home" }
        }
    }
}

#[component]
fn InvoiceView() -> Element {
    rsx! {
        layouts::Base {
            page_invoice::Index { title: config::APP_NAME.to_uppercase() + " - Invoice" }
        }
    }
}

#[component]
fn Products() -> Element {
    rsx! {
        layouts::Base {
            page_products::Index { title: config::APP_NAME.to_uppercase() + " - Products" }
        }
    }
}
