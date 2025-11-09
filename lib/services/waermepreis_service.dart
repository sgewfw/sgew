// lib/services/waermepreis_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/arbeitspreis_data.dart';
import '../models/waermepreis_data.dart';

class WaermepreisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lade Wärmeanteile aus Firebase
  Future<List<WaermeanteilData>> ladeWaermeanteile() async {
    try {
      final snapshot = await _firestore
          .collection('waermeanteile')
          .orderBy('jahr')
          .orderBy('quartal')
          .get();

      return snapshot.docs
          .map((doc) => WaermeanteilData.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Fehler beim Laden der Wärmeanteile: $e');
      return [];
    }
  }

  /// Berechne Wärmepreise basierend auf Gas/Strom-Arbeitspreisen und Wärmeanteilen
  List<QuartalsWaermepreis> berechneWaermepreise({
    required List<QuartalsPreis> gasPreise,
    required List<QuartalsPreis> stromPreise,
    required List<WaermeanteilData> waermeanteile,
  }) {
    final waermepreise = <QuartalsWaermepreis>[];

    // Für jedes Quartal mit Wärmeanteil
    for (final anteil in waermeanteile) {
      // Finde passende Gas- und Strom-Arbeitspreise
      QuartalsPreis? gasPreis;
      QuartalsPreis? stromPreis;

      try {
        gasPreis = gasPreise.firstWhere(
              (p) => p.jahr == anteil.jahr && p.quartalNummer == anteil.quartal,
        );
      } catch (e) {
        continue; // Kein Gas-Preis gefunden
      }

      try {
        stromPreis = stromPreise.firstWhere(
              (p) => p.jahr == anteil.jahr && p.quartalNummer == anteil.quartal,
        );
      } catch (e) {
        continue; // Kein Strom-Preis gefunden
      }

      // Berechne gewichtete Wärmepreise
      final waermepreisGasAnteil = anteil.anteilGas * gasPreis.preis;
      final waermepreisStromAnteil = anteil.anteilStrom * stromPreis.preis;
      final waermepreisGesamt = waermepreisGasAnteil + waermepreisStromAnteil;

      waermepreise.add(QuartalsWaermepreis(
        quartal: gasPreis.quartal,
        quartalNummer: anteil.quartal,
        jahr: anteil.jahr,
        anteilGas: anteil.anteilGas,
        anteilStrom: anteil.anteilStrom,
        gasArbeitspreis: gasPreis.preis,
        stromArbeitspreis: stromPreis.preis,
        waermepreisGasAnteil: waermepreisGasAnteil,
        waermepreisStromAnteil: waermepreisStromAnteil,
        waermepreisGesamt: waermepreisGesamt,
      ));
    }

    return waermepreise;
  }
}