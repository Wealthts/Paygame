import 'package:flutter/material.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: const Key('login_screen'));

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header ส่วนบน (แดง + โลโก้ + เส้นขอบสีทอง)[cite: 1]
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFA60C19), // สีแดง GamePay[cite: 1]
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFD4AF37), // เส้นขอบสีทองด้านล่าง[cite: 1]
                    width: 4.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              child: Column(
                children: [
                  // โลโก้ทรงสี่เหลี่ยมมนสีทอง[cite: 1]
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A017),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.sports_esports,
                      size: 40,
                      color: Color(0xFFA60C19),
                    ),
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
                    'เติมเกมไว ได้แต้มคืนทุกครั้ง',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Form ส่วนล่าง[cite: 1]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
                  const SizedBox(height: 20),

                  // ช่องกรอกชื่อผู้ใช้[cite: 1]
                  const Text('ชื่อผู้ใช้', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'username',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: const Color(0xFFFFFDF5), // สีครีมอ่อน[cite: 1]
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  const SizedBox(height: 16),

                  // ช่องกรอกรหัสผ่าน[cite: 1]
                  const Text('รหัสผ่าน', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '........',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: const Color(0xFFFFFDF5), // สีครีมอ่อน[cite: 1]
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  
                  // ลืมรหัสผ่าน[cite: 1]
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'ลืมรหัสผ่าน?',
                        style: TextStyle(
                          color: Color(0xFFA60C19),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ปุ่มเข้าสู่ระบบ[cite: 1]
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement Login Logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA60C19),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ลิงก์ไปหน้าสมัครสมาชิก[cite: 1]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ยังไม่มีบัญชี? ', style: TextStyle(color: Colors.black54)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'สมัครสมาชิก',
                          style: TextStyle(
                            color: Color(0xFFA60C19),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ข้อความระบุสิทธิ์ Role[cite: 1]
                  const Center(
                    child: Text(
                      'เข้าสู่ระบบวันนี้: Admin ได้ด้วยบัญชีเดียวกัน (แยกสิทธิ์ด้วย JWT role)',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}