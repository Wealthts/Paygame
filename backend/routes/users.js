const express = require('express');
const argon2 = require('@node-rs/argon2');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../middleware/auth'); // ใช้ middleware ตาม auth.js[cite: 9]

const router = express.Router();

// ฟังก์ชัน Broadcast ข้อมูลผู้ใช้ล่าสุดออกไปทาง Socket.io
const broadcastUsers = (io) => {
    const sql = `
        SELECT user_id, username, email, display_name, role, is_active, created_at
        FROM users
        ORDER BY user_id DESC
    `;
    con.query(sql, (err, results) => {
        if (!err && io) {
            io.emit('users_updated', results);
        }
    });
};

// GET /api/users - ดึงรายการผู้ใช้ทั้งหมด
router.get('/', verifyToken, verifyAdmin, (req, res) => {
    const sql = `
        SELECT user_id, username, email, display_name, role, is_active, created_at
        FROM users
        ORDER BY user_id DESC
    `;

    con.query(sql, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: "DB error" });
        }

        return res.json({
            total_users: result.length,
            users: result
        });
    });
});

// PUT /api/users/:id/status
router.put('/:id/status', verifyToken, verifyAdmin, (req, res) => {
    const targetUserId = req.params.id;
    const { is_active } = req.body;

    const checkSql = 'SELECT role FROM users WHERE user_id = ?';
    con.query(checkSql, [targetUserId], (err, results) => {
        if (err) return res.status(500).json({ message: "DB Check Error" });
        if (results.length === 0) return res.status(404).json({ message: "User not found" });

        if (results[0].role === 'admin') {
            return res.status(400).json({ message: "ไม่สามารถระงับการใช้งานบัญชี Admin ได้" });
        }

        // แปลงค่า is_active เป็น 1 หรือ 0 ก่อนอัปเดต MySQL
        const activeValue = (is_active === true || is_active === 1 || is_active === '1') ? 1 : 0;
        const updateSql = 'UPDATE users SET is_active = ? WHERE user_id = ?';

        con.query(updateSql, [activeValue, targetUserId], (err, updateResult) => {
            if (err) {
                console.error(err);
                return res.status(500).json({ message: "Update status failed" });
            }

            // ส่งสัญญาณ Socket.io เพื่อ Real-time ทุกเครื่อง
            if (typeof broadcastUsers === 'function') {
                broadcastUsers(req.io);
            }

            return res.json({ message: "อัปเดตสถานะสำเร็จ", is_active: activeValue });
        });
    });
});

// PUT /api/users/:id/role - เปลี่ยนบทบาท Role (บล็อกการปรับ Role ของ Admin)[cite: 7]
router.put('/:id/role', verifyToken, verifyAdmin, (req, res) => {
    const targetUserId = req.params.id;
    const { role } = req.body;

    const checkSql = 'SELECT role FROM users WHERE user_id = ?';
    con.query(checkSql, [targetUserId], (err, results) => {
        if (err) return res.status(500).json({ message: "DB error" });
        if (results.length === 0) return res.status(404).json({ message: "User not found" });

        if (results[0].role === 'admin') {
            return res.status(400).json({ message: "ไม่สามารถเปลี่ยนบทบาทของบัญชี Admin ได้" });
        }

        const updateSql = 'UPDATE users SET role = ? WHERE user_id = ?';
        con.query(updateSql, [role, targetUserId], (err) => {
            if (err) return res.status(500).json({ message: "Update role failed" });

            broadcastUsers(req.io);
            return res.json({ message: "อัปเดตบทบาทสำเร็จ" });
        });
    });
});

// PUT /api/users/:id/profile[cite: 7]
router.put('/:id/profile', verifyToken, verifyAdmin, (req, res) => {
    const userId = req.params.id;
    const { display_name, email } = req.body;

    if (!display_name || !email) {
        return res.status(400).json({ message: "กรุณากรอกข้อมูลให้ครบถ้วน" });
    }

    const sql = 'UPDATE users SET display_name = ?, email = ? WHERE user_id = ?';
    con.query(sql, [display_name.trim(), email.trim(), userId], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: "Update profile failed" });
        }

        // 💡 บรอดแคสต์ข้อมูลผู้ใช้ที่อัปเดตแล้วไปยัง Flutter ทุกเครื่องที่เปิดอยู่อัตโนมัติ
        if (typeof broadcastUsers === 'function') {
            broadcastUsers(req.io);
        } else if (req.io) {
            const getSql = 'SELECT user_id, username, email, display_name, role, is_active, created_at FROM users ORDER BY user_id DESC';
            con.query(getSql, (e, users) => {
                if (!e) req.io.emit('users_updated', users);
            });
        }

        return res.json({ message: "อัปเดตข้อมูลสำเร็จ" });
    });
});

// PUT /api/users/:id/reset-password - รีเซ็ตรหัสผ่าน[cite: 7]
router.put('/:id/reset-password', verifyToken, verifyAdmin, async (req, res) => {
    const userId = req.params.id;
    const { new_password } = req.body;

    if (!new_password || new_password.length < 6) {
        return res.status(400).json({ message: "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร" });
    }

    try {
        const passwordHash = await argon2.hash(new_password);
        const sql = 'UPDATE users SET password_hash = ? WHERE user_id = ?';
        con.query(sql, [passwordHash, userId], (err) => {
            if (err) return res.status(500).json({ message: "DB error" });
            return res.json({ message: "รีเซ็ตรหัสผ่านสำเร็จ" });
        });
    } catch (error) {
        return res.status(500).json({ message: "Password hashing failed" });
    }
});

module.exports = router;