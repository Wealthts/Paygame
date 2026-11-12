import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  late FakeBackend backend;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    originalClient = ApiService.client;
    originalTokenStore = ApiService.tokenStore;
    tokenStore = MemoryTokenStore();
    backend = FakeBackend();
    ApiService.client = MockClient(backend.handle);
    ApiService.tokenStore = tokenStore;
  });

  tearDown(() {
    ApiService.client.close();
    ApiService.client = originalClient;
    ApiService.tokenStore = originalTokenStore;
  });

  // fone
  test('registration sends the expected unauthenticated request', () async {
    await AuthService.register(
      username: 'player',
      displayName: 'Player One',
      email: 'player@example.com',
      password: 'secret123',
    );

    final request = backend.lastRequest('POST', '/api/register');
    expect(jsonDecode(request.body), {
      'username': 'player',
      'display_name': 'Player One',
      'email': 'player@example.com',
      'password': 'secret123',
    });
    expect(request.headers.containsKey('authorization'), isFalse);
  });

  // fone
  test('login loads wallet data and logout clears the account state', () async {
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

    final loginRequest = backend.lastRequest('POST', '/api/login');
    expect(jsonDecode(loginRequest.body), {
      'username': 'player',
      'password': 'secret123',
    });
    expect(loginRequest.headers.containsKey('authorization'), isFalse);
    expect(
      backend
          .lastRequest('GET', '/api/points/balance')
          .headers['authorization'],
      'Bearer player-token',
    );

    await controller.logout();

    expect(controller.authToken, isNull);
    expect(controller.currentUserId, isNull);
    expect(controller.currentUsername, isEmpty);
    expect(controller.currentRole, 'user');
    expect(controller.userPointsBalance, 0);
    expect(controller.coupons, isEmpty);
    expect(tokenStore.token, isNull);
  });

  test('failed login removes a token when the response is invalid', () async {
    backend.invalidLoginResponse = true;

    await expectLater(
      AuthService.login('player', 'secret123'),
      throwsA(isA<Exception>()),
    );

    expect(tokenStore.token, isNull);
  });

  test(
    'wallet refresh, coupon claim, and reward redemption use the API',
    () async {
      final controller = PaygameController();
      addTearDown(controller.dispose);
      controller.authToken = 'player-token';
      tokenStore.token = 'player-token';

      await controller.refreshWallet();
      expect(controller.userPointsBalance, 350);
      expect(controller.coupons.single.id, '7');
      expect(controller.walletError, isNull);

      await controller.claimCoupon(' SAVE10 ');
      expect(
        jsonDecode(backend.lastRequest('POST', '/api/coupons/claim').body),
        {'code': 'SAVE10'},
      );

      final reward = RewardItem(
        id: 'r1',
        tag: '฿20',
        name: '20 baht discount',
        cost: 200,
      );
      expect(await controller.redeemReward(reward), isTrue);
      expect(
        jsonDecode(backend.lastRequest('POST', '/api/coupons/redeem').body),
        {'reward_id': 'r1'},
      );
    },
  );

  test(
    'only completed orders are recorded once with earned and spent points',
    () {
      final controller = PaygameController();
      addTearDown(controller.dispose);
      final pending = order(status: 'Pending');
      final completed = order(status: 'completed');

      controller.addOrder(pending);
      expect(controller.latestOrder, isNull);

      controller.addOrder(completed);
      controller.addOrder(completed);

      expect(controller.latestOrder, same(completed));
      expect(controller.userPointsBalance, 385);
      expect(controller.pointHistory, hasLength(2));
      expect(controller.pointHistory.first.amount, '+35');
      expect(controller.pointHistory.last.amount, '−100');
    },
  );

  testWidgets(
    'checkout stays pending until approval, then receipt and points are reported',
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
      await tester.pumpAndSettle();

      expect(find.text('ส่งคำขอชำระเงินแล้ว'), findsOneWidget);
      expect(backend.checkoutCreated, isTrue);

      final checkoutRequest = backend.lastRequest('POST', '/api/checkout');
      expect(jsonDecode(checkoutRequest.body), {
        'package_id': 5,
        'coupon_id': null,
        'use_coins': false,
        'method': 'qr',
        'player_uid': '1234567890',
        'server_code': '',
      });

      await AuthService.login('admin', 'secret123');
      await PaymentService.updateStatus(42, 'Paid');
      expect(backend.approved, isTrue);
      expect(
        backend
            .lastRequest('PUT', '/api/payments/42/status')
            .headers['authorization'],
        'Bearer admin-token',
      );

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
      await tester.pumpAndSettle();
      expect(submittedOrder?.id, 'GP-42');
      expect(submittedOrder?.success, isFalse);
      expect(submittedOrder?.earnedPoints, 0);
      await tester.pumpWidget(
        MaterialApp(home: ReceiptScreen(order: receiptOrder())),
      );

      expect(find.text('เติมเกมสำเร็จ!'), findsOneWidget);
      expect(find.text('ได้รับ +35 แต้ม'), findsOneWidget);
      expect(find.text('แต้มคงเหลือ 385 แต้ม'), findsOneWidget);
      expect(find.text('GP-42'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'order and payment services serialize requests and parse results',
    () async {
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

      expect(
        backend.lastRequest('POST', '/api/checkout').headers['authorization'],
        'Bearer admin-token',
      );
      expect(jsonDecode(backend.lastRequest('POST', '/api/payments').body), {
        'order_id': 42,
        'method': 'qr',
      });
    },
  );

  testWidgets('receipt formats and displays its amount and points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final screen = ReceiptScreen(order: receiptOrder());
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

OrderModel order({required String status}) => OrderModel(
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

PaygameOrder receiptOrder() => PaygameOrder(
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

http.Response jsonResponse(Object? body, {int statusCode = 200}) =>
    http.Response(
      jsonEncode(body),
      statusCode,
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

class FakeBackend {
  final List<http.Request> requests = [];
  bool invalidLoginResponse = false;
  bool checkoutCreated = false;
  bool approved = false;

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;

    if (request.method == 'POST' && path == '/api/login') {
      if (invalidLoginResponse) return jsonResponse({'user': {}});
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final isAdmin = body['username'] == 'admin';
      return jsonResponse({
        'token': isAdmin ? 'admin-token' : 'player-token',
        'user': {
          'id': isAdmin ? 1 : 7,
          'username': body['username'],
          'display_name': isAdmin ? 'Admin' : 'Player One',
          'role': isAdmin ? 'admin' : 'user',
        },
      });
    }

    if (request.method == 'POST' && path == '/api/register') {
      return jsonResponse({'message': 'Register successful'}, statusCode: 201);
    }
    if (request.method == 'GET' && path == '/api/games') {
      return jsonResponse([]);
    }
    if (request.method == 'GET' && path == '/api/coupons') {
      return jsonResponse([
        {
          'coupon_id': 7,
          'name': 'WELCOME10',
          'amount_satang': 1000,
          'percent': 0,
          'minimum_satang': 0,
          'max_discount_satang': null,
          'status': 'Available',
        },
      ]);
    }
    if (request.method == 'GET' && path == '/api/points/balance') {
      return jsonResponse({'total_points': approved ? 385 : 350});
    }
    if (request.method == 'GET' && path == '/api/points/history') {
      return jsonResponse([
        {
          'type': 'Earn',
          'points_delta': approved ? 35 : 350,
          'created_at': '2026-01-02T03:04:00.000Z',
        },
      ]);
    }
    if (request.method == 'POST' && path == '/api/coupons/claim') {
      return jsonResponse({'message': 'Coupon claimed'}, statusCode: 201);
    }
    if (request.method == 'POST' && path == '/api/coupons/redeem') {
      return jsonResponse({'user_coupon_id': 8}, statusCode: 201);
    }
    if (request.method == 'POST' && path == '/api/checkout') {
      checkoutCreated = true;
      return jsonResponse({
        'order_id': 42,
        'total_amount': 35.0,
        'discount_amount': 0.0,
        'fee_amount': 0.0,
        'points_balance': 350,
        'spent_points': 0,
        'coupon_id': null,
      }, statusCode: 201);
    }
    if (request.method == 'POST' && path == '/api/payments') {
      return jsonResponse({
        'payment': {'payment_id': 3, 'status': 'Pending'},
      }, statusCode: 201);
    }
    if (request.method == 'GET' && path == '/api/orders') {
      return jsonResponse([]);
    }
    if (request.method == 'GET' && path == '/api/payments') {
      return jsonResponse([]);
    }
    if (request.method == 'PUT' && path == '/api/payments/42/status') {
      if (request.headers['authorization'] != 'Bearer admin-token') {
        return jsonResponse({
          'message': 'Admin access required',
        }, statusCode: 403);
      }
      approved = true;
      return jsonResponse({'payment_id': 42, 'status': 'Paid'});
    }
    if (request.method == 'GET' && path == '/api/admin/receipts') {
      return jsonResponse(approved ? [_receiptJson] : []);
    }
    if (request.method == 'GET' && path == '/api/admin/points/balances') {
      return jsonResponse([
        {
          'user_id': 7,
          'username': 'player',
          'display_name': 'Player One',
          'balance': approved ? 385 : 350,
          'earned_total': approved ? 35 : 0,
        },
      ]);
    }
    if (request.method == 'GET' && path == '/api/admin/points/history') {
      return jsonResponse(
        approved
            ? [
                {
                  'point_transaction_id': 10,
                  'user_id': 7,
                  'order_id': 42,
                  'type': 'Earn',
                  'points_delta': 35,
                  'created_at': '2026-01-02T03:04:00.000Z',
                  'username': 'player',
                  'game_name_snapshot': 'RoV',
                  'package_name_snapshot': '100 Diamonds',
                },
              ]
            : [],
      );
    }

    return jsonResponse({
      'message': 'No fake route for ${request.method} $path',
    }, statusCode: 404);
  }

  http.Request lastRequest(String method, String path) => requests.lastWhere(
    (request) => request.method == method && request.url.path == path,
  );

  static const _receiptJson = {
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
}
