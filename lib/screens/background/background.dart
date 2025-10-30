import 'package:flutter/material.dart';
import 'package:tytan/screens/constant/Appconstant.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundBlack,
            AppColors.backgroundDark,
            AppColors.backgroundBlack,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Top-right gradient accent - Increased size and lighter
          Positioned(
            top: -180,
            right: -200,
            child: Container(
              width: 500,
              height: 600,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.gradientOrange.withOpacity(0.06),
                    AppColors.gradientOrange.withOpacity(0.06),
                    AppColors.gradientOrange.withOpacity(0.06),
                    AppColors.gradientTransparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Bottom-left gradient accent - Keep original size
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.gradientOrange.withOpacity(0.06),
                    AppColors.gradientOrange.withOpacity(0.06),
                    AppColors.gradientTransparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
