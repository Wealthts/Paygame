const express = require('express');
const con = require('../db_config');
const { verifyToken } = require('../middleware/auth');
const { rewards, isRewardCode, toSatang, couponProblem } = require('../coupon_rules');

const router = express.Router();

// get my coupons
// Each row in user_coupons is one coupon the user owns.
// Status: Used (used_at is set), Reserved (a pending order is using it),
// Expired (can't be used any more) or Available.
router.get('/', verifyToken, (req, res) => {
    const user_id = req.user.id;
    const sql = `
        SELECT user_coupons.user_coupon_id, user_coupons.used_at, coupons.*
        FROM user_coupons
        INNER JOIN coupons ON coupons.coupon_id = user_coupons.coupon_id
        WHERE user_coupons.user_id = ?
        ORDER BY user_coupons.user_coupon_id DESC
    `;

    con.query(sql, [user_id], (err, rows) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        // how many of each coupon are used by pending orders
        const pendingSQL = `
            SELECT coupon_id, COUNT(*) AS pending
            FROM orders
            WHERE user_id = ? AND status = 'Pending' AND coupon_id IS NOT NULL
            GROUP BY coupon_id
        `;

        con.query(pendingSQL, [user_id], (err, pendingRows) => {
            if (err) {
                console.error(err);
                return res.status(500).send("DB error");
            }

            const pending = {};
            pendingRows.forEach(row => { pending[row.coupon_id] = row.pending; });

            const result = rows.map(row => {
                let status = 'Available';

                if (row.used_at) {
                    status = 'Used';
                } else if (pending[row.coupon_id] > 0) {
                    pending[row.coupon_id]--;
                    status = 'Reserved';
                } else if (couponProblem(row, Number.MAX_SAFE_INTEGER) !== null) {
                    status = 'Expired';
                }

                return {
                    user_coupon_id: row.user_coupon_id,
                    coupon_id: row.coupon_id,
                    code: row.code,
                    name: row.code,
                    discount_type: row.discount_type,
                    amount_satang: row.discount_type === 'fixed' ? toSatang(row.discount_value) : 0,
                    percent: row.discount_type === 'percent' ? Number(row.discount_value) : 0,
                    minimum_satang: toSatang(row.min_order_amount),
                    max_discount_satang: row.max_discount_amount === null ? null : toSatang(row.max_discount_amount),
                    end_date: row.end_date,
                    used_at: row.used_at,
                    status: status
                };
            });

            return res.json(result);
        });
    });
});

// claim a coupon by typing its code
router.post('/claim', verifyToken, (req, res) => {
    const user_id = req.user.id;
    const code = String(req.body.code || '').trim().toUpperCase();

    if (!code) {
        return res.status(400).send("Please enter a coupon code");
    }

    if (isRewardCode(code)) {
        return res.status(400).send("This coupon can only be redeemed with coins");
    }

    const sql = `SELECT * FROM coupons WHERE code = ?`;

    con.query(sql, [code], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.length === 0) {
            return res.status(404).send("Coupon not found");
        }

        const coupon = result[0];
        const problem = couponProblem(coupon, Number.MAX_SAFE_INTEGER);

        if (problem) {
            return res.status(400).send(problem);
        }

        // one claim per user per code
        const checkSQL = `SELECT user_coupon_id FROM user_coupons WHERE user_id = ? AND coupon_id = ?`;

        con.query(checkSQL, [user_id, coupon.coupon_id], (err, owned) => {
            if (err) {
                console.error(err);
                return res.status(500).send("DB error");
            }

            if (owned.length > 0) {
                return res.status(409).send("You already have this coupon");
            }

            const insertSQL = `INSERT INTO user_coupons (user_id, coupon_id) VALUES (?, ?)`;

            con.query(insertSQL, [user_id, coupon.coupon_id], (err, insertResult) => {
                if (err) {
                    console.error(err);
                    return res.status(500).send("DB error");
                }

                return res.status(201).json({
                    message: "Coupon claimed successfully",
                    user_coupon_id: insertResult.insertId,
                    coupon_id: coupon.coupon_id,
                    code: coupon.code
                });
            });
        });
    });
});

// redeem a reward with coins
// Runs in one transaction so coins can't be spent twice at the same time.
router.post('/redeem', verifyToken, (req, res) => {
    const user_id = req.user.id;
    const reward = rewards[req.body.reward_id];

    if (!reward) {
        return res.status(400).send("Unknown reward");
    }

    con.getConnection((err, db) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        // undo everything and send an error
        const rollback = (code, message, error) => {
            if (error) console.error(error);
            db.rollback(() => {
                db.release();
                return res.status(code).send(message);
            });
        };

        // 1. lock the user and check coins
        const checkCoins = () => {
            db.query('SELECT user_id FROM users WHERE user_id = ? FOR UPDATE', [user_id], (err) => {
                if (err) return rollback(500, "DB error", err);

                const balanceSQL = `
                    SELECT COALESCE(SUM(points_delta), 0) AS balance
                    FROM point_transactions
                    WHERE user_id = ?
                `;

                db.query(balanceSQL, [user_id], (err, result) => {
                    if (err) return rollback(500, "DB error", err);

                    if (Number(result[0].balance) < reward.cost) {
                        return rollback(400, "Not enough coins");
                    }

                    findCoupon();
                });
            });
        };

        // 2. find the reward's coupon
        const findCoupon = () => {
            db.query('SELECT coupon_id FROM coupons WHERE code = ?', [reward.code], (err, result) => {
                if (err) return rollback(500, "DB error", err);
                if (result.length === 0) return rollback(404, "Reward coupon not found");

                giveCoupon(result[0].coupon_id);
            });
        };

        // 3. give the coupon to the user
        const giveCoupon = (coupon_id) => {
            const sql = `INSERT INTO user_coupons (user_id, coupon_id) VALUES (?, ?)`;

            db.query(sql, [user_id, coupon_id], (err, result) => {
                if (err) return rollback(500, "DB error", err);
                spendCoins(result.insertId);
            });
        };

        // 4. take the coins
        const spendCoins = (user_coupon_id) => {
            const sql = `
                INSERT INTO point_transactions
                (user_id, order_id, event_key, type, points_delta)
                VALUES (?, NULL, ?, 'Redeem', ?)
            `;

            db.query(sql, [user_id, 'COUPON_' + user_coupon_id, -reward.cost], (err) => {
                if (err) return rollback(500, "DB error", err);

                db.commit((err) => {
                    if (err) return rollback(500, "DB error", err);
                    db.release();
                    return res.status(201).json({ user_coupon_id: user_coupon_id });
                });
            });
        };

        // start
        db.beginTransaction((err) => {
            if (err) {
                db.release();
                console.error(err);
                return res.status(500).send("DB error");
            }
            checkCoins();
        });
    });
});

module.exports = router;
