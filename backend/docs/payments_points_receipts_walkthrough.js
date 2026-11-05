// this file for study

/*
 * PAYMENTS, POINTS, AND RECEIPTS: COMMENTED WALKTHROUGH
 *
 * This file combines the code from routes/payments.js, routes/points.js,
 * and routes/receipts.js into one commented reference for learning and
 * presentation. The running server continues to use the original route files.
 *
 * The endpoints in this file are:
 *   POST /api/payments
 *   GET  /api/payments/:order_id
 *   GET  /api/points
 *   GET  /api/receipts/:order_id
 *
 * Every endpoint uses verifyToken. A client must send:
 *   Authorization: Bearer <JWT token>
 *
 * This code records a pending payment request and reads payment, point, and
 * receipt data. It does not contact a payment provider or itself award points.
 */

// Express creates the routers that hold the API endpoint handlers.
const express = require('express');

// This is the MySQL connection shared by the backend routes.
const con = require('../db_config');

// Middleware verifies a JWT and puts its decoded user data on req.user.
const { verifyToken } = require('../auth');

// Separate routers keep endpoints grouped by feature.
const paymentsRouter = express.Router();
const pointsRouter = express.Router();
const receiptsRouter = express.Router();

// ---------------------------------------------------------------------------
// PAYMENTS
// ---------------------------------------------------------------------------

// POST /api/payments
// Create a pending payment record for an order owned by the logged-in user.
paymentsRouter.post('/', verifyToken, (req, res) => {
    // Read the values sent by the client in the JSON request body.
    const { order_id, transaction_ref, method } = req.body;

    // All three fields are required before attempting a database insert.
    if (!order_id || !transaction_ref || !method) {
        return res.status(400).send('Invalid data');
    }

    // Insert a payment by selecting the matching order's ID and total amount.
    // The user_id condition ensures the order belongs to the logged-in user.
    // The question marks are placeholders; values are passed separately below.
    const sql = `
        INSERT INTO payments
            (order_id, transaction_ref, method, amount, status, created_at)
        SELECT order_id, ?, ?, total_amount, 'pending', NOW()
        FROM orders
        WHERE order_id = ? AND user_id = ?
    `;

    // Parameter order matches the four question marks in the SQL above.
    con.query(
        sql,
        [transaction_ref, method, order_id, req.user.id],
        (err, result) => {
            // A database error means the server could not complete the request.
            if (err) {
                console.error(err);
                return res.status(500).send('DB error');
            }

            // No inserted row means the order did not exist for this user.
            if (result.affectedRows === 0) {
                return res.status(404).send('Order not found');
            }

            // Return the ID assigned to the newly inserted payment record.
            return res.json({
                message: 'Payment created successfully',
                payment_id: result.insertId
            });
        }
    );
});

// GET /api/payments/:order_id
// Return payment records for one order belonging to the logged-in user.
paymentsRouter.get('/:order_id', verifyToken, (req, res) => {
    // Route parameters are strings; MySQL compares this value to order_id.
    const id = req.params.order_id;

    // Join orders to verify ownership before returning payment data.
    const sql = `
        SELECT payments.*
        FROM payments
        JOIN orders ON orders.order_id = payments.order_id
        WHERE payments.order_id = ? AND orders.user_id = ?
    `;

    con.query(sql, [id, req.user.id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        // An empty result means no payment was found for this user's order.
        if (results.length === 0) {
            return res.status(404).send('Payment not found');
        }

        // Send all matching payment rows as JSON.
        return res.json(results);
    });
});

// ---------------------------------------------------------------------------
// POINTS
// ---------------------------------------------------------------------------

// GET /api/points
// Return the logged-in user's point transaction history, newest first.
pointsRouter.get('/', verifyToken, (req, res) => {
    // The user ID comes from the verified token, not from client input.
    const sql = `
        SELECT *
        FROM point_transactions
        WHERE user_id = ?
        ORDER BY created_at DESC
    `;

    con.query(sql, [req.user.id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        // If there are no transactions, this returns an empty JSON array.
        return res.json(results);
    });
});

// ---------------------------------------------------------------------------
// RECEIPTS
// ---------------------------------------------------------------------------

// GET /api/receipts/:order_id
// Return a receipt only when its order belongs to the logged-in user.
receiptsRouter.get('/:order_id', verifyToken, (req, res) => {
    // Get the order ID from the URL, for example /api/receipts/12.
    const id = req.params.order_id;

    // Join orders to enforce ownership before selecting a receipt.
    const sql = `
        SELECT receipts.*
        FROM receipts
        JOIN orders ON orders.order_id = receipts.order_id
        WHERE receipts.order_id = ? AND orders.user_id = ?
    `;

    con.query(sql, [id, req.user.id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        // No result means no receipt was found for this user's order.
        if (results.length === 0) {
            return res.status(404).send('Receipt not found');
        }

        // This endpoint returns one receipt object rather than an array.
        return res.json(results[0]);
    });
});

// Export the routers so a server could mount them under /api/payments,
// /api/points, and /api/receipts. The current server mounts the original
// route modules, so this walkthrough file is reference material only.
module.exports = {
    paymentsRouter,
    pointsRouter,
    receiptsRouter
};
