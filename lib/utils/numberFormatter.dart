// lib/utils/german_number_formatter.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class GermanNumberInputFormatter extends TextInputFormatter {
  final int nachkommastellen;

  GermanNumberInputFormatter({this.nachkommastellen = 2});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Erlaube nur Ziffern, Punkt (Tausender) und Komma (Dezimal)
    String text = newValue.text;

    // Entferne alle ungültigen Zeichen
    text = text.replaceAll(RegExp(r'[^\d\.,]'), '');

    return TextEditingValue(
      text: text,
      selection: newValue.selection,
    );
  }
}

/// Formatiert eine Zahl im deutschen Format (Tausenderpunkt, Komma als Dezimaltrennzeichen)
/// Formatiert eine Zahl im deutschen Format (Tausenderpunkt, Komma als Dezimaltrennzeichen)
String deutscheZahl(double wert, int nachkommastellen) {
  if (nachkommastellen == 0) {
    // Keine Nachkommastellen - kein Komma anzeigen
    final formatter = NumberFormat('#,##0', 'de_DE');
    return formatter.format(wert);
  } else {
    // Mit Nachkommastellen
    final formatter = NumberFormat('#,##0.${'0' * nachkommastellen}', 'de_DE');
    return formatter.format(wert);
  }
}

/// Parst einen deutschen Zahlenstring zu double
/// Beispiel: "1.234,56" -> 1234.56
double? parseGermanNumber(String text) {
  if (text.isEmpty) return null;

  // Entferne Tausenderpunkte und ersetze Komma durch Punkt
  String normalized = text.replaceAll('.', '').replaceAll(',', '.');

  return double.tryParse(normalized);
}