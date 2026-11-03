const jwt = require('jsonwebtoken');
const JWT_KEY = 'paygame_secret_key';

// Check JWT
function verifyToken(req, res, next) {
    const header = req.headers['authorization'];
    const token = header.split(' ')[1];

    if (!header) return res.status(401).send('Token required');
    if (!token) return res.status(401).send('Invalid token');

    try {
        const payload = jwt.verify(token, JWT_KEY);
        req.user = payload;
        next();
    } catch (err) {
        return res.status(403).send('Unauthorized');
    }
}

// Check Admin
function verifyAdmin(req, res, next) {
    if (req.user.role !== 'admin') return res.status(403).send('Admin only');
    next();
}

module.exports = {
    verifyToken,
    verifyAdmin
};
