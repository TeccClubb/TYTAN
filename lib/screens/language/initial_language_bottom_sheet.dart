import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/DataModel/languageModel.dart' show Language;
import 'package:tytan/Providers/LanguageProvide/languageProvide.dart'
    show LanguageProvider;
import 'package:provider/provider.dart';

class LanguageSelectionBottomSheet extends StatefulWidget {
  final Function(String) onLanguageSelected;

  const LanguageSelectionBottomSheet({
    Key? key,
    required this.onLanguageSelected,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    Function(String) onLanguageSelected,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LanguageSelectionBottomSheet(onLanguageSelected: onLanguageSelected),
    );
  }

  @override
  State<LanguageSelectionBottomSheet> createState() =>
      _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState
    extends State<LanguageSelectionBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Fetch available languages when sheet initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      if (languageProvider.availableLanguages.isEmpty) {
        languageProvider.fetchLanguages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Select Language',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                if (languageProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7AEEB5)),
                  );
                } else if (languageProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Failed to load languages',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => languageProvider.fetchLanguages(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7AEEB5),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: languageProvider.availableLanguages.length,
                    itemBuilder: (context, index) {
                      final language =
                          languageProvider.availableLanguages[index];
                      return _buildLanguageItem(
                        context,
                        language,
                        languageProvider.currentLanguage.code == language.code,
                        index,
                        languageProvider.loadingIndex == index,
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

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

    // For English, use GB flag if en flag doesn't exist
    String flagCode = language.code;
    if (language.code == 'en') {
      flagCode = 'gb'; // Use GB flag for English
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/flags/$flagCode.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          title: Text(
            language.name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF7AEEB5),
                    strokeWidth: 2,
                  ),
                )
              : isSelected
              ? const Icon(Icons.check_circle, color: Color(0xFF7AEEB5))
              : null,
          onTap: () async {
            // Set language selected flag
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('language_selected', true);

            // Change language
            final success = await languageProvider.changeLanguage(
              language.code,
              loadingIndex: index,
            );

            if (success) {
              // Call callback to proceed
              widget.onLanguageSelected(language.code);
              Navigator.pop(context); // Close the bottom sheet
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to change language: ${languageProvider.error}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
