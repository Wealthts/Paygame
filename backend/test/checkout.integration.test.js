const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
// Only runs against an explicitly requested, newly created disposable database.
test('checkout reservations, ownership, concurrency, approval and refunds',
 {skip: !process.env.RUN_DB_TESTS}, async () => {
 const mysql = require('mysql2/promise');
 const name = 'paygame_test_' + Date.now();
 process.env.DB_NAME = name;
 const setup = await mysql.createConnection({host:process.env.DB_HOST || '127.0.0.1',
   port:Number(process.env.DB_PORT || 3306),user:process.env.DB_USER || 'root',
   password:process.env.DB_PASSWORD || '',multipleStatements:true});
 let server, pool;
 try {
   await setup.query('CREATE DATABASE ' + name);
   await setup.query('USE ' + name);
   await setup.query(fs.readFileSync(path.join(__dirname,'../../paygame (5).sql'),'utf8'));
   await setup.query(fs.readFileSync(path.join(__dirname,'../migrations/001_coupons.sql'),'utf8'));
   await setup.query(`INSERT INTO games (game_name,category,uid_pattern,requires_server,is_active) VALUES ('Test','Mobile','.*',0,1)`);
   const [[game]] = await setup.query('SELECT MAX(game_id) id FROM games');
   const [pack] = await setup.query(`INSERT INTO packages (game_id,package_name,price,is_active) VALUES (?,'Test pack',350,1)`,[game.id]);
   await setup.query(`INSERT INTO point_transactions (user_id,order_id,event_key,type,points_delta) VALUES (2,NULL,'SEED','Earn',2000)`);
   const express = require('express');
   const jwt = require('jsonwebtoken');
   const app = express(); app.use(express.json());
   app.use('/coupons',require('../routes/coupons'));
   app.use('/checkout',require('../routes/checkout'));
   app.use('/payments',require('../routes/payments'));
   pool = require('../db_config');
   server = await new Promise(resolve => {const s=app.listen(0,'127.0.0.1',()=>resolve(s));});
   const url = 'http://127.0.0.1:'+server.address().port;
   async function call(route,body,user=2,role='user',method='POST') {
     const response = await fetch(url+route,{method,headers:{'Content-Type':'application/json',
       Authorization:'Bearer '+jwt.sign({id:user,role},process.env.JWT_KEY || 'paygame_secret_key')},
       body:body == null ? undefined : JSON.stringify(body)});
     const text=await response.text(); let data; try {data=JSON.parse(text);}catch {data=text;}
     return {status:response.status,data};
   }
   const redeemed=await call('/coupons/redeem',{reward_id:'r1',cost:0});
   assert.equal(redeemed.status,200);
   const id=redeemed.data.coupon_id;
   const body={package_id:pack.insertId,player_uid:'1234567890',coupon_id:id,use_coins:true,method:'qr'};
   assert.equal((await call('/checkout',body,3)).status,400);
   assert.equal((await call('/checkout',{...body,coupon_id:[id]})).status,400);
   const concurrent=await Promise.all([call('/checkout',body),call('/checkout',body)]);
   assert.deepEqual(concurrent.map(x=>x.status).sort(),[200,400]);
   const order=concurrent.find(x=>x.status===200).data;
   assert.equal(order.total_amount,150); assert.equal(order.spent_points,1800);
   const [[payment]]=await setup.query('SELECT payment_id FROM payments WHERE order_id=?',[order.order_id]);
   assert.equal((await call('/payments/'+payment.payment_id+'/status',{status:'Failed'},2,'user','PUT')).status,403);
   const failed=await call('/payments/'+payment.payment_id+'/status',{status:'Failed'},1,'admin','PUT');
   assert.equal(failed.status,200);
   assert.equal((await call('/payments/'+payment.payment_id+'/status',{status:'Failed'},1,'admin','PUT')).status,200);
   const [[balance]]=await setup.query('SELECT SUM(points_delta) n FROM point_transactions WHERE user_id=2');
   assert.equal(Number(balance.n),1800);
   const next=await call('/checkout',body); assert.equal(next.status,200);
   const [[p2]]=await setup.query('SELECT payment_id FROM payments WHERE order_id=?',[next.data.order_id]);
   const approvals=await Promise.all([call('/payments/'+p2.payment_id+'/status',{status:'Paid'},1,'admin','PUT'),call('/payments/'+p2.payment_id+'/status',{status:'Paid'},1,'admin','PUT')]);
   assert.deepEqual(approvals.map(x=>x.status),[200,200]);
   assert.equal((await call('/payments/'+p2.payment_id+'/status',{status:'Failed'},1,'admin','PUT')).status,409);
   const [[earned]]=await setup.query('SELECT SUM(points_delta) n FROM point_transactions WHERE user_id=2');
   assert.equal(Number(earned.n),15);
   const [[coupon]]=await setup.query('SELECT status FROM user_coupons WHERE coupon_id=?',[id]);
   assert.equal(coupon.status,'Used');
   assert.equal((await call('/checkout',body)).status,400);
   assert.equal((await call('/coupons/redeem',{reward_id:'r1'})).status,400);
 } finally {
   if (server) await new Promise(resolve=>server.close(resolve));
   if (pool) await pool.promise().end();
   await setup.query('DROP DATABASE IF EXISTS '+name);
   await setup.end();
 }
});
