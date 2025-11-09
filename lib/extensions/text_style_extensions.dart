// lib/extensions/text_style_extensions.dart

import 'package:flutter/material.dart';

/// Extensions für TextStyle
extension TextStyleExtensions on TextStyle {
  /// Erstelle TextStyle mit anderer Farbe
  TextStyle withColor(Color color) {
    return copyWith(color: color);
  }

  /// Erstelle TextStyle mit Bold
  TextStyle bold() {
    return copyWith(fontWeight: FontWeight.bold);
  }

  /// Erstelle TextStyle mit SemiBold
  TextStyle semiBold() {
    return copyWith(fontWeight: FontWeight.w600);
  }

  /// Erstelle TextStyle mit anderer Größe
  TextStyle withSize(double size) {
    return copyWith(fontSize: size);
  }
}

/// Extensions für Color
extension ColorExtensions on Color {
  /// Verdunkle Farbe
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Aufhellen Farbe
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}