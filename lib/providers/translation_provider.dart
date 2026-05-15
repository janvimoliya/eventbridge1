import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class TranslationProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  final Map<String, String> _translationCache = {};

  String get currentLanguage => _currentLanguage;

  /// Set the current language
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }

  /// Get translated text with caching
  Future<String> getText(String text, {String fromLanguage = 'en'}) async {
    // If current language is English, return original text
    if (_currentLanguage == 'en') {
      return text;
    }

    // Create cache key
    final cacheKey = '$text|$fromLanguage|$_currentLanguage';

    // Return from cache if available
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    // Fetch translation
    final translated = await TranslationService.translate(
      text,
      targetLanguage: _currentLanguage,
      sourceLanguage: fromLanguage,
    );

    // Cache the result
    _translationCache[cacheKey] = translated;

    return translated;
  }

  /// Get multiple translations with caching
  Future<List<String>> getTexts(
    List<String> texts, {
    String fromLanguage = 'en',
  }) async {
    final results = <String>[];

    for (final text in texts) {
      final translated = await getText(text, fromLanguage: fromLanguage);
      results.add(translated);
    }

    return results;
  }

  /// Clear translation cache
  void clearCache() {
    _translationCache.clear();
  }

  /// Get language name in current language
  String getLanguageName(String languageCode) {
    return TranslationService.getLanguageName(languageCode, _currentLanguage);
  }

  /// Get all available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'en', 'name': getLanguageName('en')},
      {'code': 'hi', 'name': getLanguageName('hi')},
      {'code': 'gu', 'name': getLanguageName('gu')},
    ];
  }
}
