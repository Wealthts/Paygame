part of 'package_view.dart';

enum PaygameMethod {
  qr('QR พร้อมเพย์', 'ไม่มีค่าธรรมเนียม', Icons.qr_code_2, 0),
  wallet(
    'e-Wallet',
    'ค่าธรรมเนียม 1%',
    Icons.account_balance_wallet_outlined,
    100,
  ),
  card('บัตรเครดิต / เดบิต', 'ค่าธรรมเนียม 2.5%', Icons.credit_card, 250);

  const PaygameMethod(this.label, this.hint, this.icon, this.basisPoints);
  final String label;
  final String hint;
  final IconData icon;
  final int basisPoints;
}

/// Amounts are in satang; this callback reports simulated orders only.
class PaygameOrder {
  const PaygameOrder({
    required this.id,
    required this.game,
    required this.pack,
    required this.uid,
    required this.server,
    required this.method,
    required this.priceSatang,
    required this.discountSatang,
    required this.feeSatang,
    required this.success,
    required this.earnedPoints,
    required this.pointsBalance,
    required this.createdAt,
    this.spentPoints = 0,
    this.couponId,
  });
  final String id;
  final PaygameGame game;
  final PaygamePack pack;
  final String uid;
  final String? server;
  final PaygameMethod method;
  final int priceSatang, discountSatang, feeSatang;
  final bool success;
  final int earnedPoints, pointsBalance;
  final DateTime createdAt;
  final int spentPoints;
  final String? couponId;
  int get totalSatang => priceSatang - discountSatang + feeSatang;
}

/// Checkout screen that creates a pending order and payment request.
class PaygamePayment extends StatefulWidget {
  const PaygamePayment({
    super.key,
    required this.game,
    required this.pack,
    required this.uid,
    this.server = 'Asia',
    this.initialPoints = 0,
    this.coupons = const [],
    this.onPaymentCompleted,
  });
  final PaygameGame game;
  final PaygamePack pack;
  final String uid, server;
  final int initialPoints;
  final List<CouponModel> coupons;
  final ValueChanged<PaygameOrder>? onPaymentCompleted;
  @override
  State<PaygamePayment> createState() => _PaygamePaymentState();
}

class _PaygamePaymentState extends State<PaygamePayment> {
  static const _red = Color(0xFFB51229);
  static const _muted = Color(0xFF68626B);
  late int _points;
  bool _discount = false, _busy = false;
  CouponModel? _coupon;
  PaygameMethod _method = PaygameMethod.qr;
  PaygameGame get _game => widget.game;
  PaygamePack get _pack => widget.pack;
  String get _server => widget.server;
  int get _price => _pack.price * 100;
  CheckoutDiscount get _discounts => CheckoutDiscount(
    priceSatang: _price,
    points: _points,
    usePoints: _discount,
    coupon: _coupon,
  );
  int get _saving => _discounts.totalSatang;
  int get _fee => ((_price - _saving) * _method.basisPoints / 10000).round();
  int get _total => _price - _saving + _fee;
  int get _earned => (_price - _saving) ~/ 1000;

  @override
  void initState() {
    super.initState();
    _points = widget.initialPoints < 0 ? 0 : widget.initialPoints;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _red, primary: _red),
      scaffoldBackgroundColor: const Color(0xFFF8F7F5),
      fontFamily: 'NotoSansThai',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDD8D7)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
    return Theme(
      data: theme,
      child: PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('ตรวจสอบและชำระเงิน'),
            leading: IconButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'ย้อนกลับ',
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          '✓ แพ็กเกจ   →   ✓ UID ผู้เล่น   →   3 ชำระเงิน',
                          style: TextStyle(color: _red),
                        ),
                      ),
                      _paymentPage(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _pay,
                        child: Text('ยืนยันชำระเงิน ${_money(_total)}'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _number(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  String _money(int satang) =>
      '฿${_number(satang ~/ 100)}${satang % 100 == 0 ? '' : '.${(satang % 100).toString().padLeft(2, '0')}'}';

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEAE7E5)),
    ),
    child: Material(color: Colors.transparent, child: child),
  );

  Widget _paymentPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _card(
        Column(
          children: [
            Row(
              children: [
                const Icon(Icons.sports_esports, color: _red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_game.name} · ${_number(_pack.quantity)} ${_game.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'UID: ${widget.uid}${_game.requiresServer ? ' / $_server' : ''}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('แก้ไข'),
                ),
              ],
            ),
            const Divider(height: 28),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.confirmation_number_outlined,
                color: _red,
              ),
              title: Text(_coupon?.name ?? 'เลือกคูปอง'),
              subtitle: const Text('ใช้ได้ 1 ใบต่อครั้ง และใช้ร่วมกับคอยน์ได้'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () async {
                      final selected = await Navigator.push<CouponModel>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CouponsView(
                            coupons: widget.coupons,
                            priceSatang: _price,
                            selectedId: _coupon?.id,
                          ),
                        ),
                      );
                      if (mounted && selected != null) {
                        setState(() => _coupon = selected);
                      }
                    },
            ),
            if (_coupon != null)
              TextButton(
                onPressed: _busy ? null : () => setState(() => _coupon = null),
                child: const Text('ไม่ใช้คูปอง'),
              ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.monetization_on_outlined,
                color: Color(0xFFAA7B12),
              ),
              title: const Text(
                'ใช้คอยน์สูงสุด (10 คอยน์ = ฿1)',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                'มี ${_number(_points)} คอยน์ · ใช้ ${_discounts.spentPoints} คอยน์',
              ),
              value: _discount,
              onChanged: _points <= 0 || _busy
                  ? null
                  : (v) => setState(() => _discount = v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _heading('ช่องทางชำระเงิน'),
      for (final method in PaygameMethod.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Semantics(
            selected: _method == method,
            button: true,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: _method == method ? _red : const Color(0xFFEAE7E5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                enabled: !_busy,
                leading: Icon(method.icon, color: _red),
                title: Text(method.label),
                subtitle: Text(method.hint),
                trailing: Icon(
                  _method == method
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _method == method ? _red : _muted,
                ),
                onTap: _busy ? null : () => setState(() => _method = method),
              ),
            ),
          ),
        ),
      const SizedBox(height: 8),
      _card(
        Column(
          children: [
            _billRow('ราคาแพ็กเกจ', _money(_price)),
            _billRow('ส่วนลดคูปอง', '−${_money(_discounts.couponSatang)}'),
            _billRow('ส่วนลดคอยน์', '−${_money(_discounts.coinSatang)}'),
            _billRow('ค่าธรรมเนียม', _money(_fee)),
            const Divider(),
            _billRow('ยอดสุทธิ', _money(_total), emphasis: true),
            const SizedBox(height: 8),
            Text(
              'รับ +$_earned แต้ม เมื่อเติมสำเร็จ',
              style: const TextStyle(color: Color(0xFF986C0A)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _notice(
        Icons.lock_outline,
        'คูปองและคอยน์จะถูกจองระหว่างรออนุมัติ และคืนเมื่อรายการถูกปฏิเสธ',
      ),
    ],
  );

  Widget _billRow(String label, String value, {bool emphasis = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: emphasis ? _red : null,
                  fontSize: emphasis ? 22 : 14,
                  fontWeight: emphasis ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _notice(IconData icon, String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF0EEEB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ),
      ],
    ),
  );

  Future<void> _pay() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ยืนยันบัญชีที่จะเติม'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_game.name} · ${_number(_pack.quantity)} ${_game.unit}',
                ),
                Text('UID ${widget.uid}'),
                if (_game.requiresServer) Text('เซิร์ฟเวอร์ $_server'),
                Text('ยอดชำระ ${_money(_total)}'),
                const SizedBox(height: 16),
                const Text('รายการจะถูกส่งให้ผู้ดูแลระบบตรวจสอบและอนุมัติ'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('กลับไปตรวจสอบ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ส่งคำขอชำระเงิน'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      if (_pack.packageId <= 0) {
        throw Exception('This package is not available for purchase yet');
      }

      final orderResponse = await OrderService.create(
        packageId: _pack.packageId,
        playerUid: widget.uid,
        serverCode: _game.requiresServer ? _server : null,
        couponId: _coupon == null ? null : int.parse(_coupon!.id),
        useCoins: _discount,
        method: _method.name,
      );
      final orderId = int.tryParse(orderResponse['order_id'].toString());
      if (orderId == null) throw Exception('Invalid order ID');

      if (!mounted) return;
      final order = PaygameOrder(
        id: 'GP-$orderId',
        game: _game,
        pack: _pack,
        uid: widget.uid,
        server: _game.requiresServer ? _server : null,
        method: _method,
        priceSatang: _price,
        discountSatang:
            (num.parse(orderResponse['discount_amount'].toString()) * 100)
                .round(),
        feeSatang: (num.parse(orderResponse['fee_amount'].toString()) * 100)
            .round(),
        success: false,
        earnedPoints: 0,
        pointsBalance: int.parse(orderResponse['points_balance'].toString()),
        spentPoints: int.parse(orderResponse['spent_points'].toString()),
        couponId: orderResponse['coupon_id']?.toString(),
        createdAt: DateTime.now(),
      );
      setState(() {
        _discount = false;
      });
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            Icons.schedule_outlined,
            color: const Color(0xFF986C0A),
            size: 48,
          ),
          title: const Text('ส่งคำขอชำระเงินแล้ว'),
          content: Text(
            'คำสั่งซื้อ ${order.id}\nUID ${order.uid}\nยอดชำระ ${_money(order.totalSatang)}\nสถานะ: รอผู้ดูแลอนุมัติ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onPaymentCompleted?.call(order);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
