const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../auth');

const router = express.Router();

// get all user
router.get('/', verifyToken, verifyAdmin, (req, res) => {
    const sql = `
        SELECT
            user_id,
            username,
            display_name,
            role,
            is_active,
            created_at
        FROM users
        ORDER BY user_id DESC
    `;

    con.query(sql, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error")
        }

        return res.json({
            total_users: result.length,
            users: result
        });
    });
});

module.exports = router;