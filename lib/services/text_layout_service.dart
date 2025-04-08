//import 'services/text_layout_service.dart';
import 'package:flutter/material.dart';
import '../models/document/document.dart';

class TextLayoutService {
  List<TextSpan> applyTextWrapping({
    required String text,
    required List<DocumentElement> elements,
    required double maxWidth,
  }) {
    final textElements = elements.where((e) => e.type == 'text').toList();
    final textSpans = <TextSpan>[];

    for (final element in textElements) {
      final properties = element.properties;
      final textStyle = TextStyle(
        fontSize: properties['fontSize']?.toDouble() ?? 14,
        fontWeight: properties['isBold'] == true ? FontWeight.bold : null,
        color: _parseColor(properties['color']),
      );

      final textSpan = TextSpan(
        text: properties['text'],
        style: textStyle,
      );

      textSpans.add(textSpan);
    }

    return textSpans;
  }

  Color? _parseColor(dynamic colorValue) {
    if (colorValue is int) {
      return Color(colorValue);
    }
    return null;
  }
}