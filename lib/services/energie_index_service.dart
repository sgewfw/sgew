// lib/services/energie_index_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/index_data.dart';
import '../constants/destatis_constants.dart';

/// Service für Energie-Index Daten von Destatis
///
/// Holt Daten für:
/// - Erdgas (Gewerbe)
/// - Strom (Gewerbe & Haushalte)
/// - Wärmepreis-Index
///
/// Features:
/// - Firebase Cache (24h)
/// - Auto-Refresh bei veralteten Daten
/// - Nur Mobile kann API direkt nutzen (Security)
///
/// WICHTIG: Keine Demo-Daten! Wenn keine Daten verfügbar → NULL
class EnergieIndexService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // KONFIGURATION
  // ========================================

  /// Cache-Dauer: 24 Stunden
  static const Duration _cacheDuration = Duration(
    hours: DestatisConstants.cacheDauerStunden,
  );

  /// Basis-URL für Destatis API (Desktop/Mobile)
  static const String baseUrlDirect =
      'https://www-genesis.destatis.de/genesisWS/rest/2020';

  /// CORS-Proxy für Flutter Web
  static const String corsProxy = 'https://corsproxy.io/?';

  /// Dynamische Base-URL basierend auf Platform
  static String get baseUrl {
    if (kIsWeb) {
      print('🌐 [ENERGIE_INDEX] Using CORS proxy for Flutter Web');
      return '$corsProxy$baseUrlDirect';
    }
    print('💻 [ENERGIE_INDEX] Direct API access (Desktop/Mobile)');
    return baseUrlDirect;
  }

  // ========================================
  // CREDENTIALS MANAGEMENT
  // ========================================



  // ========================================
  // PUBLIC API - FIREBASE METHODEN
  // ========================================

  /// Lade Index-Daten aus Firebase
  ///
  /// Returns: List<IndexData> wenn Daten vorhanden, sonst leere Liste
  ///
  /// - Lädt gecachte Daten aus Firebase
  /// - Prüft automatisch Aktualität
  /// - Startet Background-Refresh wenn nötig (nur Mobile)
  /// - Returns LEERE LISTE wenn keine Daten verfügbar

// Neue Methode nach getLastUpdate() hinzufügen:

  /// Hole Destatis-Link für einen Index
  Future<String?> getIndexLink(String indexCode) async {
    try {
      final doc = await _firestore
          .collection('energie_indizes')
          .doc(indexCode)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      return data?['destatisLink'] as String?;
    } catch (e) {
      print('⚠️ [ENERGIE_INDEX] Fehler beim Laden des Links: $e');
      return null;
    }
  }
  Future<List<IndexData>> getIndexData({
    required String indexCode,
    bool forceRefresh = false,
  }) async {
    print('📖 [ENERGIE_INDEX] Lade Daten aus Firebase für $indexCode');
    print('🔍 [DEBUG] Firebase Collection: energie_indizes');
    print('🔍 [DEBUG] Document ID: $indexCode');

    try {
      final doc = await _firestore
          .collection('energie_indizes')
          .doc(indexCode)
          .get();

      print('🔍 [DEBUG] Firebase doc.exists = ${doc.exists}');

      if (!doc.exists) {
        print('⚠️ [ENERGIE_INDEX] Keine Daten in Firebase für $indexCode');
        print('🔍 [DEBUG] Versuche jetzt Auto-Refresh...');
        print('🔍 [DEBUG] kIsWeb = $kIsWeb');

        // IMMER versuchen zu refreshen
        print('🔄 [ENERGIE_INDEX] Starte initialen Refresh von API');

        try {
          print('🔍 [DEBUG] Rufe refreshIndexData auf...');

          await refreshIndexData(
            indexCode: indexCode,
            months: DestatisConstants.standardZeitraumMonate,
          );

          print('🔍 [DEBUG] refreshIndexData abgeschlossen');

          // Lade nochmal aus Firebase
          print('🔍 [DEBUG] Lade erneut aus Firebase...');
          final newDoc = await _firestore
              .collection('energie_indizes')
              .doc(indexCode)
              .get();

          print('🔍 [DEBUG] Zweiter Versuch: doc.exists = ${newDoc.exists}');

          if (newDoc.exists) {
            print('✅ [DEBUG] Daten gefunden nach Refresh!');
            return _parseFirestoreDoc(newDoc);
          } else {
            print('⚠️ [DEBUG] Auch nach Refresh keine Daten in Firebase');
          }
        } catch (e, stackTrace) {
          print('🔴 [ENERGIE_INDEX] Initialer Refresh fehlgeschlagen: $e');
          print('🔴 [DEBUG] StackTrace: $stackTrace');
        }

        // Falls alles fehlschlägt → Leere Liste
        print('⚠️ [ENERGIE_INDEX] Keine Daten verfügbar');
        return [];
      }

      final indexData = _parseFirestoreDoc(doc);

      print('✅ [ENERGIE_INDEX] ${indexData.length} Datenpunkte aus Firebase geladen');

      // Prüfe ob automatischer Refresh nötig ist
      if (!forceRefresh) {
        final needsRefresh = await _shouldRefresh(indexCode);

        if (needsRefresh) {
          print('🔄 [ENERGIE_INDEX] Starte automatischen Hintergrund-Refresh');

          // Starte Refresh im Hintergrund (ohne zu warten)
          refreshIndexData(
            indexCode: indexCode,
            months: DestatisConstants.standardZeitraumMonate,
          ).catchError((e) {
            print('🔴 [ENERGIE_INDEX] Hintergrund-Refresh fehlgeschlagen: $e');
          });
        }
      }

      return indexData;

    } catch (e, stackTrace) {
      print('🔴 [ENERGIE_INDEX] Fehler beim Laden aus Firebase: $e');
      print('🔴 [ENERGIE_INDEX] StackTrace: $stackTrace');

      // Keine Demo-Daten → Leere Liste
      return [];
    }
  }

  /// Parse Firestore Document zu IndexData Liste
  List<IndexData> _parseFirestoreDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> dataList = data['data'] ?? [];

    final indexData = dataList
        .map((item) => IndexData.fromFirestore(item as Map<String, dynamic>))
        .toList();

    // Sortiere nach Datum
    indexData.sort((a, b) => a.date.compareTo(b.date));

    return indexData;
  }

  /// Hole letztes Update-Datum
  Future<DateTime?> getLastUpdate(String indexCode) async {
    try {
      final doc = await _firestore
          .collection('energie_indizes')
          .doc(indexCode)
          .get();

      if (!doc.exists) return null;

      final timestamp = doc.data()?['lastUpdate'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      return null;
    }
  }

  /// Prüfe ob Daten verfügbar sind
  Future<bool> hasData(String indexCode) async {
    try {
      final doc = await _firestore
          .collection('energie_indizes')
          .doc(indexCode)
          .get();

      if (!doc.exists) return false;

      final dataList = doc.data()?['data'] as List?;
      return dataList != null && dataList.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Aktualisiere Daten von Destatis API (nur Mobile!)
  Future<void> refreshIndexData({
    required String indexCode,
    int months = 60,
  }) async {
    print('🔄 [ENERGIE_INDEX] === START REFRESH ===');
    print('🔄 [ENERGIE_INDEX] IndexCode: $indexCode');
    print('🔄 [ENERGIE_INDEX] Months: $months');
    print('🔄 [ENERGIE_INDEX] Platform: ${kIsWeb ? "WEB (via CORS Proxy)" : "MOBILE (Direct API)"}');

    try {
      print('🔍 [DEBUG] Rufe _fetchIndexFromAPI auf...');

      // Hole neue Daten von API (mit CORS Proxy für Web!)
      final data = await _fetchIndexFromAPI(
        indexCode: indexCode,
        months: months,
      );

      print('🔍 [DEBUG] _fetchIndexFromAPI returned ${data.length} items');

      if (data.isEmpty) {
        print('🔴 [DEBUG] Keine Daten von API erhalten!');
        throw Exception('Keine Daten von API erhalten');
      }

      print('🔍 [DEBUG] Speichere jetzt in Firebase...');

      // Speichere in Firebase
      await _saveToFirebase(indexCode, data);

      print('✅ [ENERGIE_INDEX] Daten erfolgreich aktualisiert');
      print('🔄 [ENERGIE_INDEX] === END REFRESH ===');

    } catch (e, stackTrace) {
      print('🔴 [ENERGIE_INDEX] Fehler beim Refresh: $e');
      print('🔴 [ENERGIE_INDEX] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Berechne Jahres-Durchschnitte aus Monatsdaten
  Future<List<JahresIndexData>> getJahresDurchschnitte({
    required String indexCode,
  }) async {
    final monthlyData = await getIndexData(indexCode: indexCode);

    if (monthlyData.isEmpty) return [];

    // Gruppiere nach Jahr
    final Map<int, List<IndexData>> jahresDaten = {};
    for (var data in monthlyData) {
      final jahr = data.date.year;
      jahresDaten.putIfAbsent(jahr, () => []).add(data);
    }

    // Erstelle JahresIndexData für jedes Jahr
    final List<JahresIndexData> jahresListe = [];
    for (var entry in jahresDaten.entries) {
      jahresListe.add(
        JahresIndexData.fromMonthlyData(
          entry.key,
          entry.value,
          indexCode,
        ),
      );
    }

    // Sortiere nach Jahr
    jahresListe.sort((a, b) => a.jahr.compareTo(b.jahr));

    return jahresListe;
  }

  // ========================================
  // PRIVATE METHODEN - CACHE MANAGEMENT
  // ========================================

  /// Prüft ob ein Refresh nötig ist (Daten älter als 24h)
  Future<bool> _shouldRefresh(String indexCode) async {
    try {
      final lastUpdate = await getLastUpdate(indexCode);

      if (lastUpdate == null) {
        print('🔄 [ENERGIE_INDEX] Kein letztes Update gefunden für $indexCode - Refresh nötig');
        return true;
      }

      final age = DateTime.now().difference(lastUpdate);
      final needsRefresh = age > _cacheDuration;

      if (needsRefresh) {
        print('🔄 [ENERGIE_INDEX] Daten für $indexCode sind ${age.inHours}h alt - Refresh nötig');
      } else {
        print('✅ [ENERGIE_INDEX] Daten für $indexCode sind aktuell (${age.inHours}h alt)');
      }

      return needsRefresh;
    } catch (e) {
      print('⚠️ [ENERGIE_INDEX] Fehler bei Refresh-Prüfung: $e');
      return true; // Bei Fehler refreshen
    }
  }

  /// Speichere Daten in Firebase
  Future<void> _saveToFirebase(
      String indexCode,
      List<IndexData> data,
      ) async {
    print('💾 [ENERGIE_INDEX] Speichere ${data.length} Datenpunkte in Firebase');

    try {
      final docRef = _firestore
          .collection('energie_indizes')
          .doc(indexCode);

      await docRef.set({
        'indexCode': indexCode,
        'indexName': DestatisConstants.verfuegbareIndizes[indexCode] ?? indexCode,
        'tableCode': DestatisConstants.indexToTable[indexCode],

        'variableCode': DestatisConstants.indexToVariable[indexCode],
        'lastUpdate': FieldValue.serverTimestamp(),
        'data': data.map((d) => d.toFirestore()).toList(),
      });

      print('✅ [ENERGIE_INDEX] Daten in Firebase gespeichert');
    } catch (e) {
      print('🔴 [ENERGIE_INDEX] Fehler beim Speichern in Firebase: $e');
      rethrow;
    }
  }

  // ========================================
  // PRIVATE METHODEN - API INTEGRATION
  // ========================================

  /// Hole Daten von Destatis API
  /// Hole Daten von Destatis API - Jahr für Jahr bei großen Zeiträumen
  Future<List<IndexData>> _fetchIndexFromAPI({
    required String indexCode,
    int months = 60,
  }) async {
    print('🔵 [ENERGIE_INDEX] Start fetching data for $indexCode');

    // Wenn mehr als 24 Monate: Jahr für Jahr laden
    if (months > 24) {
      print('🔵 [ENERGIE_INDEX] Großer Zeitraum ($months Monate) - lade Jahr für Jahr');
      return await _fetchIndexYearByYear(indexCode: indexCode, months: months);
    }

    // Ansonsten normal laden
    return await _fetchIndexFromAPISingle(
      indexCode: indexCode,
      months: months,
    );
  }

  /// Lade Jahr für Jahr und kombiniere
  Future<List<IndexData>> _fetchIndexYearByYear({
    required String indexCode,
    required int months,
  }) async {
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year, endDate.month - months, 1);

    final List<IndexData> allData = [];

    // Berechne Jahre
    int startYear = startDate.year;
    int endYear = endDate.year;

    print('🔵 [ENERGIE_INDEX] Lade Jahre $startYear bis $endYear einzeln');

    for (int year = startYear; year <= endYear; year++) {
      print('🔵 [ENERGIE_INDEX] Lade Jahr $year...');

      try {
        final yearData = await _fetchIndexFromAPISingle(
          indexCode: indexCode,
          startYear: year,
          endYear: year,
        );

        allData.addAll(yearData);
        print('✅ [ENERGIE_INDEX] Jahr $year: ${yearData.length} Datenpunkte');

        // Kleine Pause zwischen Requests
        await Future.delayed(const Duration(milliseconds: 500));

      } catch (e) {
        print('⚠️ [ENERGIE_INDEX] Fehler bei Jahr $year: $e');
        // Weitermachen mit nächstem Jahr
      }
    }

    // Sortiere und berechne Änderungen
    allData.sort((a, b) => a.date.compareTo(b.date));
    _calculateChanges(allData);

    print('✅ [ENERGIE_INDEX] Gesamt: ${allData.length} Datenpunkte geladen');

    return allData;
  }

  /// Einzelner API Call (für ein Jahr oder kleinen Zeitraum)
  Future<List<IndexData>> _fetchIndexFromAPISingle({
    required String indexCode,
    int? months,
    int? startYear,
    int? endYear,
  }) async {
    try {
      final username = 'DE0G77Y443';
      final password = 'nLZMwK424kvH';

      if (username.isEmpty || password.isEmpty) {
        throw Exception('Destatis Zugangsdaten nicht konfiguriert');
      }

      // Hole Table und Variable Code
      final tableCode = DestatisConstants.indexToTable[indexCode];
      final variableCode = DestatisConstants.indexToVariable[indexCode];

      if (tableCode == null || variableCode == null) {
        throw Exception('Unbekannter Index Code: $indexCode');
      }

      // Zeitraum berechnen
      DateTime calcEndDate = DateTime.now();
      DateTime calcStartDate;

      if (startYear != null && endYear != null) {
        // Spezifisches Jahr
        calcStartDate = DateTime(startYear, 1, 1);
        calcEndDate = DateTime(endYear, 12, 31);
      } else if (months != null) {
        // Monate zurück
        calcStartDate = DateTime(calcEndDate.year, calcEndDate.month - months, 1);
      } else {
        throw Exception('Entweder months oder startYear/endYear müssen angegeben werden');
      }
// Hole Klassifizierungs-Parameter
      final classifyingVariable = DestatisConstants.tableToClassifyingVariable[tableCode] ?? '';
      final classifyingKey = DestatisConstants.indexToClassifyingKey[indexCode] ?? '';

      print('🔵 [ENERGIE_INDEX] Zeitraum: ${calcStartDate.year}-${calcStartDate.month} bis ${calcEndDate.year}-${calcEndDate.month}');
      print('🔵 [ENERGIE_INDEX] Table: $tableCode, Variable: $variableCode');
      print('🔵 [ENERGIE_INDEX] Classifying: Variable="$classifyingVariable", Key="$classifyingKey"');


      final url = Uri.parse('$baseUrl/data/table');
      print('🔵 [ENERGIE_INDEX] URL: $url');

      final requestBody = <String, String>{
        'name': tableCode,
        'area': 'all',
        'compress': 'false',
        'transpose': 'false',
        'startyear': calcStartDate.year.toString(),
        'endyear': calcEndDate.year.toString(),
        'timeslices': '',
        'regionalvariable': '',
        'regionalkey': '',
        'classifyingvariable1': classifyingVariable,  // ← NEU!
        'classifyingkey1':variableCode ,            // ← NEU!
        'classifyingvariable2': '',
        'classifyingkey2': '',
        'classifyingvariable3': '',
        'classifyingkey3': '',
        'stand': '',
        'language': 'de',
      };

      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'username': username,
        'password': password,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🔵 [ENERGIE_INDEX] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [ENERGIE_INDEX] Success! Parsing JSON response...');

        final jsonData = jsonDecode(response.body);

        // Prüfe auf Fehler
        if (jsonData['Status'] != null && jsonData['Status']['Type'] == 'Fehler') {
          final errorMsg = jsonData['Status']['Content'] ?? 'Unbekannter Fehler';
          print('🔴 [ENERGIE_INDEX] API Fehler: $errorMsg');
          throw Exception('API Fehler: $errorMsg');
        }

        final data = _parseJsonResponse(jsonData, indexCode, variableCode);

        print('✅ [ENERGIE_INDEX] Parsed ${data.length} data points');
        return data;
      } else {
        print('🔴 [ENERGIE_INDEX] API Error ${response.statusCode}: ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('🔴 [ENERGIE_INDEX] ClientException (CORS/Network): $e');
      throw Exception('Netzwerkfehler: $e');
    } catch (e, stackTrace) {
      print('🔴 [ENERGIE_INDEX] Error fetching index data: $e');
      print('🔴 [ENERGIE_INDEX] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Parse JSON Response von DESTATIS API
  /// Parse JSON Response von DESTATIS API
  List<IndexData> _parseJsonResponse(
      Map<String, dynamic> jsonData,
      String indexCode,
      String variableCode,
      ) {
    print('🔵 [ENERGIE_INDEX] Parsing JSON response...');

    // ✅ NEU: Zeige den kompletten Response!
    print('🔍 [DEBUG] Kompletter JSON Response:');
    print('🔍 [DEBUG] Keys: ${jsonData.keys.toList()}');
    print('🔍 [DEBUG] JSON: ${jsonData.toString().substring(0, 500)}...'); // Erste 500 Zeichen

    final List<IndexData> data = [];

    try {
      final objectData = jsonData['Object'];
      if (objectData == null) {
        print('🔴 [ENERGIE_INDEX] Keine "Object" Daten gefunden');

        // ✅ NEU: Vielleicht ist die Struktur anders?
        print('🔍 [DEBUG] Verfügbare Keys im Response: ${jsonData.keys.join(", ")}');

        // Versuche alternative Strukturen
        if (jsonData.containsKey('Status')) {
          print('🔍 [DEBUG] Status gefunden: ${jsonData['Status']}');
        }
        if (jsonData.containsKey('Error')) {
          print('🔴 [DEBUG] Error gefunden: ${jsonData['Error']}');
        }

        return data;
      }

      final content = objectData['Content'];
      if (content == null || content is! String) {
        print('🔴 [ENERGIE_INDEX] Content ist nicht vorhanden oder kein String');
        print('🔍 [DEBUG] Object Keys: ${objectData.keys.join(", ")}');
        return data;
      }

      print('🔵 [ENERGIE_INDEX] Content ist ein CSV-String mit ${content.length} Zeichen');
      return _parseCSVString(content, indexCode, variableCode);

    } catch (e, stackTrace) {
      print('🔴 [ENERGIE_INDEX] Fehler beim JSON-Parsing: $e');
      print('🔴 [ENERGIE_INDEX] StackTrace: $stackTrace');
    }

    return data;
  }

  /// Parse CSV-String von Destatis
  /// Parse CSV-String von Destatis (TRANSPONIERT!)
  List<IndexData> _parseCSVString(
      String csvData,
      String indexCode,
      String variableCode,
      ) {
    print('🔵 [ENERGIE_INDEX] Parsing CSV string (transponiert)...');

    final lines = csvData.split('\n');
    print('🔵 [ENERGIE_INDEX] CSV hat ${lines.length} Zeilen');
// ✅ ZEIGE KOMPLETTE CSV (erste 30 Zeilen)
    print('🔍 [DEBUG] === KOMPLETTE CSV (erste 30 Zeilen) ===');
    for (int i = 0; i < 30 && i < lines.length; i++) {
      print('🔍 [CSV-$i] ${lines[i]}');
    }
    print('🔍 [DEBUG] === Ende CSV ===');
    final List<IndexData> data = [];

    try {
      // Finde Jahr-Zeile (enthält nur Jahreszahlen)
      int jahrZeileIndex = -1;
      List<String> jahre = [];

      for (int i = 0; i < lines.length && i < 20; i++) {
        final parts = lines[i].split(';');
        // Prüfe ob Zeile nur aus Jahreszahlen besteht (ab Spalte 2)
        if (parts.length > 2 && parts[2].trim().length == 4) {
          final maybeYear = int.tryParse(parts[2].trim());
          if (maybeYear != null && maybeYear >= 2020 && maybeYear <= 2030) {
            jahrZeileIndex = i;
            jahre = parts;
            print('🔵 [DEBUG] Jahr-Zeile gefunden bei Index $i');
            break;
          }
        }
      }

      if (jahrZeileIndex == -1) {
        print('🔴 [ENERGIE_INDEX] Konnte Jahr-Zeile nicht finden!');
        return data;
      }

      // Monat-Zeile ist direkt darunter
      final monatZeileIndex = jahrZeileIndex + 1;

      // Suche nach allen CC13-77 Varianten
      print('🔍 [DEBUG] === Suche nach CC13-77 Varianten ===');
      for (int i = monatZeileIndex + 1; i < lines.length; i++) {
        final line = lines[i];

        // Suche nach verschiedenen Schreibweisen
        if (line.contains('CC13-77') ||
            line.contains('CC1377') ||
            line.contains('CC13-04') ||
            line.contains('Fernwärme') ||
            line.contains('Wärme')) {
          final parts = line.split(';');
          print('🔍 [MATCH] Zeile $i: ${parts.length > 1 ? parts[0] + " | " + parts[1] : line.substring(0, 100)}');
        }
      }
      print('🔍 [DEBUG] === Ende Suche ===');



      if (monatZeileIndex >= lines.length) {
        print('🔴 [ENERGIE_INDEX] Konnte Monat-Zeile nicht finden!');
        return data;
      }

      final monate = lines[monatZeileIndex].split(';');
      print('🔵 [DEBUG] Monat-Zeile gefunden bei Index $monatZeileIndex');
      print('🔵 [DEBUG] Beispiel: ${monate.length > 2 ? monate[2] : "?"}, ${monate.length > 3 ? monate[3] : "?"}');

      // Finde Produkt-Zeile die den Variable-Code enthält
      int produktZeileIndex = -1;
      List<String> produktZeile = [];

      for (int i = monatZeileIndex + 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains(variableCode)) {
          produktZeileIndex = i;
          produktZeile = line.split(';');
          print('🔵 [DEBUG] Produkt-Zeile gefunden bei Index $i');
          print('🔵 [DEBUG] Zeile enthält: ${line.substring(0, line.length > 100 ? 100 : line.length)}');
          break;
        }
      }

      if (produktZeileIndex == -1) {
        print('🔴 [ENERGIE_INDEX] Konnte Produkt-Zeile mit Variable "$variableCode" nicht finden!');
        print('🔍 [DEBUG] Suche in ersten 10 Datenzeilen nach beliebigen Werten...');

        // Fallback: Nimm erste Zeile mit numerischen Werten
        for (int i = monatZeileIndex + 1; i < monatZeileIndex + 20 && i < lines.length; i++) {
          final testLine = lines[i].split(';');
          if (testLine.length > 2) {
            final testValue = testLine[2].trim().replaceAll(',', '.');
            if (double.tryParse(testValue) != null) {
              produktZeileIndex = i;
              produktZeile = testLine;
              print('🟡 [DEBUG] Verwende erste Zeile mit Zahlen bei Index $i');
              break;
            }
          }
        }

        if (produktZeileIndex == -1) {
          return data;
        }
      }

      // Parse die Werte
      int parsedCount = 0;
      int skippedCount = 0;

      for (int col = 2; col < produktZeile.length && col < jahre.length && col < monate.length; col++) {
        try {
          final jahrString = jahre[col].trim();
          final monatString = monate[col].trim();
          final wertString = produktZeile[col].trim().replaceAll(',', '.');

          if (wertString.isEmpty || wertString == '.' || wertString == '-' || wertString == '...') {
            skippedCount++;
            continue;
          }

          final jahr = int.tryParse(jahrString);
          final monat = _parseMonatName(monatString);
          final wert = double.tryParse(wertString);

          if (jahr != null && monat != null && wert != null) {
            data.add(IndexData(
              date: DateTime(jahr, monat),
              value: wert,
              indexCode: indexCode,
            ));
            parsedCount++;

            if (parsedCount == 1) {
              print('✅ [DEBUG] Erste Wert geparst: $monatString $jahr = $wert');
            }
          } else {
            skippedCount++;
            if (parsedCount == 0 && skippedCount <= 3) {
              print('🟡 [DEBUG] Spalte $col übersprungen: Jahr=$jahrString, Monat=$monatString, Wert=$wertString');
            }
          }
        } catch (e) {
          skippedCount++;
        }
      }

      print('✅ [ENERGIE_INDEX] CSV Parsing abgeschlossen:');
      print('   - Erfolgreich geparst: $parsedCount Werte');
      print('   - Übersprungen: $skippedCount Werte');

      // Sortiere nach Datum
      data.sort((a, b) => a.date.compareTo(b.date));

      // Berechne Änderungsraten
      _calculateChanges(data);

      return data;

    } catch (e, stackTrace) {
      print('🔴 [ENERGIE_INDEX] Fehler beim CSV-Parsing: $e');
      print('🔴 [ENERGIE_INDEX] StackTrace: $stackTrace');
      return data;
    }
  }

  /// Finde die Daten-Spalte im Header
  int _findDataColumn(List<String> headers, String variableCode) {
    // Suche nach Variable-Code
    for (int i = 0; i < headers.length; i++) {
      if (headers[i].contains(variableCode)) {
        return i;
      }
    }

    // Fallback: Normalerweise Spalte 2 (nach Jahr und Monat)
    return 2;
  }

  /// Parse Monat-Name zu Nummer
  int? _parseMonatName(String monatName) {
    final monat = monatName.toLowerCase().trim();

    switch (monat) {
      case 'januar': case 'jan': return 1;
      case 'februar': case 'feb': return 2;
      case 'märz': case 'mar': case 'mär': return 3;
      case 'april': case 'apr': return 4;
      case 'mai': return 5;
      case 'juni': case 'jun': return 6;
      case 'juli': case 'jul': return 7;
      case 'august': case 'aug': return 8;
      case 'september': case 'sep': return 9;
      case 'oktober': case 'okt': return 10;
      case 'november': case 'nov': return 11;
      case 'dezember': case 'dez': return 12;
      default: return null;
    }
  }

  /// Berechne Änderungsraten (Monat und Jahr)
  void _calculateChanges(List<IndexData> data) {
    for (int i = 1; i < data.length; i++) {
      final current = data[i];
      final previous = data[i - 1];

      // Monatliche Änderung
      final monthlyChange = IndexData.calculateChange(previous, current);

      // Jährliche Änderung (12 Monate zurück)
      double? yearlyChange;
      if (i >= 12) {
        final yearAgo = data[i - 12];
        yearlyChange = IndexData.calculateChange(yearAgo, current);
      }

      // Update mit berechneten Werten
      data[i] = current.copyWith(
        monthlyChange: monthlyChange,
        yearlyChange: yearlyChange,
      );
    }
  }
}