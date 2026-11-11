const express = require('express');
const argon2 = require('@node-rs/argon2');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// get all users
router.get('/', verifyToken, verifyAdmin, (req, res) => {
    const sql = `
        SELECT user_id, username, email, display_name, role, is_active, created_at
        FROM users
        ORDER BY user_id DESC
    `;

    con.query(sql, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        return res.json({
            total_users: result.length,
            users: result,
        });
    });
});

// Find a user that is not an admin. Admin accounts can't be changed from the admin page.
function findNonAdmin(user_id, res, next) {
    con.query('SELECT user_id, role FROM users WHERE user_id = ?', [user_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        if (result.length === 0) {
            return res.status(404).send('User not found');
        }

        if (result[0].role === 'admin') {
            return res.status(403).send("Admin accounts can't be changed");
        }

        next();
    });
}

// promote a user to admin
router.put('/:id/role', verifyToken, verifyAdmin, (req, res) => {
    const user_id = req.params.id;

    if (req.body.role !== 'admin') {
        return res.status(400).send('Role can only be changed to admin');
    }

    findNonAdmin(user_id, res, () => {
        con.query("UPDATE users SET role = 'admin' WHERE user_id = ?", [user_id], (err) => {
            if (err) {
                console.error(err);
                return res.status(500).send('DB error');
            }
            return res.json({ user_id: Number(user_id), role: 'admin' });
        });
    });
});

// activate / deactivate a user
router.put('/:id/status', verifyToken, verifyAdmin, (req, res) => {
    const user_id = req.params.id;
    const is_active = req.body.is_active;

    if (typeof is_active !== 'boolean') {
        return res.status(400).send('is_active must be true or false');
    }

    findNonAdmin(user_id, res, () => {
        const sql = 'UPDATE users SET is_active = ? WHERE user_id = ?';

        con.query(sql, [is_active ? 1 : 0, user_id], (err) => {
            if (err) {
                console.error(err);
                return res.status(500).send('DB error');
            }
            return res.json({ user_id: Number(user_id), is_active: is_active });
        });
    });
});

// set a new password for a user
router.put('/:id/password', verifyToken, verifyAdmin, (req, res) => {
    const user_id = req.params.id;
    const password = req.body.password;

    if (typeof password !== 'string' || password.length < 6) {
        return res.status(400).send('Password must be at least 6 characters');
    }

    findNonAdmin(user_id, res, async () => {
        try {
            const passwordHash = await argon2.hash(password);
            const sql = 'UPDATE users SET password_hash = ? WHERE user_id = ?';

            con.query(sql, [passwordHash, user_id], (err) => {
                if (err) {
                    console.error(err);
                    return res.status(500).send('DB error');
                }
                return res.json({ user_id: Number(user_id), message: 'Password updated' });
            });
        } catch (err) {
            console.error(err);
            return res.status(500).send('Cannot hash password');
        }
    });
});

module.exports = router;
