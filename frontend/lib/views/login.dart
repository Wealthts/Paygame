import 'package:flutter/material.dart';
import 'package:frontend/views/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: const Key('login_screen'));

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  // ระยะห่างมาตรฐาน ใช้ซ้ำทั้งหน้า
  static const double _s8 = 8;
  static const double _s16 = 16;
  static const double _s24 = 24;

  static const Color _red = Color(0xFFA60C19);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ให้ body ย่อตามคีย์บอร์ดเอง เลื่อนได้ และไม่ overflow
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                _buildHeader(context),
                _buildForm(context),
                // ดันข้อความท้ายหน้าไปชิดล่างเมื่อหน้าจอสูง
                const Spacer(),
                _buildFooterNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader(BuildContext context) {
    // ใช้ safe area จริงของเครื่อง แทนการ hardcode 60
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
      padding: EdgeInsets.fromLTRB(_s24, topInset + _s24, _s24, _s24 + 4),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.sports_esports, size: 40, color: _red),
          ),
          const SizedBox(height: 12),
          const Text(
            'GamePay',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เติมเกมรวดเร็ว รับแต้มคืนทุกครั้งที่เติม',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ---------- Form ----------
  Widget _buildForm(BuildContext context) {
    return Center(
      // จำกัดความกว้างเผื่อใช้บนแท็บเล็ต/เว็บ
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_s24, _s24, _s24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: _s24),

              _buildLabel('ชื่อผู้ใช้'),
              const SizedBox(height: _s8),
              _buildTextField(
                controller: usernameController,
                hint: 'ชื่อผู้ใช้',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: _s16),

              _buildLabel('รหัสผ่าน'),
              const SizedBox(height: _s8),
              _buildTextField(
                controller: passwordController,
                hint: '........',
                isPassword: true,
                obscure: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: _s16),

              // ลืมรหัสผ่าน: เว้นระยะด้านบน-ล่างให้สบายตา และกดง่ายขึ้น
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _s8,
                      vertical: _s8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'ลืมรหัสผ่าน?',
                    style: TextStyle(
                      color: _red,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _s24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement Login Logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _s16),

              // ใช้ Wrap เผื่อข้อความยาวจนตกบรรทัด
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'ยังไม่มีบัญชี? ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
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
          ),
        ),
      ),
    );
  }

  // ---------- Footer ----------
  Widget _buildFooterNote() {
    return SafeArea(
      top: false,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(_s24, _s24, _s24, _s16),
        child: Text(
          'เข้าสู่ระบบวันนี้: ผู้ดูแลระบบ (Admin) สามารถใช้บัญชีเดียวกันในการเข้าถึงได้ (แยกสิทธิ์ผ่าน JWT roles)',
          style: TextStyle(fontSize: 11, color: Colors.black45, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ---------- Reusable widgets ----------
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && obscure,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
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
    );
  }
}