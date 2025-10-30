import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/AuthProvide/authProvide.dart';
import 'package:tytan/screens/auth/forget.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/screens/bottomnavbar/bottomnavbar.dart';
import 'package:tytan/screens/constant/Appconstant.dart';
import 'package:tytan/screens/home/home_screen.dart';

class AuthScreen extends StatefulWidget {
  final int initialTabIndex;

  const AuthScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes for handling focus states
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // Form keys
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();

  // UI state
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Pre-fill email for demo
    _emailController.text = 'tecclubx@gmail.com';

    // Add listeners to focus nodes for UI updates
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<AuthProvide>(context);
    // Update loading state based on provider
    _isLoading = provider.isloading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40), // Reduced from 60
                    // Dynamic Title based on active tab
                    _buildHeader(),

                    const SizedBox(height: 25), // Reduced from 40
                    // Custom Tab Bar
                    _buildCustomTabBar(),

                    const SizedBox(height: 25), // Reduced from 40
                    // Form content with tab selection
                    Expanded(
                      child: _tabController.index == 0
                          ? SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: _buildLoginForm(),
                            )
                          : SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: _buildSignUpForm(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isLogin = _tabController.index == 0;
    return Column(
      children: [
        Text(
          isLogin ? 'Login' : 'Create Account',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28, // Reduced from 32
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        Text(
          isLogin
              ? 'Login your account to continue!'
              : 'Join million of users protecting their privacy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13, // Reduced from 14
            fontWeight: FontWeight.w400,
            color: AppColors.textGray,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 45, // Reduced from 50
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(22.5), // Adjusted to half of height
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(
            22.5,
          ), // Adjusted to half of height
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textGray,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15, // Reduced from 16
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15, // Reduced from 16
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Field
          _buildLabel('Email'),
          const SizedBox(height: 6), // Reduced from 8
          _buildEmailField(),

          const SizedBox(height: 18), // Reduced from 24
          // Password Field
          _buildLabel('Password'),
          const SizedBox(height: 6), // Reduced from 8
          _buildPasswordField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hintText: 'Enter your password',
            isVisible: _isPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),

          const SizedBox(height: 12), // Reduced from 16
          // Forgot Password
          // In AuthScreen class, in the _buildLoginForm method, update the Forgot Password section:
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),

          _buildActionButton(text: 'Login', onPressed: _handleLogin),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Email'),
          const SizedBox(height: 6),
          _buildEmailField(),

          const SizedBox(height: 18),

          _buildLabel('Password'),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hintText: 'Create a strong password',
            isVisible: _isPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),

          const SizedBox(height: 18),

          _buildLabel('Confirm Password'),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            hintText: 'Confirm your password',
            isVisible: _isConfirmPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),

          const SizedBox(height: 18), // Reduced from 24
          // Terms and Conditions
          _buildTermsCheckbox(),

          // Spacer - with reduced height
          const SizedBox(height: 100), // Reduced from 140
          // Create Account Button
          _buildActionButton(text: 'Create Account', onPressed: _handleSignUp),

          const SizedBox(height: 25), // Reduced from 30
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15, // Reduced from 16
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      height: 50, // Reduced from 56
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10), // Reduced from 12
        border: Border.all(
          color: _emailFocusNode.hasFocus
              ? AppColors.primary
              : Color(0xFF404040),
          width: _emailFocusNode.hasFocus ? 2.0 : 1.5,
        ),
        boxShadow: _emailFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: _emailController,
        focusNode: _emailFocusNode,
        keyboardType: TextInputType.emailAddress,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textWhite,
          fontSize: 15, // Reduced from 16
        ),
        decoration: InputDecoration(
          hintText: 'Enter your email',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textGray,
            fontSize: 15, // Reduced from 16
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, // Reduced from 16
            vertical: 14, // Reduced from 16
          ),
          suffixIcon: Icon(
            Icons.email_outlined,
            color: _emailFocusNode.hasFocus
                ? AppColors.primary
                : AppColors.textGray,
            size: 20, // Reduced from default 24
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
  }) {
    return Container(
      height: 50, // Reduced from 56
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.primary
              : const Color(0xFF404040),
          width: focusNode.hasFocus ? 2.0 : 1.5,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: !isVisible,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textWhite,
          fontSize: 15, // Reduced from 16
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textGray,
            fontSize: 15, // Reduced from 16
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, // Reduced from 16
            vertical: 14, // Reduced from 16
          ),
          suffixIcon: GestureDetector(
            onTap: onVisibilityToggle,
            child: Icon(
              isVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.textGray,
              size: 20, // Reduced from default 24
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _agreeToTerms = !_agreeToTerms;
            });
          },
          child: Container(
            width: 18, // Reduced from 20
            height: 18, // Reduced from 20
            decoration: BoxDecoration(
              color: _agreeToTerms ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: _agreeToTerms ? AppColors.primary : AppColors.textGray,
                width: 1.5, // Reduced from 2
              ),
              borderRadius: BorderRadius.circular(3), // Reduced from 4
            ),
            child: _agreeToTerms
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ) // Reduced from 14
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'I agree to the ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, // Reduced from 14
                color: AppColors.textGray,
              ),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, // Reduced from 14
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' and ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, // Reduced from 14
                    color: AppColors.textGray,
                  ),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, // Reduced from 14
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50, // Reduced from 56
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Reduced from 12
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20, // Reduced from 24
                height: 20, // Reduced from 24
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _handleLogin() async {
    // Unfocus any active fields first
    FocusScope.of(context).unfocus();

    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvide>(context, listen: false);
      authProvider.mailController.text = _emailController.text;
      authProvider.passwordController.text = _passwordController.text;

      await authProvider.login(context);

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSignUp() async {
    // Unfocus any active fields first
    FocusScope.of(context).unfocus();

    if (_signUpFormKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please agree to Terms of Service and Privacy Policy',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Passwords do not match',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvide>(context, listen: false);
      authProvider.mailController.text = _emailController.text;
      authProvider.passwordController.text = _passwordController.text;
      // For signup, we need to set username from the email since there's no username field in the UI
      authProvider.usernameController.text = _emailController.text.split(
        '@',
      )[0];

      await authProvider.signup(context);

      setState(() {
        _isLoading = false;
      });
    }
  }
}
