const express = require('express');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const con = require('../db_config');

const router = express.Router();
const JWT_KEY = 'paygame_secret_key';

// Register
// POST /api/register
router.post('/register', async (req, res) => {
    try {
        console.log('========== REGISTER DEBUG ==========');
        console.log('Content-Type:', req.headers['content-type']);
        console.log('Request Body:', JSON.stringify(req.body, null, 2));
        const { username, password, email, display_name } = req.body;

        console.log('Username:', username);
        console.log('Password:', password ? 'Received' : 'Missing');
        console.log('Email:', email);
        console.log('Display Name:', display_name);

        // Validate input
        if (!username || !password || !email || !display_name) {
            console.log('Register Request:', req.body);
            return res.status(400).json({
                message: 'Please fill in all required fields',
            });
        }

        if (
            username.trim().length < 3 ||
            password.length < 6 ||
            !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
        ) {
            return res.status(400).json({
                message: 'Invalid username, password or email',
            });
        }

        // Check duplicate username
        const checkSql = 'SELECT user_id FROM users WHERE username = ?';

        con.query(checkSql, [username.trim()], async (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).json({
                    message: 'DB error',
                });
            }

            if (result.length > 0) {
                return res.status(409).json({
                    message: 'Username already exists',
                });
            }

            try {
                // Hash password
                const passwordHash = await argon2.hash(password);

                // Insert user
                const insertSql = `
                    INSERT INTO users
                    (username, password_hash, email, display_name, role, is_active)
                    VALUES (?, ?, ?, ?, 'user', 1)
                `;

                con.query(
                    insertSql,
                    [username.trim(), passwordHash, email.trim(), display_name.trim()],
                    (err, insertResult) => {
                        if (err) {
                            console.error(err);
                            return res.status(500).json({
                                message: 'Registration failed',
                            });
                        }

                        return res.status(201).json({
                            message: 'Register successful',
                            user: {
                                id: insertResult.insertId,
                                username: username.trim(),
                                display_name: display_name.trim(),
                                role: 'user',
                            },
                        });
                    },
                );
            } catch (error) {
                console.error(error);
                return res.status(500).json({
                    message: 'Password hashing failed',
                });
            }
        });
    } catch (error) {
        console.error(error);
        return res.status(500).json({
            message: 'Server error',
        });
    }
});

// login
// POST /api/login
router.post('/login', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({
            message: 'Username and password are required',
        });
    }

    const sql = `
        SELECT user_id, username, password_hash,
               display_name, role, is_active
        FROM users
        WHERE username = ?
    `;

    con.query(sql, [username.trim()], async (err, result) => {
        // Check database error first
        if (err) {
            console.error(err);
            return res.status(500).json({
                message: 'DB error',
            });
        }

        if (result.length === 0) {
            return res.status(401).json({
                message: 'Invalid username or password',
            });
        }

        const user = result[0];

        if (user.is_active !== 1) {
            return res.status(403).json({
                message: 'This account is inactive',
            });
        }

        try {
            // Verify password
            const passwordMatch = await argon2.verify(user.password_hash, password);

            if (!passwordMatch) {
                return res.status(401).json({
                    message: 'Invalid username or password',
                });
            }

            // Create JWT
            const token = jwt.sign(
                {
                    id: user.user_id,
                    username: user.username,
                    role: user.role,
                },
                JWT_KEY,
                {
                    expiresIn: '1d',
                },
            );

            return res.json({
                message: 'Login successful',
                token: token,
                user: {
                    id: user.user_id,
                    username: user.username,
                    display_name: user.display_name,
                    role: user.role,
                },
            });
        } catch (error) {
            console.error(error);
            return res.status(500).json({
                message: 'Login failed',
            });
        }
    });
});

module.exports = router;
