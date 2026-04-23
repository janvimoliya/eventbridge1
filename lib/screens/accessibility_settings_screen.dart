import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  static const String routeName = '/accessibility-settings';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.accessibilitySettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.accessibilitySettingsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.textSize,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: userProvider.textScaleFactor,
                    min: 0.9,
                    max: 1.4,
                    divisions: 5,
                    label: userProvider.textScaleFactor.toStringAsFixed(1),
                    onChanged: userProvider.setTextScaleFactor,
                  ),
                  Text(
                    strings.textScalePreview,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                strings.accessibilityTip,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
