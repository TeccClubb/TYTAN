// import 'package:flutter/material.dart';

// class WorldMapBackground extends StatelessWidget {
//   final Widget child;
//   final double opacity;

//   const WorldMapBackground({Key? key, required this.child, this.opacity = 0.05})
//     : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // The background gradient
//         Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [Color(0xFF101010), Color(0xFF181818), Color(0xFF101010)],
//               stops: [0.0, 0.5, 1.0],
//             ),
//           ),
//         ),

//         // World map with opacity
//         Opacity(
//           opacity: opacity,
//           child: Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/world map (1).png'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         ),

//         // Child content
//         child,
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:tytan/screens/constant/Appconstant.dart';

class WorldMapBackground extends StatelessWidget {
  final Widget child;

  const WorldMapBackground({Key? key, required this.child}) : super(key: key);

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

          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/world map (1).png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
