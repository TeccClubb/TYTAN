// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tytan/Defaults/extensions.dart';
import 'package:tytan/Screens/welcome/welcome.dart';
import 'package:tytan/DataModel/languageModel.dart';
import 'package:tytan/Screens/constant/Appconstant.dart';
import 'package:tytan/Screens/background/background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/Providers/LanguageProvide/languageProvide.dart'
    show LanguageProvider;

class InitialLanguageSelectionScreen extends StatefulWidget {
  final Function(String languageCode) onLanguageSelected;

  const InitialLanguageSelectionScreen({
    Key? key,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  State<InitialLanguageSelectionScreen> createState() =>
      _InitialLanguageSelectionScreenState();
}

class _InitialLanguageSelectionScreenState
    extends State<InitialLanguageSelectionScreen> {
  // Track the selected language code
  String _selectedLanguageCode = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Fetch available languages when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      languageProvider.fetchLanguages();

      if (mounted) {
        setState(() {
          _selectedLanguageCode = languageProvider.currentLanguage.code;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              // App Logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/Tytan Logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // App name
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tytan ',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'VPN',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                'select_location'.tr(context),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              // Language list
              Expanded(
                child: Consumer<LanguageProvider>(
                  builder: (context, languageProvider, child) {
                    if (languageProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                      );
                    } else if (languageProvider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'failed_to_load_languages'.tr(context),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  languageProvider.fetchLanguages(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7AEEB5),
                              ),
                              child: Text(
                                'retry'.tr(context),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: languageProvider.availableLanguages.length,
                        itemBuilder: (context, index) {
                          final language =
                              languageProvider.availableLanguages[index];
                          return _buildLanguageItem(
                            context,
                            language,
                            _selectedLanguageCode == language.code,
                            index,
                            languageProvider.loadingIndex == index,
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              // Continue button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing || _selectedLanguageCode.isEmpty
                        ? null
                        : _continueToNextScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'continue'.tr(context),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildHeader(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.all(20),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         GestureDetector(
  //           onTap: () => Navigator.pop(context),
  //           child: Container(
  //             width: 40,
  //             height: 40,
  //             decoration: BoxDecoration(
  //               color: const Color(0xFF2A2A2A),
  //               shape: BoxShape.circle,
  //             ),
  //             child: const Icon(
  //               Icons.arrow_back_ios_new_rounded,
  //               color: Colors.white,
  //               size: 18,
  //             ),
  //           ),
  //         ),
  //         Text(
  //           'Language',
  //           style: GoogleFonts.plusJakartaSans(
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //           ),
  //         ),
  //         const SizedBox(width: 40),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLanguageItem(
    BuildContext context,
    Language language,
    bool isSelected,
    int index,
    bool isLoading,
  ) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    // For English, use GB or US flag if en flag doesn't exist
    String flagCode = language.code;
    if (language.code == 'en') {
      flagCode = 'gb'; // Use GB flag for English
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFF2A2A2A),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: isLoading
            ? null
            : () async {
                // Change language
                final success = await languageProvider.changeLanguage(
                  language.code,
                  loadingIndex: index,
                );

                if (success) {
                  // Update the selected language code
                  setState(() {
                    _selectedLanguageCode = language.code;
                  });
                }
              },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Flag Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
                  image: DecorationImage(
                    image: AssetImage('assets/flags/$flagCode.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Language Name
              Expanded(
                child: Text(
                  language.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),

              // Loading or Selected Indicator
              if (isLoading)
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
              else if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to handle continuing to next screen
  Future<void> _continueToNextScreen() async {
    if (_selectedLanguageCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Set language selected flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('language_selected', true);

      // Call callback to proceed to next screen
      widget.onLanguageSelected(_selectedLanguageCode);

      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final bool onboardingCompleted =
            prefs.getBool('onboarding_completed') ?? false;

        if (Navigator.of(context).canPop()) {
          // If called from settings, just go back
          Navigator.of(context).pop();
        } else {
          // If it's the initial flow, navigate to welcome or onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => onboardingCompleted
                  ? const WelcomeScreen()
                  : const WelcomeScreen(), // Or OnboardingScreen if implemented
            ),
          );
        }
      }
    } catch (e) {
      // log('Error in _continueToNextScreen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('an_error_occurred'.tr(context) + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Widget _buildLanguageItem(
  //   BuildContext context,
  //   Language language,
  //   bool isSelected,
  //   int index,
  //   bool isLoading,
  // ) {
  //   final languageProvider = Provider.of<LanguageProvider>(
  //     context,
  //     listen: false,
  //   );

  //   // For English, use GB or US flag if en flag doesn't exist
  //   String flagCode = language.code;
  //   if (language.code == 'en') {
  //     flagCode = 'gb'; // Use GB flag for English
  //   }

  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 8),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF3A3A3C),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(12),
  //       child: ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 12,
  //         ),
  //         leading: Container(
  //           width: 40,
  //           height: 40,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             image: DecorationImage(
  //               image: AssetImage('assets/flags/$flagCode.png'),
  //               fit: BoxFit.cover,
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.2),
  //                 blurRadius: 4,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //         ),
  //         title: Text(
  //           language.name,
  //           style: GoogleFonts.poppins(
  //             color: Colors.white,
  //             fontSize: 16,
  //             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  //           ),
  //         ),
  //         trailing: isLoading
  //             ? const SizedBox(
  //                 height: 20,
  //                 width: 20,
  //                 child: CircularProgressIndicator(
  //                   color: Colors.deepOrange,
  //                   strokeWidth: 2,
  //                 ),
  //               )
  //             : isSelected
  //             ? const Icon(Icons.check_circle, color: Colors.deepOrange)
  //             : null,
  //         onTap: () async {
  //           // Change language
  //           final success = await languageProvider.changeLanguage(
  //             language.code,
  //             loadingIndex: index,
  //           );

  //           if (success) {
  //             // Update the selected language code
  //             setState(() {
  //               _selectedLanguageCode = language.code;
  //             });
  //           } else {
  //             // ScaffoldMessenger.of(context).showSnackBar(
  //             //   SnackBar(
  //             //     content: Text(
  //             //       TranslateString('Failed to change language').tr(context) +
  //             //           ': ${languageProvider.error}',
  //             //     ),
  //             //     backgroundColor: Colors.red,
  //             //   ),
  //             // );
  //           }
  //         },
  //       ),
  //     ),
  //   );
  // }
  //       // We only need minimal initialization before onboarding
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       prefs.setBool('onboarding_completed', false);
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isProcessing = false;
  //     });
  //   }
  // }
}
