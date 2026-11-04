import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: const Key('register_screen'));

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isAcceptedTerms = false;

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header ส่วนบนสีแดงพร้อมปุ่มย้อนกลับ[cite: 1]
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFA60C19),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 4.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ปุ่มย้อนกลับ[cite: 1]
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'สร้างบัญชีใหม่',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Text('สมัครวันนี้! รับฟรี ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('50 แต้ม ', style: TextStyle(color: Color(0xFFF1C40F), fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('สำหรับเติมครั้งแรก', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            // Form สมัครสมาชิก[cite: 1]
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อผู้ใช้[cite: 1]
                  _buildInputField(label: 'ชื่อผู้ใช้', hintText: 'username', controller: _usernameController),
                  const SizedBox(height: 14),

                  // อีเมล[cite: 1]
                  _buildInputField(label: 'อีเมล', hintText: 'you@email.com', controller: _emailController),
                  const SizedBox(height: 14),

                  // เบอร์โทรศัพท์[cite: 1]
                  _buildInputField(label: 'เบอร์โทรศัพท์', hintText: '08x-xxx-xxxx', controller: _phoneController),
                  const SizedBox(height: 14),

                  // รหัสผ่าน[cite: 1]
                  _buildInputField(label: 'รหัสผ่าน', hintText: 'อย่างน้อย 8 ตัวอักษร', controller: _passwordController, isPassword: true),
                  const SizedBox(height: 6),

                  // แถบแสดงความแข็งแรงรหัสผ่าน (Password Strength Indicator)[cite: 1]
                  Row(
                    children: [
                      Expanded(child: Container(height: 4, color: const Color(0xFFF1C40F))), // สีเหลือง/ส้ม[cite: 1]
                      const SizedBox(width: 4),
                      Expanded(child: Container(height: 4, color: const Color(0xFFF1C40F))), // สีเหลือง/ส้ม[cite: 1]
                      const SizedBox(width: 4),
                      Expanded(child: Container(height: 4, color: Colors.grey.shade300)), // สีเทา[cite: 1]
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('ความแข็งแรงรหัสผ่าน: ปานกลาง', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  const SizedBox(height: 14),

                  // ยืนยันรหัสผ่าน[cite: 1]
                  _buildInputField(label: 'ยืนยันรหัสผ่าน', hintText: '........', controller: _confirmPasswordController, isPassword: true),
                  const SizedBox(height: 12),

                  // Checkbox ยอมรับเงื่อนไข[cite: 1]
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _isAcceptedTerms,
                          onChanged: (val) {
                            setState(() {
                              _isAcceptedTerms = val ?? false;
                            });
                          },
                          activeColor: const Color(0xFFA60C19),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('ยอมรับ ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'เงื่อนไขการใช้งาน',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA60C19),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ปุ่มสมัครสมาชิก[cite: 1]
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isAcceptedTerms
                          ? () {
                              // TODO: Implement Register logic with Argon2id hash
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA60C19),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // กลับไปหน้าเข้าสู่ระบบ[cite: 1]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('มีบัญชีแล้ว? ', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            color: Color(0xFFA60C19),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget ช่วยสร้าง Input Field ให้อ่านง่ายและ Clean
  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFFFDF5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF3E7D3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFA60C19)),
            ),
          ),
        ),
      ],
    );
  }
}