// lib/models/waermepreis_data.dart

/// Wärmeanteil für ein Quartal (aus Firebase)
class WaermeanteilData {
  final int jahr;
  final int quartal;
  final double anteilGas; // yn (0-1)

  const WaermeanteilData({
    required this.jahr,
    required this.quartal,
    required this.anteilGas,
  });

  double get anteilStrom => 1.0 - anteilGas;

  String get quartalKey => '$jahr-q$quartal';

  factory WaermeanteilData.fromMap(Map<String, dynamic> map) {
    return WaermeanteilData(
      jahr: map['jahr'] as int,
      quartal: map['quartal'] as int,
      anteilGas: (map['anteilGas'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jahr': jahr,
      'quartal': quartal,
      'anteilGas': anteilGas,
    };
  }
}

/// Berechneter Wärmepreis für ein Quartal
class QuartalsWaermepreis {
  final DateTime quartal;
  final int quartalNummer;
  final int jahr;

  // Anteile
  final double anteilGas;
  final double anteilStrom;

  // Arbeitspreise (Basis)
  final double gasArbeitspreis; // ct/kWh
  final double stromArbeitspreis; // ct/kWh

  // Gewichtete Wärmepreise
  final double waermepreisGasAnteil; // yn * AP_Gas
  final double waermepreisStromAnteil; // (1-yn) * AP_Strom
  final double waermepreisGesamt; // Summe

  const QuartalsWaermepreis({
    required this.quartal,
    required this.quartalNummer,
    required this.jahr,
    required this.anteilGas,
    required this.anteilStrom,
    required this.gasArbeitspreis,
    required this.stromArbeitspreis,
    required this.waermepreisGasAnteil,
    required this.waermepreisStromAnteil,
    required this.waermepreisGesamt,
  });

  String get bezeichnung => 'Q$quartalNummer $jahr';
}