import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/screens/premium/premium.dart';
import 'package:tytan/screens/setting/Account.dart';
import 'package:tytan/screens/setting/feedback.dart';
import 'package:tytan/screens/setting/protocol.dart';
import 'package:tytan/screens/tunneling/tunneling.dart';
import 'package:tytan/screens/constant/Appconstant.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/Providers/AuthProvide/authProvide.dart' show AuthProvide;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Toggle states (only for features not in VPN provider)

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<VpnProvide>();
    var authProvide = context.watch<AuthProvide>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Connection Section
                      _buildSectionCard(
                        title: 'Connection',
                        image: 'assets/wifi.png',
                        iconBackgroundColor: AppColors.primary,
                        children: [
                          _buildToggleSetting(
                            title: 'Auto-Connect',
                            subtitle: 'Connect to fastest server',
                            icon: Icons.bolt,
                            iconColor: AppColors.primary,
                            value: provider.autoConnectOn,
                            onChanged: (value) {
                              provider.toggleAutoConnectState();
                            },
                          ),
                          SizedBox(height: 6),
                          _buildNavigationSetting(
                            title: 'Protocol',
                            subtitle: provider.getProtocolDisplayName(
                              provider.selectedProtocol,
                            ),
                            icon: Icons.dns,
                            iconColor: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProtocolScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 6),
                          _buildServerLocationName(
                            title: 'Server Location',
                            subtitle:
                                provider.selectedServerIndex <
                                    provider.servers.length
                                ? "${provider.servers[provider.selectedServerIndex].name} "
                                : 'Select Server',
                            icon: Icons.public,
                            iconColor: AppColors.primary,
                            onTap: () {
                              // Navigate to server selection
                            },
                            isLastItem: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Security Section
                      _buildSectionCard(
                        title: 'Security',
                        image: 'assets/sheild.png',
                        iconBackgroundColor: AppColors.primary,
                        children: [
                          _buildToggleSetting(
                            title: 'Kill Switch',
                            subtitle: 'Block internet if VPN drops',
                            icon: Icons.power_settings_new,
                            iconColor: AppColors.primary,
                            value: provider.killSwitchOn,
                            onChanged: (value) {
                              provider.toggleKillSwitchState(context);
                            },
                          ),
                          SizedBox(height: 15),
                          _buildToggleSetting(
                            title: 'DNS Leak Protection',
                            subtitle: 'Prevent DNS leaks',
                            icon: Icons.visibility_off_outlined,
                            iconColor: AppColors.primary,
                            value: provider.dnsLeakProtection,
                            onChanged: (value) {
                              provider.toggleDnsLeakProtection();
                            },
                          ),
                          SizedBox(height: 15),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const Tunneling(),
                                ),
                              );
                            },
                            child: _buildToggleSetting1(
                              title: 'Split Tunneling',
                              subtitle: 'Manage apps using VPN',
                              icon: Icons.call_split,
                              iconColor: AppColors.primary,
                              value: false,
                              onChanged: (value) {},
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildToggleSetting(
                            title: 'AD Block',
                            subtitle: 'Block ads and trackers',
                            icon: Icons.block,
                            iconColor: AppColors.primary,
                            value: provider.adBlockerEnabled,
                            onChanged: (value) {
                              provider.toggleAdBlocker();
                            },
                            isLastItem: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Account Section
                      _buildSectionCard(
                        title: 'Account',
                        image: 'assets/person.png',
                        iconBackgroundColor: AppColors.primary,
                        children: [
                          _buildProfileSetting(
                            email: provider.user.isNotEmpty
                                ? '${provider.user.first.email}'
                                : authProvide.guestUser != null
                                ? '${authProvide.guestUser?.email}'
                                : 'loading...',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccountScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 10),
                          _buildNavigationSetting(
                            title: 'Premium Plan',
                            subtitle: provider.user.isEmpty
                                ? 'Your subscription details'
                                : authProvide.guestUser != null
                                ? 'Your subscription details'
                                : 'Upgrade to premium',
                            icon: Icons.star,
                            iconColor: Colors.amber,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PremiumScreen(),
                                ),
                              ); // Navigate to subscription details
                            },
                          ),
                          SizedBox(height: 10),
                          _buildNavigationSetting(
                            title: 'Feedback',
                            subtitle: 'Help us improve our app',
                            icon: Icons.feedback_outlined,
                            iconColor: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FeedbackScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 15),
                          _buildNavigationSetting(
                            title: 'Sign Out',
                            subtitle: 'Logout from this device',
                            icon: Icons.logout,
                            iconColor: Colors.red.shade300,
                            onTap: () async {
                              var provider = Provider.of<VpnProvide>(
                                context,
                                listen: false,
                              );

                              // Disconnect VPN if connected
                              if (provider.vpnConnectionStatus ==
                                      VpnStatusConnectionStatus.connected ||
                                  provider.vpnConnectionStatus ==
                                      VpnStatusConnectionStatus.connecting) {
                                await provider.toggleVpn();
                                // Wait for disconnection to complete
                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );
                              }

                              // Perform logout - this will clear data and navigate to WelcomeScreen
                              await provider.logout(context);
                            },
                            isLastItem: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Text(
        'Setting',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color iconBackgroundColor,
    required List<Widget> children,
    required String image,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Updated to 0xFF1A1A1A
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),

      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(image, color: Colors.white, scale: 4),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLastItem = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Using CupertinoSwitch instead of regular Switch
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting1({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    // bool isLastItem = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Using CupertinoSwitch instead of regular Switch
              // CupertinoSwitch(
              //   value: value,
              //   onChanged: onChanged,
              //   activeColor: AppColors.primary,
              //   trackColor: Colors.grey.shade700,
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLastItem = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServerLocationName({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLastItem = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // const Icon(
                //   Icons.arrow_forward_ios,
                //   color: Colors.grey,
                //   size: 16,
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSetting({
    required String email,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Profile Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue, Colors.purple, Colors.red],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFF2A2A2A), height: 1, thickness: 1),
      ],
    );
  }
}
