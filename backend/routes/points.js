const express = require('express');
const con = require('../db_config');
const { verifyToken } = require('../auth');

const router = express.Router();

// Users see their own point history; admins may filter by user_id.
router.get('/', verifyToken, (req, res) => {
    const requestedUserId = req.query.user_id;
    const userId = req.user.role === 'admin' && requestedUserId
        ? requestedUserId
        : req.user.id;

    const sql = `
        SELECT *
        FROM point_transactions
        WHERE user_id = ?
        ORDER BY created_at DESC
    `;
    con.query(sql, [userId], (err, rows) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'DB error' });
        }
        return res.json(rows);
    });
});

module.exports = router;
