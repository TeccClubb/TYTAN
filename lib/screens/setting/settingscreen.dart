import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/Providers/LanguageProvide/languageProvide.dart';
import 'package:tytan/Screens/language/initial_language_selection.dart'
    show InitialLanguageSelectionScreen;
import 'package:tytan/Screens/premium/premium.dart';
import 'package:tytan/Screens/setting/Account.dart';
import 'package:tytan/Screens/setting/protocol.dart';
import 'package:tytan/Screens/tunneling/tunneling.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/Screens/setting/contactus.dart' show ContactSupport;
import 'package:tytan/Providers/AuthProvide/authProvide.dart' show AuthProvide;
import 'package:tytan/Defaults/extensions.dart';

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
                        title: 'connection'.tr(context),
                        image: 'assets/wifi.png',
                        iconBackgroundColor: AppColors.primary,
                        children: [
                          _buildToggleSetting(
                            title: 'auto_connect'.tr(context),
                            subtitle: 'auto_connect_desc'.tr(context),
                            icon: Icons.bolt,
                            iconColor: AppColors.primary,
                            value: provider.autoConnectOn,
                            onChanged: (value) {
                              provider.toggleAutoConnectState();
                            },
                          ),
                          SizedBox(height: 6),
                          _buildNavigationSetting(
                            title: 'protocol'.tr(context),
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
                            title: 'server_location'.tr(context),
                            subtitle:
                                provider.selectedServerIndex <
                                    provider.servers.length
                                ? "${provider.servers[provider.selectedServerIndex].name} "
                                : 'select_server'.tr(context),
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
                        title: 'security_privacy'.tr(context),
                        image: 'assets/sheild.png',
                        iconBackgroundColor: AppColors.primary,
                        children: [
                          _buildToggleSetting(
                            title: 'kill_switch'.tr(context),
                            subtitle: 'kill_switch_desc'.tr(context),
                            icon: Icons.power_settings_new,
                            iconColor: AppColors.primary,
                            value: provider.killSwitchOn,
                            onChanged: (value) {
                              provider.toggleKillSwitchState(context);
                            },
                          ),
                          SizedBox(height: 15),
                          _buildToggleSetting(
                            title: 'dns_leak_protection'.tr(context),
                            subtitle: 'dns_protection_desc'.tr(context),
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
                              title: 'split_tunneling'.tr(context),
                              subtitle: 'split_tunneling_desc'.tr(context),
                              icon: Icons.call_split,
                              iconColor: AppColors.primary,
                              value: false,
                              onChanged: (value) {},
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildToggleSetting(
                            title: 'ad_block'.tr(context),
                            subtitle: 'ad_block_desc'.tr(context),
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
                        title: 'account_system'.tr(context),
                        image: 'assets/person.png',
                        iconBackgroundColor: AppColors.primary,
                        children: [
                          _buildProfileSetting(
                            email: provider.user.isNotEmpty
                                ? '${provider.user.first.email}'
                                : authProvide.guestUser != null
                                ? '${authProvide.guestUser?.email}'
                                : 'loading...'.tr(context),
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
                            title: 'premium_plan'.tr(context),
                            subtitle: provider.user.isEmpty
                                ? 'subscription_details'.tr(context)
                                : authProvide.guestUser != null
                                ? 'subscription_details'.tr(context)
                                : 'upgrade_to_premium_q'.tr(context),
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
                            title: 'contact_support'.tr(context),
                            subtitle: 'help_improve'.tr(context),
                            icon: Icons.feedback_outlined,
                            iconColor: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ContactSupport(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 15),
                          _buildNavigationSetting(
                            title: 'language'.tr(context),
                            subtitle: 'change_language'.tr(context),
                            icon: Icons.language,
                            iconColor: AppColors.primary,
                            onTap: () {
                              var provider = Provider.of<LanguageProvider>(
                                context,
                                listen: false,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InitialLanguageSelectionScreen(
                                        onLanguageSelected: (language) {
                                          provider.changeLanguage(language);
                                        },
                                      ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 15),
                          _buildNavigationSetting(
                            title: 'sign_out'.tr(context),
                            subtitle: 'logout_desc'.tr(context),
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
        'setting'.tr(context),
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
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
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
