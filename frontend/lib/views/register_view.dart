import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key})
    : super(key: key ?? const Key('register_screen'));

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Variables
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // เพิ่ม emailController[cite: 6]
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isAcceptedTerms = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  // Constants
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;

  static const Color red = Color(0xFFA60C19);
  static const Color gold = Color(0xFFD4AF37);
  static const Color yellow = Color(0xFFF1C40F);

  // Lifecycle
  @override
  void initState() {
    super.initState();
    passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose(); // คืนค่าทรัพยากร emailController[cite: 6]
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Password Strength
  int get passwordStrength {
    final password = passwordController.text;
    int score = 0;

    if (password.isEmpty) return 0;
    // At least 8 characters
    if (password.length >= 8) {
      score++;
    }

    // Uppercase and lowercase letters
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }

    // Numbers and special characters
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return score == 0 ? 1 : score;
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
                buildLoginLink(context),
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
      padding: EdgeInsets.fromLTRB(s16, topInset + s16, s16, s24),
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

          // Header Text
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create new account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: s8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Register Form
  Widget buildForm(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(s24, s24, s24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username
              _buildInputField(
                label: 'Username',
                hintText: 'username',
                controller: usernameController,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: s16),

              // Email [เพิ่มส่วนนี้][cite: 6]
              _buildInputField(
                label: 'Email',
                hintText: 'you@email.com',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: s16),

              // Password
              _buildInputField(
                label: 'Password',
                hintText: 'at least 8 characters',
                controller: passwordController,
                isPassword: true,
                obscure: obscurePassword,
                onToggleObscure: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: s8),

              // Password Strength Indicator
              _buildPasswordStrength(),

              const SizedBox(height: s16),

              // Confirm Password
              _buildInputField(
                label: 'Confirm Password',
                hintText: '........',
                controller: confirmPasswordController,
                isPassword: true,
                obscure: obscureConfirm,
                onToggleObscure: () {
                  setState(() {
                    obscureConfirm = !obscureConfirm;
                  });
                },
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: s16),

              // Terms and Conditions
              _buildTermsRow(),

              const SizedBox(height: s24),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isAcceptedTerms
                      ? () {
                          // TODO: Implement Register logic
                          // with Argon2id hash
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    disabledBackgroundColor: red.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign Up',
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

  // Password Strength Indicator
  Widget _buildPasswordStrength() {
    final strength = passwordStrength;

    final labels = ['', 'Weak', 'Medium', 'Strong'];

    final colors = [
      Colors.grey.shade300,
      Colors.redAccent,
      yellow,
      Colors.green,
    ];

    final activeColor = colors[strength];

    // Individual Strength Bar
    Widget bar(int index) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 4,
          decoration: BoxDecoration(
            color: strength > index ? activeColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            bar(0),
            const SizedBox(width: s4),
            bar(1),
            const SizedBox(width: s4),
            bar(2),
          ],
        ),

        const SizedBox(height: s4),

        Text(
          strength == 0
              ? 'Password Strength'
              : 'Password Strength: ${labels[strength]}',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  // Terms and Conditions
  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isAcceptedTerms,
            onChanged: (value) {
              setState(() {
                isAcceptedTerms = value ?? false;
              });
            },
            activeColor: red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        const SizedBox(width: s8),

        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'I accept the ',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),

              GestureDetector(
                onTap: () {
                  // TODO: Open Terms and Conditions
                },
                child: const Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 13,
                    color: red,
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

  // Login Link
  Widget buildLoginLink(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(s24, s24, s24, s16),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
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
                  color: red,
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

  // Reusable Input Field
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
        // Label
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: s8),

        // Text Field
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
        ),
      ],
    );
  }
}