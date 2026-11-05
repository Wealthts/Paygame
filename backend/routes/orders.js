const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../auth');

const router = express.Router();

// get all order of user
router.get('/', verifyToken, verifyAdmin, (req, res) => {
    const user_id = req.user.id;
    let values = [];
    let sql = "SELECT * FROM orders ";

    if (req.user.role !== 'admin') {
        sql += "WHERE user_id = ?";
        values.push(user_id);
    }
    sql += "ORDER BY created_at DESC";

    con.query(sql, values, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }
        return res.json(result);
    });
});

// get order detail
router.get('/:id', verifyToken, (req, res) => {
    const id = req.params.id;
    const user_id = req.user.id;
    let values = [id];
    let sql = "SELECT * FROM orders WHERE order_id = ? ";

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
        return res.status(400).send("Invalid order ID");
    }

    if (req.user.role !== 'admin') {
        sql += "AND user_id = ?";
        values.push(user_id);
    }

    con.query(sql, values, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.length !== 1) {
            return res.status(404).send("Order not found");
        }
        return res.json(result[0]);
    });
});

//  API update status Order
router.put('/:id/complete', verifyToken, verifyAdmin, (req, res) => {
    const order_id = req.params.id;
    const sql = `
        UPDATE orders 
        SET status = 'Completed',
            completed_at = CURRENT_TIMESTAMP 
        WHERE order_id = ?
    `;

    con.query(sql, [order_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.affectedRows === 0) {
            return res.status(404).send("Order not found or no change")
        }

        return res.json({ 
            message: "Order completed successfully"
        });
    });
});

// create order
router.post('/', verifyToken, (req, res) => {
    const { package_id, player_uid, server_code } = req.body;
    const sql = `
        SELECT 
            packages.package_id,
            packages.package_name,
            packages.price,
            games.game_name,
            games.requires_server
        FROM packages
        INNER JOIN games
        ON packages.game_id = games.game_id
        WHERE packages.package_id = ?
        AND packages.is_active = 1 
        AND games.is_active = 1 
    `;

    if (!package_id || !player_uid) {
        return res.status(400).send("Please fill all fileds");
    }

    if (!Number.isInteger(Number(package_id)) || Number(package_id) <= 0) {
        return res.status(400).send("Invalid package ID");
    }

    con.query(sql, [package_id], (err, result) => {

        const insertSQL = `
            INSERT INTO orders (
                user_id, package_id, player_uid, 
                server_code, game_name_snapshot,
                package_name_snapshot, original_price,
                discount_amount, total_amount, status
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.length !== 1) {
            return res.status(404).send("Package not found");
        }

        const item = result[0];

        // check server code
        if (item.requires_server === 1 && !server_code) {
            return res.status(400).send("Server code requires");
        }

        const user_id = req.user.id;
        const original_price = Number(item.price);
        const discount_amount = 0;
        const total_amount = original_price - discount_amount;
        const final_server_code = server_code || '';

        const values = [
            user_id, item.package_id, player_uid,
            final_server_code, item.game_name,
            item.package_name, original_price,
            discount_amount, total_amount, "Pending"
        ];

        con.query(insertSQL, values, (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).send("DB error");
            }

            return res.status(201).json({
                message: "Order created successfully",
                order_id: result.insertId,
                total_amount: total_amount,
                status: "Pending"
            });
        });
    });
});

module.exports = router;