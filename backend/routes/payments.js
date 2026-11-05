const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../auth');

const router = express.Router();

// get payment by id
router.get('/:order_id', verifyToken, (req, res) => {
    const order_id = req.params.order_id;
    const sql = `
        SELECT payments.* 
        FROM payments 
        INNER JOIN orders 
        ON payments.order_id = orders.order_id 
        WHERE payments.order_id = ?
    `;

    con.query(sql, [order_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.length === 0) {
            return res.status(404).send("Payment not found");
        }
        return res.json(result);
    });
});

// create payment
router.post('/', verifyToken, (req, res) => {
    const { order_id, method } = req.body;
    const sql = `
        SELECT order_id, user_id, total_amount, status
        FROM orders
        WHERE order_id = ?
    `;

    if (!order_id || !method) {
        return res.status(400).send("Please provide order_id and method");
    }

    con.query(sql, [order_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.length === 0) {
            return res.status(404).send("Order not found");
        }

        const order = result[0];

        // check order owner
        if (req.user.role !== 'admin' && order.user.user_id !== req.user.id) {
            return res.status(403).send("Access denied");
        }

        // check order status
        if (order.status !== "Pending") {
            return res.status(400).send("Order is not available for payment");
        }

        // check pending payment
        const checkSQL = `
            SELECT payment_id
            FROM payments
            WHERE order_id = ?
            AND status = 'Pending'
        `;

        con.query(checkSQL, [order_id], (err, paymentResult) => {
            if (err) {
                console.error(err);
                return res.status(500).send("DB error");
            }

            if (paymentResult.length > 0) {
                return res.status(400).send("Pending payment already exists");
            }

            // create transaction reference
            const transaction_ref = 'PAY' + Date.now();

            // create payment
            const insertSQL = `
                INSERT INTO payments
                (order_id, transaction_ref, method, amount, status)
                VALUES (?, ?, ?, ?, 'Pending')
            `;

            con.query(insertSQL, [order_id, transaction_ref, method, order.total_amount], (err, insertResult) => {
                if (err) {
                    console.error(err);
                    return res.status(500).send('Cannot create payment');
                }

                return res.status(201).json({
                    message: "Payment created successfully",
                    payment: {
                        payment_id: insertResult.insertId,
                        order_id: order_id,
                        transaction_ref: transaction_ref,
                        method: method,
                        amount: order.total_amount,
                        status: 'Pending'
                    }
                });
            });
        });
    });
});

// update payment status (admin)
router.put('/:id/status', verifyToken, verifyAdmin, (req, res) => {
    const payment_id = req.params.id;
    const status = req.body.status;
    const sql = `
        UPDATE payments
        SET status = ?,
            paid_at = IF
            (? = 'Paid', CURRENT_TIMESTAMP, NULL)
        WHERE payment_id = ?
    `;

    if (status !== 'Paid' && status !== 'Failed') {
        return res.status(400).send("Invalid payment status");
    }

    con.query(sql, [status, status, payment_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.affectedRows === 0) {
            return res.status(404).send("Payment not found");
        }

        return res.json({
            message: "Payment status updated successfully",
            payment_id: payment_id,
            status: status
        });
    });
});

module.exports = router;