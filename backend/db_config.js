const mysql = require("mysql2");
const con = mysql.createConnection({
    host: '127.0.0.1',
    user: 'root',
    password: 'root',
    database: 'todo'
});

con.connect((err) => {
    if (err) {
        console.error('MySQL connection failed:', err.message);
    }
});

module.exports = con;

