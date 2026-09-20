use crate::components::{Field, FieldType};
use dioxus::prelude::*;

#[component]
fn SettingField(
    id: String,
    legend: String,
    value: String,
    field_type: FieldType,
    oninput: EventHandler<String>,
) -> Element {
    rsx! {
        Field {
            id,
            field_type,
            placeholder: String::new(),
            legend,
            value,
            error: None,
            step: "1".to_string(),
            oninput,
        }
    }
}

#[component]
pub fn Index(title: String) -> Element {
    let mut settings = use_signal(|| crate::database::settings().unwrap_or_default());
    let mut message = use_signal(|| None::<(bool, String)>);

    rsx! {
        document::Title { "{title}" }

        main { class: "max-w-7xl m-auto mb-4 p-4",
            h1 { class: "text-4xl mb-4", "Settings" }

            fieldset { class: "grid grid-cols-1 md:grid-cols-2 gap-x-8 mb-6",
                legend { class: "text-xl font-light mb-2", "Application" }
                SettingField {
                    id: "appName",
                    legend: "App Name",
                    field_type: FieldType::Text,
                    value: settings.read().app_name.clone(),
                    oninput: move |value| settings.write().app_name = value,
                }
            }

            fieldset { class: "grid grid-cols-1 md:grid-cols-2 gap-x-8 mb-6",
                legend { class: "text-xl font-light mb-2", "Company Details" }
                SettingField {
                    id: "companyName",
                    legend: "Company Name",
                    field_type: FieldType::Text,
                    value: settings.read().company_name.clone(),
                    oninput: move |value| settings.write().company_name = value,
                }
                SettingField {
                    id: "companyOwner",
                    legend: "Owner Name",
                    field_type: FieldType::Text,
                    value: settings.read().company_owner.clone(),
                    oninput: move |value| settings.write().company_owner = value,
                }
                SettingField {
                    id: "companyGstin",
                    legend: "GSTIN",
                    field_type: FieldType::Text,
                    value: settings.read().company_gstin.clone(),
                    oninput: move |value| settings.write().company_gstin = value,
                }
                SettingField {
                    id: "companyEmail",
                    legend: "Email",
                    field_type: FieldType::Email,
                    value: settings.read().company_email.clone(),
                    oninput: move |value| settings.write().company_email = value,
                }
                SettingField {
                    id: "companyPhone1",
                    legend: "Phone 1",
                    field_type: FieldType::Phone,
                    value: settings.read().company_phone_1.clone(),
                    oninput: move |value| settings.write().company_phone_1 = value,
                }
                SettingField {
                    id: "companyPhone2",
                    legend: "Phone 2",
                    field_type: FieldType::Phone,
                    value: settings.read().company_phone_2.clone(),
                    oninput: move |value| settings.write().company_phone_2 = value,
                }
                div { class: "md:col-span-2",
                    SettingField {
                        id: "companyAddress",
                        legend: "Address",
                        field_type: FieldType::Text,
                        value: settings.read().company_address.clone(),
                        oninput: move |value| settings.write().company_address = value,
                    }
                }
            }

            fieldset { class: "grid grid-cols-1 md:grid-cols-2 gap-x-8 mb-6",
                legend { class: "text-xl font-light mb-2", "Bank Details" }
                SettingField {
                    id: "bankName",
                    legend: "Bank",
                    field_type: FieldType::Text,
                    value: settings.read().bank_name.clone(),
                    oninput: move |value| settings.write().bank_name = value,
                }
                SettingField {
                    id: "bankBranch",
                    legend: "Branch",
                    field_type: FieldType::Text,
                    value: settings.read().bank_branch.clone(),
                    oninput: move |value| settings.write().bank_branch = value,
                }
                SettingField {
                    id: "bankAccount",
                    legend: "Account Number",
                    field_type: FieldType::Text,
                    value: settings.read().bank_account.clone(),
                    oninput: move |value| settings.write().bank_account = value,
                }
                SettingField {
                    id: "bankIfsc",
                    legend: "IFSC",
                    field_type: FieldType::Text,
                    value: settings.read().bank_ifsc.clone(),
                    oninput: move |value| settings.write().bank_ifsc = value,
                }
            }

            button {
                class: "w-full bg-(--color-primary) text-xl hover-fade",
                onclick: move |_| {
                    let current = settings.read().clone();
                    let values = [
                        &current.app_name,
                        &current.company_name,
                        &current.company_owner,
                        &current.company_gstin,
                        &current.company_email,
                        &current.company_phone_1,
                        &current.company_phone_2,
                        &current.company_address,
                        &current.bank_name,
                        &current.bank_branch,
                        &current.bank_account,
                        &current.bank_ifsc,
                    ];
                    if values.iter().any(|value| value.trim().is_empty()) {
                        message.set(Some((false, "All settings are required".into())));
                        return;
                    }
                    match crate::database::save_settings(&current) {
                        Ok(()) => message.set(Some((true, "Settings saved".into()))),
                        Err(error) => message.set(Some((false, error))),
                    }
                },
                "Save Settings"
            }

            if let Some((success, text)) = message.read().as_ref() {
                p { class: if *success { "text-green-400 mt-3" } else { "text-red-400 mt-3" },
                    "{text}"
                }
            }
        }
    }
}
