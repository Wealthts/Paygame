-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 11, 2026 at 03:54 PM
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
-- Includes migrations/001_coupons.sql (user_coupons table + coupon columns on orders).
-- Importing this file REPLACES the existing tables in `paygame`.
--

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `user_coupons`, `receipts`, `point_transactions`, `payments`, `orders`, `packages`, `games`, `users`;
SET FOREIGN_KEY_CHECKS = 1;

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
  `is_active` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `games`
--

INSERT INTO `games` (`game_id`, `game_name`, `category`, `uid_pattern`, `requires_server`, `is_active`) VALUES
(1, 'Genshin impact', 'Openworld', '0001', 1, 1),
(2, 'ROV', 'MOBA', '0002', 0, 1),
(3, 'PUBG', 'Battle Royal', '003', 1, 1);

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
  `coupon_id` int(10) UNSIGNED DEFAULT NULL,
  `spent_points` int(11) NOT NULL DEFAULT 0,
  `coupon_discount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_amount` decimal(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`order_id`, `user_id`, `package_id`, `player_uid`, `server_code`, `game_name_snapshot`, `package_name_snapshot`, `original_price`, `discount_amount`, `total_amount`, `status`, `created_at`, `completed_at`) VALUES
(1, 1, 1, '123456789', 'Asia', 'PUBG', '100', 35.00, 0.00, 35.00, 'Pending', '2026-11-11 21:34:47', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `package_id` int(50) UNSIGNED NOT NULL,
  `game_id` int(50) UNSIGNED NOT NULL,
  `package_name` varchar(100) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `is_active` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `packages`
--

INSERT INTO `packages` (`package_id`, `game_id`, `package_name`, `price`, `is_active`) VALUES
(1, 3, '100', 35.00, 1),
(2, 3, '200', 70.00, 1),
(3, 3, '300', 105.00, 1),
(4, 3, '400', 140.00, 1);

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
(1, 1, 'PAY1794407760014', 'PromptPay', 35.00, 'Pending', '2026-11-11 21:36:00', NULL);

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

-- --------------------------------------------------------

--
-- Table structure for table `user_coupons`
--

CREATE TABLE `user_coupons` (
  `coupon_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(50) UNSIGNED NOT NULL,
  `reward_id` varchar(20) NOT NULL,
  `name` varchar(200) NOT NULL,
  `amount_satang` int(11) NOT NULL DEFAULT 0,
  `percent` int(11) NOT NULL DEFAULT 0,
  `minimum_satang` int(11) NOT NULL DEFAULT 0,
  `status` enum('Available','Reserved','Used') NOT NULL DEFAULT 'Available',
  `order_id` int(50) UNSIGNED DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(1, 'Natthawat', '$argon2id$v=19$m=19456,t=2,p=1$kqt84cevMLWfP2FPwTwmhA$H1f3I3R1wl/ASra/6uGcYGcnFC6m6G64NFmOP6wSsxY', '6731501035@lamduan.mfu.ac.th', 'Test User', 'admin', 1, '2026-11-10 22:59:11'),
(2, 'Chalisa', '$argon2id$v=19$m=19456,t=2,p=1$cBog72HpdpbrkjNj/ohTpA$glxvO0ioDpUiC/WiZBo0T9U3flx5w1mqDxIilPOWr3w', '6731901022@lamduan.mfu.ac.th', 'Film', 'user', 1, '2026-11-10 23:17:32'),
(3, 'Napat', '$argon2id$v=19$m=19456,t=2,p=1$sDf/owKJ0qOXsRrsKzNe9g$rNYMj1qMM/b1Z1WhIiQjRuTwWuyLXZ4nGVXsymhY/qo', '6731501032@lamduan.mfu.ac.th', 'Mocha', 'user', 1, '2026-11-10 23:20:03');

--
-- Indexes for dumped tables
--

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
  ADD KEY `user_id` (`user_id`);

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
-- Indexes for table `user_coupons`
--
ALTER TABLE `user_coupons`
  ADD PRIMARY KEY (`coupon_id`),
  ADD KEY `user_id` (`user_id`,`status`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `games`
--
ALTER TABLE `games`
  MODIFY `game_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `package_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `point_transactions`
--
ALTER TABLE `point_transactions`
  MODIFY `point_transaction_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `receipts`
--
ALTER TABLE `receipts`
  MODIFY `receipt_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_coupons`
--
ALTER TABLE `user_coupons`
  MODIFY `coupon_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`package_id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

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
  ADD CONSTRAINT `user_coupons_ibfk_2` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
