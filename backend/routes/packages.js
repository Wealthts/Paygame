const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../auth');
const e = require('express');
const { Version } = require('@node-rs/argon2');

const router = express.Router();

// get all package for test
router.get('/test/:game_id', (req, res) => {
    const game_id = req.params.game_id;
    const sql = "SELECT * FROM packages WHERE game_id = ?";

    con.query(sql, [game_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }
        return res.json(result);
    });
});

// get all packages by game_id
router.get('/:game_id', (req, res) => {
    const game_id = req.params.game_id;
    const sql = "SELECT * FROM packages WHERE game_id = ? AND is_active = 1";

    con.query(sql, [game_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }
        return res.json(result);
    });
});

// get package detail
router.get('/detail/:package_id', (req, res) => {
    const id = req.params.package_id;
    const sql = "SELECT * FROM packages WHERE package_id = ? AND is_active = 1";

    con.query(sql, [id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.length !== 1) {
            return res.status(404).send("Package not found");
        }
        return res.json(result[0]);
    });
});

// add package
router.post('/', verifyToken, verifyAdmin, (req, res) => {
    const { game_id, package_name, price } = req.body;
    const sql = "INSERT INTO packages (game_id, package_name, price, is_active) VALUES (?, ?, ?, 1)";

    if (!game_id || !package_name || !price === undefined || price === null || price === '') {
        return res.status(400).send("Invalid data");
    }

    if (!Number.isInteger(Number(game_id)) || !Number.isFinite(Number(price)) || Number(price) <= 0) {
        return res.status(400).send("Invalid game ID or price");
    }

    con.query(sql, [game_id, package_name, price], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }
        return res.json({
            message: "Package added successfully",
            package_id: result.insertId
        })
    });
});

// update package
router.put('/:id', verifyToken, verifyAdmin, (req, res) => {
    const id = req.params.id;
    const { package_name, price, is_active } = req.body;
    const sql = "UPDATE packages SET package_name = ?, price = ?, is_active = ? WHERE package_id = ?";

    if (
        !package_name ||
        !price === undefined ||
        !price === null ||
        !price === '' ||
        (is_active !== 0 && is_active !== 1)
    ) {
        return res.status(400).send("Invalid data 1");
    }

    if (!Number.isInteger(Number(price)) || Number(price) <= 0) {
        return res.status(400).send("Invalid data 2");
    }

    con.query(sql, [package_name, price, is_active, id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.affectedRows === 0) {
            return res.status(404).send("Package not found or no change");
        }
        return res.send("Package updated successfully");
    });
});

module.exports = router;