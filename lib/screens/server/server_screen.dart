// ignore_for_file: use_super_parameters, unnecessary_null_comparison
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:tytan/screens/premium/premium.dart';
import 'package:tytan/DataModel/serverDataModel.dart';
import 'package:tytan/screens/constant/Appconstant.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';

class ServersScreen extends StatefulWidget {
  final VoidCallback? onServerSelected;

  const ServersScreen({Key? key, this.onServerSelected}) : super(key: key);

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VpnProvide>().loadFavoriteServers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VpnProvide>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(provider),
              const SizedBox(height: 20),
              _buildQuickAction(provider),
              const SizedBox(height: 20),
              _buildRegionFilter(),
              const SizedBox(height: 20),
              _buildServerList(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Text(
        'Select Location',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar(VpnProvide provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: const Color(0xFF2A2A2A)),

          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: provider.setQueryText,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search countries or cities...',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: Colors.grey,
              fontSize: 15,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionFilter() {
    final regions = ['All', 'Free', 'Premium'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: regions
              .map(
                (region) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRegion = region;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedRegion == region
                            ? AppColors.primary
                            : const Color(0xFF1E1E1E),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        region,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedRegion == region
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildQuickAction(VpnProvide provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Fastest Server (Free servers only)
          GestureDetector(
            onTap: () async {
              log('Fastest Server button tapped');

              if (provider.servers.isEmpty) {
                log('No servers available');
                return;
              }

              log('Total servers available: ${provider.servers.length}');

              // Filter only free servers
              final freeServers = provider.servers
                  .where((server) => server.type.toLowerCase() != 'premium')
                  .toList();

              log('Free servers found: ${freeServers.length}');

              if (freeServers.isEmpty) {
                log('No free servers available - showing error message');
                _showNoServersAvailableMessage('No free servers available');
                return;
              }

              // Get last rotation index from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              int lastRotationIndex =
                  prefs.getInt('fastest_server_rotation_index') ?? -1;

              log('Last rotation index from storage: $lastRotationIndex');

              // Cycle through free servers - select next one each time
              int nextIndex = 0;

              if (lastRotationIndex >= 0 &&
                  lastRotationIndex < freeServers.length) {
                // Select next server in rotation
                nextIndex = (lastRotationIndex + 1) % freeServers.length;
                log('Cycling to next free server at index: $nextIndex');
              } else {
                log('First time selection or invalid index, starting at 0');
                nextIndex = 0;
              }

              // Save the new rotation index
              await prefs.setInt('fastest_server_rotation_index', nextIndex);
              log('Saved new rotation index: $nextIndex');

              final selectedFreeServer = freeServers[nextIndex];

              log(
                'Selected free server: ${selectedFreeServer.name} (ID: ${selectedFreeServer.id}, Type: ${selectedFreeServer.type}, Rotation Index: $nextIndex)',
              );

              // Find the index in the main servers list
              final mainIndex = provider.servers.indexWhere(
                (s) => s.id == selectedFreeServer.id,
              );

              log('Main server index: $mainIndex');

              if (mainIndex != -1) {
                provider.setSelectedServerIndex(mainIndex);
                log(
                  'Server selection updated in provider: index=$mainIndex, server=${selectedFreeServer.name}',
                );
                _showServerSelectedMessage(
                  "${selectedFreeServer.name} (Free Server)",
                );

                // If VPN is connected, disconnect first
                if (provider.vpnConnectionStatus ==
                    VpnStatusConnectionStatus.connected) {
                  log(
                    'VPN is connected, disconnecting before switching to fastest server...',
                  );
                  await provider
                      .toggleVpn(); // This will disconnect and reset timer
                  // Wait for disconnection to complete
                  await Future.delayed(const Duration(seconds: 2));
                  log('VPN disconnected, timer reset to 0');
                }

                // Switch to home screen (either via callback or pop)
                if (widget.onServerSelected != null) {
                  log('Using callback to switch to home tab');
                  // If callback exists (bottom nav), use it to switch tabs
                  widget.onServerSelected!();
                } else {
                  log('Using Navigator.pop() to return to previous screen');
                  // Otherwise, pop back to previous screen
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }

                log('Waiting 500ms before auto-connect');
                // Wait a brief moment for navigation, then auto-connect
                await Future.delayed(const Duration(milliseconds: 500));

                log('VPN status: ${provider.vpnConnectionStatus}');
                // Auto-connect to the new server
                if (provider.vpnConnectionStatus ==
                    VpnStatusConnectionStatus.disconnected) {
                  log('Starting auto-connect to ${selectedFreeServer.name}');
                  await provider.toggleVpn();
                  log('Auto-connect initiated');
                } else {
                  log('VPN still not disconnected - retrying');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: const Color(0xFF2A2A2A)),

                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fastest Server',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Connect to the best free server',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Random Server (Premium servers only if user is premium, otherwise show upgrade message)
          GestureDetector(
            onTap: () async {
              if (provider.servers.isEmpty) return;

              // Check if user is premium
              if (!provider.isPremium) {
                _showPremiumRequiredForRandomMessage();
                return;
              }

              // Filter only premium servers
              final premiumServers = provider.servers
                  .where((server) => server.type.toLowerCase() == 'premium')
                  .toList();

              if (premiumServers.isEmpty) {
                _showNoServersAvailableMessage('No premium servers available');
                return;
              }

              // Select random premium server
              final randomIndex =
                  DateTime.now().millisecond % premiumServers.length;
              final randomServer = premiumServers[randomIndex];

              // Find the index in the main servers list
              final mainIndex = provider.servers.indexWhere(
                (s) => s.id == randomServer.id,
              );

              if (mainIndex != -1) {
                provider.setSelectedServerIndex(mainIndex);
                log(
                  'Random server selection: index=$mainIndex, server=${randomServer.name}',
                );
                _showServerSelectedMessage(
                  "${randomServer.name} (Random Premium)",
                );

                // If VPN is connected, disconnect first
                if (provider.vpnConnectionStatus ==
                    VpnStatusConnectionStatus.connected) {
                  log(
                    'VPN is connected, disconnecting before switching to random server...',
                  );
                  await provider
                      .toggleVpn(); // This will disconnect and reset timer
                  // Wait for disconnection to complete
                  await Future.delayed(const Duration(seconds: 2));
                  log('VPN disconnected, timer reset to 0');
                }

                // Switch to home screen (either via callback or pop)
                if (widget.onServerSelected != null) {
                  // If callback exists (bottom nav), use it to switch tabs
                  widget.onServerSelected!();
                } else {
                  // Otherwise, pop back to previous screen
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }

                // Wait a brief moment for navigation, then auto-connect
                await Future.delayed(const Duration(milliseconds: 500));

                // Auto-connect to the new server
                if (provider.vpnConnectionStatus ==
                    VpnStatusConnectionStatus.disconnected) {
                  log('Connecting to new random server: ${randomServer.name}');
                  await provider.toggleVpn();
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shuffle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Random Server',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Image.asset(
                              'assets/Vector (4).png',
                              width: 12,
                              height: 12,
                              color: Colors.amber,
                            ),
                          ],
                        ),
                        Text(
                          'Connect to a random premium server',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerList(VpnProvide provider) {
    // Apply region filter before showing
    final filteredServers = provider.filterServers.where((server) {
      if (_selectedRegion == 'All') return true;
      if (_selectedRegion == 'Free') return server.type == 'free';
      if (_selectedRegion == 'Premium') return server.type == 'premium';
      return true;
    }).toList();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildServerListHeader(),
            const SizedBox(height: 15),
            Expanded(
              child: filteredServers.isEmpty
                  ? Center(
                      child: Text(
                        'No servers available',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filteredServers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final server = filteredServers[index];
                        return _buildServerItem(
                          provider: provider,
                          server: server,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Servers',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildServerItem({
    required VpnProvide provider,
    required Server server,
  }) {
    final isSelected =
        provider.selectedServerIndex ==
        provider.servers.indexWhere((s) => s.id == server.id);
    final isFavorite = provider.isFavoriteServer(server.id);
    // Check if server requires premium based on server type
    // You can customize this logic based on your requirements
    final isPremium = server.type.toLowerCase() == 'premium';
    final userIsPremium = provider.isPremium;

    return GestureDetector(
      onTap: () async {
        // If server requires premium but user is not premium, show message
        if (isPremium && !userIsPremium) {
          _showPremiumRequiredMessage(server.name);
          return;
        }

        // Find the index of the tapped server in the main servers list
        final index = provider.servers.indexWhere((s) => s.id == server.id);
        if (index == -1) {
          log('Server not found in servers list');
          return;
        }

        log('Selecting server: ${server.name} at index $index');
        provider.changeServer(index, 0, context);
        // if (isPremium && !userIsPremium) {
        //   _showPremiumRequiredMessage(server.name);
        //   return;
        // }

        // setState(() {
        //   _selectedServerIndex = server.id;
        // });
        // final index = provider.servers.indexWhere(
        //   (item) => item.id == server.id,
        // );
        // if (index != -1) {
        //   provider.setSelectedServerIndex(index);
        // }
        // _showServerSelectedMessage(server.name);

        // // If VPN is connected, disconnect first
        // if (provider.vpnConnectionStatus ==
        //     VpnStatusConnectionStatus.connected) {
        //   log('VPN is connected, disconnecting before switching server...');
        //   await provider.toggleVpn(); // This will disconnect and reset timer
        //   // Wait for disconnection to complete
        //   await Future.delayed(const Duration(seconds: 2));
        //   log('VPN disconnected, timer reset to 0');
        // }

        // // Switch to home screen (either via callback or pop)
        // if (widget.onServerSelected != null) {
        //   // If callback exists (bottom nav), use it to switch tabs
        //   widget.onServerSelected!();
        // } else {
        //   // Otherwise, pop back to previous screen
        //   if (mounted && Navigator.of(context).canPop()) {
        //     Navigator.of(context).pop();
        //   }
        // }

        // // Wait a brief moment for navigation, then auto-connect
        // await Future.delayed(const Duration(milliseconds: 500));

        // // Auto-connect to the new server
        // if (provider.vpnConnectionStatus ==
        //     VpnStatusConnectionStatus.disconnected) {
        //   log('Connecting to new server: ${server.name}');
        //   await provider.toggleVpn();
        // }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF2A2A2A),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Flag Icon - Use image if available, otherwise show a placeholder
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: (server.image ?? '').isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              server.image!,
                              fit: BoxFit.cover,
                              width: 30,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.flag, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.flag, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          server.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        
                        if (isPremium) ...[
                          const SizedBox(width: 6),
                          // Using the crown image instead of an icon
                          Image.asset(
                            'assets/Vector (4).png',
                            width: 14,
                            height: 14,
                            color: Colors.amber,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      server.subServers != null && server.subServers.isNotEmpty
                          ? server.subServers[0].name
                          : '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                // Favorite Star
                GestureDetector(
                  onTap: () async {
                    await provider.toggleFavoriteServer(server.id);
                    if (!mounted) {
                      return;
                    }
                    if (provider.isFavoriteServer(server.id)) {
                      _showServerFavoritedMessage(server.name);
                    } else {
                      _showServerUnfavoritedMessage(server.name);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_outline,
                      color: isFavorite ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Selected indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey,
                      width: 1.5,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 15,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for user feedback
  void _showServerSelectedMessage(String serverName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selected: $serverName',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showServerFavoritedMessage(String serverName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            Text(
              '$serverName added to favorites',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber[700],
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showServerUnfavoritedMessage(String serverName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              '$serverName removed from favorites',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[600],
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showPremiumRequiredMessage(String serverName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Premium Server',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  '$serverName is only available for Premium users',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Premium Benefits
                Text(
                  'Upgrade to Premium to unlock:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Benefits List
                _buildBenefitItem('Access to all premium servers'),
                const SizedBox(height: 8),
                _buildBenefitItem('Faster connection speeds'),
                const SizedBox(height: 8),
                _buildBenefitItem('No ads & priority support'),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Upgrade Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to Premium screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PremiumScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Upgrade',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 18, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[300],
            ),
          ),
        ),
      ],
    );
  }

  void _showNoServersAvailableMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showPremiumRequiredForRandomMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shuffle,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Premium Feature',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  'Random Server connects to premium servers only.\nUpgrade to Premium to unlock this feature!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Upgrade Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to Premium screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PremiumScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Upgrade',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
