// lib/models/project.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Projekt-Datenmodell für Projektfinder
/// 
/// Struktur:
/// - projektNummer: Erste 3 Ziffern der Kundennummer (z.B. "311" aus "31100049")
/// - ort: Standort des Projekts
/// - type: "Wärmenetz" oder "Gebäudenetz"
class Project {
  final String id;
  final String projektNummer;
  final String ort;
  final String type; // "Wärmenetz" oder "Gebäudenetz"
  final String beschreibung;
  
  // Technische Stammdaten
  final String projektName;
  final String plz;
  final String installierterAnlagentyp;
  final String? zusatzInfo;
  
  // Bild der Anlage (URL)
  final String? imageUrl;
  
  // Koordinaten für Google Maps
  final double? latitude;
  final double? longitude;
  
  // Default: Frankfurt Höchst, Schützenbleiche
  static const double defaultLatitude = 50.0986;
  static const double defaultLongitude = 8.5456;
  
  // Ansprechpartner
  final String? ansprechpartnerVorname;
  final String? ansprechpartnerNachname;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.projektNummer,
    required this.ort,
    required this.type,
    required this.beschreibung,
    required this.projektName,
    required this.plz,
    required this.installierterAnlagentyp,
    this.zusatzInfo,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.ansprechpartnerVorname,
    this.ansprechpartnerNachname,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Gibt die Latitude zurück (oder Default)
  double get lat => latitude ?? defaultLatitude;
  
  /// Gibt die Longitude zurück (oder Default)
  double get lng => longitude ?? defaultLongitude;
  
  /// Prüft ob eigene Koordinaten vorhanden sind
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Berechnet die Ansprechpartner-Email
  String get ansprechpartnerEmail {
    if (ansprechpartnerVorname != null && 
        ansprechpartnerVorname!.isNotEmpty &&
        ansprechpartnerNachname != null && 
        ansprechpartnerNachname!.isNotEmpty) {
      return '${ansprechpartnerVorname!.toLowerCase()}.${ansprechpartnerNachname!.toLowerCase()}@suewag.de';
    }
    return 'dekarbonisierung@suewag.de';
  }

  /// Berechnet den Ansprechpartner-Namen
  String get ansprechpartnerName {
    if (ansprechpartnerVorname != null && 
        ansprechpartnerVorname!.isNotEmpty &&
        ansprechpartnerNachname != null && 
        ansprechpartnerNachname!.isNotEmpty) {
      return '$ansprechpartnerVorname $ansprechpartnerNachname';
    }
    return 'Team Dekarbonisierung';
  }

  /// Prüft ob ein Bild vorhanden ist
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Erstellt ein Projekt aus Firestore Document
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      projektNummer: data['projektNummer'] ?? '',
      ort: data['ort'] ?? '',
      type: data['type'] ?? 'Wärmenetz',
      beschreibung: data['beschreibung'] ?? '',
      projektName: data['projektName'] ?? '',
      plz: data['plz'] ?? '',
      installierterAnlagentyp: data['installierterAnlagentyp'] ?? '',
      zusatzInfo: data['zusatzInfo'],
      imageUrl: data['imageUrl'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      ansprechpartnerVorname: data['ansprechpartnerVorname'],
      ansprechpartnerNachname: data['ansprechpartnerNachname'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Konvertiert zu Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'projektNummer': projektNummer,
      'ort': ort,
      'type': type,
      'beschreibung': beschreibung,
      'projektName': projektName,
      'plz': plz,
      'installierterAnlagentyp': installierterAnlagentyp,
      'zusatzInfo': zusatzInfo,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'ansprechpartnerVorname': ansprechpartnerVorname,
      'ansprechpartnerNachname': ansprechpartnerNachname,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Kopie mit Änderungen
  Project copyWith({
    String? id,
    String? projektNummer,
    String? ort,
    String? type,
    String? beschreibung,
    String? projektName,
    String? plz,
    String? installierterAnlagentyp,
    String? zusatzInfo,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? ansprechpartnerVorname,
    String? ansprechpartnerNachname,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      projektNummer: projektNummer ?? this.projektNummer,
      ort: ort ?? this.ort,
      type: type ?? this.type,
      beschreibung: beschreibung ?? this.beschreibung,
      projektName: projektName ?? this.projektName,
      plz: plz ?? this.plz,
      installierterAnlagentyp: installierterAnlagentyp ?? this.installierterAnlagentyp,
      zusatzInfo: zusatzInfo ?? this.zusatzInfo,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ansprechpartnerVorname: ansprechpartnerVorname ?? this.ansprechpartnerVorname,
      ansprechpartnerNachname: ansprechpartnerNachname ?? this.ansprechpartnerNachname,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Für CSV Export
  String toCSVLine() {
    return '$projektNummer;$ort;$type;$projektName;$plz;$installierterAnlagentyp;${zusatzInfo ?? ''};${imageUrl ?? ''};${latitude ?? ''};${longitude ?? ''};${ansprechpartnerVorname ?? ''};${ansprechpartnerNachname ?? ''};$beschreibung';
  }

  /// CSV Header
  static String get csvHeader => 'ProjektNummer;Ort;Type;ProjektName;PLZ;Anlagentyp;ZusatzInfo;ImageUrl;Latitude;Longitude;AnsprechpartnerVorname;AnsprechpartnerNachname;Beschreibung';

  /// Erstellt Projekt aus CSV Zeile
  static Project? fromCSVLine(String line, {String? existingId}) {
    final parts = line.split(';');
    if (parts.length < 13) return null;
    
    final now = DateTime.now();
    return Project(
      id: existingId ?? '',
      projektNummer: parts[0].trim(),
      ort: parts[1].trim(),
      type: parts[2].trim(),
      projektName: parts[3].trim(),
      plz: parts[4].trim(),
      installierterAnlagentyp: parts[5].trim(),
      zusatzInfo: parts[6].trim().isNotEmpty ? parts[6].trim() : null,
      imageUrl: parts[7].trim().isNotEmpty ? parts[7].trim() : null,
      latitude: parts[8].trim().isNotEmpty ? double.tryParse(parts[8].trim()) : null,
      longitude: parts[9].trim().isNotEmpty ? double.tryParse(parts[9].trim()) : null,
      ansprechpartnerVorname: parts[10].trim().isNotEmpty ? parts[10].trim() : null,
      ansprechpartnerNachname: parts[11].trim().isNotEmpty ? parts[11].trim() : null,
      beschreibung: parts[12].trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Netzwerk-Typen als Konstanten
  static const String typeWaermenetz = 'Wärmenetz';
  static const String typeGebaeudenetz = 'Gebäudenetz';
  
  /// Verfügbare Typen
  static const List<String> availableTypes = [typeWaermenetz, typeGebaeudenetz];

  /// Prüft ob Kundennummer zum Projekt passt (erste 3 Ziffern)
  bool matchesKundennummer(String kundennummer) {
    if (kundennummer.length < 3) return false;
    return kundennummer.substring(0, 3) == projektNummer;
  }

  /// Generiert Google Maps Static URL für Standort
  String getGoogleMapsStaticUrl({int width = 600, int height = 300, int zoom = 15}) {
    final location = Uri.encodeComponent('$plz $ort, Germany');
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$location&zoom=$zoom&size=${width}x$height&maptype=roadmap&markers=color:red%7C$location&key=YOUR_API_KEY';
  }

  /// Generiert Google Maps Embed URL (kostenlos, kein API Key nötig)
  String getGoogleMapsEmbedUrl() {
    final location = Uri.encodeComponent('$plz $ort, Germany');
    return 'https://www.google.com/maps?q=$location&output=embed';
  }

  @override
  String toString() {
    return 'Project(id: $id, projektNummer: $projektNummer, ort: $ort, type: $type)';
  }
}
