const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../auth');

const router = express.Router();

// get point current
router.get('/balance', verifyToken, (req, res) => {
    const user_id = req.user.id;
    const sql = `
        SELECT COALESCE(SUM(points_delta), 0) AS total_points
        FROM point_transactions
        WHERE user_id = ?
    `;

    con.query(sql, [user_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        return res.json({
            user_id: user_id,
            total_points: result[0].total_points
        });
    });
});

// get point history
router.get('/history', verifyToken, (req, res) => {
    const user_id = req.user.id;
    const sql = `
        SELECT *
        FROM point_transactions
        WHERE user_id = ?
        ORDER BY created_at DESC
    `;

    con.query(sql, [user_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }
        return res.json(result);
    });
});

// adds points after successful
router.post('/earn', verifyToken, verifyAdmin, (req, res) => {
    const { user_id, order_id, points } = req.body;
    // Check order and payment
    const checkSql = `
        SELECT orders.order_id, orders.user_id
        FROM orders
        INNER JOIN payments
        ON orders.order_id = payments.order_id
        WHERE orders.order_id = ?
        AND orders.user_id = ?
        AND payments.status = 'Paid'
    `;

    if (!user_id || !order_id || !Number.isInteger(points) || points <= 0) {
        return res.status(400).send("Invalid input");
    }

    con.query(checkSql, [order_id, user_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.length === 0) {
            return res.status(400).send("Order payment is not completed");
        }

        // Generate unique event key for this order
        const event_key = 'ORDER_' + order_id;

        const insertSql = `
            INSERT INTO point_transactions
            (user_id, order_id, event_key, type, points_delta)
            VALUES (?, ?, ?, 'Earn', ?)
        `;

        con.query(insertSql, [user_id, order_id, event_key, points], (err, insertResult) => {
            if (err) {
                // Duplicate event_key
                if (err.code === "ER_DUP_ENTRY") {
                    return res.status(409).send("Points already added for this order");
                }

                console.error(err);
                return res.status(500).send("Cannot add points");
            }

            return res.status(201).json({
                message: "Points added successfully",
                point_transaction_id: insertResult.insertId,
                user_id: user_id,
                order_id: order_id,
                points_added: points
            });
        });
    });
});

module.exports = router;
