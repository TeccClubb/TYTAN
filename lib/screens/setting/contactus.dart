import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tytan/Screens/setting/feedback.dart';
import 'package:tytan/Screens/setting/terms_of_service.dart';
import 'package:tytan/Screens/setting/privacy_policy.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:tytan/Defaults/extensions.dart';

class ContactSupport extends StatelessWidget {
  const ContactSupport({Key? key}) : super(key: key);
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@tytanvpn.com',
      query: 'subject=App Support Request',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CenteredHeader(title: "settings".tr(context)),
              const Divider(color: Color(0xFF2A2A2A), height: 1, thickness: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SectionHeader(title: "support".tr(context)),
                    SettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: "frequently_asked_questions".tr(context),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FAQScreen()),
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: "send_feedback".tr(context),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.email_outlined,
                      title: "email_support".tr(context),
                      onTap: _launchEmail,
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(title: "connect".tr(context)),
                    SettingsTile(
                      icon: Icons.public,
                      title: "follow_x".tr(context),
                      isExternal: true,
                      onTap: () => _launchUrl("https://twitter.com/yourhandle"),
                    ),
                    SettingsTile(
                      icon: Icons.camera_alt_outlined,
                      title: "follow_instagram".tr(context),
                      isExternal: true,
                      onTap: () =>
                          _launchUrl("https://instagram.com/yourhandle"),
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(title: "legal".tr(context)),
                    SettingsTile(
                      icon: Icons.description_outlined,
                      title: "Terms of Service",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'app_version'.tr(context),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              CenteredHeader(title: "faq".tr(context)),
              const Divider(color: Color(0xFF2A2A2A), height: 1, thickness: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    FAQItem(
                      question: "How do I change my server location?",
                      answer:
                          "Go to the home screen and tap the flag icon or the 'Change Location' button.",
                    ),
                    FAQItem(
                      question: "Is my connection secure?",
                      answer:
                          "Yes, we use military-grade encryption to ensure your data is safe.",
                    ),
                    FAQItem(
                      question: "Why is my connection slow?",
                      answer:
                          "Speed can be affected by your distance. Try connecting to a closer server.",
                    ),
                    FAQItem(
                      question: "Can I use this on multiple devices?",
                      answer:
                          "Yes, your subscription covers up to 5 devices simultaneously.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CenteredHeader extends StatelessWidget {
  final String title;
  const CenteredHeader({Key? key, required this.title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
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
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            width: 40,
            height: 40,
          ), // Balance trick for perfect centering
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({Key? key, required this.title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isExternal;
  const SettingsTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isExternal = false,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        trailing: Icon(
          isExternal
              ? Icons.open_in_new_rounded
              : Icons.arrow_forward_ios_rounded,
          color: Colors.grey,
          size: isExternal ? 18 : 16,
        ),
      ),
    );
  }
}

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;
  const FAQItem({Key? key, required this.question, required this.answer})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          title: Text(
            question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                answer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
