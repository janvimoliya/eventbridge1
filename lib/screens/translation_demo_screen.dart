import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../widgets/translatable_text.dart';

/// Demo screen showing real-time translation of all app content
class TranslationDemoScreen extends StatelessWidget {
  const TranslationDemoScreen({super.key});

  static const String routeName = '/translation-demo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatableText('Real-Time Translation Demo'),
      ),
      body: Consumer<TranslationProvider>(
        builder: (context, translationProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TranslatableText(
                          'Select Language',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _LanguageChip(
                              language: 'en',
                              label: 'English',
                              isSelected:
                                  translationProvider.currentLanguage == 'en',
                              onPressed: () =>
                                  translationProvider.setLanguage('en'),
                            ),
                            _LanguageChip(
                              language: 'hi',
                              label: 'हिंदी',
                              isSelected:
                                  translationProvider.currentLanguage == 'hi',
                              onPressed: () =>
                                  translationProvider.setLanguage('hi'),
                            ),
                            _LanguageChip(
                              language: 'gu',
                              label: 'ગુજરાતી',
                              isSelected:
                                  translationProvider.currentLanguage == 'gu',
                              onPressed: () =>
                                  translationProvider.setLanguage('gu'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sample Content - All translates in real-time
                const TranslatableText(
                  'Sample App Content',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ContentSection(
                          title: 'Welcome Message',
                          content:
                              'Welcome to EventBridge! Discover amazing events near you.',
                        ),
                        const SizedBox(height: 16),
                        _ContentSection(
                          title: 'Feature Highlight',
                          content:
                              'Find and book tickets for concerts, conferences, weddings, festivals, and workshops all in one place.',
                        ),
                        const SizedBox(height: 16),
                        _ContentSection(
                          title: 'Call to Action',
                          content:
                              'Sign up now to start exploring events and building your wishlist.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Common UI Elements
                const TranslatableText(
                  'Common UI Elements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: TranslatableText(
                                'Home',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const Expanded(
                              child: TranslatableText(
                                'Search',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const Expanded(
                              child: TranslatableText(
                                'Wishlist',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: TranslatableText(
                                'Wallet',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const Expanded(
                              child: TranslatableText(
                                'Profile',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const Expanded(
                              child: TranslatableText(
                                'Settings',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // How to Use
                const TranslatableText(
                  'How to Use Real-Time Translation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        TranslatableText(
                          '1. Select your preferred language from the options above',
                        ),
                        SizedBox(height: 8),
                        TranslatableText(
                          '2. Watch all text on this screen translate instantly',
                        ),
                        SizedBox(height: 8),
                        TranslatableText(
                          '3. Translations are cached for better performance',
                        ),
                        SizedBox(height: 8),
                        TranslatableText(
                          '4. The entire app supports this real-time translation feature',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Usage Instructions for Developers
                const TranslatableText(
                  'For Developers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TranslatableText(
                          'Replace Text with TranslatableText:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const TranslatableText(
                            "Text('Hello') → TranslatableText('Hello')",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String language;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _LanguageChip({
    required this.language,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onPressed(),
      label: Text(label),
      backgroundColor: isSelected
          ? Theme.of(context).primaryColor.withAlpha(200)
          : null,
    );
  }
}

class _ContentSection extends StatelessWidget {
  final String title;
  final String content;

  const _ContentSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatableText(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TranslatableText(content, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
