import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: const Key('register_screen'));

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isAcceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ระยะห่างมาตรฐาน (ใช้ชุดเดียวกับหน้า Login)
  static const double _s4 = 4;
  static const double _s8 = 8;
  static const double _s16 = 16;
  static const double _s24 = 24;

  static const Color _red = Color(0xFFA60C19);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _yellow = Color(0xFFF1C40F);

  @override
  void initState() {
    super.initState();
    // อัปเดตแถบความแข็งแรงรหัสผ่านตามที่พิมพ์จริง
    passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // คำนวณความแข็งแรงรหัสผ่าน: 0 = ว่าง, 1 = อ่อน, 2 = ปานกลาง, 3 = แข็งแรง
  int get _passwordStrength {
    final p = passwordController.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) {
      score++;
    }
    return score == 0 ? 1 : score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                _buildHeader(context),
                _buildForm(context),
                const Spacer(),
                _buildLoginLink(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        border: Border(bottom: BorderSide(color: _gold, width: 4.0)),
      ),
      padding: EdgeInsets.fromLTRB(_s16, topInset + _s16, _s16, _s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ปุ่มย้อนกลับ
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(_s8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: _s16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: _s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สร้างบัญชีใหม่',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: _s8),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: 'สมัครวันนี้ รับฟรี '),
                      TextSpan(
                        text: '50 แต้ม ',
                        style: TextStyle(
                          color: _yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: 'เมื่อเติมเงินครั้งแรก'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Form ----------
  Widget _buildForm(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_s24, _s24, _s24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                label: 'ชื่อผู้ใช้',
                hintText: 'ชื่อผู้ใช้',
                controller: usernameController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: _s16),

              _buildInputField(
                label: 'รหัสผ่าน',
                hintText: 'อย่างน้อย 8 ตัวอักษร',
                controller: passwordController,
                isPassword: true,
                obscure: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: _s8),
              _buildPasswordStrength(),
              const SizedBox(height: _s16),

              _buildInputField(
                label: 'ยืนยันรหัสผ่าน',
                hintText: '........',
                controller: confirmPasswordController,
                isPassword: true,
                obscure: _obscureConfirm,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: _s16),

              _buildTermsRow(),
              const SizedBox(height: _s24),

              // ปุ่มสมัครสมาชิก
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isAcceptedTerms
                      ? () {
                          // TODO: Implement Register logic with Argon2id hash
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    disabledBackgroundColor: _red.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- แถบความแข็งแรงรหัสผ่าน ----------
  Widget _buildPasswordStrength() {
    final strength = _passwordStrength;
    final labels = ['', 'อ่อน', 'ปานกลาง', 'แข็งแรง'];
    final colors = [
      Colors.grey.shade300,
      Colors.redAccent,
      _yellow,
      Colors.green,
    ];
    final activeColor = colors[strength];

    Widget bar(int index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            decoration: BoxDecoration(
              color: strength > index ? activeColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            bar(0),
            const SizedBox(width: _s4),
            bar(1),
            const SizedBox(width: _s4),
            bar(2),
          ],
        ),
        const SizedBox(height: _s4),
        Text(
          strength == 0
              ? 'ความแข็งแรงของรหัสผ่าน'
              : 'ความแข็งแรงของรหัสผ่าน: ${labels[strength]}',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  // ---------- Checkbox ยอมรับเงื่อนไข ----------
  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isAcceptedTerms,
            onChanged: (val) {
              setState(() => isAcceptedTerms = val ?? false);
            },
            activeColor: _red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: _s8),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'ฉันยอมรับ ',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'ข้อกำหนดการใช้งาน',
                  style: TextStyle(
                    fontSize: 13,
                    color: _red,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- ลิงก์กลับไปหน้าเข้าสู่ระบบ (ชิดล่าง) ----------
  Widget _buildLoginLink(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_s24, _s24, _s24, _s16),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'มีบัญชีอยู่แล้ว? ',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                  color: _red,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Reusable input field ----------
  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: _s8),
        TextField(
          controller: controller,
          obscureText: isPassword && obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFFFFDF5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black45,
                      size: 20,
                    ),
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF3E7D3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _red),
            ),
          ),
        ),
      ],
    );
  }
}