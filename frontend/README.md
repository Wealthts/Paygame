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
