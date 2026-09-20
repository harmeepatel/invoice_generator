pub const APP_NAME: &str = "AE";

#[derive(Clone, Debug, PartialEq)]
pub struct AppSettings {
    pub app_name: String,
    pub company_name: String,
    pub company_owner: String,
    pub company_gstin: String,
    pub company_email: String,
    pub company_phone_1: String,
    pub company_phone_2: String,
    pub company_address: String,
    pub bank_name: String,
    pub bank_branch: String,
    pub bank_account: String,
    pub bank_ifsc: String,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            app_name: APP_NAME.into(),
            company_name: "Achal Enterprise".into(),
            company_owner: "Rohit Patel".into(),
            company_gstin: "24AAZPP2696Q1ZE".into(),
            company_email: "achalenterprise@yahoo.com".into(),
            company_phone_1: "+91 95588 90077".into(),
            company_phone_2: "+91 70963 04530".into(),
            company_address: "G.F.-40, Chanakya Plaza, Nr. Swagat-3, New C.G. Road, Chandkheda, Ahmedabad, GUJARAT - 382424".into(),
            bank_name: "ICICI Bank Ltd.".into(),
            bank_branch: "New C.G. Road, Chandkheda".into(),
            bank_account: "062505500142".into(),
            bank_ifsc: "ICIC0000625".into(),
        }
    }
}
