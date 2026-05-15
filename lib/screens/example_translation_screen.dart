import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import '../widgets/translatable_text.dart';

/// Example Screen: Complete Real-Time Translation Implementation
///
/// This screen demonstrates how to properly implement real-time translation
/// for your entire app. Use this as a template for other screens.
class ExampleTranslationScreen extends StatelessWidget {
  const ExampleTranslationScreen({super.key});

  static const String routeName = '/example-translation';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Translate AppBar title
      appBar: AppBar(
        title: const TranslatableText('Example Screen'),
        centerTitle: true,
      ),
      body: Consumer<TranslationProvider>(
        builder: (context, translationProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Section Header
                const TranslatableText(
                  'Section 1: Basic Text Translation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // ✅ Card with multiple translated texts
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        TranslatableText(
                          'This text translates in real-time',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        TranslatableText(
                          'Select a language at the top to see instant translation',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Section with styled text
                const TranslatableText(
                  'Section 2: Styled Text',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatableText(
                          'Bold Important Text',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TranslatableText(
                          'Subtitle or description goes here',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        TranslatableText(
                          'Caption text in smaller font',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Section with list items
                const TranslatableText(
                  'Section 3: List Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.done),
                        title: TranslatableText('Feature One'),
                        subtitle: TranslatableText(
                          'Description of feature one',
                        ),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.done),
                        title: TranslatableText('Feature Two'),
                        subtitle: TranslatableText(
                          'Description of feature two',
                        ),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.done),
                        title: TranslatableText('Feature Three'),
                        subtitle: TranslatableText(
                          'Description of feature three',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Section with buttons
                const TranslatableText(
                  'Section 4: Buttons with Translation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: TranslatableText('Button pressed!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const TranslatableText('Primary Action'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info),
                    label: const TranslatableText('Secondary Action'),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Section with long text
                const TranslatableText(
                  'Section 5: Long Text Handling',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        TranslatableText(
                          'This is a longer paragraph that demonstrates how the translation system handles longer text. '
                          'The text will wrap automatically and translate smoothly without any issues. '
                          'Real-time translation works for all text lengths.',
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Section with current language info
                const TranslatableText(
                  'Section 6: Current Language Info',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const TranslatableText(
                              'Current Language:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              translationProvider.currentLanguage.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const TranslatableText(
                          'This value updates instantly when you change the language from your profile settings.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// How to Use This Template
/// 
/// 1. Copy this file and rename it to your screen name
/// 2. Replace the content with your actual screen design
/// 3. Use TranslatableText() for ALL text that should be translatable
/// 4. Keep the Consumer<TranslationProvider> wrapper at the top
/// 5. That's it! Your entire screen is now real-time translatable
/// 
/// Pattern to Remember:
/// 
/// ✅ GOOD: TranslatableText('Text here')
/// ❌ BAD:  Text('Text here')
/// 
/// ✅ GOOD: const TranslatableText('Text')
/// ❌ BAD:  const Text('Text')
/// 
/// Import needed:
/// import '../widgets/translatable_text.dart';
