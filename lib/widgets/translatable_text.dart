import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';

/// Widget that automatically translates text in real-time
/// Usage: TranslatableText('Your text here')
class TranslatableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;
  final double? textScaleFactor;
  final String sourceLanguage;

  const TranslatableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
    this.textScaleFactor,
    this.sourceLanguage = 'en',
  });

  @override
  State<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<TranslatableText> {
  late Future<String> _translationFuture;

  @override
  void initState() {
    super.initState();
    _updateTranslation();
  }

  void _updateTranslation() {
    final translationProvider = context.read<TranslationProvider>();
    _translationFuture = translationProvider.getText(
      widget.text,
      fromLanguage: widget.sourceLanguage,
    );
  }

  @override
  void didUpdateWidget(TranslatableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.sourceLanguage != widget.sourceLanguage) {
      _updateTranslation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, translationProvider, _) {
        // Trigger update when language changes
        _translationFuture = translationProvider.getText(
          widget.text,
          fromLanguage: widget.sourceLanguage,
        );

        return FutureBuilder<String>(
          future: _translationFuture,
          initialData: widget.text,
          builder: (context, snapshot) {
            final displayText = snapshot.data ?? widget.text;

            return Text(
              displayText,
              style: widget.style,
              textAlign: widget.textAlign,
              overflow: widget.overflow,
              maxLines: widget.maxLines,
              softWrap: widget.softWrap,
              textScaleFactor: widget.textScaleFactor,
            );
          },
        );
      },
    );
  }
}

/// Extension to quickly convert Text to TranslatableText
extension TranslatableTextExtension on String {
  /// Convert string to TranslatableText widget
  TranslatableText toTranslatableText({
    TextStyle? style,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    bool softWrap = true,
  }) {
    return TranslatableText(
      this,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}
