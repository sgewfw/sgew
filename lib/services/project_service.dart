// lib/services/project_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';

/// Service für Projekt-Verwaltung (Projektfinder)
/// 
/// Funktionen:
/// - Suche nach Kundennummer und Ort
/// - CRUD Operationen
/// - CSV Import/Export
/// - Dummy-Daten Initialisierung
class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _collection = 'projects';

  /// Collection Reference
  CollectionReference<Map<String, dynamic>> get _projectsRef => 
      _firestore.collection(_collection);

  // =====================================================
  // SUCHE (User-Funktionen)
  // =====================================================

  /// Sucht Projekt anhand Kundennummer (erste 3 Ziffern) und Ort
  /// 
  /// [kundennummer] - Vollständige Kundennummer (z.B. "31100049")
  /// [ort] - Ortsname (z.B. "Mainz")
  /// 
  /// Returns: Passendes Projekt oder null
  Future<Project?> findProject(String kundennummer, String ort) async {
    try {
      if (kundennummer.length < 3) {
        print('🔴 Kundennummer muss mindestens 3 Ziffern haben');
        return null;
      }

      final projektNummer = kundennummer.substring(0, 3);
      final ortLower = ort.trim().toLowerCase();

      print('🔍 Suche Projekt: nummer=$projektNummer, ort=$ort');

      final snapshot = await _projectsRef
          .where('projektNummer', isEqualTo: projektNummer)
          .get();

      if (snapshot.docs.isEmpty) {
        print('🔴 Kein Projekt mit Nummer $projektNummer gefunden');
        return null;
      }

      // Suche nach passendem Ort (case-insensitive)
      for (final doc in snapshot.docs) {
        final project = Project.fromFirestore(doc);
        if (project.ort.toLowerCase() == ortLower) {
          print('✅ Projekt gefunden: ${project.projektName}');
          return project;
        }
      }

      // Falls kein exakter Ort-Match, gib erstes Projekt mit der Nummer zurück
      // (Optional: könnte auch null zurückgeben für strikte Suche)
      final firstMatch = Project.fromFirestore(snapshot.docs.first);
      print('⚠️ Kein exakter Ort-Match, verwende: ${firstMatch.projektName}');
      return firstMatch;

    } catch (e) {
      print('🔴 Fehler bei Projektsuche: $e');
      return null;
    }
  }

  // =====================================================
  // CRUD (Admin-Funktionen)
  // =====================================================

  /// Lädt alle Projekte
  Future<List<Project>> getAllProjects() async {
    try {
      final snapshot = await _projectsRef
          .orderBy('projektNummer')
          .get();
      
      return snapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('🔴 Fehler beim Laden der Projekte: $e');
      return [];
    }
  }

  /// Erstellt neues Projekt
  Future<String?> createProject(Project project) async {
    try {
      final now = DateTime.now();
      final data = project.copyWith(
        createdAt: now,
        updatedAt: now,
      ).toFirestore();

      final docRef = await _projectsRef.add(data);
      print('✅ Projekt erstellt: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('🔴 Fehler beim Erstellen: $e');
      return null;
    }
  }

  /// Aktualisiert bestehendes Projekt
  Future<bool> updateProject(Project project) async {
    try {
      final data = project.copyWith(
        updatedAt: DateTime.now(),
      ).toFirestore();

      await _projectsRef.doc(project.id).update(data);
      print('✅ Projekt aktualisiert: ${project.id}');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Aktualisieren: $e');
      return false;
    }
  }

  /// Löscht Projekt
  Future<bool> deleteProject(String id) async {
    try {
      await _projectsRef.doc(id).delete();
      print('✅ Projekt gelöscht: $id');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Löschen: $e');
      return false;
    }
  }

  // =====================================================
  // CSV IMPORT/EXPORT
  // =====================================================

  /// Exportiert alle Projekte als CSV
  Future<String> exportToCSV() async {
    final projects = await getAllProjects();
    
    final buffer = StringBuffer();
    buffer.writeln(Project.csvHeader);
    
    for (final project in projects) {
      buffer.writeln(project.toCSVLine());
    }
    
    return buffer.toString();
  }

  /// Importiert Projekte aus CSV
  /// 
  /// [csvContent] - CSV Inhalt mit Header in erster Zeile
  /// [overwrite] - Wenn true, werden bestehende Projekte ersetzt
  /// 
  /// Returns: Anzahl importierter Projekte
  Future<int> importFromCSV(String csvContent, {bool overwrite = false}) async {
    try {
      final lines = csvContent.trim().split('\n');
      if (lines.length < 2) {
        print('🔴 CSV enthält keine Daten');
        return 0;
      }

      // Erste Zeile ist Header, überspringen
      int imported = 0;
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final project = Project.fromCSVLine(line);
        if (project == null) {
          print('⚠️ Zeile $i konnte nicht geparst werden');
          continue;
        }

        if (overwrite) {
          // Suche bestehendes Projekt mit gleicher Nummer und Ort
          final existing = await findProject(project.projektNummer, project.ort);
          if (existing != null) {
            await updateProject(project.copyWith(id: existing.id));
          } else {
            await createProject(project);
          }
        } else {
          await createProject(project);
        }
        imported++;
      }

      print('✅ $imported Projekte importiert');
      return imported;
    } catch (e) {
      print('🔴 Fehler beim CSV Import: $e');
      return 0;
    }
  }

  // =====================================================
  // DUMMY DATA & INITIALISIERUNG
  // =====================================================

  /// Prüft ob Projekte existieren und erstellt Dummy-Daten falls leer
  Future<void> initializeIfEmpty() async {
    try {
      final snapshot = await _projectsRef.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        print('📦 Keine Projekte vorhanden, erstelle Dummy-Daten...');
        await _createDummyData();
      } else {
        print('✅ Projekte bereits vorhanden');
      }
    } catch (e) {
      print('🔴 Fehler bei Initialisierung: $e');
    }
  }

  /// Erstellt Dummy-Daten (2 Beispielprojekte)
  Future<void> _createDummyData() async {
    final now = DateTime.now();

    final dummyProjects = [
      Project(
        id: '',
        projektNummer: '311',
        ort: 'Mainz',
        type: Project.typeWaermenetz,
        projektName: 'Fernwärme Mainz-Zentrum',
        plz: '55116',
        installierterAnlagentyp: 'Blockheizkraftwerk mit Gaskessel-Backup',
        zusatzInfo: 'Versorgungsgebiet: Altstadt, Neustadt',
        imageUrl: null, // Kein Bild -> Maps wird angezeigt
        latitude: 50.0012, // Mainz Zentrum
        longitude: 8.2710,
        ansprechpartnerVorname: 'Max',
        ansprechpartnerNachname: 'Mustermann',
        beschreibung: '''Das Fernwärme-Projekt Mainz-Zentrum versorgt über 200 Gebäude in der Mainzer Innenstadt mit klimafreundlicher Wärme. 

Die Anlage nutzt ein hocheffizientes Blockheizkraftwerk (BHKW) mit einer thermischen Leistung von 15 MW. Durch die Kraft-Wärme-Kopplung erreichen wir einen Gesamtwirkungsgrad von über 85%.

Ab 2026 planen wir die Integration einer Großwärmepumpe, die Abwärme aus dem Rhein nutzen wird.''',
        createdAt: now,
        updatedAt: now,
      ),
      Project(
        id: '',
        projektNummer: '422',
        ort: 'Wiesbaden',
        type: Project.typeGebaeudenetz,
        projektName: 'Quartier Wiesbaden-Süd',
        plz: '65197',
        installierterAnlagentyp: 'Wärmepumpen-Kaskade mit Solarthermie',
        zusatzInfo: 'Neubauquartier mit 12 Mehrfamilienhäusern',
        imageUrl: null, // Kein Bild -> Maps wird angezeigt
        latitude: null, // Keine Koordinaten -> Default Frankfurt Höchst
        longitude: null,
        ansprechpartnerVorname: null, // Team Dekarbonisierung
        ansprechpartnerNachname: null,
        beschreibung: '''Das Gebäudenetz Wiesbaden-Süd ist ein modernes Nahwärmenetz für das neue Wohnquartier "Grüne Mitte".

Das Netz versorgt 12 Mehrfamilienhäuser mit insgesamt 84 Wohneinheiten. Als primäre Wärmequelle dient eine Wärmepumpen-Kaskade mit 3 x 80 kW, unterstützt durch 200 m² Solarthermie auf den Dächern der Technikzentrale.

Das System erreicht einen erneuerbaren Anteil von über 75% und erfüllt damit bereits heute die Anforderungen des GEG 2024.''',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final project in dummyProjects) {
      await createProject(project);
    }

    print('✅ ${dummyProjects.length} Dummy-Projekte erstellt');
  }

  /// Löscht alle Projekte (nur für Entwicklung!)
  Future<void> deleteAllProjects() async {
    final snapshot = await _projectsRef.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    print('⚠️ Alle Projekte gelöscht');
  }
}
