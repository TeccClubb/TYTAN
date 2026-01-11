import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tytan/Providers/LanguageProvide/languageProvide.dart';

extension TranslationExtension on String {
  /// Translates the string using the current language in LanguageProvider.
  /// Usage: 'welcome'.tr(context)
  String tr(BuildContext context) {
    return Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).translate(this);
  }
}

class TranslateString {
  final String key;
  TranslateString(this.key);

  String tr(BuildContext context) {
    return Provider.of<LanguageProvider>(context, listen: false).translate(key);
  }
}
