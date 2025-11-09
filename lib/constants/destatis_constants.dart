// lib/constants/destatis_constants.dart

/// Destatis API Konstanten für Energie-Indizes
///
/// Diese Datei enthält alle notwendigen API-Codes für:
/// - Erdgas-Preise
/// - Strom-Preise
/// - Wärmepreis-Index
class DestatisConstants {

  // ========================================
  // ERDGAS INDIZES
  // ========================================

  /// Erdgas bei Abgabe an Handel und Gewerbe
  /// Table: 61241-0006
  /// Variable: GP19-352222
  static const String erdgasGewerbeTable = '61241-0006';
  static const String erdgasGewerbeVariable = 'GP19-352222';
  static const String erdgasGewerbeName = 'Erdgas Handel/Gewerbe -GP19-352222';
  static const String erdgasGewerbeCode = 'ERDGAS_GEWERBE';

  // ========================================
  // STROM INDIZES
  // ========================================

  /// Elektrischer Strom bei Abgabe an gewerbliche Anlagen
  /// Table: 61241-0004
  /// Variable: GP19-351113
  static const String stromGewerbeTable = '61241-0004';
  static const String stromGewerbeVariable = 'GP19-351113';
  static const String stromGewerbeName = 'Strom Handel/Gewerbe - GP19-351113';
  static const String stromGewerbeCode = 'STROM_GEWERBE';

  /// Elektrischer Strom bei Abgabe an Haushalte
  /// Table: 61241-0004
  /// Variable: GP19-351112
  static const String stromHaushalteTable = '61241-0004';
  static const String stromHaushalteVariable = 'GP19-351112';
  static const String stromHaushalteName = 'Strom Haushalte - GP19-351112';
  static const String stromHaushalteCode = 'STROM_HAUSHALTE';

  // ========================================
  // WÄRMEPREIS INDEX
  // ========================================

  /// Wärmepreis-Index (Fernwärme)
  /// Table: 61111-0006
  /// Variable: CC13-77
  static const String waermepreisTable = '61111-0006';
  static const String waermepreisVariable = 'CC13-77';
  static const String waermepreisName = 'Wärmepreisindex - CC13-77';
  static const String waermepreisCode = 'WAERMEPREIS';

  // ========================================
  // INDEX MAPPING - Alle verfügbaren Indizes
  // ========================================

  /// Map aller Indizes mit ihren Display-Namen
  static const Map<String, String> verfuegbareIndizes = {
    erdgasGewerbeCode: erdgasGewerbeName,
    waermepreisCode: waermepreisName,
    stromGewerbeCode: stromGewerbeName,
    stromHaushalteCode: stromHaushalteName,

  };

  /// Map: Index Code -> Table Code
  static const Map<String, String> indexToTable = {
    erdgasGewerbeCode: erdgasGewerbeTable,
    waermepreisCode: waermepreisTable,
    stromGewerbeCode: stromGewerbeTable,
    stromHaushalteCode: stromHaushalteTable,

  };

  /// Map: Index Code -> Variable Code
  static const Map<String, String> indexToVariable = {
    erdgasGewerbeCode: erdgasGewerbeVariable,
    waermepreisCode: waermepreisVariable,
    stromGewerbeCode: stromGewerbeVariable,
    stromHaushalteCode: stromHaushalteVariable,

  };

  // ========================================
  // KATEGORIE-GRUPPIERUNG
  // ========================================

  /// Erdgas Indizes
  static const List<String> erdgasIndizes = [
    erdgasGewerbeCode,
  ];

  /// Strom Indizes
  static const List<String> stromIndizes = [
    stromGewerbeCode,
    stromHaushalteCode,
  ];

  /// Wärme Indizes
  static const List<String> waermeIndizes = [
    waermepreisCode,
  ];

  // ========================================
  // DISPLAY-EIGENSCHAFTEN
  // ========================================

  /// Kurznamen für kompakte Anzeige
  static const Map<String, String> kurzNamen = {
    erdgasGewerbeCode: 'Erdgas GW - GP19-352222',
    stromGewerbeCode: 'Strom GW - GP19-351113',
    stromHaushalteCode: 'Strom HH - GP19-351112',
    waermepreisCode: 'WPI  CC13-77',
  };

  /// Icons für jeden Index-Typ (Material Icons Namen)
  static const Map<String, String> indexIcons = {
    erdgasGewerbeCode: 'local_fire_department',
    stromGewerbeCode: 'bolt',
    stromHaushalteCode: 'electric_bolt',
    waermepreisCode: 'thermostat',
  };

  /// Einheiten für Anzeige
  static const Map<String, String> einheiten = {
    erdgasGewerbeCode: 'Index',
    stromGewerbeCode: 'Index',
    stromHaushalteCode: 'Index',
    waermepreisCode: 'Index',
  };
  /// Mobile Labels (kurz, 2 pro Zeile)
  static const Map<String, String> mobileLabels = {
    erdgasGewerbeCode: 'Erdgas GEW',
    stromGewerbeCode: 'Strom GEW',
    stromHaushalteCode: 'Strom HH',
    waermepreisCode: 'WPI',
  };

  /// Wird für Verbraucherpreisindex benötigt
  static const Map<String, String> tableToClassifyingVariable = {
    '61111-0006': 'CC13B1',  // Verbraucherpreisindex → COICOP
    '61241-0006': 'GP19M6',         //  Erdgas → keine
    '61241-0004': 'GP19M6',         // Strom → keine
  };

  /// Klassifizierungs-Keys für spezifische Indizes
  /// Wird benötigt um Unterkategorien zu laden
  static const Map<String, String> indexToClassifyingKey = {
    erdgasGewerbeCode: 'GP19-352222',
    stromGewerbeCode: 'GP19-351113',
    stromHaushalteCode: 'GP19-351112',
    waermepreisCode: 'CC13-77',  // Spezifisch für Fernwärme
  };


  // ========================================
  // API PARAMETER
  // ========================================

  /// Basis-Jahr für Indizes
  static const int basisJahr = 2020;

  /// Basis-Wert für Prozentberechnungen
  static const double basisWert = 100.0;

  /// Standard Zeitraum in Monaten für Daten-Abruf
  static const int standardZeitraumMonate = 12; // 1 Jahre

  /// Cache-Dauer in Stunden (1 Stunde für aktuelle Daten)
  static const int cacheDauerStunden = 1;
}

/// Enum für Index-Typen
enum IndexTyp {
  erdgas,
  strom,
  waerme,
}

/// Extension für IndexTyp
extension IndexTypExtension on IndexTyp {
  /// Liste der Codes für diesen Typ
  List<String> get codes {
    switch (this) {
      case IndexTyp.erdgas:
        return DestatisConstants.erdgasIndizes;
      case IndexTyp.strom:
        return DestatisConstants.stromIndizes;
      case IndexTyp.waerme:
        return DestatisConstants.waermeIndizes;
    }
  }

  /// Display-Name für diesen Typ
  String get displayName {
    switch (this) {
      case IndexTyp.erdgas:
        return 'Erdgas';
      case IndexTyp.strom:
        return 'Strom';
      case IndexTyp.waerme:
        return 'Wärme';
    }
  }
}