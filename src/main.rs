#[allow(dead_code)]
mod components;
mod config;
mod database;
mod invoice_pdf;
mod layouts;
mod models;
mod page_index;
mod page_invoice;
mod page_products;
mod page_settings;
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
    #[route("/settings")]
    Settings {},
}

fn main() {
    database::initialize().expect("Could not initialize the local database");
    let app_name = database::settings()
        .unwrap_or_default()
        .app_name
        .to_uppercase();

    let window = WindowBuilder::new()
        .with_min_inner_size(LogicalSize::new(160 * 4, 100 * 4))
        .with_always_on_top(false)
        .with_title(app_name);

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

fn page_title(page: &str) -> String {
    let app_name = database::settings()
        .unwrap_or_default()
        .app_name
        .to_uppercase();
    format!("{app_name} - {page}")
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
            page_index::Index { title: page_title("Home") }
        }
    }
}

#[component]
fn InvoiceView() -> Element {
    rsx! {
        layouts::Base {
            page_invoice::Index { title: page_title("Invoice") }
        }
    }
}

#[component]
fn Products() -> Element {
    rsx! {
        layouts::Base {
            page_products::Index { title: page_title("Products") }
        }
    }
}

#[component]
fn Settings() -> Element {
    rsx! {
        layouts::Base {
            page_settings::Index { title: page_title("Settings") }
        }
    }
}
