
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./routes/auth');
const gameRoutes = require('./routes/games');

// Use Routes
app.use('/api', authRoutes);
app.use('/api/games', gameRoutes);

// Start Server
app.listen(3000, () => {
    console.log('Server is running at port 3000');
});