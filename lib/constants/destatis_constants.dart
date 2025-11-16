// lib/constants/destatis_constants.dart

/// Destatis API Konstanten für Energie-Indizes
///
/// Diese Datei enthält alle notwendigen API-Codes für:
/// - Erdgas-Preise
/// - Strom-Preise
/// - Wärmepreis-Index
/// - CO₂-Preis (ECarbiX)
class DestatisConstants {

  // ========================================
  // ERDGAS INDIZES
  // ========================================

  /// Erdgas bei Abgabe an Handel und Gewerbe
  /// Table: 61241-0006
  /// Variable: GP19-352222
  static const String erdgasGewerbeTable = '61241-0006';
  static const String erdgasGewerbeVariable = 'GP19-352222';
  static const String erdgasGewerbeName = 'Erdgas Handel/Gewerbe';
  static const String erdgasGewerbeCode = 'ERDGAS_GEWERBE';

  /// 🆕 Erdgas Börse (Abgabe Börsentonierung)
  /// Table: 61241-0006
  /// Variable: GP19-352228
  static const String erdgasBoerseTable = '61241-0006';
  static const String erdgasBoerseVariable = 'GP19-352228';
  static const String erdgasBorseName = 'Erdgas Börse';
  static const String erdgasBoerseCode = 'ERDGAS_BOERSE';

  // ========================================
  // STROM INDIZES
  // ========================================

  /// Elektrischer Strom bei Abgabe an gewerbliche Anlagen
  /// Table: 61241-0004
  /// Variable: GP19-351113
  static const String stromGewerbeTable = '61241-0004';
  static const String stromGewerbeVariable = 'GP19-351113';
  static const String stromGewerbeName = 'Strom Handel/Gewerbe';
  static const String stromGewerbeCode = 'STROM_GEWERBE';

  /// Elektrischer Strom bei Abgabe an Haushalte
  /// Table: 61241-0004
  /// Variable: GP19-351112
  static const String stromHaushalteTable = '61241-0004';
  static const String stromHaushalteVariable = 'GP19-351112';
  static const String stromHaushalteName = 'Strom Haushalte';
  static const String stromHaushalteCode = 'STROM_HAUSHALTE';

  // ========================================
  // WÄRMEPREIS INDEX
  // ========================================

  /// Wärmepreis-Index (Fernwärme)
  /// Table: 61111-0006
  /// Variable: CC13-77
  static const String waermepreisTable = '61111-0006';
  static const String waermepreisVariable = 'CC13-77';
  static const String waermepreisName = 'Wärmepreisindex';
  static const String waermepreisCode = 'WAERMEPREIS';

  // ========================================
  // 🆕 CO₂ PREIS (ECARBIX)
  // ========================================

  /// ECarbiX - CO₂-Preis
  /// Manuell gepflegt via Firebase (keine Destatis API)
  /// Einheit: €/Tonne
  static const String ecarbixTable = 'MANUAL';
  static const String ecarbixVariable = 'MANUAL';
  static const String ecarbixName = 'ECarbiX (CO₂-Preis)';
  static const String ecarbixCode = 'ECARBIX';

  // ========================================
  // INDEX MAPPING - Alle verfügbaren Indizes
  // ========================================

  /// Map aller Indizes mit ihren Display-Namen
  static const Map<String, String> verfuegbareIndizes = {
    erdgasGewerbeCode: erdgasGewerbeName,
    erdgasBoerseCode: erdgasBorseName,
    waermepreisCode: waermepreisName,
    stromGewerbeCode: stromGewerbeName,
    stromHaushalteCode: stromHaushalteName,
    ecarbixCode: ecarbixName,
  };

  /// Map: Index Code -> Table Code
  static const Map<String, String> indexToTable = {
    erdgasGewerbeCode: erdgasGewerbeTable,
    erdgasBoerseCode: erdgasBoerseTable,
    waermepreisCode: waermepreisTable,
    stromGewerbeCode: stromGewerbeTable,
    stromHaushalteCode: stromHaushalteTable,
    ecarbixCode: ecarbixTable,
  };

  /// Map: Index Code -> Variable Code
  static const Map<String, String> indexToVariable = {
    erdgasGewerbeCode: erdgasGewerbeVariable,
    erdgasBoerseCode: erdgasBoerseVariable,
    waermepreisCode: waermepreisVariable,
    stromGewerbeCode: stromGewerbeVariable,
    stromHaushalteCode: stromHaushalteVariable,
    ecarbixCode: ecarbixVariable,
  };

  // ========================================
  // 🆕 PREISFORMEL KATEGORISIERUNG
  // ========================================

  /// Indizes für Preisformel bis Ende 2027
  static const Set<String> preisformelBis2027 = {
    erdgasBoerseCode,
    ecarbixCode,
    waermepreisCode,
    erdgasGewerbeCode,
  };

  /// Indizes für Preisformel ab 2028
  static const Set<String> preisformelAb2028 = {
    stromGewerbeCode,
    stromHaushalteCode,
    waermepreisCode,
    erdgasGewerbeCode,
  };

  /// Prüfe ob Index in Kategorie ist
  static bool istInPreisformel(String indexCode, String kategorie) {
    switch (kategorie) {
      case 'BIS_2027':
        return preisformelBis2027.contains(indexCode);
      case 'AB_2028':
        return preisformelAb2028.contains(indexCode);
      case 'ALLE':
      default:
        return true;
    }
  }

  /// Hole gefilterte Index-Liste
  static List<String> getFilteredIndizes(String kategorie) {
    if (kategorie == 'ALLE') {
      return verfuegbareIndizes.keys.toList();
    } else if (kategorie == 'BIS_2027') {
      return preisformelBis2027.toList();
    } else if (kategorie == 'AB_2028') {
      return preisformelAb2028.toList();
    }
    return verfuegbareIndizes.keys.toList();
  }

  // ========================================
  // KATEGORIE-GRUPPIERUNG
  // ========================================

  /// Erdgas Indizes
  static const List<String> erdgasIndizes = [
    erdgasGewerbeCode,
    erdgasBoerseCode,
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

  /// 🆕 CO₂ Indizes (eigene Kategorie wegen anderer Einheit)
  static const List<String> co2Indizes = [
    ecarbixCode,
  ];

  // ========================================
  // DISPLAY-EIGENSCHAFTEN
  // ========================================

  /// Kurznamen für kompakte Anzeige
  static const Map<String, String> kurzNamen = {
    erdgasGewerbeCode: 'Erdgas GEW',
    erdgasBoerseCode: 'Erdgas Börse',
    stromGewerbeCode: 'Strom GEW',
    stromHaushalteCode: 'Strom HH',
    waermepreisCode: 'Wärmepreisindex WPI',
    ecarbixCode: 'CO₂',
  };

  /// Icons für jeden Index-Typ (Material Icons Namen)
  static const Map<String, String> indexIcons = {
    erdgasGewerbeCode: 'local_fire_department',
    erdgasBoerseCode: 'trending_up',
    stromGewerbeCode: 'bolt',
    stromHaushalteCode: 'electric_bolt',
    waermepreisCode: 'thermostat',
    ecarbixCode: 'co2',
  };

  /// Einheiten für Anzeige
  static const Map<String, String> einheiten = {
    erdgasGewerbeCode: 'Index',
    erdgasBoerseCode: 'Index',
    stromGewerbeCode: 'Index',
    stromHaushalteCode: 'Index',
    waermepreisCode: 'Index',
    ecarbixCode: '€/Tonne', // 🆕 Andere Einheit!
  };

  /// Mobile Labels (kurz, 2 pro Zeile)
  static const Map<String, String> mobileLabels = {
    erdgasGewerbeCode: 'Gas GEW',
    erdgasBoerseCode: 'Gas Börse',
    stromGewerbeCode: 'Strom GEW',
    stromHaushalteCode: 'Strom HH',
    waermepreisCode: 'WPI',
    ecarbixCode: 'CO₂',
  };

  /// Wird für Verbraucherpreisindex benötigt
  static const Map<String, String> tableToClassifyingVariable = {
    '61111-0006': 'CC13B1',  // Verbraucherpreisindex → COICOP
    '61241-0006': 'GP19M6',  // Erdgas → keine
    '61241-0004': 'GP19M6',  // Strom → keine
  };

  /// Klassifizierungs-Keys für spezifische Indizes
  /// Wird benötigt um Unterkategorien zu laden
  static const Map<String, String> indexToClassifyingKey = {
    erdgasGewerbeCode: 'GP19-352222',
    erdgasBoerseCode: 'GP19-352228',
    stromGewerbeCode: 'GP19-351113',
    stromHaushalteCode: 'GP19-351112',
    waermepreisCode: 'CC13-77',
    ecarbixCode: 'Ecarbix EEX',
  };

  // ========================================
  // API PARAMETER
  // ========================================

  /// Basis-Jahr für Indizes
  static const int basisJahr = 2020;

  /// Basis-Wert für Prozentberechnungen
  static const double basisWert = 100.0;

  /// Standard Zeitraum in Monaten für Daten-Abruf
  static const int standardZeitraumMonate = 12;

  /// Cache-Dauer in Stunden
  static const int cacheDauerStunden = 1;
}

/// Enum für Index-Typen
enum IndexTyp {
  erdgas,
  strom,
  waerme,
  co2,
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
      case IndexTyp.co2:
        return DestatisConstants.co2Indizes;
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
      case IndexTyp.co2:
        return 'CO₂';
    }
  }
}