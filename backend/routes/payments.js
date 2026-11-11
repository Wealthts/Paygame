const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// Admin payment queue. The joins provide all information needed to review a
// payment without trusting values supplied by the client.
router.get('/', verifyToken, verifyAdmin, (req, res) => {
    const sql = `
        SELECT payments.*, orders.user_id, orders.game_name_snapshot,
               orders.package_name_snapshot, orders.player_uid, orders.status AS order_status,
               users.username, users.display_name
        FROM payments
        INNER JOIN orders ON payments.order_id = orders.order_id
        INNER JOIN users ON orders.user_id = users.user_id
        ORDER BY payments.created_at DESC
    `;

    con.query(sql, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        return res.json(result);
    });
});

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
        if (req.user.role !== 'admin' && order.user_id !== req.user.id) {
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

// Approval and refunds are atomic and can only transition a pending payment.
const {transaction, fail, endpoint} = require('../transaction');
router.put('/:id/status', verifyToken, verifyAdmin, endpoint(req => transaction(async db => {
 const status = req.body.status;
 if (!['Paid','Failed'].includes(status)) fail('Invalid payment status');
 const [lookup] = await db.query(`SELECT o.user_id FROM payments p JOIN orders o ON o.order_id=p.order_id WHERE p.payment_id=?`, [req.params.id]);
 if (!lookup.length) fail('Payment not found',404);
 await db.query('SELECT user_id FROM users WHERE user_id=? FOR UPDATE',[lookup[0].user_id]);
 const [rows] = await db.query(`SELECT p.status AS payment_status, o.* FROM payments p JOIN orders o ON o.order_id=p.order_id WHERE p.payment_id=? FOR UPDATE`,[req.params.id]);
 const order = rows[0];
 if (order.payment_status === status) return {status};
 if (order.payment_status !== 'Pending' || order.status !== 'Pending') fail('Payment already finalized',409);
 await db.query("UPDATE payments SET status=?,paid_at=IF(?='Paid',CURRENT_TIMESTAMP,NULL) WHERE payment_id=?",[status,status,req.params.id]);
 await db.query("UPDATE orders SET status=?, completed_at=IF(?='Paid',CURRENT_TIMESTAMP,NULL) WHERE order_id=?",[status==='Paid'?'Completed':'Cancelled',status,order.order_id]);
 await db.query("UPDATE user_coupons SET status=?,order_id=IF(?='Paid',order_id,NULL) WHERE order_id=? AND status='Reserved'",[status==='Paid'?'Used':'Available',status,order.order_id]);
 if (status === 'Failed' && order.spent_points > 0) {
   await db.query(`INSERT INTO point_transactions (user_id,order_id,event_key,type,points_delta) VALUES (?,?,?,'Refund',?)`,[order.user_id,order.order_id,'REFUND_'+order.order_id,order.spent_points]);
 }
 if (status === 'Paid') {
   await db.query('INSERT IGNORE INTO receipts (order_id,receipt_number) VALUES (?,?)',[order.order_id,'RCP-'+order.order_id]);
   const earned = Math.floor(Math.round((Number(order.original_price)-Number(order.discount_amount))*100)/1000);
   await db.query(`INSERT IGNORE INTO point_transactions (user_id,order_id,event_key,type,points_delta) VALUES (?,?,?,'Earn',?)`,[order.user_id,order.order_id,'ORDER_'+order.order_id,earned]);
 }
 return {payment_id:req.params.id,status};
})));
module.exports = router;
