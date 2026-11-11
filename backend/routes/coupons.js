const router = require('express').Router();
const pool = require('../db_config');
const {verifyToken} = require('../middleware/auth');
const {transaction, fail, balance, endpoint} = require('../transaction');
const {rewards} = require('../discounts');
router.use(verifyToken);
router.get('/', endpoint(async req => {
 const [rows] = await pool.promise().query('SELECT * FROM user_coupons WHERE user_id=? ORDER BY created_at DESC, coupon_id DESC', [req.user.id]);
 return rows;
}));
router.post('/redeem', endpoint(req => transaction(async db => {
 const reward = rewards[req.body.reward_id];
 if (!reward) fail('Unknown reward');
 await db.query('SELECT user_id FROM users WHERE user_id=? FOR UPDATE', [req.user.id]);
 if (await balance(db, req.user.id) < reward.cost) fail('Not enough coins');
 const [created] = await db.query(`INSERT INTO user_coupons
 (user_id,reward_id,name,amount_satang,percent,minimum_satang) VALUES (?,?,?,?,?,?)`,
 [req.user.id,req.body.reward_id,reward.name,reward.amount,reward.percent,reward.minimum]);
 await db.query(`INSERT INTO point_transactions (user_id,order_id,event_key,type,points_delta)
 VALUES (?,NULL,?,'Redeem',?)`, [req.user.id, 'COUPON_'+created.insertId, -reward.cost]);
 return {coupon_id: created.insertId};
})));
module.exports = router;
