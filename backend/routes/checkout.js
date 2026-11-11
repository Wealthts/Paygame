const express = require('express');
const { randomUUID } = require('node:crypto');
const con = require('../db_config');
const { verifyToken } = require('../middleware/auth');
const { couponProblem, couponDiscount } = require('../coupon_rules');

const router = express.Router();

// Payment fee in basis points (100 = 1%)
const FEES = { qr: 0, wallet: 100, card: 250 };

// create order + payment in one step
// Body: package_id, player_uid, server_code, coupon_id (optional), use_coins (true/false), method
// Everything runs in one transaction: if any step fails, nothing is saved.
router.post('/', verifyToken, (req, res) => {
    const user_id = req.user.id;
    const { package_id, player_uid, server_code, coupon_id, use_coins = false, method } = req.body;

    if (!Number.isInteger(package_id) || package_id <= 0) {
        return res.status(400).send("Invalid package ID");
    }

    if (typeof player_uid !== 'string' || !player_uid.trim() || player_uid.length > 100) {
        return res.status(400).send("Invalid player UID");
    }

    if (coupon_id != null && (!Number.isInteger(coupon_id) || coupon_id <= 0)) {
        return res.status(400).send("Invalid coupon");
    }

    if (typeof use_coins !== 'boolean') {
        return res.status(400).send("Invalid use_coins");
    }

    if (!(method in FEES)) {
        return res.status(400).send("Invalid payment method");
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

        // values filled in step by step
        let pack;
        let coupon = null;
        let couponSatang = 0;

        // 1. lock the user so coins and coupons can't be used twice at the same time
        const lockUser = () => {
            db.query('SELECT user_id FROM users WHERE user_id = ? FOR UPDATE', [user_id], (err) => {
                if (err) return rollback(500, "DB error", err);
                findPackage();
            });
        };

        // 2. find the package
        const findPackage = () => {
            const sql = `
                SELECT packages.*, games.game_name, games.requires_server
                FROM packages
                INNER JOIN games ON packages.game_id = games.game_id
                WHERE packages.package_id = ?
                AND packages.is_active = 1
                AND games.is_active = 1
            `;

            db.query(sql, [package_id], (err, result) => {
                if (err) return rollback(500, "DB error", err);
                if (result.length !== 1) return rollback(404, "Package not found");

                pack = result[0];

                if (pack.requires_server === 1 && !server_code) {
                    return rollback(400, "Server code required");
                }

                if (coupon_id == null) return checkCoins();
                findCoupon();
            });
        };

        // 3. check the coupon
        const findCoupon = () => {
            db.query('SELECT * FROM coupons WHERE coupon_id = ? FOR UPDATE', [coupon_id], (err, result) => {
                if (err) return rollback(500, "DB error", err);
                if (result.length === 0) return rollback(404, "Coupon not found");

                coupon = result[0];

                // how many of this coupon the user owns but hasn't used
                const ownedSQL = `
                    SELECT COUNT(*) AS owned
                    FROM user_coupons
                    WHERE user_id = ? AND coupon_id = ? AND used_at IS NULL
                `;

                db.query(ownedSQL, [user_id, coupon_id], (err, owned) => {
                    if (err) return rollback(500, "DB error", err);

                    // pending orders using this coupon (everyone, and this user)
                    const pendingSQL = `
                        SELECT COUNT(*) AS all_pending,
                               COALESCE(SUM(user_id = ?), 0) AS my_pending
                        FROM orders
                        WHERE coupon_id = ? AND status = 'Pending'
                    `;

                    db.query(pendingSQL, [user_id, coupon_id], (err, pending) => {
                        if (err) return rollback(500, "DB error", err);

                        if (Number(owned[0].owned) - Number(pending[0].my_pending) <= 0) {
                            return rollback(400, "Coupon is unavailable");
                        }

                        const priceSatang = Math.round(Number(pack.price) * 100);
                        const problem = couponProblem(coupon, priceSatang, Number(pending[0].all_pending));

                        if (problem) return rollback(400, problem);

                        couponSatang = couponDiscount(coupon, priceSatang);
                        checkCoins();
                    });
                });
            });
        };

        // 4. work out coins and the final price (10 coins = 1 baht)
        const checkCoins = () => {
            const sql = `
                SELECT COALESCE(SUM(points_delta), 0) AS balance
                FROM point_transactions
                WHERE user_id = ?
            `;

            db.query(sql, [user_id], (err, result) => {
                if (err) return rollback(500, "DB error", err);

                const balance = Number(result[0].balance);
                const priceSatang = Math.round(Number(pack.price) * 100);
                const afterCoupon = priceSatang - couponSatang;
                const spent = use_coins ? Math.max(0, Math.min(balance, Math.floor(afterCoupon / 10))) : 0;
                const discountSatang = couponSatang + spent * 10;
                const feeSatang = Math.round((priceSatang - discountSatang) * FEES[method] / 10000);
                const totalSatang = priceSatang - discountSatang + feeSatang;

                createOrder({ balance, spent, discountSatang, feeSatang, totalSatang });
            });
        };

        // 5. create the order
        const createOrder = (money) => {
            const sql = `
                INSERT INTO orders (
                    user_id, package_id, player_uid, server_code,
                    game_name_snapshot, package_name_snapshot, original_price,
                    discount_amount, total_amount, status,
                    coupon_id, coupon_code_snapshot, spent_points, coupon_discount, fee_amount
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', ?, ?, ?, ?, ?)
            `;
            const values = [
                user_id, package_id, player_uid.trim(), server_code || '',
                pack.game_name, pack.package_name, pack.price,
                money.discountSatang / 100, money.totalSatang / 100,
                coupon ? coupon.coupon_id : null, coupon ? coupon.code : null,
                money.spent, couponSatang / 100, money.feeSatang / 100
            ];

            db.query(sql, values, (err, result) => {
                if (err) return rollback(500, "DB error", err);
                spendCoins(result.insertId, money);
            });
        };

        // 6. take the coins (refunded if the admin rejects the payment)
        const spendCoins = (order_id, money) => {
            if (money.spent === 0) return createPayment(order_id, money);

            const sql = `
                INSERT INTO point_transactions
                (user_id, order_id, event_key, type, points_delta)
                VALUES (?, ?, ?, 'Spend', ?)
            `;

            db.query(sql, [user_id, order_id, 'SPEND_' + order_id, -money.spent], (err) => {
                if (err) return rollback(500, "DB error", err);
                createPayment(order_id, money);
            });
        };

        // 7. create the pending payment
        const createPayment = (order_id, money) => {
            const sql = `
                INSERT INTO payments (order_id, transaction_ref, method, amount, status)
                VALUES (?, ?, ?, ?, 'Pending')
            `;

            db.query(sql, [order_id, randomUUID(), method, money.totalSatang / 100], (err) => {
                if (err) return rollback(500, "DB error", err);

                db.commit((err) => {
                    if (err) return rollback(500, "DB error", err);
                    db.release();

                    return res.status(201).json({
                        order_id: order_id,
                        total_amount: money.totalSatang / 100,
                        discount_amount: money.discountSatang / 100,
                        coupon_discount: couponSatang / 100,
                        coupon_code: coupon ? coupon.code : null,
                        fee_amount: money.feeSatang / 100,
                        spent_points: money.spent,
                        points_balance: money.balance - money.spent,
                        coupon_id: coupon ? coupon.coupon_id : null
                    });
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
            lockUser();
        });
    });
});

module.exports = router;
