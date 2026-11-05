import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: const Key('register_screen'));

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isAcceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header ส่วนบนสีแดงพร้อมปุ่มย้อนกลับ
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFA60C19),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFD4AF37), width: 4.0),
                ),
              ),
              padding: const EdgeInsets.only(
                top: 50,
                left: 16,
                right: 16,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ปุ่มย้อนกลับ
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Create new account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Text(
                        'Sign up today! Get it for free ',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '50 points ',
                        style: TextStyle(
                          color: Color(0xFFF1C40F),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'For the first top-up',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form สมัครสมาชิก
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อผู้ใช้
                  _buildInputField(
                    label: 'Username',
                    hintText: 'username',
                    controller: usernameController,
                  ),
                  const SizedBox(height: 14),

                  // อีเมล
                  _buildInputField(
                    label: 'Email',
                    hintText: 'you@email.com',
                    controller: emailController,
                  ),
                  const SizedBox(height: 14),

                  // เบอร์โทรศัพท์
                  _buildInputField(
                    label: 'Telephone number',
                    hintText: '08x-xxx-xxxx',
                    controller: phoneController,
                  ),
                  const SizedBox(height: 14),

                  // รหัสผ่าน
                  _buildInputField(
                    label: 'Password',
                    hintText: 'At least 8 characters',
                    controller: passwordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 6),

                  // แถบแสดงความแข็งแรงรหัสผ่าน (Password Strength Indicator)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          color: const Color(0xFFF1C40F),
                        ),
                      ), // สีเหลือง/ส้ม
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          color: const Color(0xFFF1C40F),
                        ),
                      ), // สีเหลือง/ส้ม
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          color: Colors.grey.shade300,
                        ),
                      ), // สีเทา
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Password strength: Medium',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),

                  // ยืนยันรหัสผ่าน[cite: 1]
                  _buildInputField(
                    label: 'Confirm password',
                    hintText: '........',
                    controller: confirmPasswordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),

                  // Checkbox ยอมรับเงื่อนไข[cite: 1]
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isAcceptedTerms,
                          onChanged: (val) {
                            setState(() {
                              isAcceptedTerms = val ?? false;
                            });
                          },
                          activeColor: const Color(0xFFA60C19),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Accept ',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Terms of Use',
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

                  // ปุ่มสมัครสมาชิก
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isAcceptedTerms
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
                        'Sign up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // กลับไปหน้าเข้าสู่ระบบ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Log in',
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
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFFFDF5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
