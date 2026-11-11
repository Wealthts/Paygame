const router = require('express').Router();
const {randomUUID} = require('node:crypto');
const {verifyToken} = require('../middleware/auth');
const {transaction, fail, balance, endpoint} = require('../transaction');
const {calculate} = require('../discounts');
router.post('/', verifyToken, endpoint(req => transaction(async db => {
 const {package_id, player_uid, server_code, coupon_id, use_coins = false, method} = req.body;
 if (!Number.isInteger(package_id) || package_id <= 0 || typeof player_uid !== 'string' || !player_uid.trim() || player_uid.length > 100) fail('Invalid package or player UID');
 if (typeof use_coins !== 'boolean' || (coupon_id != null && (!Number.isInteger(coupon_id) || coupon_id <= 0)) || req.body.coupon_ids != null) fail('Select at most one coupon');
 if (!['qr','wallet','card'].includes(method)) fail('Invalid payment method');
 await db.query('SELECT user_id FROM users WHERE user_id=? FOR UPDATE', [req.user.id]);
 const [packages] = await db.query(`SELECT p.*, g.game_name, g.requires_server FROM packages p
 JOIN games g ON p.game_id=g.game_id WHERE p.package_id=? AND p.is_active=1 AND g.is_active=1`, [package_id]);
 const pack = packages[0];
 if (!pack) fail('Package not found',404);
 if (pack.requires_server && !server_code) fail('Server required');
 let coupon;
 if (coupon_id != null) {
   const [rows] = await db.query("SELECT * FROM user_coupons WHERE coupon_id=? AND user_id=? AND status='Available' FOR UPDATE", [coupon_id,req.user.id]);
   coupon = rows[0]; if (!coupon) fail('Coupon is unavailable');
   if (Math.round(Number(pack.price)*100) < coupon.minimum_satang) fail('Coupon minimum not met');
 }
 const funds = await balance(db,req.user.id);
 const result = calculate(Math.round(Number(pack.price)*100),funds,use_coins,coupon,method);
 const [order] = await db.query(`INSERT INTO orders
 (user_id,package_id,player_uid,server_code,game_name_snapshot,package_name_snapshot,original_price,
 discount_amount,total_amount,status,coupon_id,spent_points,coupon_discount,fee_amount)
 VALUES (?,?,?,?,?,?,?,?,?,'Pending',?,?,?,?)`, [req.user.id,package_id,player_uid,server_code || '',pack.game_name,
 pack.package_name,pack.price,(result.discount+result.spent*10)/100,result.total/100,coupon_id || null,result.spent,result.discount/100,result.fee/100]);
 const id = order.insertId;
 if (coupon) await db.query("UPDATE user_coupons SET status='Reserved',order_id=? WHERE coupon_id=?",[id,coupon_id]);
 if (result.spent) await db.query(`INSERT INTO point_transactions (user_id,order_id,event_key,type,points_delta)
 VALUES (?,?,?,'Spend',?)`, [req.user.id,id,'SPEND_'+id,-result.spent]);
 await db.query(`INSERT INTO payments (order_id,transaction_ref,method,amount,status) VALUES (?,?,?,?,'Pending')`,
 [id,randomUUID(),method,result.total/100]);
 return {order_id:id,total_amount:result.total/100,discount_amount:(result.discount+result.spent*10)/100,
 fee_amount:result.fee/100,spent_points:result.spent,points_balance:funds-result.spent,coupon_id:coupon_id || null};
})));
module.exports = router;
