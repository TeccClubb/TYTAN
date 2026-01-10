import 'dart:convert';

class Language {
  final String name;
  final String code;
  final bool isRtl;
  final bool isDefault;
  final Map<String, dynamic>? translations;

  Language({
    required this.name,
    required this.code,
    required this.isRtl,
    required this.isDefault,
    this.translations,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    Map<String, String>? translationsMap;

    if (json['translations'] != null) {
      // Parse the translations JSON string into a Map
      final translationData = jsonDecode(json['translations'] as String);
      translationsMap = Map<String, String>.from(translationData as Map);
    }

    return Language(
      name: json['name'] as String,
      code: json['code'] as String,
      isRtl: json['is_rtl'] as bool,
      isDefault: json['default'] as bool,
      translations: translationsMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'is_rtl': isRtl,
    'default': isDefault,
    'translations': translations != null ? jsonEncode(translations) : null,
  };
}
