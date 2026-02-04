// lib/models/city.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Stadt-Model für Fernwärme-Bedarfsabfrage
class City {
  final String id;
  final String name;
  final String? plz; // 🆕 Postleitzahl
  final LatLng center;
  final double zoom;

  City({
    required this.id,
    required this.name,
    this.plz,
    required this.center,
    required this.zoom,
  });

  /// Factory aus Firestore-Dokument
  factory City.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['center'] as GeoPoint;

    return City(
      id: doc.id,
      name: data['name'] ?? '',
      plz: data['plz']?.toString(), // PLZ als String (kann "0" vorne haben)
      center: LatLng(geoPoint.latitude, geoPoint.longitude),
      zoom: (data['zoom'] ?? 12.0).toDouble(),
    );
  }

  /// Konvertierung zu Firestore-Map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'plz': plz,
      'center': GeoPoint(center.latitude, center.longitude),
      'zoom': zoom,
    };
  }

  @override
  String toString() => 'City(id: $id, name: $name, plz: $plz)';
}
