const express = require('express');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const con = require('../db_config');
const crypto = require('crypto');
const { sendMail } = require('../utils/mailer');


const router = express.Router();
const JWT_KEY = 'paygame_secret_key';

// Register
// POST /api/register
router.post('/register', async (req, res) => {
    try {
        console.log('========== REGISTER DEBUG ==========');
        console.log('Content-Type:', req.headers['content-type']);
        console.log('Request Body:', JSON.stringify(req.body, null, 2));
        const { username, password, email, display_name } = req.body;

        console.log('Username:', username);
        console.log('Password:', password ? 'Received' : 'Missing');
        console.log('Email:', email);
        console.log('Display Name:', display_name);

        // Validate input
        if (
            !username ||
            !password ||
            !email ||
            !display_name
        ) {
            console.log('Register Request:', req.body);
            return res.status(400).json({
                message: "Please fill in all required fields"
            });
        }

        if (
            username.trim().length < 3 ||
            password.length < 6 ||
            !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
        ) {
            return res.status(400).json({
                message: "Invalid username, password or email"
            });
        }

        // Check duplicate username
        const checkSql = "SELECT user_id FROM users WHERE username = ?";

        con.query(checkSql, [username.trim()], async (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).json({
                    message: "DB error"
                });
            }

            if (result.length > 0) {
                return res.status(409).json({
                    message: "Username already exists"
                });
            }

            try {
                // Hash password
                const passwordHash = await argon2.hash(password);

                // Insert user
                const insertSql = `
                    INSERT INTO users
                    (username, password_hash, email, display_name, role, is_active)
                    VALUES (?, ?, ?, ?, 'user', 1)
                `;

                con.query(
                    insertSql,
                    [
                        username.trim(),
                        passwordHash,
                        email.trim(),
                        display_name.trim()
                    ],
                    (err, insertResult) => {
                        if (err) {
                            console.error(err);
                            return res.status(500).json({
                                message: 'Registration failed'
                            });
                        }

                        return res.status(201).json({
                            message: 'Register successful',
                            user: {
                                id: insertResult.insertId,
                                username: username.trim(),
                                display_name: display_name.trim(),
                                role: 'user'
                            }
                        });
                    }
                );
            } catch (error) {
                console.error(error);
                return res.status(500).json({
                    message: 'Password hashing failed'
                });
            }
        });
    } catch (error) {
        console.error(error);
        return res.status(500).json({
            message: 'Server error'
        });
    }
});


// login
router.post('/login', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({
            message: "Username and password are required"
        });
    }

    const inputLogin = username.trim();

    const sql = `
        SELECT user_id, username, email, password_hash,
        display_name, role, is_active
        FROM users
        WHERE username = ? OR LOWER(email) = LOWER(?)
    `;

    con.query(sql, [inputLogin, inputLogin], async (err, result) => {
        // Check database error first
        if (err) {
            console.error(err);
            return res.status(500).json({
                message: "DB error"
            });
        }

        if (result.length === 0) {
            console.log(`Login failed: User '${inputLogin}' not found in DB`);
            return res.status(401).json({
                message: "Invalid username or password"
            });
        }

        const user = result[0];

        if (user.is_active !== 1 && user.is_active !== true) {
            return res.status(403).json({
                message: "This account is inactive"
            });
        }

        try {
            // Verify password
            const passwordMatch = await argon2.verify(
                user.password_hash,
                password
            );

            if (!passwordMatch) {
                console.log(`Login failed: Password mismatch for user '${user.username}'`);
                return res.status(401).json({
                    message: "Invalid username or password"
                });
            }

            // Create JWT
            const token = jwt.sign(
                {
                    id: user.user_id,
                    username: user.username,
                    role: user.role
                },
                JWT_KEY,
                {
                    expiresIn: '1d'
                }
            );

            return res.json({
                message: "Login successful",
                token: token,
                user: {
                    id: user.user_id,
                    username: user.username,
                    display_name: user.display_name,
                    role: user.role
                }
            });
        } catch (error) {
            console.error('Argon2 Verify Error:', error);
            return res.status(500).json({
                message: "Login failed"
            });
        }
    });
});

// ---------------------------------------------------------------
// Forgot / Reset Password (ส่งรหัสยืนยัน 6 หลักไปทางอีเมลจริง)
// ---------------------------------------------------------------
const db = con.promise();

const RESET_CODE_TTL_MIN = 15;          // รหัสหมดอายุใน 15 นาที
const RESET_RESEND_COOLDOWN_SEC = 60;   // ขอรหัสใหม่ได้ทุก 60 วินาที
const RESET_MAX_ATTEMPTS = 5;           // กรอกผิดได้ไม่เกิน 5 ครั้งต่อรหัส
const RESET_SECRET = process.env.RESET_SECRET || JWT_KEY;
const FORGOT_GENERIC_MESSAGE =
    'If this email is registered, a verification code has been sent.';

function hashResetCode(userId, code) {
    return crypto
        .createHmac('sha256', RESET_SECRET)
        .update(`${userId}:${code}`)
        .digest('hex');
}

function isValidEmail(email) {
    return typeof email === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

function escapeHtml(text) {
    return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

// หา user ที่ใช้งานได้จากอีเมล (ถ้ามีหลายบัญชีใช้อีเมลเดียวกัน จะใช้บัญชีแรก)
async function findActiveUserByEmail(email) {
    const [users] = await db.query(
        `SELECT user_id, username, display_name
         FROM users
         WHERE email = ? AND is_active = 1
         ORDER BY user_id ASC
         LIMIT 1`,
        [email]
    );
    return users[0] || null;
}

// POST /api/forgot-password   body: { email }
// ตอบข้อความเดิมเสมอ ไม่บอกว่ามีอีเมลนี้ในระบบหรือไม่
router.post('/forgot-password', async (req, res) => {
    const email = typeof req.body.email === 'string' ? req.body.email.trim() : '';

    if (!isValidEmail(email)) {
        return res.status(400).json({ message: 'Please enter a valid email address' });
    }

    try {
        const user = await findActiveUserByEmail(email);

        if (!user) {
            return res.json({ message: FORGOT_GENERIC_MESSAGE });
        }

        // กันกดขอรหัสถี่เกินไป
        const [recent] = await db.query(
            `SELECT reset_id FROM password_resets
             WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND)
             LIMIT 1`,
            [user.user_id, RESET_RESEND_COOLDOWN_SEC]
        );

        if (recent.length > 0) {
            return res.json({ message: FORGOT_GENERIC_MESSAGE });
        }

        // ล้างรหัสเก่าที่หมดอายุนานแล้ว และยกเลิกรหัสเดิมที่ยังไม่ได้ใช้
        await db.query('DELETE FROM password_resets WHERE expires_at < DATE_SUB(NOW(), INTERVAL 1 DAY)');
        await db.query(
            'UPDATE password_resets SET used_at = NOW() WHERE user_id = ? AND used_at IS NULL',
            [user.user_id]
        );

        // สร้างรหัส 6 หลัก (เก็บเฉพาะค่า hash ใน DB)
        const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');

        const [inserted] = await db.query(
            `INSERT INTO password_resets (user_id, code_hash, expires_at)
            VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE))`,
            [user.user_id, hashResetCode(user.user_id, code), RESET_CODE_TTL_MIN]
        );

        try {
            await sendMail({
                to: email,
                subject: 'GamePay - Password reset code',
                text:
                    `Hello ${user.display_name},\n\n` +
                    `Your GamePay password reset code is: ${code}\n` +
                    `Account: ${user.username}\n` +
                    `This code expires in ${RESET_CODE_TTL_MIN} minutes.\n\n` +
                    `If you did not request this, you can ignore this email.\n\n` +
                    `สวัสดีคุณ ${user.display_name} รหัสยืนยันสำหรับรีเซ็ตรหัสผ่านคือ ${code} ` +
                    `(หมดอายุใน ${RESET_CODE_TTL_MIN} นาที) หากคุณไม่ได้เป็นผู้ขอ กรุณาไม่ต้องสนใจอีเมลฉบับนี้`,
                html: `
                    <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:24px;border:1px solid #eee;border-radius:12px">
                        <h2 style="color:#A60C19;margin-top:0">GamePay</h2>
                        <p>Hello ${escapeHtml(user.display_name)},</p>
                        <p>Use this code to reset the password of account <b>${escapeHtml(user.username)}</b>:</p>
                        <p style="font-size:32px;font-weight:bold;letter-spacing:8px;text-align:center;background:#FFFDF5;padding:16px;border-radius:8px">${code}</p>
                        <p>This code expires in ${RESET_CODE_TTL_MIN} minutes.</p>
                        <p style="color:#888;font-size:12px">If you did not request this, you can ignore this email.<br>
                        หากคุณไม่ได้เป็นผู้ขอ กรุณาไม่ต้องสนใจอีเมลฉบับนี้</p>
                    </div>`
            });
        } catch (mailErr) {
    console.error('Send reset email failed:', mailErr.message);
    console.log(`\n🔑 [DEV OTP] รหัสยืนยันสำหรับ ${email} คือ: ${code}\n`);

    // ไม่ต้องลบออกจาก DB และส่งสถานะสำเร็จกลับไปให้หน้าแอปไป Step 2 ต่อได้เลย
    return res.json({ message: FORGOT_GENERIC_MESSAGE });
}

        return res.json({ message: FORGOT_GENERIC_MESSAGE });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Server error' });
    }
});

// POST /api/reset-password   body: { email, code, new_password }
router.post('/reset-password', async (req, res) => {
    const email = typeof req.body.email === 'string' ? req.body.email.trim() : '';
    const code = String(req.body.code || '').trim();
    const newPassword = req.body.new_password;

    if (!isValidEmail(email) || !/^\d{6}$/.test(code)) {
        return res.status(400).json({ message: 'Invalid email or code' });
    }

    if (typeof newPassword !== 'string' || newPassword.length < 6) {
        return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    const invalid = { message: 'Invalid or expired code' };

    try {
        const user = await findActiveUserByEmail(email);

        if (!user) {
            return res.status(400).json(invalid);
        }

        // รหัสล่าสุดที่ยังไม่ถูกใช้และยังไม่หมดอายุ
        const [rows] = await db.query(
            `SELECT reset_id, code_hash, attempts
             FROM password_resets
             WHERE user_id = ? AND used_at IS NULL AND expires_at > NOW()
             ORDER BY reset_id DESC
             LIMIT 1`,
            [user.user_id]
        );

        if (rows.length === 0) {
            return res.status(400).json(invalid);
        }

        const reset = rows[0];

        if (reset.attempts >= RESET_MAX_ATTEMPTS) {
            return res.status(429).json({
                message: 'Too many attempts. Please request a new code.'
            });
        }

        const expected = Buffer.from(reset.code_hash, 'hex');
        const actual = Buffer.from(hashResetCode(user.user_id, code), 'hex');
        const matched =
            expected.length === actual.length && crypto.timingSafeEqual(expected, actual);

        if (!matched) {
            await db.query(
                'UPDATE password_resets SET attempts = attempts + 1 WHERE reset_id = ?',
                [reset.reset_id]
            );
            return res.status(400).json(invalid);
        }

        const passwordHash = await argon2.hash(newPassword);

        // ใช้รหัสได้ครั้งเดียว (กัน request ซ้อนกัน)
        const [consumed] = await db.query(
            'UPDATE password_resets SET used_at = NOW() WHERE reset_id = ? AND used_at IS NULL',
            [reset.reset_id]
        );

        if (consumed.affectedRows === 0) {
            return res.status(400).json(invalid);
        }

        await db.query(
            'UPDATE users SET password_hash = ? WHERE user_id = ?',
            [passwordHash, user.user_id]
        );

        return res.json({ message: 'Password has been reset successfully' });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Server error' });
    }
});


module.exports = router;