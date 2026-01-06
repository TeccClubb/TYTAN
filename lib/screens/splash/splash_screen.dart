// ignore_for_file: use_super_parameters
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/screens/welcome/welcome.dart';
import 'package:tytan/screens/constant/Appconstant.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/screens/bottomnavbar/bottomnavbar.dart';
import 'package:tytan/Providers/AuthProvide/authProvide.dart';

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

  // VPN status rotation
  final List<String> _vpnStatusTexts = [
    'Initializing secure connection…',
    'Establishing secure tunnel',
    'Encrypting data traffic',
    'Masking IP address',
    'Applying DNS filtering',
    'Connection protected',
  ];

  int _currentStatusIndex = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    final provider = context.read<VpnProvide>();
    provider.init();

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadingController.forward();
    });

    // Rotate VPN status text
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _currentStatusIndex =
            (_currentStatusIndex + 1) % _vpnStatusTexts.length;
      });
    });

    // Navigate after loading completes
    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _statusTimer?.cancel();
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final String? appAccountToken = prefs.getString('app_account_token');

    final bool isLoggedIn =
        token != null && token.isNotEmpty ||
        appAccountToken != null && appAccountToken.isNotEmpty;

    if (isLoggedIn && mounted) {
      final provider = context.read<VpnProvide>();
      final authProvider = context.read<AuthProvide>();

      await Future.wait([
        provider.getServersPlease(true),
        provider.getUser(),
        provider.getPremium(context),
        provider.loadFavoriteServers(),
        provider.loadSelectedServerIndex(),
      ]);

      provider.lProtocolFromStorage();
      provider.myAutoConnect();
      provider.loadKillSwitchState();
      provider.loadAdBlocker();
      provider.loadDnsLeakProtection();
      authProvider.getGuestUser();

      if (provider.servers.isNotEmpty) {
        final currentIndex = provider.selectedServerIndex;
        final isInvalidIndex =
            currentIndex == 0 || currentIndex >= provider.servers.length;

        final isNonPremiumWithPremiumServer =
            !provider.isPremium &&
                !isInvalidIndex &&
                provider.servers[currentIndex].type
                    .toLowerCase()
                    .contains('premium');

        if (isInvalidIndex || isNonPremiumWithPremiumServer) {
          if (provider.isPremium) {
            await provider.selectFastestServerByHealth();
          } else {
            await provider.selectFastestServerByHealth(freeOnly: true);
          }
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const BottomNavBar() : const WelcomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
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

                // Logo
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Opacity(
                        opacity: _logoAnimation.value,
                        child: Image.asset(
                          'assets/Tytan Logo.png',
                          width: 200,
                          height: 218,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Title
                FadeTransition(
                  opacity: _logoAnimation,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tytan ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 39,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'VPN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 39,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure and Quick',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
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
                                  width: MediaQuery.of(context).size.width *
                                      0.8 *
                                      _loadingAnimation.value,
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

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _vpnStatusTexts[_currentStatusIndex],
                              key: ValueKey(_currentStatusIndex),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textGray,
                              ),
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
