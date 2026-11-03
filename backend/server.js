
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./routes/auth');
const gameRoutes = require('./routes/games');
const packageRoutes = require('./routes/packages');
const paymentRoutes = require('./routes/payments');
const pointRoutes = require('./routes/points');
const receiptRoutes = require('./routes/receipts');

// Use Routes
app.use('/api', authRoutes);
app.use('/api/games', gameRoutes);
app.use('/api/packages', packageRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/points', pointRoutes);
app.use('/api/receipts', receiptRoutes);

// Start Server
app.listen(3000, () => {
    console.log('Server is running at port 3000');
});
