import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/screens/background/background.dart';
import 'package:tytan/screens/constant/Appconstant.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showPlanSelection = false;
  String _selectedPlan = 'yearly'; // Default to yearly plan (best value)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Load plans from VPN provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VpnProvide>(context, listen: false);
      provider.getPlans();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      if (_showPlanSelection) {
        _showPlanSelection = false;
        _animationController.reverse();
      } else {
        _showPlanSelection = true;
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return _buildHeader(
                    context,
                    _showPlanSelection ? 'Choose Your Plan' : 'Premium',
                  );
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Features View (First Screen)
                    AnimatedOpacity(
                      opacity: _showPlanSelection ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: _showPlanSelection,
                        child: _buildFeaturesView(),
                      ),
                    ),

                    // Plan Selection View (Second Screen)
                    AnimatedOpacity(
                      opacity: _showPlanSelection ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_showPlanSelection,
                        child: _buildPlanSelectionView(),
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

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_showPlanSelection) {
                _toggleView(); // Go back to features view
              } else {
                Navigator.pop(context); // Exit the screen
              }
            },
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
          Expanded(
            child: Center(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance the header
        ],
      ),
    );
  }

  // FIRST SCREEN - FEATURES VIEW
  Widget _buildFeaturesView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildLogo(),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 30),
            _buildFeatureItem(
              icon: Icons.all_inclusive,
              title: 'Unlimited Bandwidth',
              description: 'Stream, download, and browse without limits',
            ),
            const SizedBox(height: 15),
            _buildFeatureItem(
              icon: Icons.flash_on,
              title: 'Ultra-Fast Speeds',
              description: '10× faster than free tier connections',
            ),
            const SizedBox(height: 15),
            _buildFeatureItem(
              icon: Icons.shield_outlined,
              title: 'Advanced Security',
              description: 'Military-grade encryption & kill switch',
            ),
            const SizedBox(height: 15),
            _buildFeatureItem(
              icon: Icons.public,
              title: 'Global Server Access',
              description: 'Connect to 80+ countries worldwide',
            ),
            const SizedBox(height: 40),
            _buildContinueButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/Tytan Logo.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Unlock Premium',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _toggleView,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Continue',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // SECOND SCREEN - PLAN SELECTION VIEW
  Widget _buildPlanSelectionView() {
    return Consumer<VpnProvide>(
      builder: (context, provider, child) {
        // Show loading indicator while plans are being fetched
        if (provider.plans.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Display plans from VPN provider
                ...provider.plans.map((plan) {
                  // Calculate monthly price
                  final monthlyPrice = plan.discountPrice > 0
                      ? plan.discountPrice
                      : plan.originalPrice;

                  // Calculate savings percentage
                  final savingsPercent = plan.originalPrice > 0
                      ? ((plan.originalPrice - plan.discountPrice) /
                                plan.originalPrice *
                                100)
                            .round()
                      : 0;

                  // Determine icon based on interval
                  IconData planIcon;
                  if (plan.invoiceInterval.toLowerCase().contains('month') &&
                      plan.invoicePeriod == 1) {
                    planIcon = Icons.calendar_month;
                  } else if (plan.invoiceInterval.toLowerCase().contains(
                    'year',
                  )) {
                    planIcon = Icons.star;
                  } else {
                    planIcon = Icons.access_time;
                  }

                  // Build subtitle with savings info
                  String subtitle = plan.description;
                  if (savingsPercent > 0 && plan.isBestDeal) {
                    subtitle = 'Best value • Save $savingsPercent%';
                  } else if (savingsPercent > 0) {
                    subtitle = 'Save $savingsPercent%';
                  }

                  // Build billing info
                  String billingInfo =
                      'Billed \$${plan.originalPrice.toStringAsFixed(2)} ${plan.invoiceInterval}';
                  if (plan.invoicePeriod > 1) {
                    billingInfo =
                        'Billed \$${plan.originalPrice.toStringAsFixed(2)} every ${plan.invoicePeriod} ${plan.invoiceInterval}s';
                  }
                  if (plan.trialPeriod > 0) {
                    billingInfo +=
                        ' • ${plan.trialPeriod} ${plan.trialInterval} free trial';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: _buildPlanOption(
                      planId: plan.slug,
                      title: plan.name,
                      subtitle: subtitle,
                      price: '\$${monthlyPrice.toStringAsFixed(2)}',
                      billingInfo: billingInfo,
                      icon: planIcon,
                      isPopular: plan.isBestDeal,
                    ),
                  );
                }).toList(),
                const SizedBox(height: 40),
                _buildStartTrialButton(),
                const SizedBox(height: 20),
                _buildTrialInfo(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanOption({
    required String planId,
    required String title,
    required String subtitle,
    required String price,
    required String billingInfo,
    required IconData icon,
    required bool isPopular,
  }) {
    final bool isSelected = _selectedPlan == planId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = planId;
        });
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
        child: Column(
          children: [
            // Popular badge if applicable
            if (isPopular)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Most Popular',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    text: price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: '\n/month',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Billing info
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isPopular ? Colors.amber : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  billingInfo,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartTrialButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          // Start premium trial with selected plan
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Starting premium trial with ${_selectedPlan.toUpperCase()} plan',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Start Premium Trial',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTrialInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoItem('7-day\nfree trial'),
        _buildInfoDot(),
        _buildInfoItem('Cancel\nanytime'),
        _buildInfoDot(),
        _buildInfoItem('No\ncommitments'),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
    );
  }

  Widget _buildInfoDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
