const nodemailer = require('nodemailer');

let transporter = null;

// สร้าง SMTP transporter จากค่าใน .env (สร้างครั้งเดียวแล้วใช้ซ้ำ)
function getTransporter() {
    if (transporter) return transporter;

    const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;

    if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
        throw new Error('SMTP is not configured (set SMTP_HOST, SMTP_USER, SMTP_PASS in .env)');
    }

    const port = Number(SMTP_PORT || 465);

    transporter = nodemailer.createTransport({
        host: SMTP_HOST,
        port,
        secure: port === 465, // 465 = SSL, 587 = STARTTLS
        auth: { user: SMTP_USER, pass: SMTP_PASS }
    });

    return transporter;
}

// ส่งอีเมลจริงผ่าน SMTP
async function sendMail({ to, subject, text, html }) {
    const from = process.env.MAIL_FROM || `"GamePay" <${process.env.SMTP_USER}>`;

    return getTransporter().sendMail({ from, to, subject, text, html });
}

module.exports = { sendMail };