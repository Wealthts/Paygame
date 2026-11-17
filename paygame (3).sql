-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 17, 2026 at 11:04 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `paygame`
--

-- --------------------------------------------------------

--
-- Table structure for table `coupons`
--

CREATE TABLE `coupons` (
  `coupon_id` int(50) UNSIGNED NOT NULL,
  `code` varchar(50) NOT NULL,
  `discount_type` enum('fixed','percent') NOT NULL,
  `discount_value` decimal(10,2) NOT NULL,
  `min_order_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `max_discount_amount` decimal(10,2) DEFAULT NULL,
  `use_limit` int(50) UNSIGNED DEFAULT NULL,
  `use_count` int(50) UNSIGNED NOT NULL DEFAULT 0,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `coupons`
--

INSERT INTO `coupons` (`coupon_id`, `code`, `discount_type`, `discount_value`, `min_order_amount`, `max_discount_amount`, `use_limit`, `use_count`, `start_date`, `end_date`, `is_active`, `created_at`) VALUES
(1, 'WELCOME10', 'fixed', 10.00, 30.00, NULL, 100, 1, '2026-11-01 00:00:00', '2026-12-31 23:59:59', 1, '2026-11-11 23:00:00'),
(2, 'SAVE20P', 'percent', 20.00, 100.00, 50.00, 50, 1, '2026-11-01 00:00:00', '2026-12-31 23:59:59', 1, '2026-11-11 23:00:00'),
(3, 'REWARD20', 'fixed', 20.00, 0.00, NULL, NULL, 0, '2026-01-01 00:00:00', '2030-12-31 23:59:59', 1, '2026-11-11 23:00:00'),
(4, 'REWARD50', 'fixed', 50.00, 300.00, NULL, NULL, 0, '2026-01-01 00:00:00', '2030-12-31 23:59:59', 1, '2026-11-11 23:00:00'),
(5, 'REWARD5P', 'percent', 5.00, 0.00, NULL, NULL, 0, '2026-01-01 00:00:00', '2030-12-31 23:59:59', 1, '2026-11-11 23:00:00'),
(6, 'REWARD150', 'fixed', 150.00, 1000.00, NULL, NULL, 0, '2026-01-01 00:00:00', '2030-12-31 23:59:59', 1, '2026-11-11 23:00:00'),
(7, 'TEST10', 'percent', 20.00, 200.00, 80.00, 100, 0, '2026-11-15 00:00:00', '2026-12-31 23:59:59', 1, '2026-11-15 18:18:09');

-- --------------------------------------------------------

--
-- Table structure for table `games`
--

CREATE TABLE `games` (
  `game_id` int(50) UNSIGNED NOT NULL,
  `game_name` varchar(100) NOT NULL,
  `category` varchar(100) NOT NULL,
  `uid_pattern` varchar(100) NOT NULL,
  `requires_server` tinyint(1) NOT NULL,
  `image_url` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `games`
--

INSERT INTO `games` (`game_id`, `game_name`, `category`, `uid_pattern`, `requires_server`, `image_url`, `is_active`) VALUES
(1, 'Genshin Impact', 'Mobile', '0001', 1, '', 1),
(2, 'ROV', 'Mobile', '0002', 0, '', 0),
(3, 'PUBG', 'PC', '0003', 0, '', 1),
(4, 'Honkai impact', 'PC', '0004', 1, '', 0);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int(50) UNSIGNED NOT NULL,
  `user_id` int(50) UNSIGNED NOT NULL,
  `package_id` int(50) UNSIGNED NOT NULL,
  `player_uid` varchar(100) NOT NULL,
  `server_code` varchar(100) NOT NULL,
  `game_name_snapshot` varchar(100) NOT NULL,
  `package_name_snapshot` varchar(100) NOT NULL,
  `original_price` decimal(10,2) NOT NULL,
  `discount_amount` decimal(10,2) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `status` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL,
  `coupon_id` int(50) UNSIGNED DEFAULT NULL,
  `user_coupon_id` int(50) UNSIGNED DEFAULT NULL,
  `coupon_code_snapshot` varchar(50) DEFAULT NULL,
  `spent_points` int(11) NOT NULL DEFAULT 0,
  `coupon_discount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_amount` decimal(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`order_id`, `user_id`, `package_id`, `player_uid`, `server_code`, `game_name_snapshot`, `package_name_snapshot`, `original_price`, `discount_amount`, `total_amount`, `status`, `created_at`, `completed_at`, `coupon_id`, `user_coupon_id`, `coupon_code_snapshot`, `spent_points`, `coupon_discount`, `fee_amount`) VALUES
(1, 1, 1, '123456789', 'Asia', 'PUBG', '100 UC', 35.00, 0.00, 35.00, 'Completed', '2026-11-11 21:34:47', '2026-11-12 02:39:03', NULL, NULL, NULL, 0, 0.00, 0.00),
(2, 3, 4, '123456789', 'Asia', 'PUBG', '1000 UC', 560.00, 0.00, 560.00, 'Completed', '2026-11-12 03:50:44', '2026-11-12 03:51:39', NULL, NULL, NULL, 0, 0.00, 0.00),
(3, 3, 1, '123456789', '', 'PUBG', '400 UC', 200.00, 0.00, 200.00, 'Completed', '2026-11-14 14:55:22', NULL, NULL, NULL, NULL, 0, 0.00, 0.00),
(4, 3, 1, '123456789', '', 'PUBG', '400 UC', 200.00, 0.00, 200.00, 'Pending', '2026-11-14 14:56:07', NULL, NULL, NULL, NULL, 0, 0.00, 0.00),
(5, 3, 1, '123456789', '', 'PUBG', '400 UC', 200.00, 0.00, 200.00, 'Cancelled', '2026-11-14 14:56:30', NULL, NULL, NULL, NULL, 0, 0.00, 0.00),
(6, 3, 1, '123456789', 'Asia', 'PUBG', '100 UC', 35.00, 10.00, 25.00, 'Pending', '2026-11-15 19:29:57', NULL, 1, 1, 'WELCOME10', 0, 10.00, 0.00),
(7, 3, 1, '987654321', '', 'PUBG', '100 UC', 35.00, 0.00, 35.00, 'Pending', '2026-11-15 19:31:08', NULL, NULL, NULL, NULL, 0, 0.00, 0.00),
(8, 4, 4, '123456789', '', 'PUBG', '500 UC', 200.00, 0.00, 200.00, 'Pending', '2026-11-15 21:20:08', NULL, NULL, NULL, NULL, 0, 0.00, 0.00),
(9, 3, 4, '987654321', '', 'PUBG', '500 UC', 200.00, 2.00, 198.00, 'Pending', '2026-11-15 21:21:10', NULL, NULL, NULL, NULL, 20, 0.00, 0.00),
(10, 3, 4, '123456789', '', 'PUBG', '500 UC', 200.00, 42.00, 158.00, 'Pending', '2026-11-15 21:21:53', NULL, 2, 2, 'SAVE20P', 20, 40.00, 0.00),
(11, 3, 4, '123456789', '', 'PUBG', '500 UC', 200.00, 42.00, 158.00, 'Cancelled', '2026-11-15 21:46:02', NULL, 2, 2, 'SAVE20P', 20, 40.00, 0.00),
(12, 3, 4, '987654321', '', 'PUBG', '500 UC', 200.00, 0.00, 200.00, 'Completed', '2026-11-15 21:51:49', NULL, NULL, NULL, NULL, 0, 0.00, 0.00),
(13, 4, 5, '123456789', '', 'PUBG', '1000 UC', 400.00, 0.00, 400.00, 'Cancelled', '2026-11-17 01:55:32', NULL, NULL, NULL, NULL, 0, 0.00, 0.00),
(14, 3, 5, '123456789', '', 'PUBG', '1000 UC', 400.00, 0.00, 400.00, 'Completed', '2026-11-17 02:10:40', '2026-11-17 03:37:04', NULL, NULL, NULL, 0, 0.00, 0.00),
(15, 3, 5, '123456789', '', 'PUBG', '1000 UC', 400.00, 15.00, 385.00, 'Completed', '2026-11-17 16:46:13', '2026-11-17 16:48:22', NULL, NULL, NULL, 150, 0.00, 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `package_id` int(50) UNSIGNED NOT NULL,
  `game_id` int(50) UNSIGNED NOT NULL,
  `package_name` varchar(100) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `reward_points` int(50) NOT NULL,
  `is_active` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `packages`
--

INSERT INTO `packages` (`package_id`, `game_id`, `package_name`, `price`, `reward_points`, `is_active`) VALUES
(1, 3, '100 UC', 35.00, 6, 1),
(2, 3, '200 UC', 70.00, 14, 1),
(3, 3, '300 UC', 100.00, 20, 1),
(4, 3, '500 UC', 200.00, 40, 1),
(5, 3, '1000 UC', 400.00, 80, 1);

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `payment_id` int(50) UNSIGNED NOT NULL,
  `order_id` int(50) UNSIGNED NOT NULL,
  `transaction_ref` varchar(100) NOT NULL,
  `method` varchar(100) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `status` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`payment_id`, `order_id`, `transaction_ref`, `method`, `amount`, `status`, `created_at`, `paid_at`) VALUES
(1, 1, 'PAY1794407760014', 'PromptPay', 35.00, 'Paid', '2026-11-11 21:36:00', '2026-11-12 02:39:03'),
(2, 2, 'PAY6516861681651', 'PromptPay', 560.00, 'Paid', '2026-11-12 03:50:44', '2026-11-12 03:51:39'),
(3, 4, 'TXN-TEST-001', 'PromptPay', 200.00, 'Paid', '2026-11-14 15:37:28', '2026-11-14 15:52:07'),
(4, 12, 'TEST_PAYMENT_001', 'PromptPay', 200.00, 'Paid', '2026-11-15 21:52:53', '2026-11-15 21:53:41'),
(5, 14, 'adad-14168719711641441', 'PromptPay', 400.00, 'Paid', '2026-11-17 02:11:41', '2026-11-17 03:36:54'),
(6, 15, 'Pay-sedofluighsdf55454', 'PromtPay', 385.00, 'Paid', '2026-11-17 16:46:56', '2026-11-17 16:48:05');

-- --------------------------------------------------------

--
-- Table structure for table `point_transactions`
--

CREATE TABLE `point_transactions` (
  `point_transaction_id` int(50) UNSIGNED NOT NULL,
  `user_id` int(50) UNSIGNED NOT NULL,
  `order_id` int(50) UNSIGNED DEFAULT NULL,
  `event_key` varchar(100) NOT NULL,
  `type` varchar(100) NOT NULL,
  `points_delta` int(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `point_transactions`
--

INSERT INTO `point_transactions` (`point_transaction_id`, `user_id`, `order_id`, `event_key`, `type`, `points_delta`, `created_at`) VALUES
(1, 1, 1, 'ORDER_1', 'Earn', 3, '2026-11-12 02:39:03'),
(2, 3, 2, 'ORDER_2', 'Earn', 56, '2026-11-12 03:51:39'),
(3, 3, NULL, 'MANUAL_BONUS_001', 'Earn', 20, '2026-11-15 16:24:29'),
(4, 3, NULL, 'MANUAL_SPEND_001', 'Spend', -5, '2026-11-15 16:25:27'),
(5, 3, 9, 'ORDER_9_SPEND', 'Spend', -20, '2026-11-15 21:21:10'),
(6, 3, 10, 'ORDER_10_SPEND', 'Spend', -20, '2026-11-15 21:21:53'),
(7, 3, 11, 'ORDER_11_SPEND', 'Spend', -20, '2026-11-15 21:46:02'),
(8, 3, 11, 'ORDER_11_REFUND', 'Earn', 20, '2026-11-15 21:50:14'),
(9, 3, 12, 'ORDER_12', 'Earn', 40, '2026-11-15 21:53:41'),
(10, 6, NULL, 'ADMIN_6_1794827797497000', 'Earn', 100, '2026-11-16 18:16:37'),
(13, 3, 14, 'ORDER_14', 'Earn', 80, '2026-11-17 03:36:54'),
(14, 3, 15, 'ORDER_15_SPEND', 'Spend', -150, '2026-11-17 16:46:13'),
(15, 3, 15, 'ORDER_15', 'Earn', 80, '2026-11-17 16:48:05');

-- --------------------------------------------------------

--
-- Table structure for table `receipts`
--

CREATE TABLE `receipts` (
  `receipt_id` int(50) UNSIGNED NOT NULL,
  `order_id` int(50) UNSIGNED NOT NULL,
  `receipt_number` varchar(100) NOT NULL,
  `issued_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `receipts`
--

INSERT INTO `receipts` (`receipt_id`, `order_id`, `receipt_number`, `issued_at`) VALUES
(1, 1, 'RCP_1', '2026-11-12 02:39:03'),
(2, 2, 'RCP_2', '2026-11-12 03:51:39'),
(3, 12, 'RCP_12', '2026-11-15 22:00:15'),
(4, 4, 'RCP_4', '2026-11-17 13:45:02'),
(5, 14, 'RCP_14', '2026-11-17 13:45:02'),
(7, 15, 'RCP_15', '2026-11-17 16:48:05');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(50) UNSIGNED NOT NULL,
  `username` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `display_name` varchar(100) NOT NULL,
  `role` enum('admin','user') NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password_hash`, `email`, `display_name`, `role`, `is_active`, `created_at`) VALUES
(1, 'Natthawat', '$argon2id$v=19$m=19456,t=2,p=1$kqt84cevMLWfP2FPwTwmhA$H1f3I3R1wl/ASra/6uGcYGcnFC6m6G64NFmOP6wSsxY', '6731501035@lamduan.mfu.ac.th', 'Test admin', 'admin', 1, '2026-11-10 22:59:11'),
(2, 'Chalisa', '$argon2id$v=19$m=19456,t=2,p=1$cBog72HpdpbrkjNj/ohTpA$glxvO0ioDpUiC/WiZBo0T9U3flx5w1mqDxIilPOWr3w', '6731901022@lamduan.mfu.ac.th', 'Film', 'user', 1, '2026-11-10 23:17:32'),
(3, 'Napat', '$argon2id$v=19$m=19456,t=2,p=1$sDf/owKJ0qOXsRrsKzNe9g$rNYMj1qMM/b1Z1WhIiQjRuTwWuyLXZ4nGVXsymhY/qo', '6731501033@lamduan.mfu.ac.th', 'Mocha', 'user', 1, '2026-11-10 23:20:03'),
(4, 'Boom', '$argon2id$v=19$m=19456,t=2,p=1$K+Hr6yjXmR5QKgVNQqkMqA$Xv0nRVTGAel2j8qRUVejX8+blnas4i3zVlbosanl7CM', 'Boom@gmail.com', 'Test admin', 'admin', 1, '2026-11-14 09:48:56'),
(5, 'Bas', '$argon2id$v=19$m=19456,t=2,p=1$56k0f4NqxDy04iWc3WpC5A$SEvsB0cJGzfisCZoO+jDTieBebeqi/YzIAMQU5+SqwY', 'Bas@gmail.com', 'Test admin', 'admin', 0, '2026-11-14 09:56:41'),
(6, 'Fone', '$argon2id$v=19$m=19456,t=2,p=1$dfu/YWtERSkuF6HjGl0VaA$d16VApybrUaFMsAnYA1Rm66S/4qtAVQuo8QutcgJvWQ', 'fone@gmail.com', 'Tester user', 'user', 1, '2026-11-16 00:34:20');

-- --------------------------------------------------------

--
-- Table structure for table `user_coupons`
--

CREATE TABLE `user_coupons` (
  `user_coupon_id` int(50) UNSIGNED NOT NULL,
  `user_id` int(50) UNSIGNED NOT NULL,
  `coupon_id` int(50) UNSIGNED NOT NULL,
  `used_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_coupons`
--

INSERT INTO `user_coupons` (`user_coupon_id`, `user_id`, `coupon_id`, `used_at`) VALUES
(1, 3, 1, '2026-11-15 19:29:57'),
(2, 3, 2, '2026-11-15 21:21:53'),
(3, 2, 1, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `coupons`
--
ALTER TABLE `coupons`
  ADD PRIMARY KEY (`coupon_id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `games`
--
ALTER TABLE `games`
  ADD PRIMARY KEY (`game_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `package_id` (`package_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `coupon_id` (`coupon_id`),
  ADD KEY `idx_orders_user_coupon_id` (`user_coupon_id`);

--
-- Indexes for table `packages`
--
ALTER TABLE `packages`
  ADD PRIMARY KEY (`package_id`),
  ADD KEY `game_id` (`game_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD UNIQUE KEY `transaction_ref` (`transaction_ref`),
  ADD UNIQUE KEY `uq_payments_order_id` (`order_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `point_transactions`
--
ALTER TABLE `point_transactions`
  ADD PRIMARY KEY (`point_transaction_id`),
  ADD UNIQUE KEY `event_key` (`event_key`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `receipts`
--
ALTER TABLE `receipts`
  ADD PRIMARY KEY (`receipt_id`),
  ADD UNIQUE KEY `order_id` (`order_id`),
  ADD UNIQUE KEY `receipt_number` (`receipt_number`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `user_coupons`
--
ALTER TABLE `user_coupons`
  ADD PRIMARY KEY (`user_coupon_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `coupon_id` (`coupon_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `coupons`
--
ALTER TABLE `coupons`
  MODIFY `coupon_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `games`
--
ALTER TABLE `games`
  MODIFY `game_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `package_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `point_transactions`
--
ALTER TABLE `point_transactions`
  MODIFY `point_transaction_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `receipts`
--
ALTER TABLE `receipts`
  MODIFY `receipt_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_coupons`
--
ALTER TABLE `user_coupons`
  MODIFY `user_coupon_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_orders_user_coupon_assignment` FOREIGN KEY (`user_coupon_id`) REFERENCES `user_coupons` (`user_coupon_id`),
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`package_id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`coupon_id`);

--
-- Constraints for table `packages`
--
ALTER TABLE `packages`
  ADD CONSTRAINT `packages_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `games` (`game_id`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`);

--
-- Constraints for table `point_transactions`
--
ALTER TABLE `point_transactions`
  ADD CONSTRAINT `point_transactions_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  ADD CONSTRAINT `point_transactions_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `receipts`
--
ALTER TABLE `receipts`
  ADD CONSTRAINT `receipts_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`);

--
-- Constraints for table `user_coupons`
--
ALTER TABLE `user_coupons`
  ADD CONSTRAINT `user_coupons_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `user_coupons_ibfk_2` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`coupon_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
