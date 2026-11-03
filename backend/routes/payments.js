const express = require('express');
const con = require('../db_config');
const { verifyToken } = require('../auth');

const router = express.Router();

// create payment
router.post('/', verifyToken, (req, res) => {
    const { order_id, transaction_ref, method } = req.body;

    if (!order_id || !transaction_ref || !method)
        return res.status(400).send('Invalid data');

    const sql = "INSERT INTO payments (order_id, transaction_ref, method, amount, status, created_at) SELECT order_id, ?, ?, total_amount, 'pending', NOW() FROM orders WHERE order_id = ? AND user_id = ?";
    con.query(sql, [transaction_ref, method, order_id, req.user.id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        if (result.affectedRows === 0) return res.status(404).send('Order not found');
        return res.json({ message: 'Payment created successfully', payment_id: result.insertId });
    });
});

// get payment by order id
router.get('/:order_id', verifyToken, (req, res) => {
    const id = req.params.order_id;
    const sql = "SELECT payments.* FROM payments JOIN orders ON orders.order_id = payments.order_id WHERE payments.order_id = ? AND orders.user_id = ?";

    con.query(sql, [id, req.user.id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        if (results.length === 0) return res.status(404).send('Payment not found');
        return res.json(results);
    });
});

module.exports = router;
