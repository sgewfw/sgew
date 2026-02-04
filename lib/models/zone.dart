// lib/models/zone.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Zonentyp: Bestand oder Ausbau
enum ZoneType {
  existing, // Bestand (Grün)
  potential, // Ausbau (Orange)
}

/// Extension für ZoneType
extension ZoneTypeExtension on ZoneType {
  String get displayName {
    switch (this) {
      case ZoneType.existing:
        return 'Bestand';
      case ZoneType.potential:
        return 'Ausbau';
    }
  }

  String get firestoreValue {
    switch (this) {
      case ZoneType.existing:
        return 'existing';
      case ZoneType.potential:
        return 'potential';
    }
  }

  static ZoneType fromString(String value) {
    switch (value) {
      case 'existing':
        return ZoneType.existing;
      case 'potential':
        return ZoneType.potential;
      default:
        return ZoneType.existing;
    }
  }
}

/// Zone-Model für Fernwärme-Gebiete
class Zone {
  final String id;
  final ZoneType type;
  final List<LatLng> points;
  final Color color;

  Zone({
    required this.id,
    required this.type,
    required this.points,
    required this.color,
  });

  /// Standard-Farbe basierend auf Zonentyp
  static Color getDefaultColor(ZoneType type) {
    switch (type) {
      case ZoneType.existing:
        return const Color(0xFF65B32E); // Grün - Bestand
      case ZoneType.potential:
        return const Color(0xFFE84E0F); // Orange - Ausbau
    }
  }

  /// Factory aus Firestore-Dokument
  factory Zone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = ZoneTypeExtension.fromString(data['type'] ?? 'existing');
    final pointsList = data['points'] as List<dynamic>? ?? [];

    final points = pointsList.map((p) {
      final geoPoint = p as GeoPoint;
      return LatLng(geoPoint.latitude, geoPoint.longitude);
    }).toList();

    // Farbe aus Hex-String oder Standard
    Color color;
    if (data['color'] != null) {
      final hexString = data['color'] as String;
      color = Color(int.parse(hexString.replaceFirst('#', '0xFF')));
    } else {
      color = getDefaultColor(type);
    }

    return Zone(
      id: doc.id,
      type: type,
      points: points,
      color: color,
    );
  }

  /// Konvertierung zu Firestore-Map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.firestoreValue,
      'points': points
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(),
      'color': '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
    };
  }

  /// Erstellt Google Maps Polygon aus dieser Zone
  Polygon toGooglePolygon({VoidCallback? onTap}) {
    return Polygon(
      polygonId: PolygonId(id),
      points: points,
      fillColor: color.withOpacity(0.35),
      strokeColor: color,
      strokeWidth: 2,
      consumeTapEvents: onTap != null,
      onTap: onTap,
    );
  }

  @override
  String toString() => 'Zone(id: $id, type: ${type.displayName}, points: ${points.length})';
}
