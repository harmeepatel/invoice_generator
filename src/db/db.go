package db

import "database/sql"

func Init(db *sql.DB) error {
	return createTable(db)
}

func createTable(db *sql.DB) error {
	_, err := db.Exec(`
        CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY,
            ...
        );
    `)
	return err
}
