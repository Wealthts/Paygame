const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// All routes in this file are admin-only
router.use(verifyToken, verifyAdmin);

// GET /api/admin/receipts
// Every receipt with its order, user and payment details (newest first)
router.get('/receipts', (req, res) => {
    const sql = `
        SELECT receipts.receipt_id,
               receipts.receipt_number,
               receipts.issued_at,
               orders.order_id,
               orders.player_uid,
               orders.server_code,
               orders.game_name_snapshot,
               orders.package_name_snapshot,
               orders.original_price,
               orders.discount_amount,
               orders.fee_amount,
               orders.total_amount,
               orders.spent_points,
               orders.coupon_code_snapshot,
               users.username,
               users.display_name,
               payments.method,
               payments.status AS payment_status
        FROM receipts
        INNER JOIN orders ON receipts.order_id = orders.order_id
        INNER JOIN users ON orders.user_id = users.user_id
        LEFT JOIN payments ON payments.order_id = orders.order_id
        ORDER BY receipts.issued_at DESC
    `;

    con.query(sql, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        return res.json(result);
    });
});

// GET /api/admin/points/balances
// Current balance and lifetime earned points of every user
router.get('/points/balances', (req, res) => {
    const sql = `
        SELECT users.user_id,
               users.username,
               users.display_name,
               COALESCE(SUM(point_transactions.points_delta), 0) AS balance,
               COALESCE(SUM(CASE
                   WHEN point_transactions.type = 'Earn' THEN point_transactions.points_delta
                   ELSE 0
               END), 0) AS earned_total
        FROM users
        LEFT JOIN point_transactions ON point_transactions.user_id = users.user_id
        GROUP BY users.user_id, users.username, users.display_name
        ORDER BY balance DESC, users.username ASC
    `;

    con.query(sql, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        return res.json(result);
    });
});

// GET /api/admin/points/history
// Latest point transactions of all users (newest first, max 500 rows)
router.get('/points/history', (req, res) => {
    const sql = `
        SELECT point_transactions.point_transaction_id,
               point_transactions.user_id,
               point_transactions.order_id,
               point_transactions.event_key,
               point_transactions.type,
               point_transactions.points_delta,
               point_transactions.created_at,
               users.username,
               orders.game_name_snapshot,
               orders.package_name_snapshot
        FROM point_transactions
        INNER JOIN users ON point_transactions.user_id = users.user_id
        LEFT JOIN orders ON point_transactions.order_id = orders.order_id
        ORDER BY point_transactions.created_at DESC, point_transactions.point_transaction_id DESC
        LIMIT 500
    `;

    con.query(sql, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        return res.json(result);
    });
});

module.exports = router;
