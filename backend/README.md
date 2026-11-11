<!-- init stage -->
- node -v
- cmd
- npm init -y
- create file "db_config.js" in server
- create file "app.js" in server

<!-- install server -->
- npm install express mysql2 cors
- npm install @node-rs/argon2
- npm install jsonwebtoken
- npm install mockup

<!-- install flutter -->
- flutter pub add http
- flutter pub add mocktail

<!-- run server -->
- node --watch app.js

<!-- update or fix -->
- flutter pub add


## Coupon checkout setup

Before running this revision, apply `migrations/001_coupons.sql` once to your
existing database (back up your database before schema changes):

```sql
USE paygame;
SOURCE migrations/001_coupons.sql;
```

Restart with `node server.js`. Optional connection environment variables:
`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.

- `GET /api/coupons`: current user's available, reserved and used coupons.
- `POST /api/coupons/redeem`: `{ "reward_id": "r1" }`; costs come from the server.
- `POST /api/checkout`: `package_id`, `player_uid`, optional `server_code`,
  one optional `coupon_id`, boolean `use_coins`, and `method` (`qr`, `wallet`, `card`).
  Creates the order, payment and reservations in one transaction.
- `PUT /api/payments/:id/status`: admin approval (`Paid`) or rejection (`Failed`).
  Rejection cancels the order and returns the coupon and coins. Repeated identical
  decisions are harmless; reversing a final decision is rejected.

The original order-completion endpoint now directs admins to payment approval
so coupon finalization, coins and receipts cannot be bypassed.

Run `node --test test/*.test.js` for unit tests. Set `RUN_DB_TESTS=1` to also run
integration tests against a local MariaDB/MySQL server. Those tests create and
remove a uniquely named `paygame_test_*` database, and require create/drop rights.
They import the repository schema and apply the migration automatically.
