import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/paygame_controller.dart';
import 'package:frontend/views/register_view.dart';
import 'package:frontend/views/forget_view.dart';
import 'package:frontend/views/admin/admin_shell_view.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({Key? key, this.onLoginSuccess})
    : super(key: key ?? const Key('login_screen'));

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;

  static const Color red = Color(0xFFA60C19);
  static const Color gold = Color(0xFFD4AF37);

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Login function
  Future<void> handleLogin() async {
    if (isLoading) return;

    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter username and password")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final controller = context.read<PaygameController>();
      await controller.login(username, password);
      if (!mounted) return;

      // Admin Navigation
      if (controller.currentRole == 'admin') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminShellView(
              onLogout: () async {
                await context.read<PaygameController>().logout();

                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      } else {
        // User Navigation
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login successful")));

        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
                buildFooterNote(),
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
        children: [
          // GamePay Logo
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.sports_esports, size: 40, color: red),
          ),

          const SizedBox(height: 12),

          // App Name
          const Text(
            'GamePay',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          // Description
          const Text(
            'Top up your games quickly and earn points back with every transaction.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Login Form
  // ============================================================
  Widget buildForm(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(s24, s24, s24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Title
              const Text(
                'Log in',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: s24),

              // Username
              buildLabel('Username'),

              const SizedBox(height: s8),

              buildTextField(
                controller: usernameController,
                hint: 'username',
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: s16),

              // Password
              buildLabel('Password'),

              const SizedBox(height: s8),

              buildTextField(
                controller: passwordController,
                hint: '........',
                isPassword: true,
                obscure: obscurePassword,
                onToggleObscure: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: s16),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgetScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: s8,
                      vertical: s8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: red,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: s24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: s16),

              // Register Link
              buildRegisterLink(context),
            ],
          ),
        ),
      ),
    );
  }

  // Register Link
  Widget buildRegisterLink(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            "Don't have an account yet? ",
            style: TextStyle(color: Colors.black54),
          ),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: const Text(
              'Sign up',
              style: TextStyle(
                color: red,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Footer
  Widget buildFooterNote() {
    return SafeArea(
      top: false,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(s24, s24, s24, s16),
        child: Text(
          'ผู้ดูแลระบบ (Admin) สามารถใช้บัญชีเดียวกันในการเข้าถึงได้ (แยกสิทธิ์ผ่าน JWT roles)',
          style: TextStyle(fontSize: 11, color: Colors.black45, height: 1.4),
          textAlign: TextAlign.center,
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
      ),
    );
  }

  // Reusable Text Field
  Widget buildTextField({
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

        // Input Padding
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        // Show / Hide Password
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

        // Default Border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF3E7D3)),
        ),

        // Focus Border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red),
        ),
      ),
    );
  }
}
