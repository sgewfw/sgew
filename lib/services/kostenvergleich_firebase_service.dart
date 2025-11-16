// lib/services/kostenvergleich_firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kostenvergleich_data.dart';

class KostenvergleichFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _stammdatenCollection =>
      _firestore.collection('kostenvergleich_stammdaten');

  CollectionReference get _metadataCollection =>
      _firestore.collection('kostenvergleich_metadata');

  /// Lade aktuelles Jahr (für User)
  Future<int?> getAktuellesJahr() async {
    try {
      final doc = await _metadataCollection.doc('aktiv').get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['jahr'] as int;
      }
      return null;
    } catch (e) {
      print('❌ Fehler beim Laden des aktuellen Jahres: $e');
      return null;
    }
  }

  /// Setze aktives Jahr
  Future<void> setzeAktivesJahr(int jahr) async {
    try {
      await _metadataCollection.doc('aktiv').set({
        'jahr': jahr,
        'aktualisiertAm': FieldValue.serverTimestamp(),
      });
      print('✅ Aktives Jahr auf $jahr gesetzt');
    } catch (e) {
      print('❌ Fehler beim Setzen des aktiven Jahres: $e');
      rethrow;
    }
  }

  /// Lade Stammdaten für ein Jahr
  Future<KostenvergleichJahr?> ladeStammdaten(int jahr) async {
    try {
      final doc = await _stammdatenCollection.doc(jahr.toString()).get();

      if (!doc.exists) {
        print('⚠️ Keine Stammdaten für Jahr $jahr gefunden');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return KostenvergleichJahr.fromMap(data);
    } catch (e) {
      print('❌ Fehler beim Laden der Stammdaten für $jahr: $e');
      return null;
    }
  }

  /// Lade alle verfügbaren Jahre (für Admin)
  Future<List<int>> ladeVerfuegbareJahre() async {
    try {
      final snapshot = await _stammdatenCollection.get();

      final jahre = snapshot.docs
          .map((doc) => int.tryParse(doc.id))
          .where((jahr) => jahr != null)
          .cast<int>()
          .toList();

      jahre.sort((a, b) => b.compareTo(a)); // Neueste zuerst

      return jahre;
    } catch (e) {
      print('❌ Fehler beim Laden der verfügbaren Jahre: $e');
      return [];
    }
  }

  /// Speichere Stammdaten
  Future<void> speichereStammdaten(KostenvergleichJahr daten) async {
    try {
      await _stammdatenCollection
          .doc(daten.jahr.toString())
          .set(daten.toMap());

      print('✅ Stammdaten für ${daten.jahr} gespeichert');
    } catch (e) {
      print('❌ Fehler beim Speichern der Stammdaten: $e');
      rethrow;
    }
  }

  /// Erstelle neues Jahr aus Vorjahr
  Future<KostenvergleichJahr> kopiereVorjahr({
    required int neuesJahr,
    required int vorjahr,
  }) async {
    try {
      // Lade Vorjahr
      final vorjahrDaten = await ladeStammdaten(vorjahr);

      if (vorjahrDaten == null) {
        throw Exception('Vorjahr $vorjahr nicht gefunden');
      }

      // Erstelle Kopie für neues Jahr
      final neueDaten = vorjahrDaten.copyWith(
        id: neuesJahr.toString(),
        jahr: neuesJahr,
        gueltigAb: DateTime(neuesJahr, 1, 1),
        gueltigBis: DateTime(neuesJahr, 12, 31),
        erstelltAm: DateTime.now(),
        aktualisiertAm: null,
        istAktiv: false,
        status: 'entwurf',
      );

      // Speichere als Entwurf
      await speichereStammdaten(neueDaten);

      print('✅ Jahr $neuesJahr aus $vorjahr kopiert (Entwurf)');

      return neueDaten;
    } catch (e) {
      print('❌ Fehler beim Kopieren des Vorjahres: $e');
      rethrow;
    }
  }

  /// Aktiviere Jahr (nur eines kann aktiv sein)
  Future<void> aktiviereJahr(int jahr) async {
    try {
      // 1. Deaktiviere alle anderen Jahre
      final alleJahre = await ladeVerfuegbareJahre();

      for (final j in alleJahre) {
        if (j != jahr) {
          final daten = await ladeStammdaten(j);
          if (daten != null && daten.istAktiv) {
            await speichereStammdaten(daten.copyWith(
              istAktiv: false,
              status: 'archiviert',
              aktualisiertAm: DateTime.now(),
            ));
          }
        }
      }

      // 2. Aktiviere das gewünschte Jahr
      final daten = await ladeStammdaten(jahr);
      if (daten == null) {
        throw Exception('Jahr $jahr nicht gefunden');
      }

      await speichereStammdaten(daten.copyWith(
        istAktiv: true,
        status: 'aktiv',
        aktualisiertAm: DateTime.now(),
      ));

      // 3. Setze Metadata
      await setzeAktivesJahr(jahr);

      print('✅ Jahr $jahr aktiviert');
    } catch (e) {
      print('❌ Fehler beim Aktivieren des Jahres: $e');
      rethrow;
    }
  }

  /// Lösche Jahr
  Future<void> loescheJahr(int jahr) async {
    try {
      // Prüfe ob Jahr aktiv ist
      final daten = await ladeStammdaten(jahr);
      if (daten?.istAktiv == true) {
        throw Exception('Aktives Jahr kann nicht gelöscht werden');
      }

      await _stammdatenCollection.doc(jahr.toString()).delete();

      print('✅ Jahr $jahr gelöscht');
    } catch (e) {
      print('❌ Fehler beim Löschen des Jahres: $e');
      rethrow;
    }
  }

  /// Validiere Stammdaten
  List<String> validiereStammdaten(KostenvergleichJahr daten) {
    final fehler = <String>[];

    // Grunddaten prüfen
    if (daten.grunddaten.beheizteFlaeche.wert <= 0) {
      fehler.add('Beheizte Fläche muss größer 0 sein');
    }
    if (daten.grunddaten.heizenergiebedarf.wert <= 0) {
      fehler.add('Heizenergiebedarf muss größer 0 sein');
    }

    // Finanzierung prüfen
    if (daten.finanzierung.zinssatz.wert <= 0) {
      fehler.add('Zinssatz muss größer 0 sein');
    }
    if (daten.finanzierung.laufzeitJahre.wert <= 0) {
      fehler.add('Laufzeit muss größer 0 sein');
    }

    // Szenarien prüfen
    final erforderlicheSzenarien = [
      'waermepumpe',
      'waermenetzOhneUGS',
      'waermenetzKunde',
      'waermenetzSuewag',
    ];

    for (final szenarioId in erforderlicheSzenarien) {
      if (!daten.szenarien.containsKey(szenarioId)) {
        fehler.add('Szenario $szenarioId fehlt');
        continue;
      }

      final szenario = daten.szenarien[szenarioId]!;

      // Investitionskosten
      if (szenario.investition.gesamtBrutto < 0) {
        fehler.add('${szenario.bezeichnung}: Investitionskosten ungültig');
      }

      // Wärmekosten
      if (szenarioId == 'waermepumpe') {
        if (szenario.waermekosten.stromverbrauchKWh == null ||
            szenario.waermekosten.stromverbrauchKWh!.wert <= 0) {
          fehler.add('${szenario.bezeichnung}: Stromverbrauch fehlt');
        }
        if (szenario.waermekosten.stromarbeitspreisCtKWh == null) {
          fehler.add('${szenario.bezeichnung}: Stromarbeitspreis fehlt');
        }
        if (szenario.waermekosten.jahresarbeitszahl == null) {
          fehler.add('${szenario.bezeichnung}: JAZ fehlt');
        }
      } else {
        // Wärmenetz
        if (szenario.waermekosten.waermeGasArbeitspreisCtKWh == null) {
          fehler.add('${szenario.bezeichnung}: Wärme-Gas-Arbeitspreis fehlt');
        }
        if (szenario.waermekosten.waermeStromArbeitspreisCtKWh == null) {
          fehler.add('${szenario.bezeichnung}: Wärme-Strom-Arbeitspreis fehlt');
        }
      }
    }

    return fehler;
  }

  /// Stream für Echtzeit-Updates (optional)
  Stream<KostenvergleichJahr?> watchStammdaten(int jahr) {
    return _stammdatenCollection
        .doc(jahr.toString())
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return KostenvergleichJahr.fromMap(
        snapshot.data() as Map<String, dynamic>,
      );
    });
  }

  /// Stream für aktuelles Jahr (optional)
  Stream<int?> watchAktuellesJahr() {
    return _metadataCollection.doc('aktiv').snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return (snapshot.data() as Map<String, dynamic>)['jahr'] as int;
    });
  }
}