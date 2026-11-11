-- Apply once to the existing paygame database before starting the new API.
ALTER TABLE point_transactions MODIFY order_id INT UNSIGNED NULL;
CREATE TABLE user_coupons (
 coupon_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 user_id INT UNSIGNED NOT NULL,
 reward_id VARCHAR(20) NOT NULL,
 name VARCHAR(200) NOT NULL,
 amount_satang INT NOT NULL DEFAULT 0,
 percent INT NOT NULL DEFAULT 0,
 minimum_satang INT NOT NULL DEFAULT 0,
 status ENUM('Available','Reserved','Used') NOT NULL DEFAULT 'Available',
 order_id INT UNSIGNED NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 INDEX(user_id, status),
 FOREIGN KEY(user_id) REFERENCES users(user_id),
 FOREIGN KEY(order_id) REFERENCES orders(order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
ALTER TABLE orders
 ADD coupon_id INT UNSIGNED NULL,
 ADD spent_points INT NOT NULL DEFAULT 0,
 ADD coupon_discount DECIMAL(10,2) NOT NULL DEFAULT 0,
 ADD fee_amount DECIMAL(10,2) NOT NULL DEFAULT 0;
