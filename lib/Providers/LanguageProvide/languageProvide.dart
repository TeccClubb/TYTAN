import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/DataModel/languageModel.dart' show Language;
import 'package:tytan/Defaults/utils.dart' show UUtils;

class LanguageProvider extends ChangeNotifier {
  // TODO: Replace with the actual API base URL for your application
  final String _baseUrl =
      UUtils.baseUrl; // Update this with your actual API URL

  List<Language> _availableLanguages = [];
  Language _currentLanguage = Language(
    name: 'English',
    code: 'en',
    isRtl: false,
    isDefault: true,
  );
  bool _isLoading = false;
  String? _error;
  int _loadingIndex = -1;

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
      final response = await http.get(Uri.parse('${_baseUrl}languages'));
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
      final response = await http.get(
        Uri.parse('${_baseUrl}languages/$languageCode'),
      );

      log(
        'Fetching language translations for $languageCode from ${_baseUrl}languages/$languageCode',
      );
      log('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          // Create a language object with translations
          final lang = Language(
            name: data['name'],
            code: data['code'],
            isRtl: data['is_rtl'],
            isDefault: data['default'],
            translations: jsonDecode(data['translations']),
          );

          _currentLanguage = lang;

          Get.updateLocale(Locale(lang.code));

          // Save to preferences
          await _saveLanguageToPrefs(lang);
          _loadingIndex = -1; // Reset loading index after successful load

          notifyListeners();
          return true;
        } else {
          _error = 'Invalid data format received from server';
        }
      } else {
        _error = 'Failed to load language: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching language: ${e.toString()}';
    } finally {
      _loadingIndex = -1; // Reset loading index on error
      notifyListeners();
    }

    return false;
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
        notifyListeners();
      } else {
        // If no language is stored, use default (English) or first available language
        final defaultLang = _availableLanguages.firstWhere(
          (lang) => lang.isDefault,
          orElse: () => _availableLanguages.isNotEmpty
              ? _availableLanguages.first
              : Language(
                  name: 'English',
                  code: 'en',
                  isRtl: false,
                  isDefault: true,
                ),
        );

        await changeLanguage(defaultLang.code);
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
