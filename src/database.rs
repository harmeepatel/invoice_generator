use crate::config::{AppSettings, APP_NAME};
use crate::models::Product;
use directories::ProjectDirs;
use rusqlite::{params, Connection};
use std::fs;
use std::path::PathBuf;

fn database_path() -> Result<PathBuf, String> {
    let project_dirs = ProjectDirs::from("com", "Harmee", APP_NAME)
        .ok_or_else(|| "Could not locate the application data directory".to_string())?;
    let data_dir = project_dirs.data_dir();

    fs::create_dir_all(data_dir).map_err(|error| error.to_string())?;
    Ok(data_dir.join("ae.sqlite3"))
}

fn connection() -> Result<Connection, String> {
    Connection::open(database_path()?).map_err(|error| error.to_string())
}

pub fn initialize() -> Result<(), String> {
    connection()?
        .execute_batch(
            "CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                serial_number TEXT NOT NULL UNIQUE COLLATE NOCASE,
                name TEXT NOT NULL,
                hsn TEXT NOT NULL,
                rate_paise INTEGER NOT NULL CHECK (rate_paise > 0),
                gst_basis_points INTEGER NOT NULL CHECK (
                    gst_basis_points >= 0 AND gst_basis_points <= 4000
                ),
                stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
            );

            CREATE TABLE IF NOT EXISTS settings (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                app_name TEXT NOT NULL,
                company_name TEXT NOT NULL,
                company_owner TEXT NOT NULL,
                company_gstin TEXT NOT NULL,
                company_email TEXT NOT NULL,
                company_phone_1 TEXT NOT NULL,
                company_phone_2 TEXT NOT NULL,
                company_address TEXT NOT NULL,
                bank_name TEXT NOT NULL,
                bank_branch TEXT NOT NULL,
                bank_account TEXT NOT NULL,
                bank_ifsc TEXT NOT NULL
            );",
        )
        .map_err(|error| error.to_string())
}

pub fn settings() -> Result<AppSettings, String> {
    let connection = connection()?;
    let result = connection.query_row(
        "SELECT app_name, company_name, company_owner, company_gstin,
                company_email, company_phone_1, company_phone_2, company_address,
                bank_name, bank_branch, bank_account, bank_ifsc
         FROM settings WHERE id = 1",
        [],
        |row| {
            Ok(AppSettings {
                app_name: row.get(0)?,
                company_name: row.get(1)?,
                company_owner: row.get(2)?,
                company_gstin: row.get(3)?,
                company_email: row.get(4)?,
                company_phone_1: row.get(5)?,
                company_phone_2: row.get(6)?,
                company_address: row.get(7)?,
                bank_name: row.get(8)?,
                bank_branch: row.get(9)?,
                bank_account: row.get(10)?,
                bank_ifsc: row.get(11)?,
            })
        },
    );

    match result {
        Ok(settings) => Ok(settings),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(AppSettings::default()),
        Err(error) => Err(error.to_string()),
    }
}

pub fn save_settings(settings: &AppSettings) -> Result<(), String> {
    connection()?
        .execute(
            "INSERT INTO settings (
                id, app_name, company_name, company_owner, company_gstin,
                company_email, company_phone_1, company_phone_2, company_address,
                bank_name, bank_branch, bank_account, bank_ifsc
             ) VALUES (1, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)
             ON CONFLICT(id) DO UPDATE SET
                app_name = excluded.app_name,
                company_name = excluded.company_name,
                company_owner = excluded.company_owner,
                company_gstin = excluded.company_gstin,
                company_email = excluded.company_email,
                company_phone_1 = excluded.company_phone_1,
                company_phone_2 = excluded.company_phone_2,
                company_address = excluded.company_address,
                bank_name = excluded.bank_name,
                bank_branch = excluded.bank_branch,
                bank_account = excluded.bank_account,
                bank_ifsc = excluded.bank_ifsc",
            params![
                settings.app_name.trim(),
                settings.company_name.trim(),
                settings.company_owner.trim(),
                settings.company_gstin.trim(),
                settings.company_email.trim(),
                settings.company_phone_1.trim(),
                settings.company_phone_2.trim(),
                settings.company_address.trim(),
                settings.bank_name.trim(),
                settings.bank_branch.trim(),
                settings.bank_account.trim(),
                settings.bank_ifsc.trim(),
            ],
        )
        .map(|_| ())
        .map_err(|error| error.to_string())
}

pub fn products() -> Result<Vec<Product>, String> {
    let connection = connection()?;
    let mut statement = connection
        .prepare(
            "SELECT id, serial_number, name, hsn, rate_paise,
                    gst_basis_points, stock_quantity
             FROM products
             ORDER BY name COLLATE NOCASE, serial_number COLLATE NOCASE",
        )
        .map_err(|error| error.to_string())?;

    let rows = statement
        .query_map([], |row| {
            Ok(Product {
                id: row.get(0)?,
                serial_number: row.get(1)?,
                name: row.get(2)?,
                hsn: row.get(3)?,
                rate_paise: row.get(4)?,
                gst_basis_points: row.get(5)?,
                stock_quantity: row.get(6)?,
            })
        })
        .map_err(|error| error.to_string())?;

    rows.collect::<Result<Vec<_>, _>>()
        .map_err(|error| error.to_string())
}

pub fn save_product(product: &Product) -> Result<(), String> {
    let connection = connection()?;

    if product.id == 0 {
        connection.execute(
            "INSERT INTO products (
                serial_number, name, hsn, rate_paise,
                gst_basis_points, stock_quantity
             ) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                product.serial_number.trim(),
                product.name.trim(),
                product.hsn.trim(),
                product.rate_paise,
                product.gst_basis_points,
                product.stock_quantity,
            ],
        )
    } else {
        connection.execute(
            "UPDATE products
             SET serial_number = ?1,
                 name = ?2,
                 hsn = ?3,
                 rate_paise = ?4,
                 gst_basis_points = ?5,
                 stock_quantity = ?6
             WHERE id = ?7",
            params![
                product.serial_number.trim(),
                product.name.trim(),
                product.hsn.trim(),
                product.rate_paise,
                product.gst_basis_points,
                product.stock_quantity,
                product.id,
            ],
        )
    }
    .map(|_| ())
    .map_err(|error| error.to_string())
}

pub fn delete_product(id: i64) -> Result<(), String> {
    connection()?
        .execute("DELETE FROM products WHERE id = ?1", [id])
        .map(|_| ())
        .map_err(|error| error.to_string())
}

pub fn clear_products() -> Result<(), String> {
    let connection = connection()?;

    connection
        .execute_batch(
            "DELETE FROM products;
             DELETE FROM sqlite_sequence WHERE name = 'products';",
        )
        .map_err(|error| error.to_string())
}
