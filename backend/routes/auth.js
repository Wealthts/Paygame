const express = require('express');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const con = require('../db_config');

const router = express.Router();
const JWT_KEY = 'paygame_secret_key';

// Register
router.post('/register', (req, res) => {
    const { username, password, display_name } = req.body;
    const hash = argon2.hashSync(password);
    const sql = "INSERT INTO users (username, password_hash, display_name, role, is_active) VALUES (?, ?, ?, 'user', 1)";

    con.query(sql, [username, hash, display_name], (err) => {

        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        return res.send('Register successful');
    });

    if (!username || !password || !display_name) {
        return res.status(400).send('Please fill all fields');
    }
});

// Login
router.post('/login', (req, res) => {
    const { username, password } = req.body;
    const sql = "SELECT * FROM users WHERE username = ?";

    con.query(sql, [username], (err, result) => {
        const user = result[0];

        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        if (result.length !== 1) {
            return res.status(401).send('Wrong username');
        }

        // Check account status
        if (user.is_active !== 1) {
            return res.status(403).send('Account disabled');
        }

        // Check password
        const same = argon2.verifySync(
            user.password_hash,
            password
        );

        if (!same) {
            return res.status(401).send('Wrong password');
        }

        // Create JWT
        const payload = {
            id: user.user_id,
            username: user.username,
            role: user.role
        };

        const token = jwt.sign(payload, JWT_KEY, {
            expiresIn: '1d'
        });

        res.json({
            message: 'Login successful',
            token: token,
            user: {
                id: user.user_id,
                username: user.username,
                display_name: user.display_name,
                role: user.role
            }
        });
    });
});

module.exports = router;