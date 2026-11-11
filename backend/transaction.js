const pool = require('./db_config');
async function transaction(work) {
 const db = await pool.promise().getConnection();
 try { await db.beginTransaction(); const result = await work(db); await db.commit(); return result; }
 catch (error) { await db.rollback(); throw error; }
 finally { db.release(); }
}
function fail(message, status = 400) { const error = new Error(message); error.status = status; throw error; }
async function balance(db, user) {
 const [rows] = await db.query('SELECT COALESCE(SUM(points_delta),0) AS balance FROM point_transactions WHERE user_id=?', [user]);
 return Number(rows[0].balance);
}
function endpoint(work) { return async (req,res) => {
 try { res.json(await work(req)); }
 catch (error) { if (!error.status) console.error(error); res.status(error.status || 500).send(error.status ? error.message : 'Database error'); }
}; }
module.exports = {transaction, fail, balance, endpoint};
