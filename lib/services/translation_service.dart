import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationService {
  // Free translation API endpoint (MyMemory Translated API - no key required)
  // Alternative: Google Translate API (requires API key and may incur costs)
  static const String _translationApiUrl =
      'https://api.mymemory.translated.net/get';

  // Language codes mapping
  static const Map<String, String> _languageCodes = {
    'en': 'en-US',
    'hi': 'hi-IN',
    'gu': 'gu-IN',
  };

  /// Translate text to target language
  /// Returns translated text or original text if translation fails
  static Future<String> translate(
    String text, {
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    if (text.isEmpty) {
      return text;
    }

    // If source and target are same, return original
    if (sourceLanguage == targetLanguage) {
      return text;
    }

    try {
      final response = await http
          .get(
            Uri.parse(_translationApiUrl).replace(
              queryParameters: {
                'q': text,
                'langpair': '$sourceLanguage|$targetLanguage',
              },
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseStatus'] == 200) {
          final translatedText = data['responseData']['translatedText'] ?? text;
          return translatedText;
        }
      }

      return text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  /// Translate multiple texts at once
  static Future<List<String>> translateMultiple(
    List<String> texts, {
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    final results = <String>[];

    for (final text in texts) {
      final translated = await translate(
        text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
      results.add(translated);
    }

    return results;
  }

  /// Get language code from locale
  static String getLanguageCode(String locale) {
    return _languageCodes[locale] ?? 'en-US';
  }

  /// Language names in different languages (for dropdown display)
  static String getLanguageName(String code, String targetLanguage) {
    final Map<String, Map<String, String>> languageNames = {
      'en': {'en': 'English', 'hi': 'English', 'gu': 'English'},
      'hi': {'en': 'Hindi', 'hi': 'हिंदी', 'gu': 'Hindi'},
      'gu': {'en': 'Gujarati', 'hi': 'Gujarati', 'gu': 'ગુજરાતી'},
    };

    return languageNames[code]?[targetLanguage] ?? code;
  }
}
