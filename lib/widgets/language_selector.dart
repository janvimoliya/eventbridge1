import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/translation_provider.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'gu': 'ગુજરાતી',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, TranslationProvider>(
      builder: (context, userProvider, translationProvider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LanguageButton(
                      code: 'en',
                      name: _languageNames['en']!,
                      isSelected: userProvider.languageCode == 'en',
                      onPressed: () async {
                        await userProvider.setLanguage('en');
                        await translationProvider.setLanguage('en');
                      },
                    ),
                    _LanguageButton(
                      code: 'hi',
                      name: _languageNames['hi']!,
                      isSelected: userProvider.languageCode == 'hi',
                      onPressed: () async {
                        await userProvider.setLanguage('hi');
                        await translationProvider.setLanguage('hi');
                      },
                    ),
                    _LanguageButton(
                      code: 'gu',
                      name: _languageNames['gu']!,
                      isSelected: userProvider.languageCode == 'gu',
                      onPressed: () async {
                        await userProvider.setLanguage('gu');
                        await translationProvider.setLanguage('gu');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String code;
  final String name;
  final bool isSelected;
  final VoidCallback onPressed;

  const _LanguageButton({
    required this.code,
    required this.name,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onPressed(),
      label: Text(name),
      avatar: isSelected
          ? const Icon(Icons.check_circle, size: 18)
          : CircleAvatar(
              radius: 9,
              child: Text(
                code.toUpperCase(),
                style: const TextStyle(fontSize: 8),
              ),
            ),
      backgroundColor: isSelected
          ? Theme.of(context).primaryColor.withAlpha(200)
          : null,
    );
  }
}
