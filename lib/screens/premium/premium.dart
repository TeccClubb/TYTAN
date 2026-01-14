import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:tytan/Providers/VpnProvide/vpnProvide.dart';
import 'package:tytan/Defaults/extensions.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

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
      "feature": "stable_connection",
      "desc": "no_drops_desc",
      "free": true,
      "premium": true,
    },
    {
      "feature": "no_speed_limits",
      "desc": "max_speed_desc",
      "free": false,
      "premium": true,
    },
    {
      "feature": "global_servers",
      "desc": "access_all_countries_desc",
      "free": false,
      "premium": true,
    },
    {
      "feature": "secure_encryption",
      "desc": "data_protected_desc",
      "free": true,
      "premium": true,
    },
    {
      "feature": "kill_switch",
      "desc": "internet_block_desc",
      "free": false,
      "premium": true,
    },
    {
      "feature": "dns_leak_protection",
      "desc": "isp_leak_desc",
      "free": false,
      "premium": true,
    },
    {
      "feature": "app_level_control",
      "desc": "choose_apps_desc",
      "free": false,
      "premium": true,
    },
    {
      "feature": "ad_tracker_block",
      "desc": "less_ads_desc",
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
                _showPlanSelection
                    ? 'choose_plan'.tr(context)
                    : 'premium_access'.tr(context),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 1, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      if (!_showPlanSelection)
                        _buildComparisonView()
                      else
                        _buildPlanSelectionView(),
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

  // --- HEADER ---
  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          ),
          Text(
            title,
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

  // --- SECTION 1: COMPARISON VIEW (Marketing Hero) ---
  Widget _buildComparisonView() {
    return Column(
      children: [
        Text(
          'go_premium_full_access'.tr(context),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 25),

        // The Comparison Table
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            children: [
              _buildTableHead(),
              const Divider(color: Color(0xFF2A2A2A), height: 30),
              ..._comparisonData.map((item) => _buildTableRow(item)),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // Marketing Philosophy Text
        Text(
          'free_traffic_desc'.tr(context),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 30),
        _buildActionButton('upgrade_to_premium'.tr(context), _toggleView),
        const SizedBox(height: 20),
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
            'free'.tr(context),
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
            'premium'.tr(context),
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

  // --- SECTION 2: PLAN SELECTION VIEW ---
  Widget _buildPlanSelectionView() {
    return Consumer<VpnProvide>(
      builder: (context, provider, child) {
        if (provider.plans.isEmpty)
          return Center(child: CircularProgressIndicator());
        return Column(
          children: [
            ...provider.plans.map((plan) => _buildPlanCard(plan)),
            const SizedBox(height: 30),
            _buildActionButton("start_premium".tr(context), () {}),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    bool isSelected = _selectedPlan == plan.slug;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan.slug),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF2A2A2A),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  plan.invoiceInterval,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              '\$${plan.discountPrice.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
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
