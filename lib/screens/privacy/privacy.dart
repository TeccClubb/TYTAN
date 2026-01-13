import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';
import 'package:tytan/Defaults/extensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image.asset('assets/Tytan Logo.png', height: 80),
                      ),
                      const SizedBox(height: 30),
                      _buildInfoCard(
                        context,
                        title: 'privacy_overview_title'.tr(context),
                        content: 'privacy_overview_desc'.tr(context),
                        icon: Icons.security,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        context,
                        'privacy_info_collection_title'.tr(context),
                      ),
                      _buildSectionText(
                        context,
                        'privacy_info_collection_desc'.tr(context),
                      ),

                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        context,
                        'privacy_data_usage_title'.tr(context),
                      ),
                      _buildSectionText(
                        context,
                        'privacy_data_usage_desc'.tr(context),
                      ),

                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        context,
                        'privacy_third_party_title'.tr(context),
                      ),
                      _buildSectionText(
                        context,
                        'privacy_third_party_desc'.tr(context),
                      ),

                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        context,
                        'privacy_security_measures_title'.tr(context),
                      ),
                      _buildSectionText(
                        context,
                        'privacy_security_measures_desc'.tr(context),
                      ),

                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        context,
                        'privacy_policy_changes_title'.tr(context),
                      ),
                      _buildSectionText(
                        context,
                        'privacy_policy_changes_desc'.tr(context),
                      ),

                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'last_updated'.tr(context),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'privacy_policy'.tr(context),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textGray,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionText(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppColors.textGray,
        height: 1.6,
      ),
    );
  }
}
