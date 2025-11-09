// lib/models/index_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model für Energie-Index Datenpunkte
///
/// Repräsentiert einen einzelnen Datenpunkt eines Energie-Index
/// (Erdgas, Strom, Wärme) zu einem bestimmten Zeitpunkt
class IndexData {
  /// Datum des Datenpunkts (normalerweise Monatserster)
  final DateTime date;

  /// Index-Wert (z.B. 105.2 für 2020=100)
  final double value;

  /// Index-Code (z.B. 'ERDGAS_GEWERBE')
  final String indexCode;

  /// Optional: Änderung zum Vormonat in Prozent
  final double? monthlyChange;

  /// Optional: Änderung zum Vorjahr in Prozent
  final double? yearlyChange;

  IndexData({
    required this.date,
    required this.value,
    required this.indexCode,
    this.monthlyChange,
    this.yearlyChange,
  });

  // ========================================
  // JSON SERIALISIERUNG (für API)
  // ========================================

  /// Erstelle IndexData aus JSON
  factory IndexData.fromJson(Map<String, dynamic> json) {
    return IndexData(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      indexCode: json['indexCode'] as String,
      monthlyChange: json['monthlyChange'] != null
          ? (json['monthlyChange'] as num).toDouble()
          : null,
      yearlyChange: json['yearlyChange'] != null
          ? (json['yearlyChange'] as num).toDouble()
          : null,
    );
  }

  /// Konvertiere zu JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'indexCode': indexCode,
      if (monthlyChange != null) 'monthlyChange': monthlyChange,
      if (yearlyChange != null) 'yearlyChange': yearlyChange,
    };
  }

  // ========================================
  // FIRESTORE SERIALISIERUNG
  // ========================================

  /// Erstelle IndexData aus Firestore Document
  factory IndexData.fromFirestore(Map<String, dynamic> data) {
    return IndexData(
      date: (data['date'] as Timestamp).toDate(),
      value: (data['value'] as num).toDouble(),
      indexCode: data['indexCode'] as String,
      monthlyChange: data['monthlyChange'] != null
          ? (data['monthlyChange'] as num).toDouble()
          : null,
      yearlyChange: data['yearlyChange'] != null
          ? (data['yearlyChange'] as num).toDouble()
          : null,
    );
  }

  /// Konvertiere zu Firestore Format
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'value': value,
      'indexCode': indexCode,
      if (monthlyChange != null) 'monthlyChange': monthlyChange,
      if (yearlyChange != null) 'yearlyChange': yearlyChange,
    };
  }

  // ========================================
  // UTILITY METHODEN
  // ========================================

  /// Erstelle eine Kopie mit geänderten Werten
  IndexData copyWith({
    DateTime? date,
    double? value,
    String? indexCode,
    double? monthlyChange,
    double? yearlyChange,
  }) {
    return IndexData(
      date: date ?? this.date,
      value: value ?? this.value,
      indexCode: indexCode ?? this.indexCode,
      monthlyChange: monthlyChange ?? this.monthlyChange,
      yearlyChange: yearlyChange ?? this.yearlyChange,
    );
  }

  /// Berechne die Änderungsrate zwischen zwei IndexData Objekten
  /// Returns: Prozentuale Änderung (z.B. 5.2 für +5.2%)
  static double calculateChange(IndexData from, IndexData to) {
    if (from.value == 0) return 0.0;
    return ((to.value - from.value) / from.value) * 100;
  }

  @override
  String toString() {
    return 'IndexData(date: ${date.year}-${date.month}, value: $value, code: $indexCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IndexData &&
        other.date == date &&
        other.value == value &&
        other.indexCode == indexCode;
  }

  @override
  int get hashCode => Object.hash(date, value, indexCode);
}

/// Model für aggregierte Jahres-Daten
///
/// Fasst mehrere Monatsdaten zu Jahreswerten zusammen
class JahresIndexData {
  /// Jahr
  final int jahr;

  /// Durchschnittlicher Index-Wert des Jahres
  final double durchschnitt;

  /// Minimum-Wert im Jahr
  final double minimum;

  /// Maximum-Wert im Jahr
  final double maximum;

  /// Index-Code
  final String indexCode;

  /// Anzahl der Monate mit Daten (normalerweise 12)
  final int anzahlMonate;

  /// Ist das Jahr noch nicht vollständig? (aktuelles Jahr)
  final bool istVorlaeufig;

  JahresIndexData({
    required this.jahr,
    required this.durchschnitt,
    required this.minimum,
    required this.maximum,
    required this.indexCode,
    required this.anzahlMonate,
    required this.istVorlaeufig,
  });

  /// Erstelle JahresIndexData aus einer Liste von Monatsdaten
  factory JahresIndexData.fromMonthlyData(
      int jahr,
      List<IndexData> monthlyData,
      String indexCode,
      ) {
    if (monthlyData.isEmpty) {
      throw ArgumentError('monthlyData darf nicht leer sein');
    }

    final values = monthlyData.map((d) => d.value).toList();
    final durchschnitt = values.reduce((a, b) => a + b) / values.length;
    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);

    final currentYear = DateTime.now().year;
    final istVorlaeufig = jahr == currentYear && monthlyData.length < 12;

    return JahresIndexData(
      jahr: jahr,
      durchschnitt: durchschnitt,
      minimum: minimum,
      maximum: maximum,
      indexCode: indexCode,
      anzahlMonate: monthlyData.length,
      istVorlaeufig: istVorlaeufig,
    );
  }

  /// Erstelle JahresIndexData aus JSON
  factory JahresIndexData.fromJson(Map<String, dynamic> json) {
    return JahresIndexData(
      jahr: json['jahr'] as int,
      durchschnitt: (json['durchschnitt'] as num).toDouble(),
      minimum: (json['minimum'] as num).toDouble(),
      maximum: (json['maximum'] as num).toDouble(),
      indexCode: json['indexCode'] as String,
      anzahlMonate: json['anzahlMonate'] as int,
      istVorlaeufig: json['istVorlaeufig'] as bool,
    );
  }

  /// Konvertiere zu JSON
  Map<String, dynamic> toJson() {
    return {
      'jahr': jahr,
      'durchschnitt': durchschnitt,
      'minimum': minimum,
      'maximum': maximum,
      'indexCode': indexCode,
      'anzahlMonate': anzahlMonate,
      'istVorlaeufig': istVorlaeufig,
    };
  }

  @override
  String toString() {
    return 'JahresIndexData(jahr: $jahr, Ø: ${durchschnitt.toStringAsFixed(1)}, ${istVorlaeufig ? 'vorläufig' : 'final'})';
  }
}