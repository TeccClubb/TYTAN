import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/Defaults/extensions.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';

class PremiumScreen extends StatefulWidget {
  final bool isBack;
  PremiumScreen({Key? key, this.isBack = true}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showPlanSelection = false;
  String _selectedPlan = '';
  // The Data for your Comparison Table
  final List<Map<String, dynamic>> _comparisonData = [
    {
      "feature": "Stable connection",
      "desc": "(No drops during use)",
      "free": true,
      "premium": true,
    },
    {
      "feature": "No speed limits",
      "desc": "(Maximum network speed)",
      "free": false,
      "premium": true,
    },
    {
      "feature": "Global servers",
      "desc": "(Access all countries)",
      "free": false,
      "premium": true,
    },
    {
      "feature": "Secure encryption",
      "desc": "(Data is protected)",
      "free": true,
      "premium": true,
    },
    {
      "feature": "Kill Switch",
      "desc": "(Internet block on drop)",
      "free": false,
      "premium": true,
    },
    {
      "feature": "DNS leak protection",
      "desc": "(ISP cannot see requests)",
      "free": false,
      "premium": true,
    },
    {
      "feature": "App-level control",
      "desc": "(Choose apps for VPN)",
      "free": false,
      "premium": true,
    },
    {
      "feature": "Ad & tracker block",
      "desc": "(Less ads & traffic)",
      "free": false,
      "premium": true,
    },
  ];
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VpnProvide>(context, listen: false).getPlans();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _showPlanSelection = !_showPlanSelection;
      _showPlanSelection
          ? _animationController.forward()
          : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(
                context,
                _showPlanSelection ? 'Choose Your Plan' : 'Premium Access',
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 1, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildLogo(),
                      const SizedBox(height: 30),
                      if (!_showPlanSelection)
                        _buildComparisonView()
                      else
                        _buildPlanSelectionView(),
                      const SizedBox(
                        height: 0,
                      ), // Add bottom padding to avoid overlap with bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- LOGO ---
  Widget _buildLogo() {
    return Center(child: Image.asset('assets/Tytan Logo.png', height: 120));
  }

  // --- BOTTOM NAVIGATION ---
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: _buildActionButton(
        _showPlanSelection ? "Start Premium Trial" : "Upgrade to Premium",
        _showPlanSelection ? () {} : _toggleView,
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.isBack || _showPlanSelection)
            GestureDetector(
              onTap: () =>
                  _showPlanSelection ? _toggleView() : Navigator.pop(context),
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
            )
          else
            const SizedBox(width: 40, height: 40), // Placeholder for centering
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }

  // --- SECTION 1: COMPARISON VIEW (Marketing Hero) ---
  Widget _buildComparisonView() {
    return Column(
      children: [
        // Hero Section with Gradient
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary.withOpacity(0.2), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                '🚀 Unlock Premium Power',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Experience unlimited VPN with premium features',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Premium Features Grid
        _buildPremiumFeatures(),

        const SizedBox(height: 25),

        // Enhanced Comparison Table
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A2A2A)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Feature Comparison',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildTableHead(),
              const Divider(color: Color(0xFF2A2A2A), height: 30),
              ..._comparisonData.map((item) => _buildTableRow(item)),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // Call to Action with Stats
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('5GB', 'Free Monthly'),
                  _buildStatItem('∞', 'Premium Traffic'),
                  _buildStatItem('50+', 'Global Servers'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Join thousands of users who upgraded to Premium for unlimited access and premium security features.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildPremiumFeatures() {
    return Column(
      children: [
        Text(
          'Premium Features',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildFeatureItem(Icons.lock, 'Secure Encryption'),
            _buildFeatureItem(Icons.public, 'Global Servers'),
            _buildFeatureItem(Icons.speed, 'No Speed Limits'),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String text) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  // --- SECTION 2: PLAN SELECTION VIEW ---
  Widget _buildPlanSelectionView() {
    return Consumer<VpnProvide>(
      builder: (context, provider, child) {
        if (provider.plans.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Loading premium plans...',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            // Special Offer Banner
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Limited Time: Save up to 70% on annual plans!',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Plan Cards
            ...provider.plans.asMap().entries.map((entry) {
              int index = entry.key;
              var plan = entry.value;
              bool isPopular = index == 1; // Make second plan popular
              return _buildModernPlanCard(plan, isPopular);
            }),

            // Benefits Section
            _buildPlanBenefits(),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildModernPlanCard(dynamic plan, bool isPopular) {
    bool isSelected = _selectedPlan == plan.slug;
    double originalPrice = plan.discountPrice * 1.5; // Simulate original price
    double savings =
        ((originalPrice - plan.discountPrice) / originalPrice * 100);

    // Determine if this is the best deal (highest savings)
    bool isBestDeal = plan.isBestDeal;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan.slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                )
              : null,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isBestDeal
                      ? AppColors.primary.withOpacity(0.4)
                      : const Color(0xFF2A2A2A)),
            width: isSelected ? 2.5 : (isBestDeal ? 1.5 : 1),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            if (isBestDeal && !isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isBestDeal ? 15 : 20),
          child: Stack(
            children: [
              // Glassmorphism Background Effect
              if (isSelected || isBestDeal)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.06),
                          Colors.transparent,
                          AppColors.primary.withOpacity(0.03),
                        ],
                      ),
                    ),
                  ),
                ),

              // Best Deal Badge
              if (isBestDeal)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BEST DEAL',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Card Content
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                margin: EdgeInsets.only(top: isBestDeal ? 28 : 0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.95),
                  borderRadius: isBestDeal
                      ? BorderRadius.only(
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(0),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        )
                      : BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Left side - Plan Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              plan.invoicePeriod.toString() +
                                  ' ' +
                                  plan.invoiceInterval,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right side - Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price Row with Original and Current Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Original Price (if discounted) - on the left
                            if (savings > 0)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 6,
                                  bottom: 4,
                                ),
                                child: Text(
                                  '\$${originalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),

                            // Current Price - big and bold
                            Text(
                              '\$',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              plan.discountPrice.toStringAsFixed(2),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),

                        // Savings Badge
                        if (savings > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C853), Color(0xFF00E676)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SAVE ${savings.toInt()}%',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildPlanBenefits() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '✨ What You Get',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBenefitItem(
                  Icons.all_inclusive_rounded,
                  'Unlimited\nBandwidth',
                ),
              ),
              Expanded(
                child: _buildBenefitItem(
                  Icons.public_rounded,
                  '50+ Global\nServers',
                ),
              ),
              Expanded(
                child: _buildBenefitItem(
                  Icons.security_rounded,
                  'Military-Grade\nEncryption',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBenefitItem(
                  Icons.support_agent_rounded,
                  '24/7 Priority\nSupport',
                ),
              ),
              Expanded(
                child: _buildBenefitItem(
                  Icons.block_rounded,
                  'Ad & Tracker\nBlocking',
                ),
              ),
              Expanded(
                child: _buildBenefitItem(
                  Icons.speed_rounded,
                  'No Speed\nLimits',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.grey[300],
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHead() {
    return Row(
      children: [
        const Expanded(flex: 3, child: SizedBox()),
        Expanded(
          flex: 1,
          child: Text(
            "Free",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            "Premium",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['feature'].toString().tr(context),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item['desc'].toString().tr(context),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Icon(
              item['free'] ? Icons.check_circle : Icons.cancel,
              color: item['free'] ? Colors.green : Colors.grey[800],
              size: 20,
            ),
          ),
          Expanded(
            flex: 1,
            child: Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
