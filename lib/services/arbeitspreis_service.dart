// lib/services/arbeitspreis_service.dart

import '../models/arbeitspreis_data.dart';
import '../models/index_data.dart';

/// Service zur Berechnung der Arbeitspreise nach § 8
///
/// Quartalspreise werden mit Mittelwert von n-4 bis n-2 Monaten berechnet
class ArbeitspreisService {

  /// Berechne Gas-Quartalspreise
  List<QuartalsPreis> berechneGasQuartalspreise({
    required List<IndexData> kGasData, // GP19-352222
    required List<IndexData> mGasData, // CC13-77
  }) {
    return _berechneQuartalspreise(
      typ: 'gas',
      kData: kGasData,
      mData: mGasData,
      startpreis: ArbeitspreisKonstanten.ap0Gas,
      kBasis: ArbeitspreisKonstanten.kGasBasis,
      mBasis: ArbeitspreisKonstanten.mGasBasis,
    );
  }

  /// Berechne Strom-Quartalspreise
  List<QuartalsPreis> berechneStromQuartalspreise({
    required List<IndexData> kStromData, // GP19-351113
    required List<IndexData> mStromData, // GP19-351112
  }) {
    return _berechneQuartalspreise(
      typ: 'strom',
      kData: kStromData,
      mData: mStromData,
      startpreis: ArbeitspreisKonstanten.ap0Strom,
      kBasis: ArbeitspreisKonstanten.kStromBasis,
      mBasis: ArbeitspreisKonstanten.mStromBasis,
    );
  }

  /// Interne Berechnung
  /// Interne Berechnung
  List<QuartalsPreis> _berechneQuartalspreise({
    required String typ,
    required List<IndexData> kData,
    required List<IndexData> mData,
    required double startpreis,
    required double kBasis,
    required double mBasis,
  }) {
    final quartale = <QuartalsPreis>[];

    // Finde alle möglichen Quartale aus den Daten
    final alleDaten = <DateTime>{};
    alleDaten.addAll(kData.map((d) => d.date));
    alleDaten.addAll(mData.map((d) => d.date));

    final sortedDates = alleDaten.toList()..sort();
    if (sortedDates.isEmpty) return quartale;

    // Gruppiere nach Quartalen
    final quartalsStarts = <DateTime>{};
    for (final date in sortedDates) {
      final quartalStart = ArbeitspreisKonstanten.getQuartalStart(date);
      quartalsStarts.add(quartalStart);
    }

    // 🆕 ERWEITERTE PRÜFUNG: Prüfe ob wir genug Daten für ein ZUKÜNFTIGES Quartal haben
    final letztesDate = sortedDates.last;
    final naechstesQuartal = _getNaechstesQuartal(ArbeitspreisKonstanten.getQuartalStart(letztesDate));
    final berechnungsmonateNaechstesQuartal = ArbeitspreisKonstanten.getBerechnungsmonate(naechstesQuartal);

    // Prüfe ob alle 3 Berechnungsmonate vorhanden sind
    final hatAlleBerechnungsmonate = berechnungsmonateNaechstesQuartal.every((monat) {
      return alleDaten.any((d) => d.year == monat.year && d.month == monat.month);
    });

    if (hatAlleBerechnungsmonate) {
      print('✅ Füge zukünftiges Quartal hinzu: Q${ArbeitspreisKonstanten.getQuartalNummer(naechstesQuartal)} ${naechstesQuartal.year}');
      quartalsStarts.add(naechstesQuartal);
    } else {
      print('❌ Zukünftiges Quartal nicht möglich - fehlende Berechnungsmonate');
    }

    final sortedQuartale = quartalsStarts.toList()..sort();

    // Berechne jeden Quartalspreis
    for (final quartalStart in sortedQuartale) {
      // Hole Berechnungsmonate (n-4, n-3, n-2)
      final berechnungsmonate = ArbeitspreisKonstanten.getBerechnungsmonate(quartalStart);

      // Hole Index-Werte für diese Monate
      final kWerte = <double>[];
      final mWerte = <double>[];

      for (final monat in berechnungsmonate) {
        final kWert = _findIndexValue(kData, monat);
        final mWert = _findIndexValue(mData, monat);

        if (kWert != null) kWerte.add(kWert);
        if (mWert != null) mWerte.add(mWert);
      }

      // Nur berechnen wenn alle 3 Werte vorhanden
      if (kWerte.length == 3 && mWerte.length == 3) {
        final kMittelwert = _berechneMittelwert(kWerte);
        final mMittelwert = _berechneMittelwert(mWerte);

        final berechnungsdaten = QuartalsBerechnungsdaten(
          typ: typ,
          monat1: berechnungsmonate[0],
          monat2: berechnungsmonate[1],
          monat3: berechnungsmonate[2],
          kWert1: kWerte[0],
          kWert2: kWerte[1],
          kWert3: kWerte[2],
          kMittelwert: kMittelwert,
          mWert1: mWerte[0],
          mWert2: mWerte[1],
          mWert3: mWerte[2],
          mMittelwert: mMittelwert,
          kBasis: kBasis,
          mBasis: mBasis,
          quartalBezeichnung: 'Q${ArbeitspreisKonstanten.getQuartalNummer(quartalStart)} ${quartalStart.year}',
        );

        final preis = _berechnePreis(
          startpreis: startpreis,
          kMittelwert: kMittelwert,
          mMittelwert: mMittelwert,
          kBasis: kBasis,
          mBasis: mBasis,
        );

        quartale.add(QuartalsPreis(
          quartal: quartalStart,
          quartalNummer: ArbeitspreisKonstanten.getQuartalNummer(quartalStart),
          jahr: quartalStart.year,
          preis: preis,
          berechnungsdaten: berechnungsdaten,
        ));
      }
    }

    return quartale;
  }

  /// Hilfsmethode: Berechne nächstes Quartal
  DateTime _getNaechstesQuartal(DateTime quartalStart) {
    return DateTime(quartalStart.year, quartalStart.month + 3, 1);
  }

  /// Berechne Preis nach Formel
  /// AP = Startpreis × (x × K_mittel / K_basis + (1-x) × M_mittel / M_basis)
  double _berechnePreis({
    required double startpreis,
    required double kMittelwert,
    required double mMittelwert,
    required double kBasis,
    required double mBasis,
  }) {
    const x = ArbeitspreisKonstanten.x;

    final kostenAnteil = x * (kMittelwert / kBasis);
    final marktAnteil = (1 - x) * (mMittelwert / mBasis);

    return startpreis * (kostenAnteil + marktAnteil);
  }

  /// Erstelle Quartals-Übersicht für Tabelle
  List<QuartalsUebersicht> erstelleQuartalsUebersicht(List<QuartalsPreis> preise) {
    return preise.map((p) {
      return QuartalsUebersicht(
        quartal: p.quartal,
        quartalNummer: p.quartalNummer,
        jahr: p.jahr,
        kMittelwert: p.berechnungsdaten.kMittelwert,
        mMittelwert: p.berechnungsdaten.mMittelwert,
        preis: p.preis,
      );
    }).toList();
  }

  /// Finde Index-Wert für ein bestimmtes Datum
  double? _findIndexValue(List<IndexData> data, DateTime date) {
    try {
      return data.firstWhere((d) =>
      d.date.year == date.year && d.date.month == date.month
      ).value;
    } catch (e) {
      return null;
    }
  }

  /// Berechne Mittelwert
  double _berechneMittelwert(List<double> werte) {
    if (werte.isEmpty) return 0;
    final summe = werte.fold<double>(0, (sum, w) => sum + w);
    return summe / werte.length;
  }
}