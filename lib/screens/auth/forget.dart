import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/AuthProvide/authProvide.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/screens/constant/Appconstant.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controller
  final TextEditingController _emailController = TextEditingController();

  // Focus node
  final FocusNode _emailFocusNode = FocusNode();

  // Form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // UI state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

    // Initialize provider with email value
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvide>(context, listen: false);
      authProvider.mailController.text = _emailController.text;
    });

    // Add listener to focus node for UI updates
    _emailFocusNode.addListener(() => setState(() {}));

    // Add listener to sync email field with provider
    _emailController.addListener(() {
      Future.microtask(() {
        if (mounted) {
          final authProvider = Provider.of<AuthProvide>(context, listen: false);
          authProvider.mailController.text = _emailController.text;
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();

    // Clear the provider's email when we leave this screen
    Future.microtask(() {
      if (mounted) {
        try {
          final authProvider = Provider.of<AuthProvide>(context, listen: false);
          authProvider.mailController.text = '';
        } catch (e) {
          // Handle case where provider is not available
        }
      }
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get loading state from AuthProvide
    final authProvider = Provider.of<AuthProvide>(context);
    _isLoading = authProvider.isloading;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Back button
                    _buildBackButton(),

                    const SizedBox(height: 30),

                    // Header section
                    _buildHeader(),

                    const SizedBox(height: 40),

                    // Form section
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: _buildForm(),
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(22.5),
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Text(
            'Forgot Password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please enter your email we will send you\npassword reset link to your email.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textGray,
              letterSpacing: 0.2,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Label
          Text(
            'Email',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 6),

          // Email Field
          _buildEmailField(),

          const SizedBox(height: 40),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _emailFocusNode.hasFocus
              ? AppColors.primary
              : AppColors.primary,
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
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your email',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textGray,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIcon: Icon(
            Icons.email_outlined,
            color: _emailFocusNode.hasFocus
                ? AppColors.primary
                : AppColors.textGray,
            size: 20,
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

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Submit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _handleSubmit() async {
    // Unfocus any active fields first
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Get AuthProvide instance
      final authProvider = Provider.of<AuthProvide>(context, listen: false);
      // Set email in provider's controller
      authProvider.mailController.text = _emailController.text;

      // Call forgot password API
      await authProvider.forgotPassword(context);

      setState(() {
        _isLoading = false;
      });

      // Optional: Go back to login screen after a delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    }
  }
}
