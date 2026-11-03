const express = require('express');
const con = require('../db_config');
const { verifyToken } = require('../auth');

const router = express.Router();

// get receipt by order id
router.get('/:order_id', verifyToken, (req, res) => {
    const id = req.params.order_id;
    const sql = "SELECT receipts.* FROM receipts JOIN orders ON orders.order_id = receipts.order_id WHERE receipts.order_id = ? AND orders.user_id = ?";

    con.query(sql, [id, req.user.id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        if (results.length === 0) return res.status(404).send('Receipt not found');
        return res.json(results[0]);
    });
});

module.exports = router;
