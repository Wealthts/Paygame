const express = require('express');
const con = require('../db_config');
const { verifyToken } = require('../auth');

const router = express.Router();

// Return the order details, related game/package, and its payment as a receipt.
router.get('/:order_id', verifyToken, (req, res) => {
    const sql = `
        SELECT o.*, u.username, u.display_name,
               p.package_name, p.points AS package_points,
               g.game_name,
               pay.payment_id, pay.payment_method, pay.transaction_ref,
               pay.status AS payment_status, pay.created_at AS paid_at
        FROM orders o
        INNER JOIN users u ON u.user_id = o.user_id
        LEFT JOIN packages p ON p.package_id = o.package_id
        LEFT JOIN games g ON g.game_id = p.game_id
        LEFT JOIN payments pay ON pay.order_id = o.order_id
        WHERE o.order_id = ? AND (? = 'admin' OR o.user_id = ?)
        ORDER BY pay.payment_id DESC
        LIMIT 1
    `;
    con.query(sql, [req.params.order_id, req.user.role, req.user.id], (err, rows) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'DB error' });
        }
        if (rows.length === 0) return res.status(404).json({ message: 'Receipt not found' });
        return res.json(rows[0]);
    });
});

module.exports = router;
