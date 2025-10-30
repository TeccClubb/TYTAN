import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/screens/constant/Appconstant.dart';

class ProtocolScreen extends StatefulWidget {
  const ProtocolScreen({Key? key}) : super(key: key);

  @override
  State<ProtocolScreen> createState() => _ProtocolScreenState();
}

class _ProtocolScreenState extends State<ProtocolScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load protocol from provider when screen loads
    final provider = Provider.of<VpnProvide>(context, listen: false);
    provider.lProtocolFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VpnProvide>(context);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildProtocolOption(
                        provider: provider,
                        protocol: Protocol.openvpn,
                        name: 'OpenVPN',
                        description:
                            'Experience next-gen speed with lightweight encryption and instant connectivity.',
                        feature: 'Ultra Fast',
                        featureColor: Colors.green,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      _buildProtocolOption(
                        provider: provider,
                        protocol: Protocol.wireguard,
                        name: 'WireGuard',
                        description:
                            'Enjoy military-grade security with time-tested, stable, and reliable protection.',
                        feature: 'Stable Connection',
                        featureColor: Colors.blue,
                        iconColor: const Color(0xFF0A84FF),
                      ),
                      const SizedBox(height: 16),
                      _buildProtocolOption(
                        provider: provider,
                        protocol: Protocol.singbox,
                        name: 'SingBox',
                        description:
                            'Next-generation VPN protocol with advanced features and high performance.',
                        feature: 'Advanced',
                        featureColor: Colors.purple,
                        iconColor: const Color(0xFF8B5CF6),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          Text(
            'Protocol',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(width: 40, height: 40),
        ],
      ),
    );
  }

  Widget _buildProtocolOption({
    required VpnProvide provider,
    required Protocol protocol,
    required String name,
    required String description,
    required String feature,
    required Color featureColor,
    required Color iconColor,
  }) {
    final bool isSelected = provider.selectedProtocol == protocol;

    return GestureDetector(
      onTap: () async {
        // Try to set the protocol
        final success = await provider.setProtocol(protocol);

        if (!success && mounted) {
          // Show error message if protocol change failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please disconnect VPN before changing protocol',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (success && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Protocol changed to $name',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: featureColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        feature,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: featureColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
