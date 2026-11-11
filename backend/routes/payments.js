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
            return res.status(500).send('DB error');
        }

        if (result.length === 0) {
            return res.status(404).send('Payment not found');
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
        return res.status(400).send('Please provide order_id and method');
    }

    con.query(sql, [order_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        if (result.length === 0) {
            return res.status(404).send('Order not found');
        }

        const order = result[0];

        // check order owner
        if (req.user.role !== 'admin' && order.user_id !== req.user.id) {
            return res.status(403).send('Access denied');
        }

        // check order status
        if (order.status !== 'Pending') {
            return res.status(400).send('Order is not available for payment');
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
                return res.status(500).send('DB error');
            }

            if (paymentResult.length > 0) {
                return res.status(400).send('Pending payment already exists');
            }

            // create transaction reference
            const transaction_ref = 'PAY' + Date.now();

            // create payment
            const insertSQL = `
                INSERT INTO payments
                (order_id, transaction_ref, method, amount, status)
                VALUES (?, ?, ?, ?, 'Pending')
            `;

            con.query(
                insertSQL,
                [order_id, transaction_ref, method, order.total_amount],
                (err, insertResult) => {
                    if (err) {
                        console.error(err);
                        return res.status(500).send('Cannot create payment');
                    }

                    return res.status(201).json({
                        message: 'Payment created successfully',
                        payment: {
                            payment_id: insertResult.insertId,
                            order_id: order_id,
                            transaction_ref: transaction_ref,
                            method: method,
                            amount: order.total_amount,
                            status: 'Pending',
                        },
                    });
                },
            );
        });
    });
});

// update payment status (admin approve / reject)
// Every step runs inside one transaction: if any query fails, nothing changes.
router.put('/:id/status', verifyToken, verifyAdmin, (req, res) => {
    const payment_id = req.params.id;
    const status = req.body.status;

    if (!['Paid', 'Failed'].includes(status)) {
        return res.status(400).send('Invalid payment status');
    }

    con.getConnection((err, db) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        // undo everything and send an error
        const rollback = (code, message, error) => {
            if (error) console.error(error);
            db.rollback(() => {
                db.release();
                return res.status(code).send(message);
            });
        };

        // save everything and send the result
        const commit = (body) => {
            db.commit((err) => {
                if (err) return rollback(500, 'DB error', err);
                db.release();
                return res.json(body);
            });
        };

        // 1. update payment
        const updatePayment = (order) => {
            const sql = `
                UPDATE payments
                SET status = ?, paid_at = IF(? = 'Paid', CURRENT_TIMESTAMP, NULL)
                WHERE payment_id = ?
            `;

            db.query(sql, [status, status, payment_id], (err) => {
                if (err) return rollback(500, 'DB error', err);
                updateOrder(order);
            });
        };

        // 2. update order (Paid -> Completed, Failed -> Cancelled)
        const updateOrder = (order) => {
            const orderStatus = status === 'Paid' ? 'Completed' : 'Cancelled';
            const sql = `
                UPDATE orders
                SET status = ?, completed_at = IF(? = 'Paid', CURRENT_TIMESTAMP, NULL)
                WHERE order_id = ?
            `;

            db.query(sql, [orderStatus, status, order.order_id], (err) => {
                if (err) return rollback(500, 'DB error', err);
                updateCoupon(order);
            });
        };

        // 3. approved + coupon: mark one of the user's coupons as used and count the use
        //    (rejected orders don't touch the coupon, so it becomes available again)
        const updateCoupon = (order) => {
            if (status !== 'Paid') return refundCoins(order);
            if (!order.coupon_id) return createReceipt(order);

            const useSQL = `
                UPDATE user_coupons
                SET used_at = CURRENT_TIMESTAMP
                WHERE user_id = ? AND coupon_id = ? AND used_at IS NULL
                ORDER BY user_coupon_id
                LIMIT 1
            `;

            db.query(useSQL, [order.user_id, order.coupon_id], (err) => {
                if (err) return rollback(500, 'DB error', err);

                const countSQL = `UPDATE coupons SET use_count = use_count + 1 WHERE coupon_id = ?`;

                db.query(countSQL, [order.coupon_id], (err) => {
                    if (err) return rollback(500, 'DB error', err);
                    createReceipt(order);
                });
            });
        };

        // 4a. rejected: give back the coins the user spent
        const refundCoins = (order) => {
            if (order.spent_points <= 0) {
                return commit({ payment_id: payment_id, status: status });
            }

            const sql = `
                INSERT INTO point_transactions
                (user_id, order_id, event_key, type, points_delta)
                VALUES (?, ?, ?, 'Refund', ?)
            `;
            const values = [
                order.user_id,
                order.order_id,
                'REFUND_' + order.order_id,
                order.spent_points,
            ];

            db.query(sql, values, (err) => {
                if (err) return rollback(500, 'DB error', err);
                commit({ payment_id: payment_id, status: status });
            });
        };

        // 4b. approved: create receipt
        const createReceipt = (order) => {
            const sql = `
                INSERT IGNORE INTO receipts (order_id, receipt_number)
                VALUES (?, ?)
            `;

            db.query(sql, [order.order_id, 'RCP-' + order.order_id], (err) => {
                if (err) return rollback(500, 'DB error', err);
                earnPoints(order);
            });
        };

        // 5. approved: give points (1 point per 10 baht)
        const earnPoints = (order) => {
            const paid = Number(order.original_price) - Number(order.discount_amount);
            const earned = Math.floor(Math.round(paid * 100) / 1000);
            const sql = `
                INSERT IGNORE INTO point_transactions
                (user_id, order_id, event_key, type, points_delta)
                VALUES (?, ?, ?, 'Earn', ?)
            `;
            const values = [order.user_id, order.order_id, 'ORDER_' + order.order_id, earned];

            db.query(sql, values, (err) => {
                if (err) return rollback(500, 'DB error', err);
                commit({ payment_id: payment_id, status: status });
            });
        };

        db.beginTransaction((err) => {
            if (err) {
                db.release();
                console.error(err);
                return res.status(500).send('DB error');
            }

            // find the order owner
            const lookupSQL = `
                SELECT orders.user_id
                FROM payments
                INNER JOIN orders ON orders.order_id = payments.order_id
                WHERE payments.payment_id = ?
            `;

            db.query(lookupSQL, [payment_id], (err, lookup) => {
                if (err) return rollback(500, 'DB error', err);
                if (lookup.length === 0) return rollback(404, 'Payment not found');

                // lock the user so coins and coupons can't change at the same time
                const lockUserSQL = `SELECT user_id FROM users WHERE user_id = ? FOR UPDATE`;

                db.query(lockUserSQL, [lookup[0].user_id], (err) => {
                    if (err) return rollback(500, 'DB error', err);

                    // lock the payment and its order
                    const orderSQL = `
                        SELECT payments.status AS payment_status, orders.*
                        FROM payments
                        INNER JOIN orders ON orders.order_id = payments.order_id
                        WHERE payments.payment_id = ?
                        FOR UPDATE
                    `;

                    db.query(orderSQL, [payment_id], (err, rows) => {
                        if (err) return rollback(500, 'DB error', err);

                        const order = rows[0];

                        // same decision again: nothing to do
                        if (order.payment_status === status) {
                            return commit({ status: status });
                        }

                        // only a pending payment can be approved or rejected
                        if (order.payment_status !== 'Pending' || order.status !== 'Pending') {
                            return rollback(409, 'Payment already finalized');
                        }

                        updatePayment(order);
                    });
                });
            });
        });
    });
});

module.exports = router;
