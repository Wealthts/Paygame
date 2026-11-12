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
  late bool isApproved;
  late bool invalidLogin;

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Simple in-memory mock for FlutterSecureStorage
    final secureStorage = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = call.arguments as Map?;
          final key = args?['key'] as String?;
          if (call.method == 'write' && key != null) {
            secureStorage[key] = args?['value'] as String? ?? '';
          } else if (call.method == 'read' && key != null) {
            return secureStorage[key];
          } else if (call.method == 'delete' && key != null) {
            secureStorage.remove(key);
          } else if (call.method == 'deleteAll') {
            secureStorage.clear();
          }
          return null;
        });

    isApproved = false;
    invalidLogin = false;
    originalClient = ApiService.client;
    originalTokenStore = ApiService.tokenStore;
    tokenStore = MemoryTokenStore();
    ApiService.tokenStore = tokenStore;

    // Simple mockup API router
    ApiService.client = MockClient((req) async {
      switch ('${req.method} ${req.url.path}') {
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

        case 'GET /api/games':
        case 'GET /api/orders':
        case 'GET /api/payments':
          return jsonOk([]);

        case 'GET /api/coupons':
          return jsonOk([mockCouponJson]);

        case 'GET /api/points/balance':
          return jsonOk({'total_points': isApproved ? 385 : 350});

        case 'GET /api/points/history':
          return jsonOk([
            {
              'type': 'Earn',
              'points_delta': isApproved ? 35 : 350,
              'created_at': '2026-01-02T03:04:00.000Z',
            },
          ]);

        case 'POST /api/coupons/claim':
          return jsonOk({'message': 'Coupon claimed'}, status: 201);

        case 'POST /api/coupons/redeem':
          return jsonOk({'user_coupon_id': 8}, status: 201);

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

        case 'POST /api/payments':
          return jsonOk({
            'payment': {'payment_id': 3, 'status': 'Pending'},
          }, status: 201);

        case 'PUT /api/payments/42/status':
          isApproved = true;
          return jsonOk({'payment_id': 42, 'status': 'Paid'});

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
          return jsonOk(isApproved ? [mockPointHistoryJson] : []);

        default:
          return jsonOk({'message': 'Not found'}, status: 404);
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

  // 1. AuthService.register
  test('1. register creates a new user account', () async {
    await AuthService.register(
      username: 'player',
      displayName: 'Player One',
      email: 'player@example.com',
      password: 'secret123',
    );
  });

  // 2. PaygameController.login & logout
  test('2. login loads wallet data and logout clears account state', () async {
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
    expect(controller.pointHistory.single.amount, '+350');

    await controller.logout();

    expect(controller.authToken, isNull);
    expect(controller.currentUserId, isNull);
    expect(controller.currentUsername, isEmpty);
    expect(controller.userPointsBalance, 0);
    expect(controller.coupons, isEmpty);
    expect(tokenStore.token, isNull);
  });

  // 3. AuthService.login (invalid response)
  test('3. failed login throws and clears stored token', () async {
    invalidLogin = true;

    await expectLater(
      AuthService.login('player', 'secret123'),
      throwsA(isA<Exception>()),
    );
    expect(tokenStore.token, isNull);
  });

  // 4. PaygameController.refreshWallet, claimCoupon & redeemReward
  test('4. wallet refresh, coupon claim, and reward redemption work', () async {
    final controller = PaygameController();
    addTearDown(controller.dispose);

    controller.authToken = 'player-token';
    controller.currentUserId = 7;
    tokenStore.token = 'player-token';

    await controller.refreshWallet();
    expect(controller.userPointsBalance, 350);
    expect(controller.coupons.single.id, '7');
    expect(controller.walletError, isNull);

    await controller.claimCoupon(' SAVE10 ');

    final reward = RewardItem(
      id: 'r1',
      tag: '฿20',
      name: '20 baht discount',
      cost: 200,
    );
    expect(await controller.redeemReward(reward), isTrue);
  });

  // 5. PaygameController.addOrder
  test('5. pending order is ignored and completed order updates points', () {
    final controller = PaygameController();
    addTearDown(controller.dispose);

    controller.addOrder(mockOrder(status: 'Pending'));
    expect(controller.latestOrder, isNull);

    final completed = mockOrder(status: 'completed');
    controller.addOrder(completed);

    expect(controller.latestOrder, same(completed));
    expect(controller.userPointsBalance, 385);
    expect(controller.pointHistory, hasLength(2));
    expect(controller.pointHistory.first.amount, '+35');
    expect(controller.pointHistory.last.amount, '−100');
  });

  // 6. PaygamePayment + Admin approval + AdminReportService + ReceiptScreen
  testWidgets(
    '6. checkout stays pending until approval, then receipt and points show',
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
      // Use timed pump() instead of pumpAndSettle() to avoid timer/spinner hangs
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('ส่งคำขอชำระเงินแล้ว'), findsOneWidget);

      // Admin approves payment
      await AuthService.login('admin', 'secret123');
      await PaymentService.updateStatus(42, 'Paid');

      final receipts = await AdminReportService.fetchReceipts();
      final balances = await AdminReportService.fetchPointBalances();
      final history = await AdminReportService.fetchPointHistory();

      expect(receipts.single.receiptNumber, 'RCP-42');
      expect(receipts.single.paymentStatus, 'Paid');
      expect(balances.single.balance, 385);
      expect(balances.single.earnedTotal, 35);
      expect(history.single.type, 'Earn');
      expect(history.single.pointsDelta, 35);
      expect(history.single.note, 'Top-up RoV 100 Diamonds');

      await tester.tap(find.text('ตกลง'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(submittedOrder?.id, 'GP-42');
      expect(submittedOrder?.success, isFalse);
      expect(submittedOrder?.earnedPoints, 0);

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

  // 7. OrderService & PaymentService
  test('7. order and payment services serialize and parse mock data', () async {
    tokenStore.token = 'admin-token';

    final checkout = await OrderService.create(
      packageId: 5,
      playerUid: '1234567890',
      method: 'card',
    );
    expect(checkout['order_id'], 42);
    expect(await OrderService.list(), isEmpty);

    final payment = await PaymentService.create(orderId: 42, method: 'qr');
    expect(payment['payment']['status'], 'Pending');
    expect(await PaymentService.listForAdmin(), isEmpty);
    await PaymentService.updateStatus(42, 'Paid');
  });

  // 8. ReceiptScreen formatting & UI
  testWidgets('8. receipt formats and displays amount and points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final screen = ReceiptScreen(order: mockReceiptOrder());
    expect(screen.number(123456), '123,456');
    expect(screen.money(3500), '฿35.00');
    expect(screen.dateText(DateTime(2026, 1, 2, 3, 4)), '2 ม.ค. 2569 · 03:04');

    await tester.pumpWidget(MaterialApp(home: screen));

    expect(find.text('ยอดชำระ'), findsOneWidget);
    expect(find.text('฿35.00'), findsNWidgets(2));
    expect(find.text('ได้รับ +35 แต้ม'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

// --- Mockup Data & Helpers ---

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

const mockCouponJson = {
  'coupon_id': 7,
  'name': 'WELCOME10',
  'amount_satang': 1000,
  'percent': 0,
  'minimum_satang': 0,
  'max_discount_satang': null,
  'status': 'Available',
};

const mockPointHistoryJson = {
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
