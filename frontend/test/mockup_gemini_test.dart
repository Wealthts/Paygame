import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/paygame_controller.dart';
import 'package:frontend/models/paygame_models.dart';
import 'package:frontend/services/admin_report_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/order_service.dart';
import 'package:frontend/services/payment_service.dart';
import 'package:frontend/views/user/package_view.dart';
import 'package:frontend/views/user/receipt_view.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late http.Client originalClient;
  late ApiTokenStore originalTokenStore;
  late MemoryTokenStore tokenStore;
  late Map<String, String> secureStorage;
  late bool isApproved;
  late bool invalidLogin;

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // In-memory mock for FlutterSecureStorage (used by PaygameController)
    secureStorage = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
      final args = call.arguments as Map?;
      final key = args?['key'] as String?;
      switch (call.method) {
        case 'write':
          if (key != null) secureStorage[key] = args?['value'] as String? ?? '';
          return null;
        case 'read':
          return key != null ? secureStorage[key] : null;
        case 'delete':
          if (key != null) secureStorage.remove(key);
          return null;
        case 'deleteAll':
          secureStorage.clear();
          return null;
        default:
          return null;
      }
    });

    isApproved = false;
    invalidLogin = false;
    originalClient = ApiService.client;
    originalTokenStore = ApiService.tokenStore;
    tokenStore = MemoryTokenStore();
    ApiService.tokenStore = tokenStore;

    // Simple mockup backend router
    ApiService.client = MockClient((req) async {
      switch ('${req.method} ${req.url.path}') {
        // --- Auth ---
        case 'POST /api/register':
          return jsonOk({'message': 'Register successful'}, status: 201);

        case 'POST /api/login':
          if (invalidLogin) return jsonOk({'user': {}});
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          final isAdmin = body['username'] == 'admin';
          return jsonOk({
            'token': isAdmin ? 'admin-token' : 'player-token',
            'user': {
              'id': isAdmin ? 1 : 7,
              'username': body['username'],
              'display_name': isAdmin ? 'Admin' : 'Player One',
              'role': isAdmin ? 'admin' : 'user',
            },
          });

        case 'POST /api/logout':
          return jsonOk({'message': 'Logged out'});

        // --- Games & Packages ---
        case 'GET /api/games':
          return jsonOk([mockGameJson]);

        // --- Wallet, Coupons & Rewards ---
        case 'GET /api/coupons':
          return jsonOk([mockCouponJson]);

        case 'GET /api/points/balance':
          return jsonOk({'total_points': isApproved ? 385 : 350});

        case 'GET /api/points/history':
          return jsonOk(mockUserPointHistoryJson);

        case 'POST /api/coupons/claim':
          return jsonOk({'message': 'Coupon claimed'}, status: 201);

        case 'POST /api/coupons/redeem':
          return jsonOk({'user_coupon_id': 8}, status: 201);

        // --- Orders & Payments ---
        case 'POST /api/checkout':
          return jsonOk({
            'order_id': 42,
            'total_amount': 35.0,
            'discount_amount': 0.0,
            'fee_amount': 0.0,
            'points_balance': 350,
            'spent_points': 0,
            'coupon_id': null,
          }, status: 201);

        case 'GET /api/orders':
          return jsonOk([mockOrderHistoryJson]);

        case 'POST /api/payments':
          return jsonOk({
            'payment': {'payment_id': 3, 'status': 'Pending'},
          }, status: 201);

        case 'GET /api/payments':
          return jsonOk([mockPaymentHistoryJson]);

        case 'PUT /api/payments/42/status':
          isApproved = true;
          return jsonOk({'payment_id': 42, 'status': 'Paid'});

        // --- Admin Receipts & History ---
        case 'GET /api/admin/receipts':
          return jsonOk(isApproved ? [mockReceiptJson] : []);

        case 'GET /api/admin/points/balances':
          return jsonOk([
            {
              'user_id': 7,
              'username': 'player',
              'display_name': 'Player One',
              'balance': isApproved ? 385 : 350,
              'earned_total': isApproved ? 35 : 0,
            },
          ]);

        case 'GET /api/admin/points/history':
          return jsonOk(isApproved ? [mockAdminPointHistoryJson] : []);

        default:
          return jsonOk({'message': 'Not mocked'}, status: 404);
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
    ApiService.client.close();
    ApiService.client = originalClient;
    ApiService.tokenStore = originalTokenStore;
  });

  // ===========================================================================
  // 1. REGISTER, LOGIN, AUTO-LOGIN & LOGOUT
  // ===========================================================================
  group('Auth (Register, Login, Auto-Login, Logout)', () {
    test('registers a new user account', () async {
      await AuthService.register(
        username: 'player',
        displayName: 'Player One',
        email: 'player@example.com',
        password: 'secret123',
      );
    });

    test('login saves session, loads wallet, and logout clears all state', () async {
      final controller = PaygameController();
      addTearDown(controller.dispose);

      await controller.login(' player ', 'secret123');

      expect(controller.authToken, 'player-token');
      expect(controller.currentUserId, 7);
      expect(controller.currentUsername, 'player');
      expect(controller.currentDisplayName, 'Player One');
      expect(controller.currentRole, 'user');
      expect(controller.userPointsBalance, 350);
      expect(controller.coupons.single.name, 'WELCOME10');
      expect(secureStorage['user_id'], '7');

      await controller.logout();

      expect(controller.authToken, isNull);
      expect(controller.currentUserId, isNull);
      expect(controller.currentUsername, isEmpty);
      expect(controller.userPointsBalance, 0);
      expect(controller.coupons, isEmpty);
      expect(controller.pointHistory, isEmpty);
      expect(secureStorage, isEmpty);
      expect(tokenStore.token, isNull);
    });

    test('tryAutoLogin restores saved session and wallet', () async {
      tokenStore.token = 'player-token';
      secureStorage.addAll({
        'user_id': '7',
        'username': 'player',
        'display_name': 'Player One',
        'role': 'user',
      });

      final controller = PaygameController();
      addTearDown(controller.dispose);

      await controller.tryAutoLogin();

      expect(controller.authToken, 'player-token');
      expect(controller.currentUserId, 7);
      expect(controller.currentUsername, 'player');
      expect(controller.userPointsBalance, 350);
    });

    test('failed login throws exception and clears token', () async {
      invalidLogin = true;

      await expectLater(
        AuthService.login('player', 'secret123'),
        throwsA(isA<Exception>()),
      );
      expect(tokenStore.token, isNull);
    });
  });

  // ===========================================================================
  // 2. GAMES & PACKAGES
  // ===========================================================================
  group('Games & Packages', () {
    test('loads active game catalog and parses package models', () async {
      final controller = PaygameController();
      addTearDown(controller.dispose);

      await controller.loadCatalog();

      expect(controller.games, hasLength(1));
      final game = controller.games.single;
      expect(game.gameId, '1');
      expect(game.gameName, 'RoV');
      expect(game.shortName, 'RoV');
      expect(game.unit, 'Diamonds');
      expect(game.isActive, isTrue);

      final pkg = PackageModel.fromJson(mockPackageJson);
      expect(pkg.packageId, 5);
      expect(pkg.gameId, '1');
      expect(pkg.packageName, '100 Diamonds');
      expect(pkg.price, 35.0);
      expect(pkg.isActive, isTrue);
    });
  });

  // ===========================================================================
  // 3. REWARDS, COUPONS & DISCOUNTS
  // ===========================================================================
  group('Rewards, Coupons & Checkout Discounts', () {
    test('calculates coupon and point discounts accurately', () {
      const coupon = CouponModel(
        id: '7',
        name: 'WELCOME10',
        amountSatang: 1000, // ฿10 discount
      );
      final discount = CheckoutDiscount(
        priceSatang: 3500, // ฿35
        points: 100, // worth ฿10 (1000 satang)
        usePoints: true,
        coupon: coupon,
      );

      expect(discount.couponSatang, 1000);
      expect(discount.spentPoints, 100);
      expect(discount.coinSatang, 1000);
      expect(discount.totalSatang, 2000);
    });

    test('claims coupon and redeems reward using points', () async {
      final controller = PaygameController();
      addTearDown(controller.dispose);

      await controller.login('player', 'secret123');
      expect(controller.userPointsBalance, 350);

      await controller.claimCoupon(' SAVE10 ');
      expect(controller.walletError, isNull);

      const reward = RewardItem(
        id: 'r1',
        tag: '฿20',
        name: '20 baht discount',
        cost: 200,
      );
      expect(await controller.redeemReward(reward), isTrue);
    });
  });

  // ===========================================================================
  // 4. ORDERS, PAYMENTS & RECEIPTS
  // ===========================================================================
  group('Orders, Payments & Receipts', () {
    test('creates order, submits payment, and admin approves status', () async {
      tokenStore.token = 'admin-token';

      final checkout = await OrderService.create(
        packageId: 5,
        playerUid: '1234567890',
        method: 'qr',
      );
      expect(checkout['order_id'], 42);

      final payment = await PaymentService.create(orderId: 42, method: 'qr');
      expect(payment['payment']['status'], 'Pending');

      await PaymentService.updateStatus(42, 'Paid');
      expect(isApproved, isTrue);
    });

    testWidgets(
      'checkout stays pending until admin approval, then shows paid receipt',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = PaygameController();
        addTearDown(controller.dispose);
        await controller.login('player', 'secret123');

        PaygameOrder? submittedOrder;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => PaygamePayment(
                          game: const PaygameGame('RoV', 'Diamonds', []),
                          pack: const PaygamePack(100, 35, packageId: 5),
                          uid: '1234567890',
                          onPaymentCompleted: (order) => submittedOrder = order,
                        ),
                      ),
                    ),
                    child: const Text('Open checkout'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open checkout'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ยืนยันชำระเงิน ฿35'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ส่งคำขอชำระเงิน'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('ส่งคำขอชำระเงินแล้ว'), findsOneWidget);

        // Admin approves payment
        await AuthService.login('admin', 'secret123');
        await PaymentService.updateStatus(42, 'Paid');

        await tester.tap(find.text('ตกลง'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(submittedOrder?.id, 'GP-42');
        expect(submittedOrder?.success, isFalse);

        // Render final paid receipt
        await tester.pumpWidget(
          MaterialApp(home: ReceiptScreen(order: mockReceiptOrder())),
        );

        expect(find.text('เติมเกมสำเร็จ!'), findsOneWidget);
        expect(find.text('ได้รับ +35 แต้ม'), findsOneWidget);
        expect(find.text('แต้มคงเหลือ 385 แต้ม'), findsOneWidget);
        expect(find.text('GP-42'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('receipt formats Thai currency, numbers, and Buddhist date', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final screen = ReceiptScreen(order: mockReceiptOrder());
      expect(screen.number(123456), '123,456');
      expect(screen.money(3500), '฿35.00');
      expect(
        screen.dateText(DateTime(2026, 1, 2, 3, 4)),
        '2 ม.ค. 2569 · 03:04',
      );

      await tester.pumpWidget(MaterialApp(home: screen));
      expect(find.text('ยอดชำระ'), findsOneWidget);
      expect(find.text('฿35.00'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  // ===========================================================================
  // 5. SEE ALL HISTORY (USER & ADMIN)
  // ===========================================================================
  group('All History (Orders, Payments, Points & Admin Reports)', () {
    test('views user point history and records completed order points', () async {
      final controller = PaygameController();
      addTearDown(controller.dispose);

      await controller.login('player', 'secret123');

      // Initial point history loaded from /api/points/history
      expect(controller.pointHistory, hasLength(2));
      expect(controller.pointHistory[0].amount, '+350');
      expect(controller.pointHistory[0].isEarned, isTrue);
      expect(controller.pointHistory[1].amount, '-100');
      expect(controller.pointHistory[1].isEarned, isFalse);

      // Pending order is ignored; completed order appends earned & spent points
      controller.addOrder(mockOrder(status: 'Pending'));
      expect(controller.latestOrder, isNull);

      controller.addOrder(mockOrder(status: 'completed'));
      expect(controller.latestOrder?.orderId, 'GP-42');
      expect(controller.userPointsBalance, 385);
      expect(controller.pointHistory, hasLength(4));
      expect(controller.pointHistory[0].amount, '+35');
      expect(controller.pointHistory[1].amount, '−100');
    });

    test('views all order history, payment history, and admin reports', () async {
      tokenStore.token = 'admin-token';
      await PaymentService.updateStatus(42, 'Paid');

      // 1. All user orders
      final orders = await OrderService.list();
      expect(orders, hasLength(1));
      expect(orders.single['order_id'], 42);
      expect(orders.single['status'], 'Paid');

      // 2. All admin payments
      final payments = await PaymentService.listForAdmin();
      expect(payments, hasLength(1));
      expect(payments.single['payment_id'], 3);
      expect(payments.single['status'], 'Paid');

      // 3. All admin receipts
      final receipts = await AdminReportService.fetchReceipts();
      expect(receipts.single.receiptNumber, 'RCP-42');
      expect(receipts.single.paymentStatus, 'Paid');

      // 4. All user point balances
      final balances = await AdminReportService.fetchPointBalances();
      expect(balances.single.balance, 385);
      expect(balances.single.earnedTotal, 35);

      // 5. All point transaction history
      final history = await AdminReportService.fetchPointHistory();
      expect(history.single.type, 'Earn');
      expect(history.single.pointsDelta, 35);
      expect(history.single.note, 'Top-up RoV 100 Diamonds');
    });
  });
}

// =============================================================================
// MOCKUP DATA & HELPERS
// =============================================================================

const mockGameJson = {
  'game_id': 1,
  'game_name': 'RoV',
  'short_name': 'RoV',
  'category': 'MOBA',
  'unit': 'Diamonds',
  'uid_pattern': r'^\d{10}$',
  'requires_server': 0,
  'is_active': 1,
};

const mockPackageJson = {
  'package_id': 5,
  'game_id': 1,
  'package_name': '100 Diamonds',
  'price': 35.0,
  'is_active': 1,
};

const mockCouponJson = {
  'coupon_id': 7,
  'name': 'WELCOME10',
  'amount_satang': 1000,
  'percent': 0,
  'minimum_satang': 0,
  'max_discount_satang': null,
  'status': 'Available',
};

const mockUserPointHistoryJson = [
  {
    'type': 'Earn',
    'points_delta': 350,
    'created_at': '2026-01-02T03:04:00.000Z',
  },
  {
    'type': 'Redeem',
    'points_delta': -100,
    'created_at': '2026-01-03T05:10:00.000Z',
  },
];

const mockOrderHistoryJson = {
  'order_id': 42,
  'game_name': 'RoV',
  'package_name': '100 Diamonds',
  'player_uid': '1234567890',
  'total_amount': 35.0,
  'status': 'Paid',
  'created_at': '2026-01-02T03:04:00.000Z',
};

const mockPaymentHistoryJson = {
  'payment_id': 3,
  'order_id': 42,
  'method': 'qr',
  'amount': 35.0,
  'status': 'Paid',
  'created_at': '2026-01-02T03:04:00.000Z',
};

const mockAdminPointHistoryJson = {
  'point_transaction_id': 10,
  'user_id': 7,
  'order_id': 42,
  'type': 'Earn',
  'points_delta': 35,
  'created_at': '2026-01-02T03:04:00.000Z',
  'username': 'player',
  'game_name_snapshot': 'RoV',
  'package_name_snapshot': '100 Diamonds',
};

const mockReceiptJson = {
  'receipt_id': 11,
  'receipt_number': 'RCP-42',
  'issued_at': '2026-01-02T03:04:00.000Z',
  'order_id': 42,
  'username': 'player',
  'display_name': 'Player One',
  'game_name_snapshot': 'RoV',
  'package_name_snapshot': '100 Diamonds',
  'player_uid': '1234567890',
  'server_code': '',
  'method': 'qr',
  'payment_status': 'Paid',
  'original_price': '35.00',
  'discount_amount': '0.00',
  'fee_amount': '0.00',
  'total_amount': '35.00',
  'spent_points': 0,
  'coupon_code_snapshot': null,
};

OrderModel mockOrder({required String status}) => OrderModel(
  orderId: 'GP-42',
  gameName: 'RoV',
  packageName: '100 Diamonds',
  playerUid: '1234567890',
  originalPrice: 35,
  discountAmount: 0,
  totalAmount: 35,
  paymentMethod: 'QR พร้อมเพย์',
  status: status,
  earnedPoints: 35,
  pointsBalance: 385,
  createdAt: DateTime(2026, 1, 2, 3, 4),
  spentPoints: 100,
  couponId: '7',
);

PaygameOrder mockReceiptOrder() => PaygameOrder(
  id: 'GP-42',
  game: const PaygameGame('RoV', 'Diamonds', []),
  pack: const PaygamePack(100, 35, packageId: 5),
  uid: '1234567890',
  server: null,
  method: PaygameMethod.qr,
  priceSatang: 3500,
  discountSatang: 0,
  feeSatang: 0,
  success: true,
  earnedPoints: 35,
  pointsBalance: 385,
  createdAt: DateTime(2026, 1, 2, 3, 4),
  spentPoints: 100,
  couponId: '7',
);

http.Response jsonOk(Object? body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class MemoryTokenStore implements ApiTokenStore {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}