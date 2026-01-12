import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Divider(color: Color(0xFF2A2A2A), height: 1, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Last Updated', 'January 11, 2026'),
                      const SizedBox(height: 20),
                      _buildSection(
                        '1. Introduction',
                        'At Tytan VPN, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our VPN service.',
                      ),
                      _buildSection(
                        '2. No-Logging Policy',
                        'We do NOT log, track, or store:\n• Your browsing history\n• Connection timestamps\n• DNS queries\n• IP addresses used while connected\n• Bandwidth usage\n• Traffic data\n\nYour online activities remain completely private and anonymous.',
                      ),
                      _buildSection(
                        '3. Information We Collect',
                        'We collect minimal information necessary to provide our service:\n\n• Account Information: Email address for account creation and communication\n• Payment Information: Processed securely through third-party payment providers (we do not store credit card details)\n• Device Information: Device type, operating system version for compatibility\n• Usage Statistics: Aggregated, anonymous data about app performance and crashes',
                      ),
                      _buildSection(
                        '4. How We Use Your Information',
                        'We use collected information to:\n• Provide and maintain our VPN service\n• Process payments and manage subscriptions\n• Send important service updates and notifications\n• Improve app performance and user experience\n• Provide customer support\n• Prevent fraud and abuse',
                      ),
                      _buildSection(
                        '5. Data Sharing',
                        'We do NOT sell, rent, or share your personal information with third parties for marketing purposes. We may share data only in the following circumstances:\n\n• With payment processors to handle transactions\n• With cloud service providers who help us operate our infrastructure\n• When required by law or to protect our legal rights\n• In the event of a merger or acquisition (users will be notified)',
                      ),
                      _buildSection(
                        '6. Data Security',
                        'We implement industry-standard security measures to protect your data:\n• Military-grade AES-256 encryption\n• Secure server infrastructure\n• Regular security audits\n• Encrypted data transmission\n• Secure authentication protocols',
                      ),
                      _buildSection(
                        '7. Data Retention',
                        'We retain your account information for as long as your account is active. If you delete your account, we will remove your personal information within 30 days, except where we are required to retain it for legal purposes.',
                      ),
                      _buildSection(
                        '8. Your Rights',
                        'You have the right to:\n• Access your personal information\n• Request correction of inaccurate data\n• Request deletion of your account and data\n• Opt-out of marketing communications\n• Export your data\n\nTo exercise these rights, contact us at support@tytanvpn.com',
                      ),
                      _buildSection(
                        '9. Cookies and Tracking',
                        'Our mobile app does not use cookies. We use minimal analytics to improve app performance, which can be disabled in your device settings.',
                      ),
                      _buildSection(
                        '10. Children\'s Privacy',
                        'Our service is not intended for users under 13 years of age. We do not knowingly collect information from children under 13.',
                      ),
                      _buildSection(
                        '11. International Data Transfers',
                        'Your data may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information.',
                      ),
                      _buildSection(
                        '12. Changes to Privacy Policy',
                        'We may update this Privacy Policy from time to time. We will notify you of significant changes via email or in-app notification.',
                      ),
                      _buildSection(
                        '13. Contact Us',
                        'If you have questions or concerns about this Privacy Policy, please contact us:\n\nEmail: support@tytanvpn.com\n\nWe are committed to addressing your privacy concerns promptly.',
                      ),
                      const SizedBox(height: 40),
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
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          Text(
            'Privacy Policy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}
