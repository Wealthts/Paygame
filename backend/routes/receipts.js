const express = require('express');
const con = require('../db_config');
const { verifyToken } = require('../auth');

const router = express.Router();

// receipt by order id
router.get('/:order_id', verifyToken, (req, res) => {
    const order_id = req.params.order_id;
    const sql = `
        SELECT receipts.receipt_id,
               receipts.order_id,
               receipts.receipt_number,
               receipts.issued_at,
               orders.user_id,
               orders.game_name_snapshot,
               orders.package_name_snapshot,
               orders.total_amount
        FROM receipts
        INNER JOIN orders
        ON receipts.order_id = orders.order_id
        WHERE receipts.order_id = ?
    `;

    con.query(sql, [order_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB server");
        }

        if (result.length === 0) {
            return res.status(404).send("Receipt not found");
        }

        const receipt = result[0];

        if (req.user.role !== 'admin' && receipt.user_id !== req.user.id) {
            return res.status(403).send("Access denied");
        }

        return res.json({
            receipt_id: receipt.receipt_id,
            order_id: receipt.order_id,
            receipt_number: receipt.receipt_number,
            issued_at: receipt.issued_at,
            game_name: receipt.game_name_snapshot,
            package_name: receipt.package_name_snapshot,
            tatal_amount: receipt.tatal_amount
        });
    });
});

// create receipt
router.post('/', verifyToken, (req, res) => {
    const { order_id } = req.body;
    const checkSQL = `
        SELECT orders.order_id,
               orders.user_id,
               orders.total_amount,
               orders.game_name_snapshot,
               orders.package_name_snapshot,
               payments.status AS payment_status
        FROM orders
        INNER JOIN payments
        ON orders.order_id = payments.order_id
        WHERE orders.order_id = ?
        AND payments.status = 'Paid'
    `;

    if (!order_id) {
        return res.status(400).send('Please provide order_id');
    }

    con.query(checkSQL, [order_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.length === 0) {
            return res.status(400).send("Payment is not completed");
        }

        const order = result[0];

        const receipt_number = 'RCP' + Date.now();
        const insertSQL = `
            INSERT INTO receipts
            (order_id, receipt_number)
            VALUES (?, ?)
        `;

        con.query(insertSQL, [order_id, receipt_number], (err, insertResult) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(409).send('Receipt already exists');
                }
                console.error(err);
                return res.status(500).send('Cannot create receipt');
            }

            const updateSQL = `
                UPDATE orders 
                SET status = 'Completed', completed_at = CURRENT_TIMESTAMP 
                WHERE order_id = ?
            `;

            con.query(updateSQL, [order_id], (err, updateResult) => {
                if (err) {
                    console.error(err);
                    return res.status(500).send("DB error");
                }

                if (updateResult.affectedRows === 0) {
                    return res.status(404).send("Order not found or status not changed");
                }

                return res.status(201).json({
                    message: "Receipt created successfully",
                    receipt: {
                        receipt_id: insertResult.insertId,
                        order_id: order.order_id,
                        receipt_number: receipt_number,
                        game_name: order.game_name_snapshot,
                        package_name: order.package_name_snapshot,
                        total_amount: order.total_amount,
                        order_status: "Completed"
                    }
                });
            });
        });
    });
});

module.exports = router;
