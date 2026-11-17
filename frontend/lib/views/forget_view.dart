import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/login_view.dart';

class ForgetScreen extends StatefulWidget {
  const ForgetScreen({Key? key})
    : super(key: key ?? const Key('forget_screen'));

  @override
  State<ForgetScreen> createState() => _ForgetScreenState();
}

class _ForgetScreenState extends State<ForgetScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;

  static const Color red = Color(0xFFA60C19);
  static const Color gold = Color(0xFFD4AF37);

  // ต้องตรงกับ cooldown ฝั่ง Backend (60 วินาที)
  static const int resendCooldownSeconds = 60;

  // 0 = กรอกอีเมล, 1 = กรอกรหัสยืนยัน + รหัสผ่านใหม่
  int step = 0;
  bool isLoading = false;
  bool obscurePassword = true;
  int resendSeconds = 0;
  Timer? resendTimer;

  @override
  void dispose() {
    resendTimer?.cancel();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    super.dispose();
  }

  // Main Build
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
                buildHeader(context),
                buildForm(context),
                const Spacer(),
                buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header
  Widget buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s24, topInset + s24, s24, s24 + 4),
      decoration: const BoxDecoration(
        color: red,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        border: Border(bottom: BorderSide(color: gold, width: 4.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(s8),
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

          const SizedBox(height: s16),

          // Header Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forgot your password?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: s8),

                Text(
                  'Reset your password and get back to GamePay.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Forget Password Form
  Widget buildForm(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(s24, s24, s24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step == 0) ...buildEmailStep() else ...buildCodeStep(),

              const SizedBox(height: s16),

              // Back to Login
              Center(
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: red,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
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

  // Step 1: Email
  List<Widget> buildEmailStep() {
    return [
      const Text(
        'Reset Password',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),

      const SizedBox(height: s8),

      const Text(
        'Enter your registered email address. '
        'We will send a 6-digit verification code to your email.',
        style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
      ),

      const SizedBox(height: s24),

      buildLabel('Email'),

      const SizedBox(height: s8),

      buildTextField(
        controller: emailController,
        hint: 'example@email.com',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => sendCode(),
      ),

      const SizedBox(height: s24),

      buildPrimaryButton('Send Verification Code', sendCode),
    ];
  }

  // Step 2: Code + New Password
  List<Widget> buildCodeStep() {
    return [
      const Text(
        'Enter Verification Code',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),

      const SizedBox(height: s8),

      Text(
        'We sent a 6-digit code to ${emailController.text.trim()}. '
        'The code expires in 15 minutes.',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black54,
          height: 1.5,
        ),
      ),

      const SizedBox(height: s24),

      buildLabel('Verification Code'),

      const SizedBox(height: s8),

      buildTextField(
        controller: codeController,
        hint: '123456',
        icon: Icons.pin_outlined,
        keyboardType: TextInputType.number,
        maxLength: 6,
        formatters: [FilteringTextInputFormatter.digitsOnly],
      ),

      const SizedBox(height: s16),

      buildLabel('New Password'),

      const SizedBox(height: s8),

      buildTextField(
        controller: passwordController,
        hint: 'At least 6 characters',
        icon: Icons.lock_outline,
        obscure: obscurePassword,
        suffix: IconButton(
          icon: Icon(
            obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.black45,
          ),
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
        ),
      ),

      const SizedBox(height: s16),

      buildLabel('Confirm New Password'),

      const SizedBox(height: s8),

      buildTextField(
        controller: confirmController,
        hint: 'Re-enter new password',
        icon: Icons.lock_outline,
        obscure: obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => resetPassword(),
      ),

      const SizedBox(height: s24),

      buildPrimaryButton('Reset Password', resetPassword),

      const SizedBox(height: s8),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: isLoading ? null : changeEmail,
            child: const Text('Change email'),
          ),
          TextButton(
            onPressed: (isLoading || resendSeconds > 0) ? null : sendCode,
            child: Text(
              resendSeconds > 0
                  ? 'Resend code in ${resendSeconds}s'
                  : 'Resend code',
            ),
          ),
        ],
      ),
    ];
  }

  // Primary Button (แสดง loading ระหว่างเรียก API)
  Widget buildPrimaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: red,
          disabledBackgroundColor: red.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // Reusable Text Field
  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscure = false,
    Widget? suffix,
    int? maxLength,
    List<TextInputFormatter>? formatters,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscure,
      maxLength: maxLength,
      inputFormatters: formatters,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFFFFDF5),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        prefixIcon: Icon(icon, color: Colors.black45),
        suffixIcon: suffix,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF3E7D3)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red),
        ),
      ),
    );
  }

  // Reusable Label
  Widget buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: 14,
      ),
    );
  }

  // Step 1: ขอรหัสยืนยันทางอีเมล (ใช้เป็นปุ่ม Resend ด้วย)
  Future<void> sendCode() async {
    if (isLoading) return;

    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Please enter your email address.');
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      showMessage('Please enter a valid email address.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.forgotPassword(email);

      if (!mounted) return;

      setState(() => step = 1);
      startResendCooldown();
      showMessage('If this email is registered, a verification code has been sent.');
    } catch (e) {
      if (!mounted) return;
      showMessage(errorText(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Step 2: ยืนยันรหัส + ตั้งรหัสผ่านใหม่
  Future<void> resetPassword() async {
    if (isLoading) return;

    final code = codeController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (code.length != 6) {
      showMessage('Please enter the 6-digit verification code.');
      return;
    }

    if (password.length < 6) {
      showMessage('Password must be at least 6 characters.');
      return;
    }

    if (password != confirm) {
      showMessage('Passwords do not match.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.resetPassword(
        email: emailController.text.trim(),
        code: code,
        newPassword: password,
      );

      if (!mounted) return;

      showMessage('Password reset successful. Please log in.');
      _goToLogin();
    } catch (e) {
      if (!mounted) return;
      showMessage(errorText(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // กลับไปแก้อีเมล
  void changeEmail() {
    resendTimer?.cancel();
    codeController.clear();
    passwordController.clear();
    confirmController.clear();

    setState(() {
      step = 0;
      resendSeconds = 0;
    });
  }

  // นับถอยหลังก่อนขอรหัสใหม่ได้
  void startResendCooldown() {
    resendTimer?.cancel();
    setState(() => resendSeconds = resendCooldownSeconds);

    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  // แปลง Exception เป็นข้อความที่อ่านง่าย
  // เช่น "API Error 400: {message: Invalid or expired code}" -> "Invalid or expired code"
  String errorText(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    final match = RegExp(r'\{message: (.*)\}').firstMatch(text);

    return match?.group(1) ?? text;
  }

  // Navigation
  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Message
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // Footer
  Widget buildFooter() {
    return SafeArea(
      top: false,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(s24, s24, s24, s16),
        child: Text(
          'GamePay - Secure Game Top Up',
          style: TextStyle(fontSize: 11, color: Colors.black45),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}