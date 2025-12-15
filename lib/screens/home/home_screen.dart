// ignore_for_file: deprecated_member_use, use_super_parameters
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/ReusableWidgets/customSnackBar.dart' show showCustomSnackBar;
import 'package:tytan/screens/background/map.dart';
import 'package:tytan/screens/premium/premium.dart';
import 'package:tytan/screens/constant/Appconstant.dart';
import 'package:tytan/screens/server/server_screen.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToServers;

  const HomeScreen({Key? key, this.onNavigateToServers}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // For connecting animation
  late AnimationController _connectingAnimationController;

  @override
  void initState() {
    super.initState();

    // Setup animation controller for connecting animation
    _connectingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Load data only if not already loaded (from splash screen)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<VpnProvide>();

      // Only load if servers are empty (means user came directly without splash)
      if (provider.servers.isEmpty) {
        // Load user data and premium status first
        await provider.getUser();
        await provider.getPremium(context);
        provider.lProtocolFromStorage();
        provider.myAutoConnect();
        // provider.myKillSwitch();

        // Load servers
        await provider.getServersPlease(true);

        await provider.loadFavoriteServers();
        await provider.loadSelectedServerIndex();

        // Auto-select fastest server if no valid server is selected
        // OR if user is not premium but has a premium server selected
        if (provider.servers.isNotEmpty) {
          final currentIndex = provider.selectedServerIndex;
          final isInvalidIndex = currentIndex == 0 || currentIndex >= provider.servers.length;
          final isNonPremiumWithPremiumServer = !provider.isPremium && 
              !isInvalidIndex && 
              provider.servers[currentIndex].type.toLowerCase() == 'premium';
          
          if (isInvalidIndex || isNonPremiumWithPremiumServer) {
            if (provider.isPremium) {
              await provider.selectFastestServerByHealth();
            } else {
              await provider.selectFastestServerByHealth(freeOnly: true);
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _connectingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WorldMapBackground(
        child: SafeArea(
          child: Column(children: [Expanded(child: _buildContent())]),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final provider = context.watch<VpnProvide>();

    // Show different content based on connection state
    switch (provider.vpnConnectionStatus) {
      case VpnStatusConnectionStatus.connecting:
        return _buildConnectingView();
      case VpnStatusConnectionStatus.connected:
        return _buildConnectedView();
      case VpnStatusConnectionStatus.disconnected:
        return _buildDisconnectedView();
      case VpnStatusConnectionStatus.disconnecting:
        return _buildConnectingView();
      case VpnStatusConnectionStatus.reconnecting:
        return _buildDisconnectedView();
    }
  }

  Widget _buildAppHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/Tytan Logo.png', width: 44, height: 44),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tytan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'VPN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Secure and Quick',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
            ],
          ),

          GestureDetector(
            onTap: () {
              // Handle info icon tap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
            },
            child: Container(
              // width: 36,
              // height: 36,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.transparent.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Image.asset('assets/premium.png', width: 20, height: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedView() {
    final provider = context.watch<VpnProvide>();
    final selectedServer =
        provider.servers.isNotEmpty &&
            provider.selectedServerIndex < provider.servers.length
        ? provider.servers[provider.selectedServerIndex]
        : null;

    return Column(
      children: [
        _buildAppHeader(),
        const Spacer(flex: 1),
        // Status Text
        Text(
          'Disconnected',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF1706),
          ),
        ),
        const SizedBox(height: 10),
        // Timer
        Text(
          "00:00:00",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 50),

        // Power Button
        GestureDetector(
          onTap: () async {
            // Ensure we have servers
            if (provider.servers.isEmpty) {
              showCustomSnackBar(
                context,
                Icons.error,
                'No servers',
                'No servers available to connect.',
                Colors.red,
              );
              return;
            }

            final selectedServer = provider.servers[provider.selectedServerIndex];
            final isServerPremium = selectedServer.type.toLowerCase() == 'premium';

            if (isServerPremium && !provider.isPremium) {
              // Block non-premium users from connecting to premium servers
              showCustomSnackBar(
                context,
                Icons.lock,
                'Premium Required',
                '${selectedServer.name} is available for premium users only.',
                Colors.orange,
              );
              return;
            }

            await provider.toggleVpn();
          },
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(70),
            ),
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
        ),

        const Spacer(flex: 1),

        // Show Selected Server for all users - No Premium Widget
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: GestureDetector(
            onTap: () {
              // If callback exists (bottom nav), use it to switch tabs
              if (widget.onNavigateToServers != null) {
                widget.onNavigateToServers!();
              } else {
                // Otherwise, push to servers screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServersScreen(),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: const Color(0xFF2A2A2A)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  // Server Flag
                  Builder(
                    builder: (context) {
                      final hasValidServer = selectedServer != null && (selectedServer.image ?? '').isNotEmpty;

                      if (hasValidServer) {
                        return ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: selectedServer.image!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              child: const Icon(
                                Icons.flag,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }

                      // Fallback placeholder when no image/selected server
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        child: const Icon(Icons.flag, color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Server',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.servers.isNotEmpty &&
                                  provider.selectedServerIndex >= 0 &&
                                  provider.selectedServerIndex <
                                      provider.servers.length
                              ? provider
                                    .servers[provider.selectedServerIndex]
                                    .name
                              : 'No server selected',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_right,
                    color: AppColors.textGray,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingView() {
    var provider = context.watch<VpnProvide>();

    var selectedServer = provider.servers.isNotEmpty &&
            provider.selectedServerIndex < provider.servers.length
        ? provider.servers[provider.selectedServerIndex]
        : null;

    final bool isDisconnecting = provider.vpnConnectionStatus == VpnStatusConnectionStatus.disconnecting;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // Modern Connecting Animation
        AnimatedBuilder(
          animation: _connectingAnimationController,
          builder: (context, child) {
            final animValue = _connectingAnimationController.value;
            final pulseValue = 0.95 + 0.1 * math.sin(animValue * 2 * math.pi);
            final glowOpacity = 0.3 + 0.3 * math.sin(animValue * 2 * math.pi);

            return SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outermost pulsing glow
                  Transform.scale(
                    scale: pulseValue,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.0),
                            AppColors.primary.withOpacity(0.05),
                            AppColors.primary.withOpacity(glowOpacity * 0.15),
                          ],
                          stops: const [0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Rotating gradient arc - outer
                  Transform.rotate(
                    angle: animValue * 2 * math.pi,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppColors.primary.withOpacity(0),
                            AppColors.primary.withOpacity(0.5),
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.5),
                            AppColors.primary.withOpacity(0),
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Counter-rotating inner arc
                  Transform.rotate(
                    angle: -animValue * 2 * math.pi * 0.7,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary.withOpacity(0.25),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Dotted orbit circle
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: CustomPaint(
                      painter: DottedCirclePainter(
                        color: AppColors.primary.withOpacity(0.35),
                        dottedLength: 4,
                        spaceLength: 8,
                      ),
                    ),
                  ),

                  // Orbiting particles
                  ...List.generate(6, (index) {
                    final particleAngle =
                        (animValue * 2 * math.pi * 0.5) + (index * math.pi / 3);
                    final radius = 85.0;
                    final particleSize = 4.0 + (index % 3) * 1.5;
                    final opacity = 0.4 + (index % 3) * 0.2;
                    return Positioned(
                      left:
                          140 +
                          radius * math.cos(particleAngle) -
                          particleSize / 2,
                      top:
                          140 +
                          radius * math.sin(particleAngle) -
                          particleSize / 2,
                      child: Container(
                        width: particleSize,
                        height: particleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(opacity),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Glowing background behind center
                  Container(
                    width: 135,
                    height: 135,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(
                            glowOpacity * 0.6,
                          ),
                          blurRadius: 35,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),

                  // Center circle with gradient border
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A1A),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Transform.scale(
                            scale: 0.95 + (pulseValue - 0.95) * 0.3,
                            child: Image.asset(
                              'assets/Tytan Logo.png',
                              width: 55,
                              height: 55,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 40),

        // Status Text with animated dots
        AnimatedBuilder(
          animation: _connectingAnimationController,
          builder: (context, child) {
            final dotOpacity1 =
                (_connectingAnimationController.value * 3) % 1.0 > 0.33
                ? 1.0
                : 0.3;
            final dotOpacity2 =
                (_connectingAnimationController.value * 3) % 1.0 > 0.66
                ? 1.0
                : 0.3;
            final dotOpacity3 =
                (_connectingAnimationController.value * 3) % 1.0 > 0.9
                ? 1.0
                : 0.3;

            return Column(
              children: [
                Text(
                  isDisconnecting ? 'Disconnecting' : 'Connecting',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedDot(dotOpacity1),
                    const SizedBox(width: 6),
                    _buildAnimatedDot(dotOpacity2),
                    const SizedBox(width: 6),
                    _buildAnimatedDot(dotOpacity3),
                  ],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 30),

        // Server info card
        if (selectedServer != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.85),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((selectedServer.image ?? '').isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: selectedServer.image!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Text(
                  selectedServer.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${selectedServer.id}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Spacer(flex: 3),

        // Secure connection indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                isDisconnecting
                    ? 'Securing your data...'
                    : 'Establishing secure tunnel...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for animated dots
  Widget _buildAnimatedDot(double opacity) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(opacity),
      ),
    );
  }

  Widget _buildConnectedView() {
    final provider = context.watch<VpnProvide>();
    final selectedServer =
        provider.servers.isNotEmpty &&
            provider.selectedServerIndex < provider.servers.length
        ? provider.servers[provider.selectedServerIndex]
        : null;

    return Column(
      children: [
        _buildAppHeader(),
        const Spacer(flex: 1),
        // Status Text
        Text(
          'Connected',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF02F30A),
          ),
        ),
        const SizedBox(height: 10),
        // Timer
        Text(
          provider.getFormattedDuration(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),

        // Power Button
        // Power Button
        GestureDetector(
          onTap: provider.toggleVpn,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(70),
            ),
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Connection Status Message
        Text(
          'Your connection is protected',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 30),

        // Speed Metrics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Download
              Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: Colors.amber[400],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'DOWNLOAD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${provider.downloadSpeed} ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.textGray.withOpacity(0.5),
              ),

              // Upload
              Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 16,
                        color: Colors.teal[300],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'UPLOAD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.teal[300],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${provider.uploadSpeed}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Spacer(flex: 1),

        // Current Server Status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              // If callback exists (bottom nav), use it to switch tabs
              if (widget.onNavigateToServers != null) {
                widget.onNavigateToServers!();
              } else {
                // Otherwise, push to servers screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServersScreen(),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Country Flag
                      Builder(
                        builder: (context) {
                          final hasValidServer =
                              selectedServer != null &&
                              (selectedServer.image ?? '').isNotEmpty;

                          if (hasValidServer) {
                            return ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: selectedServer.image!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green.withOpacity(0.1),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green.withOpacity(0.1),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.flag,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          }

                          // Fallback placeholder when no image/selected server
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.flag,
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.servers.isNotEmpty &&
                                    provider.selectedServerIndex >= 0 &&
                                    provider.selectedServerIndex <
                                        provider.servers.length
                                ? provider
                                      .servers[provider.selectedServerIndex]
                                      .name
                                : 'No server selected',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            (selectedServer?.subServers.isNotEmpty ?? false)
                                ? selectedServer!.subServers.first.name
                                : 'N/A',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Signal Strength (based on health_score if available)
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 3,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 3,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 3,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColors.textGray,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// Helper painter for dotted circle effect
class DottedCirclePainter extends CustomPainter {
  final Color color;
  final double dottedLength;
  final double spaceLength;

  DottedCirclePainter({
    required this.color,
    required this.dottedLength,
    required this.spaceLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double totalLength = dottedLength + spaceLength;
    final double radius = size.width / 2;
    final double circumference = 2 * 3.14159 * radius;
    final int segments = (circumference / totalLength).floor();

    for (int i = 0; i < segments; i++) {
      final double startAngle = (i * totalLength) / radius;
      final double endAngle = (i * totalLength + dottedLength) / radius;

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: radius,
        ),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
