import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/screens/constant/Appconstant.dart';
import 'package:tytan/screens/welcome/welcome.dart';
import 'package:tytan/screens/bottomnavbar/bottomnavbar.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late Animation<double> _logoAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadingController.forward();
    });

    // Navigate to next screen after loading completes
    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  // In your splash screen _navigateToNextScreen method, change it to:
  Future<void> _navigateToNextScreen() async {
    // Check if user is already logged in
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final bool isLoggedIn = token != null && token.isNotEmpty;

    // If user is logged in, preload servers and user data
    if (isLoggedIn && mounted) {
      final provider = context.read<VpnProvide>();

      // Preload all necessary data in parallel
      await Future.wait([
        provider.getServersPlease(true),
        provider.getUser(),
        provider.getPremium(),
        provider.loadFavoriteServers(),
        provider.loadSelectedServerIndex(),
      ]);

      // Load protocol, auto-connect, and kill switch settings (synchronous)
      provider.lProtocolFromStorage();
      provider.myAutoConnect();
      provider.myKillSwitch();

      // Auto-select fastest server if no valid server is selected
      if (provider.servers.isNotEmpty &&
          (provider.selectedServerIndex == 0 ||
              provider.selectedServerIndex >= provider.servers.length)) {
        await provider.selectFastestServerByHealth();
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Navigate to Home if logged in, otherwise to Welcome screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            isLoggedIn ? const BottomNavBar() : const WelcomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
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

                // Logo Section with Animation
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
                            width: 200,
                            height: 218,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Title Section
                FadeTransition(
                  opacity: _logoAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Tytan VPN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 39,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure and Quick',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Loading Section
                AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loadingAnimation.value,
                      child: Column(
                        children: [
                          // Loading Bar
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.loadingBarGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: Duration.zero,
                                  width:
                                      MediaQuery.of(context).size.width *
                                      0.8 *
                                      _loadingAnimation
                                          .value, // Changed from 0.3 to 0.8 for full width
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Initializing secure connection...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
