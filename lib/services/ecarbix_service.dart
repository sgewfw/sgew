// lib/services/ecarbix_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/index_data.dart';
import '../constants/destatis_constants.dart';

/// Service für ECarbiX CO₂-Preis von EEX
///
/// HINWEIS: Die EEX-API ist nicht öffentlich zugänglich (HTTP 403).
/// Daher nutzen wir gepflegte Fallback-Daten, die monatlich aktualisiert werden.
///
/// Aktualisierung der Daten:
/// 1. Besuche: https://www.eex.com/de/customised-solutions/agfw
/// 2. Wähle Jahr 2024/2025
/// 3. Kopiere neue Werte in _generateFallbackData()
///
/// Features:
/// - Firebase Cache (1h)
/// - Gepflegte Fallback-Daten (monatliches Update)
/// - Optional: Versuch API-Zugriff (falls EEX API öffnet)
class EcarbixService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // KONFIGURATION
  // ========================================

  /// Cache-Dauer: 1 Stunde
  static const Duration _cacheDuration = Duration(hours: 1);

  /// EEX API Base-URL (aktuell blockiert mit HTTP 403)
  static const String _apiBaseUrl = 'https://api.eex-group.com/pub/customise-widget/table-data';

  /// CORS-Proxy für Flutter Web
  static const String _corsProxy = 'https://corsproxy.io/?';

  /// Generiere API-URL für ein bestimmtes Jahr
  static String _getApiUrl({required int year}) {
    final startDate = '$year-01-01';
    final endDate = '$year-12-31';

    final baseUrl = '$_apiBaseUrl?'
        'shortCode=EEX%20ECarbix%20Month%20Index&'
        'commodity=ENVIRONMENTALS&'
        'pricing=l&'
        'areas=EU&'
        'products=ECarbix&'
        'maturity=undefined&'
        'startDate=$startDate&'
        'endDate=$endDate&'
        'maturityType=undefined&'
        'isRolling=true&'
        'rolling=0';

    // CORS-Proxy nur für Flutter Web
    if (kIsWeb) {
      return '$_corsProxy$baseUrl';
    }

    return baseUrl;
  }

  bool _lastDataWasFallback = false;

  /// Gibt zurück ob die zuletzt geladenen Daten Fallback-Daten waren
  bool get isUsingFallbackData => _lastDataWasFallback;

  // ========================================
  // PUBLIC API
  // ========================================

  /// Lade ECarbiX-Daten aus Firebase (mit Auto-Refresh)
  Future<List<IndexData>> getEcarbixData({
    bool forceRefresh = false,
  }) async {
    print('📖 [ECARBIX] Lade Daten aus Firebase');

    try {
      final doc = await _firestore
          .collection('energie_indizes')
          .doc(DestatisConstants.ecarbixCode)
          .get();

      if (!doc.exists) {
        print('⚠️ [ECARBIX] Keine Daten in Firebase - initialisiere mit Fallback');
        final data = _generateFallbackData();
        await _saveToFirebase(data);
        return data;
      }

      final data = doc.data()!;
      final List<dynamic> dataList = data['data'] ?? [];

      final ecarbixData = dataList
          .map((item) => IndexData.fromFirestore(item as Map<String, dynamic>))
          .toList();

      ecarbixData.sort((a, b) => a.date.compareTo(b.date));

      print('✅ [ECARBIX] ${ecarbixData.length} Datenpunkte aus Firebase geladen');

      // Auto-Refresh nur bei forceRefresh (da API blockiert ist)
      if (forceRefresh) {
        final needsRefresh = await _shouldRefresh();

        if (needsRefresh) {
          print('🔄 [ECARBIX] Versuche API-Refresh (kann fehlschlagen wegen HTTP 403)');

          _tryFetchFromApi().then((freshData) {
            if (freshData != null) {
              return _saveToFirebase(freshData);
            }
          }).catchError((e) {
            print('🔴 [ECARBIX] API-Refresh fehlgeschlagen: $e');
          });
        }
      }

      return ecarbixData;

    } catch (e, stackTrace) {
      print('🔴 [ECARBIX] Fehler beim Laden aus Firebase: $e');
      print('🔴 [ECARBIX] StackTrace: $stackTrace');

      // Fallback direkt nutzen
      return _generateFallbackData();
    }
  }

  /// Manuelles Refresh - versucht API, fällt zurück auf manuelle Daten-Eingabe
  Future<void> refreshEcarbixData() async {
    print('🔄 [ECARBIX] Starte manuellen Refresh');

    try {
      // Versuche API (wird wahrscheinlich fehlschlagen)
      final apiData = await _tryFetchFromApi();

      if (apiData != null && apiData.isNotEmpty) {
        await _saveToFirebase(apiData);
        print('✅ [ECARBIX] API-Daten erfolgreich geladen');
        return;
      }

      // API fehlgeschlagen - nutze Fallback
      print('⚠️ [ECARBIX] API nicht verfügbar - verwende gepflegte Fallback-Daten');
      final fallbackData = _generateFallbackData();
      await _saveToFirebase(fallbackData);
      print('✅ [ECARBIX] Fallback-Daten aktualisiert');

    } catch (e, stackTrace) {
      print('🔴 [ECARBIX] Fehler beim Refresh: $e');
      print('🔴 [ECARBIX] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Hole letztes Update-Datum
  Future<DateTime?> getLastUpdate() async {
    try {
      final doc = await _firestore
          .collection('energie_indizes')
          .doc(DestatisConstants.ecarbixCode)
          .get();

      if (!doc.exists) return null;

      final timestamp = doc.data()?['lastUpdate'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      return null;
    }
  }

  /// Prüfe ob Daten verfügbar sind
  Future<bool> hasData() async {
    try {
      final doc = await _firestore
          .collection('energie_indizes')
          .doc(DestatisConstants.ecarbixCode)
          .get();

      if (!doc.exists) return false;

      final dataList = doc.data()?['data'] as List?;
      return dataList != null && dataList.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Vergleiche aktuelle Fallback-Daten mit Firebase
  Future<Map<String, dynamic>> compareWithFirebase() async {
    try {
      final firebaseData = await getEcarbixData();
      final fallbackData = _generateFallbackData();

      final differences = <String, Map<String, double>>{};

      for (var fallbackEntry in fallbackData) {
        final fbEntry = firebaseData.firstWhere(
              (fb) => fb.date == fallbackEntry.date,
          orElse: () => IndexData(
            date: fallbackEntry.date,
            value: -1,
            indexCode: DestatisConstants.ecarbixCode,
          ),
        );

        if (fbEntry.value != fallbackEntry.value && fbEntry.value != -1) {
          differences[fallbackEntry.date.toString()] = {
            'firebase': fbEntry.value,
            'fallback': fallbackEntry.value,
          };
        }
      }

      return {
        'hasDifferences': differences.isNotEmpty,
        'differences': differences,
        'fallbackData': fallbackData,
        'firebaseData': firebaseData,
      };
    } catch (e) {
      print('🔴 [ECARBIX] Fehler beim Vergleich: $e');
      return {
        'hasDifferences': false,
        'differences': {},
        'error': e.toString(),
      };
    }
  }

  // ========================================
  // PRIVATE METHODEN
  // ========================================

  /// Prüft ob ein Refresh nötig ist (Daten älter als 1h)
  Future<bool> _shouldRefresh() async {
    try {
      final lastUpdate = await getLastUpdate();

      if (lastUpdate == null) {
        print('🔄 [ECARBIX] Kein letztes Update gefunden - Refresh nötig');
        return true;
      }

      final age = DateTime.now().difference(lastUpdate);
      final needsRefresh = age > _cacheDuration;

      if (needsRefresh) {
        print('🔄 [ECARBIX] Daten sind ${age.inMinutes}min alt - Refresh nötig');
      } else {
        print('✅ [ECARBIX] Daten sind aktuell (${age.inMinutes}min alt)');
      }

      return needsRefresh;
    } catch (e) {
      print('⚠️ [ECARBIX] Fehler bei Refresh-Prüfung: $e');
      return true;
    }
  }

  /// Speichere Daten in Firebase
  Future<void> _saveToFirebase(List<IndexData> data) async {
    print('💾 [ECARBIX] Speichere ${data.length} Datenpunkte in Firebase');

    try {
      final docRef = _firestore
          .collection('energie_indizes')
          .doc(DestatisConstants.ecarbixCode);

      await docRef.set({
        'indexCode': DestatisConstants.ecarbixCode,
        'indexName': DestatisConstants.ecarbixName,
        'tableCode': DestatisConstants.ecarbixTable,
        'variableCode': DestatisConstants.ecarbixVariable,
        'lastUpdate': FieldValue.serverTimestamp(),
        'source': 'EEX (manuell gepflegt)',
        'sourceUrl': 'https://www.eex.com/de/customised-solutions/agfw',
        'isFallback': _lastDataWasFallback,
        'data': data.map((d) => d.toFirestore()).toList(),
      }, SetOptions(merge: false));

      print('✅ [ECARBIX] Daten in Firebase gespeichert');
    } catch (e) {
      print('🔴 [ECARBIX] Fehler beim Speichern in Firebase: $e');
      rethrow;
    }
  }

  /// Versuche API zu nutzen (gibt null zurück bei Fehler)
  Future<List<IndexData>?> _tryFetchFromApi() async {
    print('🔵 [ECARBIX] Versuche API-Zugriff (kann mit HTTP 403 fehlschlagen)');

    try {
      final currentYear = DateTime.now().year;
      final List<IndexData> allData = [];

      // Versuche aktuelles Jahr und Vorjahr
      for (final year in [currentYear - 1, currentYear]) {
        try {
          final url = _getApiUrl(year: year);

          final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            final List<dynamic> data = json['data'] ?? [];

            for (var row in data) {
              try {
                final dateStr = row[2] as String;
                final price = (row[4] as num).toDouble();

                if (price <= 0) continue;

                final date = DateTime.parse(dateStr);

                allData.add(IndexData(
                  date: DateTime(date.year, date.month, 1),
                  value: price,
                  indexCode: DestatisConstants.ecarbixCode,
                ));
              } catch (e) {
                continue;
              }
            }

            print('✅ [ECARBIX] Jahr $year: ${data.length} Punkte von API');
          } else if (response.statusCode == 403) {
            print('⚠️ [ECARBIX] HTTP 403 für Jahr $year - API blockiert Zugriff');
          } else {
            print('⚠️ [ECARBIX] HTTP ${response.statusCode} für Jahr $year');
          }
        } catch (e) {
          print('⚠️ [ECARBIX] Fehler Jahr $year: $e');
        }
      }

      if (allData.isEmpty) {
        print('ℹ️ [ECARBIX] Keine API-Daten verfügbar');
        return null;
      }

      allData.sort((a, b) => a.date.compareTo(b.date));
      _lastDataWasFallback = false;
      print('✅ [ECARBIX] API-Erfolg: ${allData.length} Datenpunkte');

      return allData;

    } catch (e) {
      print('ℹ️ [ECARBIX] API nicht erreichbar: $e');
      return null;
    }
  }

  /// Gepflegte Fallback-Daten von EEX
  ///
  /// **WICHTIG: Monatlich aktualisieren!**
  ///
  /// Update-Prozess:
  /// 1. Besuche: https://www.eex.com/de/customised-solutions/agfw
  /// 2. Wähle Jahr im Dropdown (2024, 2025)
  /// 3. Kopiere neue Werte aus der Tabelle
  /// 4. Update diese Methode
  /// 5. Rufe refreshEcarbixData() auf
  ///
  /// Letzte Aktualisierung: 16.11.2025
  List<IndexData> _generateFallbackData() {
    print('📊 [ECARBIX] Verwende gepflegte Fallback-Daten (Stand: 16.11.2025)');

    // ✅ Echte Daten von EEX
    final fallbackData = [
      // 2025 Daten
      {'year': 2025, 'month': 1, 'price': 75.72},
      {'year': 2025, 'month': 2, 'price': 75.58},
      {'year': 2025, 'month': 3, 'price': 68.63},
      {'year': 2025, 'month': 4, 'price': 64.06},
      {'year': 2025, 'month': 5, 'price': 70.43},
      {'year': 2025, 'month': 6, 'price': 72.23},
      {'year': 2025, 'month': 7, 'price': 70.20},
      {'year': 2025, 'month': 8, 'price': 71.05},
      {'year': 2025, 'month': 9, 'price': 75.57},
      {'year': 2025, 'month': 10, 'price': 78.04},
      // 2024 Daten
      {'year': 2024, 'month': 1, 'price': 65.36},
      {'year': 2024, 'month': 2, 'price': 55.46},
      {'year': 2024, 'month': 3, 'price': 57.63},
      {'year': 2024, 'month': 4, 'price': 63.73},
      {'year': 2024, 'month': 5, 'price': 70.95},
      {'year': 2024, 'month': 6, 'price': 68.53},
      {'year': 2024, 'month': 7, 'price': 66.92},
      {'year': 2024, 'month': 8, 'price': 70.13},
      {'year': 2024, 'month': 9, 'price': 65.12},
      {'year': 2024, 'month': 10, 'price': 63.21},
      {'year': 2024, 'month': 11, 'price': 67.01},
      {'year': 2024, 'month': 12, 'price': 66.80},
    ];

    final data = fallbackData.map((entry) {
      return IndexData(
        date: DateTime(entry['year'] as int, entry['month'] as int, 1),
        value: entry['price'] as double,
        indexCode: DestatisConstants.ecarbixCode,
      );
    }).toList();

    data.sort((a, b) => a.date.compareTo(b.date));

    _lastDataWasFallback = true;
    print('✅ [ECARBIX] ${data.length} Fallback-Datenpunkte geladen');

    return data;
  }
}