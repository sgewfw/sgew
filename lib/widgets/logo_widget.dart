// lib/widgets/logo_widget.dart

import 'package:flutter/material.dart';

/// Wiederverwendbares Logo Widget
///
/// Verwendung: `const AppLogo()` oder `const AppLogo(height: 50)`
class AppLogo extends StatelessWidget {
  /// Höhe des Logos
  final double height;

  /// Breite des Logos (optional, sonst automatisch)
  final double? width;

  /// Fit-Modus
  final BoxFit fit;

  const AppLogo({
    Key? key,
    this.height = 40,
    this.width,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      width: width,
      fit: fit,
      // Fallback falls Logo nicht geladen werden kann
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.energy_savings_leaf,
          size: height * 0.8,
          color: Colors.white,
        );
      },
    );
  }
}

/// Kleine Logo-Variante (z.B. für Cards)
class SmallAppLogo extends StatelessWidget {
  const SmallAppLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AppLogo(height: 24);
  }
}

/// Große Logo-Variante (z.B. für Splash Screen)
class LargeAppLogo extends StatelessWidget {
  const LargeAppLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AppLogo(height: 120);
  }
}