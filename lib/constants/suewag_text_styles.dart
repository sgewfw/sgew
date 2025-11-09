// lib/constants/suewag_text_styles.dart

import 'package:flutter/material.dart';
import 'suewag_colors.dart';

/// Süwag/Syna Text Styles
///
/// Definiert konsistente Text-Stile für die gesamte App
/// basierend auf dem Corporate Design
class SuewagTextStyles {

  // ========================================
  // HEADLINES / ÜBERSCHRIFTEN
  // ========================================

  /// Große Überschrift (z.B. Seitentitel)
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: SuewagColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Mittlere Überschrift (z.B. Section-Titel)
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: SuewagColors.textPrimary,
    letterSpacing: -0.3,
  );

  /// Kleine Überschrift (z.B. Card-Titel)
  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: SuewagColors.textPrimary,
  );

  /// Mini-Überschrift (z.B. Widget-Header)
  static const TextStyle headline4 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: SuewagColors.textPrimary,
  );

  // ========================================
  // BODY TEXT / FLIESSTEXT
  // ========================================

  /// Standard Body Text (Groß)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: SuewagColors.textPrimary,
    height: 1.5,
  );

  /// Standard Body Text (Medium)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: SuewagColors.textPrimary,
    height: 1.4,
  );

  /// Standard Body Text (Klein)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: SuewagColors.textSecondary,
    height: 1.3,
  );

  // ========================================
  // LABELS / BESCHRIFTUNGEN
  // ========================================

  /// Label (Groß) - z.B. für Buttons
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SuewagColors.textPrimary,
    letterSpacing: 0.5,
  );

  /// Label (Medium) - z.B. für Form-Felder
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: SuewagColors.textPrimary,
    letterSpacing: 0.3,
  );

  /// Label (Klein) - z.B. für Tags
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: SuewagColors.textSecondary,
    letterSpacing: 0.5,
  );

  // ========================================
  // ZAHLEN / STATISTIKEN
  // ========================================

  /// Große Zahl (z.B. Hauptmetrik)
  static const TextStyle numberLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: SuewagColors.textPrimary,
    letterSpacing: -1.0,
  );

  /// Mittlere Zahl (z.B. Kennzahl)
  static const TextStyle numberMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: SuewagColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Kleine Zahl (z.B. in Tabellen)
  static const TextStyle numberSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SuewagColors.textPrimary,
  );

  // ========================================
  // CAPTIONS / HILFSTEXT
  // ========================================

  /// Caption Text (z.B. unter Bildern, Timestamps)
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: SuewagColors.textSecondary,
  );

  /// Overline (z.B. Kategorie-Labels über Content)
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: SuewagColors.textSecondary,
    letterSpacing: 1.0,
  );

  // ========================================
  // STATUS / FEEDBACK
  // ========================================

  /// Erfolgs-Text (Grün)
  static TextStyle success = bodyMedium.copyWith(
    color: SuewagColors.leuchtendgruen,
    fontWeight: FontWeight.w600,
  );

  /// Warn-Text (Orange)
  static TextStyle warning = bodyMedium.copyWith(
    color: SuewagColors.verkehrsorange,
    fontWeight: FontWeight.w600,
  );

  /// Fehler-Text (Rot)
  static TextStyle error = bodyMedium.copyWith(
    color: SuewagColors.erdbeerrot,
    fontWeight: FontWeight.w600,
  );

  /// Info-Text (Blau)
  static TextStyle info = bodyMedium.copyWith(
    color: SuewagColors.indiablau,
    fontWeight: FontWeight.w600,
  );

  // ========================================
  // BUTTONS
  // ========================================

  /// Button Text (Groß)
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  /// Button Text (Medium)
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Button Text (Klein)
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // ========================================
  // TABELLEN
  // ========================================

  /// Tabellen-Header
  static const TextStyle tableHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: SuewagColors.textPrimary,
    letterSpacing: 0.3,
  );

  /// Tabellen-Zelle
  static const TextStyle tableCell = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: SuewagColors.textPrimary,
  );

  /// Tabellen-Zahl (rechtsbündig)
  static const TextStyle tableNumber = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: SuewagColors.textPrimary,
  );

  // ========================================
  // CHARTS
  // ========================================

  /// Chart-Achsen-Label
  static const TextStyle chartAxisLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: SuewagColors.textSecondary,
  );

  /// Chart-Datenlabel
  static const TextStyle chartDataLabel = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: SuewagColors.textPrimary,
  );

  /// Chart-Legende
  static const TextStyle chartLegend = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: SuewagColors.textPrimary,
  );
}

/// Extension für schnelle Style-Anpassungen
extension TextStyleExtension on TextStyle {
  /// Setze Farbe
  TextStyle withColor(Color color) {
    return copyWith(color: color);
  }

  /// Setze Größe
  TextStyle withSize(double size) {
    return copyWith(fontSize: size);
  }

  /// Setze Fettdruck
  TextStyle bold() {
    return copyWith(fontWeight: FontWeight.bold);
  }

  /// Setze Semibold
  TextStyle semiBold() {
    return copyWith(fontWeight: FontWeight.w600);
  }

  /// Setze Normal
  TextStyle normal() {
    return copyWith(fontWeight: FontWeight.normal);
  }
}