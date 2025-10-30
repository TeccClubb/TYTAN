import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tytan/screens/background/map.dart';
import 'package:tytan/screens/constant/Appconstant.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/screens/premium/premium.dart';
import 'package:tytan/screens/server/server_screen.dart';
import 'dart:async';

enum ConnectionState { disconnected, connecting, connected }

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToServers;

  const HomeScreen({Key? key, this.onNavigateToServers}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
        await provider.getPremium();
        provider.lProtocolFromStorage();
        provider.myAutoConnect();
        provider.myKillSwitch();

        // Load servers
        await provider.getServersPlease(true);

        await provider.loadFavoriteServers();
        await provider.loadSelectedServerIndex();

        // Auto-select fastest server if no valid server is selected
        if (provider.servers.isNotEmpty) {
          if (provider.selectedServerIndex == 0 ||
              provider.selectedServerIndex >= provider.servers.length) {
            await provider.selectFastestServerByHealth();
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

  Future<void> _toggleConnection() async {
    final provider = context.read<VpnProvide>();

    // Prevent action if already in a transitional state
    if (provider.isloading) {
      return;
    }

    // If currently connected, show disconnecting animation before actual disconnect
    if (provider.vpnConnectionStatus == VpnStatusConnectionStatus.connected) {
      // Call toggleVpn (which will set status to disconnecting and stop timer)
      final disconnectFuture = provider.toggleVpn();

      // Wait 10 seconds to show the disconnecting animation
      await Future.delayed(const Duration(seconds: 10));

      // Wait for actual disconnection to complete
      await disconnectFuture;
    } else {
      // Connecting - just proceed normally (timer will be started in provider)
      await provider.toggleVpn();
    }
  }

  ConnectionState _getConnectionState(VpnProvide provider) {
    switch (provider.vpnConnectionStatus) {
      case VpnStatusConnectionStatus.connected:
        return ConnectionState.connected;
      case VpnStatusConnectionStatus.connecting:
      case VpnStatusConnectionStatus.reconnecting:
        return ConnectionState.connecting;
      case VpnStatusConnectionStatus.disconnecting:
        return ConnectionState
            .connecting; // Use connecting view for disconnecting animation
      case VpnStatusConnectionStatus.disconnected:
        return ConnectionState.disconnected;
    }
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
    final connectionState = _getConnectionState(provider);

    // Show different content based on connection state
    switch (connectionState) {
      case ConnectionState.connecting:
        return _buildConnectingView();
      case ConnectionState.connected:
        return _buildConnectedView();
      case ConnectionState.disconnected:
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
              Image.asset('assets/Tytan Logo.png', width: 40, height: 40),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tytan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'VPN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
              Text(
                'Secure and Quick',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGray,
                ),
              ),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.textGray, width: 1),
              ),
              child: Center(
                child: Image.asset('assets/i.png', width: 20, height: 20),
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        // Timer
        Text(
          '00:00:00',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFA0A0A0),
          ),
        ),
        const SizedBox(height: 50),

        // Power Button
        GestureDetector(
          onTap: _toggleConnection,
          child: Container(
            width: 120,
            height: 120,
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
                size: 50,
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
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  // Server Flag
                  if (selectedServer != null)
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: selectedServer.image,
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
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
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
                          selectedServer?.name ?? 'Loading...',
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
    final provider = context.watch<VpnProvide>();
    final selectedServer =
        provider.servers.isNotEmpty &&
            provider.selectedServerIndex < provider.servers.length
        ? provider.servers[provider.selectedServerIndex]
        : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Connecting Animation
        AnimatedBuilder(
          animation: _connectingAnimationController,
          builder: (context, child) {
            return SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating circle
                  Transform.rotate(
                    angle: _connectingAnimationController.value * 2 * 3.14159,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppColors.primary.withOpacity(0),
                            AppColors.primary.withOpacity(0.8),
                            AppColors.primary.withOpacity(0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Middle dotted circle
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          painter: DottedCirclePainter(
                            color: Colors.white.withOpacity(0.5),
                            dottedLength: 5,
                            spaceLength: 5,
                          ),
                        );
                      },
                    ),
                  ),

                  // Inner orange circle
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E1E1E),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/Tytan Logo.png',
                          width: 60,
                          height: 60,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 30),

        // Connecting Text
        Center(
          child: Text(
            provider.vpnConnectionStatus ==
                    VpnStatusConnectionStatus.disconnecting
                ? 'Disconnecting....'
                : 'Connecting....',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Server Name
        Text(
          selectedServer?.name ?? 'Selecting server...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        // Timer
        Text(
          provider.getFormattedDuration(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFA0A0A0),
          ),
        ),
        const SizedBox(height: 50),

        // Power Button
        GestureDetector(
          onTap: _toggleConnection,
          child: Container(
            width: 120,
            height: 120,
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
                size: 50,
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
                    '${provider.downloadSpeed} Kb/s',
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
                    '${provider.uploadSpeed} Kb/s',
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
                      if (selectedServer != null)
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: selectedServer.image,
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
                        )
                      else
                        Container(
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedServer?.name ?? 'No Server',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            selectedServer?.type ?? 'N/A',
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
