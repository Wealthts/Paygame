const express = require('express');
const con = require('../db_config');
const { verifyToken } = require('../auth');

const router = express.Router();

// get point history
router.get('/', verifyToken, (req, res) => {
    const sql = "SELECT * FROM point_transactions WHERE user_id = ? ORDER BY created_at DESC";

    con.query(sql, [req.user.id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        return res.json(results);
    });
});

module.exports = router;
