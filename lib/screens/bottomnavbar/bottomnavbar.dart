// ignore_for_file: file_names
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tytan/screens/constant/Appconstant.dart';
import 'package:tytan/screens/home/home_screen.dart';
import 'package:tytan/screens/server/server_screen.dart';
import 'package:tytan/screens/setting/setting_screen.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  // Current tab index (starts at 0 for Home screen)
  var currentIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    // Auto-connect when app starts (only if not already connected)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnect();
    });
  }

  Future<void> _autoConnect() async {
    final provider = Provider.of<VpnProvide>(context, listen: false);
    // Only auto-connect if VPN is disconnected
    if (provider.vpnConnectionStatus ==
        VpnStatusConnectionStatus.disconnected) {
      await provider.autoC(context);
    }
  }

  // Method to get current page with callback
  Widget _getCurrentPage() {
    switch (currentIndex.value) {
      case 0:
        return HomeScreen(
          onNavigateToServers: () {
            // When home screen wants to navigate to servers
            setState(() {
              currentIndex.value = 1;
            });
          },
        );
      case 1:
        return ServersScreen(
          onServerSelected: () {
            // When user selects a server, switch to Home screen
            setState(() {
              currentIndex.value = 0;
            });
          },
        );
      case 2:
        return const SettingsScreen();
      default:
        return HomeScreen(
          onNavigateToServers: () {
            setState(() {
              currentIndex.value = 1;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      left: false,
      right: false,
      child: Obx(
        () => Scaffold(
          body: _getCurrentPage(),
          bottomNavigationBar: Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, "Home", 0),
                _buildNavItem(Icons.dns_rounded, "Servers", 1),
                _buildNavItem(Icons.settings, "Setting", 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = currentIndex.value == index;
    final Color itemColor = isSelected ? AppColors.primary : Colors.grey;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex.value = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: itemColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
