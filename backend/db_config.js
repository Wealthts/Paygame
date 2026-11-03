const mysql = require('mysql2');

const con = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'paygame'
});

con.connect((err) => {
    if (err) return console.log('Database connection failed:', err);
    console.log('Connected to paygame database');
});

module.exports = con;
