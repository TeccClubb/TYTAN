import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tytan/Defaults/utils.dart' show UUtils;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/DataModel/languageModel.dart' show Language;

class LanguageProvider extends ChangeNotifier {
  final String _baseUrl = UUtils.baseUrl;

  List<Language> _availableLanguages = [
    Language(name: 'English', code: 'en', isRtl: false, isDefault: true),
    Language(name: 'Russian', code: 'ru', isRtl: false, isDefault: false),
  ];
  Language _currentLanguage = Language(
    name: 'English',
    code: 'en',
    isRtl: false,
    isDefault: true,
  );
  bool _isLoading = false;
  String? _error;
  int _loadingIndex = -1;

  LanguageProvider() {
    // We don't call loadLanguageFromPrefs here because it's called in main.dart
  }

  // Getters
  List<Language> get availableLanguages => _availableLanguages;
  int get loadingIndex => _loadingIndex;
  Language get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRtl => _currentLanguage.isRtl;

  // Method to fetch all available languages
  Future<void> fetchLanguages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('${_baseUrl}languages'))
          .timeout(const Duration(seconds: 5));
      print('Fetching languages from ${_baseUrl}languages');
      print('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['status'] == true && data['languages'] != null) {
          _availableLanguages = List<Language>.from(
            data['languages'].map((lang) => Language.fromJson(lang)),
          );

          print('Available languages: ${_availableLanguages.length}');

          notifyListeners();

          // If there's no current language set, try to load from preferences or use default
          if (_currentLanguage.code.isEmpty) {
            await loadLanguageFromPrefs();
          }
        } else {
          _error = 'Invalid data format received from server';
          print('Invalid data format received from server');
        }
      } else {
        print('Failed to load languages: ${response.statusCode}');
        _error = 'Failed to load languages: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching languages: ${e.toString()}';
      print('Error fetching languages: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to fetch a specific language and its translations
  Future<bool> fetchLanguageTranslations(
    String languageCode, {
    int loadingIndex = -1,
  }) async {
    _error = null;
    _loadingIndex = loadingIndex;
    notifyListeners();

    try {
      // Try to load from API first
      try {
        final response = await http
            .get(Uri.parse('${_baseUrl}languages/$languageCode'))
            .timeout(const Duration(seconds: 5));

        print(
          'Fetching language translations for $languageCode from ${_baseUrl}languages/$languageCode',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == true) {
            Map<String, dynamic>? trans;
            if (data['translations'] is String) {
              trans = jsonDecode(data['translations']);
            } else if (data['translations'] is Map) {
              trans = data['translations'];
            }

            final lang = Language(
              name:
                  data['name'] ??
                  (languageCode == 'ru' ? 'Russian' : 'English'),
              code: data['code'] ?? languageCode,
              isRtl: data['is_rtl'] ?? false,
              isDefault: data['default'] ?? false,
              translations: trans,
            );

            _currentLanguage = lang;
            _saveLanguageToPrefs(lang);
            Get.updateLocale(Locale(lang.code));
            _loadingIndex = -1;
            notifyListeners();
            print(
              'Successfully loaded translations from API for $languageCode',
            );
            return true;
          }
        }
        print('API returned invalid response, falling back to local assets');
      } catch (e) {
        print('API translation fetch failed, falling back to local assets: $e');
      }

      // Fallback to local assets
      print('Loading translations from local assets for $languageCode');
      return await loadLocalTranslations(languageCode);
    } catch (e) {
      _error = 'Error fetching language: ${e.toString()}';
      print('Error in fetchLanguageTranslations: ${e.toString()}');
      // Try to load from local assets as last resort
      return await loadLocalTranslations(languageCode);
    } finally {
      _loadingIndex = -1;
      notifyListeners();
    }
  }

  Future<bool> loadLocalTranslations(String languageCode) async {
    try {
      print('Attempting to load local translations for $languageCode');
      String assetPath = 'assets/l10n/$languageCode.json';
      String jsonString = await rootBundle.loadString(assetPath);
      Map<String, dynamic> translations = jsonDecode(jsonString);

      _currentLanguage = Language(
        name: languageCode == 'ru' ? 'Russian' : 'English',
        code: languageCode,
        isRtl: languageCode == 'ar' || languageCode == 'he', // Simple check
        isDefault: languageCode == 'en',
        translations: translations,
      );

      _saveLanguageToPrefs(_currentLanguage);
      Get.updateLocale(Locale(languageCode));
      print('Successfully loaded local translations for $languageCode');
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to load local translations for $languageCode: $e');
      return false;
    }
  }

  // Change current language
  Future<bool> changeLanguage(
    String languageCode, {
    int loadingIndex = -1,
  }) async {
    return await fetchLanguageTranslations(
      languageCode,
      loadingIndex: loadingIndex,
    );
  }

  // Load language from shared preferences
  Future<void> loadLanguageFromPrefs() async {
    try {
      print('Loading language from preferences...');
      final prefs = await SharedPreferences.getInstance();
      final languageData = prefs.getString('current_language');

      if (languageData != null) {
        print('Found saved language data: $languageData');
        _currentLanguage = Language.fromJson(jsonDecode(languageData));
        // Always ensure translations are loaded
        if (_currentLanguage.translations == null ||
            _currentLanguage.translations!.isEmpty) {
          print(
            'Translations missing, loading from local assets for ${_currentLanguage.code}',
          );
          await loadLocalTranslations(_currentLanguage.code);
        } else {
          // Translations exist, just update locale
          Get.updateLocale(Locale(_currentLanguage.code));
          print('Loaded language from preferences: ${_currentLanguage.code}');
          notifyListeners();
        }
      } else {
        // If no language is stored, use default (English)
        print('No saved language, loading default (English)');
        await loadLocalTranslations('en');
      }
    } catch (e) {
      _error = 'Error loading language preferences: ${e.toString()}';
      print('Error loading language preferences: ${e.toString()}');
      // Fallback to English if there's any error
      await loadLocalTranslations('en');
    }
  }

  // Save language to shared preferences
  Future<void> _saveLanguageToPrefs(Language language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_language', jsonEncode(language.toJson()));
    } catch (e) {
      _error = 'Error saving language preferences: ${e.toString()}';
      notifyListeners();
    }
  }

  // Translate a key to the current language
  String translate(String key, {String defaultValue = ''}) {
    if (_currentLanguage.translations == null) {
      return defaultValue.isEmpty ? key : defaultValue;
    }

    return _currentLanguage.translations![key] ??
        (defaultValue.isEmpty ? key : defaultValue);
  }
}
