const mysql = require('mysql2');
// A dedicated pooled connection is required for each checkout transaction.
module.exports = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'paygame',
    connectionLimit: 10
});
