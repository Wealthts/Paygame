const express = require("express");
const con = require("../db_config");
const { verifyToken, verifyAdmin } = require("../middleware/auth");

const router = express.Router();

// GET: test packages by game_id
// GET /api/packages/test/:game_id
router.get("/test/:game_id", (req, res) => {
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

// GET: all packages for admin
// GET api/package/:game_id
router.get("/admin/:game_id", verifyToken, verifyAdmin, (req, res) => {
    const game_id = req.params.game_id;
    const sql = "SELECT * FROM packages WHERE game_id = ? ORDER BY package_id DESC";

    con.query(sql, [game_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }
        return res.json(result);
    });
});

// GET: active packages by game_id
// GET: /api/packages/:game_id
router.get("/:game_id", (req, res) => {
    const game_id = req.params.game_id;
    const sql = `
        SELECT *
        FROM packages
        WHERE game_id = ?
        AND is_active = 1
        ORDER BY package_id DESC
    `;

    con.query(sql, [game_id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        return res.json(result);
    });
});

// GET: package detail
// GET: api/packages/detail/:package_id
router.get("/detail/:package_id", (req, res) => {
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

// POST: add package
// POST api/packages
router.post("/", verifyToken, verifyAdmin, (req, res) => {
    const { game_id, package_name, price } = req.body;
    const sql = `
        INSERT INTO packages
        (game_id, package_name, price, is_active)
        VALUES (?, ?, ?, 1)
    `;

    if (
        game_id === undefined ||
        typeof package_name !== 'string' ||
        package_name.trim() === '' ||
        price === undefined ||
        price === null ||
        price === ""
    ) {
        return res.status(400).send("Invalid data");
    }

    const gameId = Number(game_id);
    const packagePrice = Number(price);

    if (
        !Number.isInteger(gameId) ||
        gameId <= 0 ||
        !Number.isFinite(packagePrice) ||
        packagePrice <= 0
    ) {
        return res.status(400).send("Invalid game ID or price");
    }

    con.query(sql, [gameId, package_name.trim(), packagePrice], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }
        return res.json({
            message: "Package added successfully",
            package_id: result.insertId,
        });
    });
});

// PUT: update package
// PUT api/packages/:id
router.put("/:id", verifyToken, verifyAdmin, (req, res) => {
    const id = Number(req.params.id);
    const { package_name, price, is_active } = req.body;

    if (
        !Number.isInteger(id) ||
        id <= 0 ||
        typeof package_name !== "string" ||
        package_name.trim() === "" ||
        price === undefined ||
        price === null ||
        price === "" ||
        (Number(is_active) !== 0 && Number(is_active) !== 1)
    ) {
        return res.status(400).send("Invalid data");
    }

    const packagePrice = Number(price);

    if (!Number.isFinite(packagePrice) || packagePrice <= 0) {
        return res.status(400).send("Invalid price");
    }

    const sql = `
        UPDATE packages
        SET package_name = ?,
            price = ?,
            is_active = ?
        WHERE package_id = ?
    `;

    con.query(sql, [
        package_name.trim(),
        packagePrice,
        Number(is_active),
        id
    ], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.affectedRows === 0) {
            return con.query("SELECT package_id FROM packages WHERE package_id = ?",
                [id], (checkErr, rows) => {
                    if (checkErr) {
                        console.error(checkErr);
                        return res.status(500).send("DB error");
                    }

                    if (rows.length === 0) {
                        return res.status(404).send("Package not found");
                    }

                    return res.json({
                        message: "Package unchanged",
                    });
                },
            );
        }

        return res.json({
            message: "Package updated successfully",
        });
    },
    );
});

// DELETE: soft delete package
// DELETE api/packages/:id
router.delete("/:id", verifyToken, verifyAdmin, (req, res) => {
    const id = Number(req.params.id);
    const sql = `
        UPDATE packages
        SET is_active = 0
        WHERE package_id = ?
    `;

    if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).send("Invalid package ID");
    }

    con.query(sql, [id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.affectedRows === 0) {
            return con.query("SELECT package_id FROM packages WHERE package_id = ?",
                [id], (checkErr, rows) => {
                    if (checkErr) {
                        console.error(checkErr);
                        return res.status(500).send("DB error");
                    }

                    if (rows.length === 0) {
                        return res.status(404).send("Package not found");
                    }

                    return res.json({
                        message: "Package already inactive",
                    });
                },
            );
        }

        return res.json({
            message: "Package deactivated successfully",
        });
    });
});

module.exports = router;
