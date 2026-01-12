import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

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
                        '1. Acceptance of Terms',
                        'By downloading, installing, or using Tytan VPN, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
                      ),
                      _buildSection(
                        '2. Service Description',
                        'Tytan VPN provides virtual private network services to protect your online privacy and security. We offer both free and premium subscription plans with varying features and limitations.',
                      ),
                      _buildSection(
                        '3. Free Service Limitations',
                        'Free users receive 5 GB of traffic per month with full access to all features. Once the limit is reached, VPN access will be paused until the next billing cycle or until you upgrade to a premium plan.',
                      ),
                      _buildSection(
                        '4. Premium Subscription',
                        'Premium subscriptions provide unlimited traffic, access to all global servers, and priority support. Subscriptions are billed on a recurring basis according to your selected plan (weekly, monthly, or yearly).',
                      ),
                      _buildSection(
                        '5. User Responsibilities',
                        'You agree to:\n• Use the service only for lawful purposes\n• Not engage in any activity that violates local, national, or international laws\n• Not use the service to transmit malicious software or engage in hacking\n• Not share your account credentials with others\n• Not attempt to bypass any service limitations',
                      ),
                      _buildSection(
                        '6. Privacy and Data',
                        'We are committed to protecting your privacy. We do not log your browsing activity or connection data. Please refer to our Privacy Policy for detailed information about data collection and usage.',
                      ),
                      _buildSection(
                        '7. Service Availability',
                        'While we strive to provide uninterrupted service, we do not guarantee 100% uptime. Service may be temporarily unavailable due to maintenance, technical issues, or circumstances beyond our control.',
                      ),
                      _buildSection(
                        '8. Refund Policy',
                        'Premium subscriptions may be eligible for refunds within 7 days of purchase if you are not satisfied with the service. Please contact our support team to request a refund.',
                      ),
                      _buildSection(
                        '9. Termination',
                        'We reserve the right to suspend or terminate your account if you violate these terms or engage in abusive behavior. You may cancel your subscription at any time through your account settings.',
                      ),
                      _buildSection(
                        '10. Changes to Terms',
                        'We may update these Terms of Service from time to time. Continued use of the service after changes constitutes acceptance of the new terms.',
                      ),
                      _buildSection(
                        '11. Limitation of Liability',
                        'Tytan VPN is provided "as is" without warranties of any kind. We are not liable for any damages arising from your use or inability to use the service.',
                      ),
                      _buildSection(
                        '12. Contact Information',
                        'If you have questions about these Terms of Service, please contact us at:\n\nEmail: support@tytanvpn.com',
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
            'Terms of Service',
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
