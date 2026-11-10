const jwt = require('jsonwebtoken');
const JWT_KEY = 'paygame_secret_key';

// Verify JWT Token
function verifyToken(req, res, next) {
    const authHeader = req.headers.authorization;
    const token = authHeader.split(' ')[1];

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
        return res.status(401).json({
            message: "Access token required"
        });
    }

    try {
        const payload = jwt.verify(token, JWT_KEY);
        req.user = payload;
        next();
    } catch (err) {
        return res.status(403).json({
            message: "Invalid or expired token"
        });
    }
}

// Verify Admin Role
function verifyAdmin(req, res, next) {
    if (!req.user || req.user.role !== 'admin') {
        return res.status(403).json({
            message: "Admin access required"
        });
    }
    next();
}

module.exports = {
    verifyToken,
    verifyAdmin
};
