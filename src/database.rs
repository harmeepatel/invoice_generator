use crate::config::APP_NAME;
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
            );",
        )
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
