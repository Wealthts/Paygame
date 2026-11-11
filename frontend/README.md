# Paygame frontend

Flutter client for Paygame.

## Source layout

```text
lib/
├── main.dart
├── theme/
│   ├── app_colors.dart
│   └── app_theme.dart
├── models/
│   └── paygame_models.dart
├── controllers/
│   └── paygame_controller.dart
└── views/
    ├── login_view.dart
    ├── user/
    │   ├── home_view.dart
    │   ├── game_detail_view.dart
    │   ├── payment_view.dart
    │   ├── history_view.dart
    │   ├── receipt_view.dart
    │   └── widgets/
    │       └── dashed_divider.dart
    └── admin/
        ├── admin_dashboard_view.dart
        ├── admin_users_view.dart
        ├── admin_games_view.dart
        ├── admin_packages_view.dart
        ├── admin_orders_view.dart
        ├── admin_payments_view.dart
        ├── admin_points_view.dart
        └── admin_receipts_view.dart
```

The `payment_view.dart` file is a Dart part of `game_detail_view.dart` because
the payment flow shares its library and state. Admin view files are scaffolds;
their management features are not implemented yet.

## Run

From this directory, run `flutter run`.

## Coupons and coins

Apply `backend/migrations/001_coupons.sql` to the existing database once, then
restart the API. The Coupons tab displays available, reserved and used coupons.
Reward redemption and checkout now use authenticated backend APIs.

One coupon can be selected per order. Its minimum spend uses the package price.
Coins apply after the coupon at 10 coins per baht, up to the remaining price.
Fees and earned coins are based on the discounted price. Submission creates the
order and payment atomically, reserving the coupon and debiting coins. Admin
approval consumes the coupon; rejection restores the coupon and refunds coins.
Refresh the Coupons tab to retrieve the latest balance after admin review.

Validation: `flutter analyze`, `flutter test test/coupons_test.dart`,
`flutter build web`; backend tests: `node --test test/*.test.js`.
