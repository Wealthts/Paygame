const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
const authRoutes = require('./routes/auth');
const gamesRoutes = require('./routes/games');
const ordersRoutes = require('./routes/orders');
const packagesRoutes = require('./routes/packages');
const paymentsRoutes = require('./routes/payments');
const pointsRoutes = require('./routes/points');
const receiptsRoutes = require('./routes/receipts');
const usersRoutes = require('./routes/users');

// Use Routes
app.use('/api', authRoutes);
app.use('/api/games', gamesRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/packages', packagesRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/points', pointsRoutes);
app.use('/api/receipts', receiptsRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/coupons', require('./routes/coupons'));
app.use('/api/checkout', require('./routes/checkout'));
app.use('/api/admin', require('./routes/admin_reports'));

// Start Server
app.listen(3000, () => {
    console.log('Server is running at port 3000');
});
