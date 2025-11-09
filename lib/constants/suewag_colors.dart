// lib/constants/suewag_colors.dart

import 'package:flutter/material.dart';

/// Süwag/Syna Corporate Design Farben
/// Basierend auf dem offiziellen Farbkonzept
class SuewagColors {
  // ========================================
  // PASTELL FARBEN
  // ========================================

  /// Bischofsrot (Pastell) - Rosa/Pink
  static const Color bischofsrot = Color(0xFFd56aa6);

  /// Altrosa (Pastell)
  static const Color altrosa = Color(0xFFf19f9c);

  /// Kerzengelb (Pastell)
  static const Color kerzengelb = Color(0xFFf5a26c);

  /// Orientgelb (Pastell)
  static const Color orientgelb = Color(0xFFfdc75f);

  /// Fasergrün (Pastell) - Hellgrün
  static const Color fasergruen = Color(0xFFc7d540);

  /// Arktisgrün (Pastell) - Türkis
  static const Color arktisgruen = Color(0xFF52bbb5);

  /// Karibikblau (Pastell)
  static const Color karibikblau = Color(0xFF7ccef4);

  // ========================================
  // BRIGHT FARBEN (Kräftigere Varianten)
  // ========================================

  /// Brilliantkarmin (Bright) - Kräftiges Pink
  static const Color brilliantkarmin = Color(0xFFc82285);

  /// Erdbeerrot (Bright)
  static const Color erdbeerrot = Color(0xFFe50056);

  /// Verkehrsorange (Bright)
  static const Color verkehrsorange = Color(0xFFe84e0f);

  /// Dahliengelb (Bright)
  static const Color dahliengelb = Color(0xFFf59c00);

  /// Leuchtendgrün (Bright)
  static const Color leuchtendgruen = Color(0xFF65b32e);

  /// Indiablau (Bright) - Kräftiges Türkis
  static const Color indiablau = Color(0xFF009ba4);

  /// Alpenblau (Bright)
  static const Color alpenblau = Color(0xFF00a7e0);

  // ========================================
  // GRAUTÖNE (Buntaufbau)
  // ========================================

  /// Quartzgrau 100% - Dunkelster Grauton
  static const Color quartzgrau100 = Color(0xFF6a6562);

  /// Quartzgrau 75%
  static const Color quartzgrau75 = Color(0xFF938e8c);

  /// Quartzgrau 50%
  static const Color quartzgrau50 = Color(0xFFbab5b3);

  /// Quartzgrau 25%
  static const Color quartzgrau25 = Color(0xFFdddbd0);

  /// Quartzgrau 10% - Hellster Grauton
  static const Color quartzgrau10 = Color(0xFFf6f4f4);

  // ========================================
  // GRAUTÖNE (Unbuntaufbau) - Für Neutralität
  // ========================================

  /// Quartzgrau Unbunt 100%
  static const Color quartzgrauUnbunt100 = Color(0xFF666665);

  /// Quartzgrau Unbunt 75%
  static const Color quartzgrauUnbunt75 = Color(0xFF909090);

  /// Quartzgrau Unbunt 50%
  static const Color quartzgrauUnbunt50 = Color(0xFFb9b8b8);

  /// Quartzgrau Unbunt 25%
  static const Color quartzgrauUnbunt25 = Color(0xFFdedede);

  /// Quartzgrau Unbunt 10%
  static const Color quartzgrauUnbunt10 = Color(0xFFf4f4f4);

  // ========================================
  // SCHWARZ & WEIẞ
  // ========================================

  /// Schwarz
  static const Color schwarz = Color(0xFF000000);

  /// Weiß
  static const Color weiss = Color(0xFFffffff);

  // ========================================
  // ANWENDUNGSSPEZIFISCHE FARBEN
  // ========================================

  /// Primärfarbe für die App (Energie-Thema)
  static const Color primary = SuewagColors.quartzgrau75;

  /// Sekundärfarbe
  static const Color secondary = leuchtendgruen;

  /// Akzentfarbe
  static const Color accent = verkehrsorange;

  /// Hintergrundfarbe
  static const Color background = weiss;

  /// Hintergrund für Cards
  static const Color cardBackground = quartzgrau10;

  /// Text Primär (Dunkel)
  static const Color textPrimary = quartzgrau100;

  /// Text Sekundär (Mittel)
  static const Color textSecondary = quartzgrau75;

  /// Text Disabled (Hell)
  static const Color textDisabled = quartzgrau50;

  /// Divider / Border Farbe
  static const Color divider = quartzgrau25;

  // ========================================
  // INDEX-SPEZIFISCHE FARBEN
  // ========================================

  /// Erdgas Farbe (Orange-Ton für Gas)
  static const Color erdgas = verkehrsorange;

  /// Strom Farbe (Gelb-Ton für Elektrizität)
  static const Color strom = dahliengelb;

  /// Wärme Farbe (Rot-Ton für Wärme)
  static const Color waerme = erdbeerrot;

  /// Chart Farbe 1 (für Gewerbe)
  static const Color chartGewerbe = indiablau;

  /// Chart Farbe 2 (für Haushalte)
  static const Color chartHaushalte = leuchtendgruen;
}

/// Extension für Material Color Shades
extension SuewagColorExtension on Color {
  /// Erstelle eine hellere Variante der Farbe
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Erstelle eine dunklere Variante der Farbe
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}