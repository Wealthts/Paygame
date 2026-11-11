const express = require('express');
const con = require('../db_config');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// ฟังก์ชันช่วยดึงรายการผู้ใช้และ Broadcast ผ่าน Socket.io
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
            return res.status(500).send("DB error");
        }

        return res.json({
            total_users: result.length,
            users: result
        });
    });
});

// PUT /api/users/:id/status - สลับสถานะเปิด/ปิดใช้งาน (ห้ามระงับบัญชี Admin)
router.put('/:id/status', verifyToken, verifyAdmin, (req, res) => {
    const targetUserId = req.params.id;
    const { is_active } = req.body;

    // 1. ตรวจสอบ Role ของผู้ใช้เป้าหมายก่อน
    const checkSql = 'SELECT role FROM users WHERE user_id = ?';
    con.query(checkSql, [targetUserId], (err, results) => {
        if (err) return res.status(500).json({ message: "DB error" });
        if (results.length === 0) return res.status(404).json({ message: "User not found" });

        // 🛑 บล็อกไม่ให้ระงับบัญชี Admin
        if (results[0].role === 'admin') {
            return res.status(400).json({ message: "ไม่สามารถระงับการใช้งานบัญชี Admin ได้" });
        }

        // 2. อัปเดตสถานะใน MySQL
        const updateSql = 'UPDATE users SET is_active = ? WHERE user_id = ?';
        con.query(updateSql, [is_active ? 1 : 0, targetUserId], (err) => {
            if (err) return res.status(500).json({ message: "Update failed" });

            // 3. ยิงข้อมูลล่าสุดออก Socket.io ไปหาทุกเครื่องทันที
            broadcastUsers(req.io);

            return res.json({ message: "Updated status successfully" });
        });
    });
});

// PUT /api/users/:id/role - เปลี่ยนบทบาท Role (ห้ามปรับ Role บัญชี Admin)
router.put('/:id/role', verifyToken, verifyAdmin, (req, res) => {
    const targetUserId = req.params.id;
    const { role } = req.body;

    const checkSql = 'SELECT role FROM users WHERE user_id = ?';
    con.query(checkSql, [targetUserId], (err, results) => {
        if (err) return res.status(500).json({ message: "DB error" });
        if (results.length === 0) return res.status(404).json({ message: "User not found" });

        // 🛑 บล็อกไม่ให้เปลี่ยนบทบาทของ Admin
        if (results[0].role === 'admin') {
            return res.status(400).json({ message: "ไม่สามารถเปลี่ยนบทบาทของบัญชี Admin ได้" });
        }

        const updateSql = 'UPDATE users SET role = ? WHERE user_id = ?';
        con.query(updateSql, [role, targetUserId], (err) => {
            if (err) return res.status(500).json({ message: "Update failed" });

            broadcastUsers(req.io);

            return res.json({ message: "Updated role successfully" });
        });
    });
});

module.exports = router;