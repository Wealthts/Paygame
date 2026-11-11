const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// GET: active games for users
// GET /api/games
router.get('/', (req, res) => {
    const sql = 'SELECT * FROM games WHERE is_active = 1 ORDER BY game_id DESC';

    con.query(sql, (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        return res.json(results);
    });
});

// GET: all games for admin
// GET /api/games/admin/all
router.get('/admin/all', verifyToken, verifyAdmin, (req, res) => {
    const sql = 'SELECT * FROM games ORDER BY game_id DESC';

    con.query(sql, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        return res.json({
            total_games: result.length,
            games: result,
        });
    });
});

// GET: game by id
// GET /api/games/:id
router.get('/:id', (req, res) => {
    const id = req.params.id;
    const sql = 'SELECT * FROM games WHERE game_id = ? AND is_active = 1';

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
        return res.status(400).send('Invalid game ID');
    }

    con.query(sql, [id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        if (result.length !== 1) {
            return res.status(404).send('Game not found');
        }
        return res.json(result[0]);
    });
});

// POST: add new game
// POST /api/games
router.post('/', verifyToken, verifyAdmin, (req, res) => {
    const { game_name, category, uid_pattern, requires_server } = req.body;
    const sql =
        'INSERT INTO games (game_name, category, uid_pattern, requires_server, is_active) VALUES (?, ?, ?, ?, 1)';

    if (
        !game_name ||
        !category ||
        !uid_pattern ||
        (requires_server !== 0 && requires_server !== 1)
    ) {
        return res.status(400).send('Invalid data');
    }

    con.query(sql, [game_name, category, uid_pattern, requires_server], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        return res.status(201).json({
            message: 'Game added successfuly',
            game_id: result.insertId,
        });
    });
});

// PUT: update game
// PUT /api/games/:id
router.put('/:id', verifyToken, verifyAdmin, (req, res) => {
    const id = req.params.id;
    const { game_name, category, uid_pattern, requires_server, is_active } = req.body;
    const sql =
        'UPDATE games SET game_name = ?, category = ?, uid_pattern = ?, requires_server = ?, is_active = ? WHERE game_id = ?';

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
        return res.status(400).send('Invalid game ID');
    }

    if (
        !game_name ||
        !category ||
        !uid_pattern ||
        (requires_server !== 0 && requires_server !== 1) ||
        (is_active !== 0 && is_active !== 1)
    ) {
        return res.status(400).send('Invalid data');
    }

    con.query(
        sql,
        [game_name, category, uid_pattern, requires_server, is_active, id],
        (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).send('DB error');
            }

            if (result.affectedRows === 0) {
                return res.status(404).send('Game not found or no change');
            }

            return res.json({
                message: 'Game updated successfully',
            });
        },
    );
});

// DELETE: soft delete game
// DELETE /api/games/:id
router.delete('/:id', verifyToken, verifyAdmin, (req, res) => {
    const id = req.params.id;
    const checkSql = 'SELECT game_id FROM games WHERE game_id = ?';

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
        return res.status(400).send('Invalid game ID');
    }

    con.query(checkSql, [id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        if (result.length === 0) {
            return res.status(404).send('Game not found');
        }

        const updateSql = 'UPDATE games SET is_active = 0 WHERE game_id = ?';

        con.query(updateSql, [id], (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).send('DB error');
            }

            return res.json({
                message: 'Game deactivated successfully',
            });
        });
    });
});

module.exports = router;
