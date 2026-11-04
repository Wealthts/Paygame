import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'payment_view.dart';

// Run as a Flutter entry point, or push PaygamePackage from an existing app.
// All prices, UID rules, points and payments are demo data from gamepay-ui.
void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: PaygamePackage()),
);

class PaygamePack {
  const PaygamePack(this.quantity, this.price, {this.enabled = true});
  final int quantity;
  final int price;
  final bool enabled;
}

class PaygameGame {
  const PaygameGame(
    this.name,
    this.unit,
    this.packs, {
    this.requiresServer = false,
  });
  final String name;
  final String unit;
  final List<PaygamePack> packs;
  final bool requiresServer;
}

const paygameGames = <String, PaygameGame>{
  'rov': PaygameGame('RoV', 'คูปอง', [
    PaygamePack(40, 35),
    PaygamePack(90, 79),
    PaygamePack(230, 199),
    PaygamePack(400, 350),
    PaygamePack(800, 690),
    PaygamePack(1650, 1390),
  ]),
  'ff': PaygameGame('Free Fire', 'เพชร', [
    PaygamePack(100, 39),
    PaygamePack(310, 119),
    PaygamePack(520, 199),
    PaygamePack(1060, 399),
    PaygamePack(2180, 799),
    PaygamePack(5600, 1999),
  ]),
  'pubg': PaygameGame('PUBG Mobile', 'UC', [
    PaygamePack(60, 35),
    PaygamePack(180, 99),
    PaygamePack(325, 179),
    PaygamePack(660, 349),
    PaygamePack(1800, 899),
    PaygamePack(3850, 1799),
  ]),
  'genshin': PaygameGame('Genshin Impact', 'Crystals', [
    PaygamePack(60, 35),
    PaygamePack(300, 179),
    PaygamePack(980, 530),
    PaygamePack(1980, 1099),
    PaygamePack(3280, 1799),
    PaygamePack(6480, 3499),
  ], requiresServer: true),
  'valorant': PaygameGame('Valorant', 'VP', [
    PaygamePack(125, 35),
    PaygamePack(420, 110),
    PaygamePack(700, 179),
    PaygamePack(1375, 350),
    PaygamePack(2400, 600),
    PaygamePack(4000, 999),
  ]),
  'mlbb': PaygameGame('Mobile Legends', 'เพชร', [
    PaygamePack(50, 35),
    PaygamePack(150, 99),
    PaygamePack(300, 199),
    PaygamePack(550, 350),
    PaygamePack(1100, 690),
    PaygamePack(2200, 1390),
  ]),
};

class PaygamePackage extends StatefulWidget {
  const PaygamePackage({
    super.key,
    this.gameId = 'rov',
    this.initialPoints = 0,
    this.onPaymentCompleted,
  });
  final String gameId;
  final int initialPoints;
  final ValueChanged<PaygameOrder>? onPaymentCompleted;

  @override
  State<PaygamePackage> createState() => _PaygamePackageState();
}

class _PaygamePackageState extends State<PaygamePackage> {
  static const _red = Color(0xFFB51229);
  static const _muted = Color(0xFF68626B);
  final _form = GlobalKey<FormState>();
  final _uid = TextEditingController();
  final _scroll = ScrollController();
  late PaygameGame _game;
  late int _points;
  int _selected = 3;
  String _server = 'Asia';

  PaygamePack get _pack => _game.packs[_selected];
  int get _price => _pack.price * 100;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    _game = paygameGames[widget.gameId] ?? paygameGames['rov']!;
    _points = widget.initialPoints < 0 ? 0 : widget.initialPoints;
    _selected = _game.packs.length > 3 && _game.packs[3].enabled
        ? 3
        : _game.packs.indexWhere((p) => p.enabled);
  }

  @override
  void didUpdateWidget(covariant PaygamePackage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _initialize();
      _uid.clear();
      _server = 'Asia';
    }
  }

  @override
  void dispose() {
    _uid.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _number(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  String _money(int satang) =>
      '฿${_number(satang ~/ 100)}${satang % 100 == 0 ? '' : '.${(satang % 100).toString().padLeft(2, '0')}'}';

  void _openPayment() {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaygamePayment(
          game: _game,
          pack: _pack,
          uid: _uid.text,
          server: _server,
          initialPoints: _points,
          onPaymentCompleted: (order) {
            if (mounted) setState(() => _points = order.pointsBalance);
            if (order.success && mounted) Navigator.of(context).pop();
            widget.onPaymentCompleted?.call(order);
          },
        ),
      ),
    );
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
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _game.name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'เลือกแพ็กเกจสำหรับบัญชีเกมของคุณ',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  _steps(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(20),
                      child: _selected < 0
                          ? const Text('ยังไม่มีแพ็กเกจที่เปิดขาย')
                          : _packagePage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _selected < 0 ? null : _bottomAction(),
      ),
    );
  }

  Widget _steps() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: i < 2 ? _red : const Color(0xFFEAE7E5),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: i < 2 ? Colors.white : _muted,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  ['แพ็กเกจ', 'UID ผู้เล่น', 'ชำระเงิน'][i],
                  style: TextStyle(fontSize: 11, color: i < 2 ? _red : _muted),
                ),
              ),
              if (i < 2)
                const Expanded(child: Divider(indent: 7, endIndent: 7)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  Widget _packagePage() => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('1. เลือกแพ็กเกจ'),
        const Text(
          'ราคาเป็นเงินบาท',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final columns = constraints.maxWidth >= 560
                ? 3
                : constraints.maxWidth < 280 || scale > 1.4
                ? 1
                : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                _game.packs.length,
                (i) => SizedBox(width: width, child: _packageTile(i)),
              ),
            );
          },
        ),
        const SizedBox(height: 26),
        _heading('2. กรอก UID ผู้เล่น'),
        const Text('Player UID'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _uid,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: const InputDecoration(
            hintText: 'กรอก UID ตัวเลข 10–12 หลัก',
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => RegExp(r'^[0-9]{10,12}$').hasMatch(value ?? '')
              ? null
              : 'กรอก UID เป็นตัวเลข 10–12 หลัก',
        ),
        const SizedBox(height: 8),
        const Text(
          'ตรวจ UID ให้ตรงกับบัญชีที่ต้องการเติม',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
        if (_game.requiresServer) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _server,
            decoration: const InputDecoration(labelText: 'เซิร์ฟเวอร์'),
            items: [
              'Asia',
              'Europe',
              'America',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (value) => setState(() => _server = value!),
          ),
        ],
        TextButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('วิธีหา UID ในเกม'),
              content: Text(
                'เปิดเกม ${_game.name} แล้วไปที่โปรไฟล์ผู้เล่น '
                'มองหา UID หรือ Player ID และคัดลอกเลขมาที่ช่องนี้ '
                'หากหาไม่พบ ให้ดูคำแนะนำจากผู้ให้บริการเกม',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('เข้าใจแล้ว'),
                ),
              ],
            ),
          ),
          icon: const Icon(Icons.help_outline, size: 18),
          label: const Text('ดูวิธีหา UID ในเกม'),
        ),
        _notice(
          Icons.shield_outlined,
          'ไม่ต้องใช้รหัสผ่านเกม\nเติมให้บัญชีตาม UID ที่ระบุเท่านั้น',
        ),
      ],
    ),
  );

  Widget _packageTile(int i) {
    final pack = _game.packs[i];
    final selected = _selected == i;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFFFF7F8) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? _red : const Color(0xFFDFDAD8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: pack.enabled ? () => setState(() => _selected = i) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i == 3)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5BC48),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'ยอดนิยม',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                if (i != 3) const SizedBox(height: 19),
                Text(
                  '${_number(pack.quantity)} ${_game.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _money(pack.price * 100),
                      style: const TextStyle(
                        color: _red,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      pack.enabled ? '+${pack.price ~/ 10} แต้ม' : 'ปิดขาย',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _bottomAction() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFEAE7E5))),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final amount = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ยอดชำระ',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                    Text(
                      _money(_price),
                      style: const TextStyle(
                        color: _red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'รับ +${_pack.price ~/ 10} แต้ม',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                );
                final button = FilledButton.icon(
                  onPressed: _openPayment,
                  label: const Text('ไปชำระเงิน'),
                  icon: const Icon(Icons.chevron_right),
                );
                if (constraints.maxWidth < 310 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [amount, const SizedBox(height: 8), button],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: amount),
                    const SizedBox(width: 12),
                    button,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
