import 'package:flutter/material.dart';
import 'package:tytan/Defaults/extensions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'onboarding_screen'.tr(context),
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
