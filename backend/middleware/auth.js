
const jwt = require('jsonwebtoken');

const JWT_KEY = process.env.JWT_KEY || 'paygame_secret_key';

// Verify JWT Token
function verifyToken(req, res, next) {
    const authHeader = req.headers.authorization;

    // Check Authorization Header
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            message: 'Access token required'
        });
    }

    // Extract Token
    const token = authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({
            message: 'Invalid authorization format'
        });
    }

    try {
        // Verify JWT
        const payload = jwt.verify(token, JWT_KEY);

        // Save user information to request
        req.user = payload;

        next();

    } catch (err) {
        console.error('JWT Verification Error:', err.message);

        return res.status(401).json({
            message: 'Invalid or expired token'
        });
    }
}

// Verify Admin Role
function verifyAdmin(req, res, next) {

    // Check user authentication
    if (!req.user) {
        return res.status(401).json({
            message: 'Authentication required'
        });
    }

    // Check Admin Role
    if (req.user.role !== 'admin') {
        return res.status(403).json({
            message: 'Admin access required'
        });
    }

    next();
}

module.exports = {
    verifyToken,
    verifyAdmin
};
