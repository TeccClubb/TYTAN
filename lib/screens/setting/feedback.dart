import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  String _selectedFeedbackType = '';
  bool _isSubmitting = false;

  final List<String> _feedbackTypes = [
    'App Design',
    'Speed',
    'Connection',
    'Bugs',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Load user email from provider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VpnProvide>(context, listen: false);
      if (provider.user.isNotEmpty) {
        provider.emailController.text = provider.user.first.email;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(
                  color: Color(0xFF2A2A2A),
                  height: 1,
                  thickness: 1,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating section
                      _buildRatingSection(),
                      const SizedBox(height: 30),

                      // Feedback type selection
                      Text(
                        'What would you like to share about?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildFeedbackTypeSelection(),
                      const SizedBox(height: 30),

                      // Feedback text field
                      Text(
                        'Tell us more',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildFeedbackTextField(),
                      const SizedBox(height: 20),

                      // // Attach screenshot
                      // Row(
                      //   children: [
                      //     const Icon(
                      //       Icons.attach_file,
                      //       color: Colors.white,
                      //       size: 20,
                      //     ),
                      //     const SizedBox(width: 10),
                      //     Text(
                      //       'Attach screenshot (optional)',
                      //       style: GoogleFonts.plusJakartaSans(
                      //         fontSize: 14,
                      //         color: Colors.white,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 10),

                      // Send feedback button
                      _buildSendButton(),
                      const SizedBox(height: 10),

                      // Response time note
                      Center(
                        child: Text(
                          'We usually respond within 24 hours.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
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
            'Feedback',
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

  Widget _buildRatingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'How would you rate your experience ?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                child: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: index < _rating ? Colors.amber : Colors.grey,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTypeSelection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _feedbackTypes.map((type) {
        final bool isSelected = _selectedFeedbackType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFeedbackType = type;
              // Set the subject in the provider's subject controller
              context.read<VpnProvide>().subjectController.text = type;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFF212121),
              borderRadius: BorderRadius.circular(20),
              border: isSelected 
                  ? Border.all(color: AppColors.primary, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Text(
              type,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedbackTextField() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: context.read<VpnProvide>().messageController,
        maxLines: null,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tell us what\'s on your mind...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () async {
          setState(() {
            _isSubmitting = true;
          });
          await context.read<VpnProvide>().addFeedback(context);
          setState(() {
            _isSubmitting = false;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Send Feedback',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
