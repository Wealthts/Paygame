part of 'game_detail_view.dart';

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
  int get totalSatang => priceSatang - discountSatang + feeSatang;
}

/// Checkout screen for the selected package. Payments are simulated.
class PaygamePayment extends StatefulWidget {
  const PaygamePayment({
    super.key,
    required this.game,
    required this.pack,
    required this.uid,
    this.server = 'Asia',
    this.initialPoints = 0,
    this.onPaymentCompleted,
  });
  final PaygameGame game;
  final PaygamePack pack;
  final String uid, server;
  final int initialPoints;
  final ValueChanged<PaygameOrder>? onPaymentCompleted;
  @override
  State<PaygamePayment> createState() => _PaygamePaymentState();
}

class _PaygamePaymentState extends State<PaygamePayment> {
  static const _red = Color(0xFFB51229);
  static const _muted = Color(0xFF68626B);
  late int _points;
  bool _discount = false, _busy = false;
  PaygameMethod _method = PaygameMethod.qr;
  PaygameGame get _game => widget.game;
  PaygamePack get _pack => widget.pack;
  String get _server => widget.server;
  int get _price => _pack.price * 100;
  int get _saving =>
      _discount && _points >= 100 ? (_price < 1000 ? _price : 1000) : 0;
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
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.monetization_on_outlined,
                color: Color(0xFFAA7B12),
              ),
              title: const Text(
                'ใช้ 100 แต้ม ลด ฿10',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: Text('มี ${_number(_points)} แต้ม'),
              value: _discount,
              onChanged: _points < 100 || _busy
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
            _billRow('ส่วนลดจากแต้ม', '−${_money(_saving)}'),
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
      _notice(Icons.lock_outline, 'นี่คือการชำระเงินจำลอง ไม่มีการหักเงินจริง'),
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
      final success = await showDialog<bool>(
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
                const Text(
                  'นี่คือการทดลองชำระเงิน เลือกผลลัพธ์เพื่อดูหน้าจอถัดไป',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('กลับไปตรวจสอบ'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('จำลองชำระไม่สำเร็จ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('จำลองชำระสำเร็จ'),
            ),
          ],
        ),
      );
      if (!mounted || success == null) return;
      final earned = success ? _earned : 0;
      final balance = success
          ? _points - (_saving > 0 ? 100 : 0) + earned
          : _points;
      final order = PaygameOrder(
        id: 'GP-${DateTime.now().microsecondsSinceEpoch}',
        game: _game,
        pack: _pack,
        uid: widget.uid,
        server: _game.requiresServer ? _server : null,
        method: _method,
        priceSatang: _price,
        discountSatang: _saving,
        feeSatang: _fee,
        success: success,
        earnedPoints: earned,
        pointsBalance: balance,
        createdAt: DateTime.now(),
      );
      setState(() {
        _points = balance;
        if (success) {
          _discount = false;
        }
      });
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: success ? const Color(0xFF16754D) : _red,
            size: 48,
          ),
          title: Text(success ? 'เติมเกมสำเร็จ! (จำลอง)' : 'ชำระเงินไม่สำเร็จ'),
          content: Text(
            success
                ? 'คำสั่งซื้อ ${order.id}\nUID ${order.uid}\nยอดชำระ ${_money(order.totalSatang)}'
                      '\nได้รับ +$earned แต้ม\nแต้มคงเหลือ ${_number(balance)} แต้ม'
                : 'ไม่มีการหักเงินหรือแต้ม คุณสามารถลองทำรายการใหม่ได้',
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
      if (success) Navigator.of(context).pop();
      widget.onPaymentCompleted?.call(order);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
