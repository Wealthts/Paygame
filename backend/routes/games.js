const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../auth');

const router = express.Router();

// get all games
router.get('/', (_, res) => {
    const sql = "SELECT * FROM games WHERE is_active = 1";

    con.query(sql, (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        res.json(results);
    });
});

// get game by id
router.get('/:id', (req, res) => {
    const id = req.params.id;
    const sql = "SELECT * FROM games WHERE game_id = ? AND is_active = 1";

    con.query(sql, [id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        if (results.length !== 1) return res.status(404).send('Game not found');
        return res.json(results[0]);
    });
});

// add add new game
router.post('/', verifyToken, verifyAdmin, (req, res) => {
    const { game_name, category, uid_pattern, requires_server } = req.body;
    const sql = "INSERT INTO games (game_name, category, uid_pattern, requires_server, is_active) VALUES (?, ?, ?, ?, 1)";

    if (!game_name || !category || !uid_pattern || (requires_server !== 0 && requires_server !== 1)) {
        return res.status(400).send('Invalid data');
    }

    con.query(sql, [game_name, category, uid_pattern, requires_server], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        return res.json({
            message: "Game added successfuly",
            game_id: result.insertId
        });
    });
});

// update game
router.put('/:id', verifyToken, verifyAdmin, (req, res) => {
    const id = req.params.id;
    const { game_name, category, uid_pattern, requires_server, is_active } = req.body;
    const sql = "UPDATE games SET game_name = ?, category = ?, uid_pattern = ?, requires_server = ?, is_active = ? WHERE game_id = ?";

    con.query(sql, [game_name, category, uid_pattern, requires_server, is_active, id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send("DB error");
        }

        if (result.affectedRows === 0) {
            return res.status(404).send("Game not found or no change");
        }
        return res.send("Game update successfully")
    });
});

module.exports = router;