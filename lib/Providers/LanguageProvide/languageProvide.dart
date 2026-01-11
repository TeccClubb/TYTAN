import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/DataModel/languageModel.dart' show Language;
import 'package:tytan/Defaults/utils.dart' show UUtils;

class LanguageProvider extends ChangeNotifier {
  // TODO: Replace with the actual API base URL for your application
  final String _baseUrl =
      UUtils.baseUrl; // Update this with your actual API URL

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
    loadLanguageFromPrefs();
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
      log('Fetching languages from ${_baseUrl}languages');
      log('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['status'] == true && data['languages'] != null) {
          _availableLanguages = List<Language>.from(
            data['languages'].map((lang) => Language.fromJson(lang)),
          );

          log('Available languages: ${_availableLanguages.length}');

          notifyListeners();

          // If there's no current language set, try to load from preferences or use default
          if (_currentLanguage.code.isEmpty) {
            await loadLanguageFromPrefs();
          }
        } else {
          _error = 'Invalid data format received from server';
          log('Invalid data format received from server');
        }
      } else {
        log('Failed to load languages: ${response.statusCode}');
        _error = 'Failed to load languages: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching languages: ${e.toString()}';
      log('Error fetching languages: ${e.toString()}');
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

        log(
          'Fetching language translations for $languageCode from ${_baseUrl}languages/$languageCode',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == true) {
            final lang = Language(
              name:
                  data['name'] ??
                  (languageCode == 'ru' ? 'Russian' : 'English'),
              code: data['code'] ?? languageCode,
              isRtl: data['is_rtl'] ?? false,
              isDefault: data['default'] ?? false,
              translations: jsonDecode(data['translations']),
            );

            _currentLanguage = lang;
            _saveLanguageToPrefs(lang);
            Get.updateLocale(Locale(lang.code));
            _loadingIndex = -1;
            notifyListeners();
            return true;
          }
        }
      } catch (e) {
        log('API translation fetch failed, falling back to local assets: $e');
      }

      // Fallback to local assets
      return await loadLocalTranslations(languageCode);
    } catch (e) {
      _error = 'Error fetching language: ${e.toString()}';
    } finally {
      _loadingIndex = -1;
      notifyListeners();
    }

    return false;
  }

  Future<bool> loadLocalTranslations(String languageCode) async {
    try {
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
      log('Loaded local translations for $languageCode');
      notifyListeners();
      return true;
    } catch (e) {
      log('Failed to load local translations for $languageCode: $e');
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
      final prefs = await SharedPreferences.getInstance();
      final languageData = prefs.getString('current_language');

      if (languageData != null) {
        _currentLanguage = Language.fromJson(jsonDecode(languageData));
        if (_currentLanguage.translations == null) {
          await loadLocalTranslations(_currentLanguage.code);
        }
        notifyListeners();
      } else {
        // If no language is stored, use default (English)
        await loadLocalTranslations('en');
      }
    } catch (e) {
      _error = 'Error loading language preferences: ${e.toString()}';
      log('Error loading language preferences: ${e.toString()}');
      notifyListeners();
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
