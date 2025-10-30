import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/AuthProvide/authProvide.dart';
import 'package:tytan/screens/auth/auth_screen.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/screens/constant/Appconstant.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late Animation<double> _logoAnimation;
  late Animation<double> _contentAnimation;

  int _selectedOption = -1; // Track which option is selected

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      _contentController.forward();
    });
  }

  void _selectOption(int index) async {
    print('Selected option: $index'); // Debug print
    setState(() {
      _selectedOption = index;
    });

    // Handle login option selection
    if (index == 0) {
      // Email login - Navigate to auth screen with Login tab active
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthScreen(initialTabIndex: 0),
        ),
      );
    } else if (index == 1) {
      // Google login - Call the googleSignIn method from AuthProvide
      final authProvider = Provider.of<AuthProvide>(context, listen: false);
      await authProvider.googleSignIn(context);
    } else if (index == 2) {
      // Apple ID login - Not implemented yet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apple ID login not implemented yet'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 5),

                // Logo Section
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Opacity(
                        opacity: _logoAnimation.value,
                        child: Center(
                          child: Image.asset(
                            'assets/Tytan Logo.png',
                            width: 160,
                            height: 180,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Welcome Title Section
                FadeTransition(
                  opacity: _contentAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Welcome To',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                          letterSpacing: -0.5,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Tytan ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'VPN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Login Options Section
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_contentAnimation),
                  child: FadeTransition(
                    opacity: _contentAnimation,
                    child: Column(
                      children: [
                        // Continue with Email
                        _buildLoginOption(
                          index: 0,
                          icon: Icons.email_outlined,
                          text: 'Continue with Email',
                          useCustomIcon: false,
                          onTap: () => _selectOption(0),
                        ),

                        const SizedBox(height: 16),

                        // Continue with Google
                        _buildLoginOption(
                          index: 1,
                          icon: Icons
                              .g_mobiledata, // This will be ignored when useCustomIcon is true
                          text: 'Continue with Google',
                          useCustomIcon: true,
                          customIconPath:
                              'assets/google (2).png', // Add your Google logo here
                          onTap: () => _selectOption(1),
                        ),

                        const SizedBox(height: 16),

                        // Continue with Apple ID
                        _buildLoginOption(
                          index: 2,
                          icon: Icons.apple,
                          text: 'Continue with Apple ID',
                          useCustomIcon: false,
                          onTap: () => _selectOption(2),
                        ),

                        const SizedBox(height: 32),

                        // Sign up option
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textGray,
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                // Navigate to auth screen with Sign Up tab active (index 1)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AuthScreen(initialTabIndex: 1),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign up',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginOption({
    required int index,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool useCustomIcon = false,
    String? customIconPath,
  }) {
    final isSelected = _selectedOption == index;
    final isEmailOption = index == -1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isEmailOption ? AppColors.primary : const Color(0xFF404040)),
            width: isSelected ? 1.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Custom Image
            useCustomIcon && customIconPath != null
                ? Image.asset(customIconPath, width: 24, height: 24)
                : Icon(
                    icon,
                    color: isSelected
                        ? AppColors.primary
                        : (isEmailOption
                              ? AppColors.primary
                              : AppColors.textWhite),
                    size: 24,
                  ),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isEmailOption ? AppColors.primary : AppColors.textWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
