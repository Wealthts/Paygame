const express = require('express');
const con = require('../db_config');
const { verifyToken } = require('../auth');

const router = express.Router();

// Create a payment record for an existing order.
router.post('/', verifyToken, (req, res) => {
    const { order_id, payment_method, transaction_ref } = req.body;

    if (!Number.isInteger(Number(order_id)) || Number(order_id) <= 0 || !payment_method) {
        return res.status(400).json({ message: 'order_id and payment_method are required' });
    }

    const sql = `
        SELECT order_id, user_id, total_amount
        FROM orders
        WHERE order_id = ?
    `;

    con.query(sql, [order_id], (err, orders) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'DB error' });
        }
        if (orders.length === 0) return res.status(404).json({ message: 'Order not found' });
        if (req.user.role !== 'admin' && Number(orders[0].user_id) !== Number(req.user.id)) {
            return res.status(403).json({ message: 'You cannot pay for this order' });
        }

        const insertSql = `
            INSERT INTO payments (order_id, amount, payment_method, transaction_ref, status)
            VALUES (?, ?, ?, ?, 'pending')
        `;
        con.query(insertSql, [order_id, orders[0].total_amount, payment_method, transaction_ref || null], (insertErr, result) => {
            if (insertErr) {
                console.error(insertErr);
                return res.status(500).json({ message: 'DB error' });
            }
            return res.status(201).json({
                message: 'Payment created',
                payment_id: result.insertId,
                order_id: Number(order_id),
                amount: orders[0].total_amount,
                payment_method,
                status: 'pending'
            });
        });
    });
});

// Get payment information for an order.
router.get('/:order_id', verifyToken, (req, res) => {
    const sql = `
        SELECT p.*
        FROM payments p
        INNER JOIN orders o ON o.order_id = p.order_id
        WHERE p.order_id = ? AND (? = 'admin' OR o.user_id = ?)
        ORDER BY p.payment_id DESC
    `;
    con.query(sql, [req.params.order_id, req.user.role, req.user.id], (err, rows) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'DB error' });
        }
        if (rows.length === 0) return res.status(404).json({ message: 'Payment not found' });
        return res.json(rows);
    });
});

module.exports = router;
