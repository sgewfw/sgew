// lib/utils/geo_utils.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Geometrie-Hilfsfunktionen für Karten-Operationen
class GeoUtils {
  /// Prüft ob ein Punkt innerhalb eines Polygons liegt
  /// Verwendet den Ray-Casting Algorithmus
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    int intersections = 0;
    final int n = polygon.length;

    for (int i = 0; i < n; i++) {
      final LatLng p1 = polygon[i];
      final LatLng p2 = polygon[(i + 1) % n];

      // Prüfe ob der horizontale Strahl vom Punkt die Kante schneidet
      if (_rayIntersectsSegment(point, p1, p2)) {
        intersections++;
      }
    }

    // Ungerade Anzahl von Schnittpunkten = Punkt ist innerhalb
    return intersections % 2 == 1;
  }

  /// Hilfsfunktion: Prüft ob ein Strahl nach rechts eine Linie schneidet
  static bool _rayIntersectsSegment(LatLng point, LatLng p1, LatLng p2) {
    // Stelle sicher dass p1.latitude <= p2.latitude
    LatLng a = p1;
    LatLng b = p2;
    if (a.latitude > b.latitude) {
      a = p2;
      b = p1;
    }

    // Punkt ist nicht im vertikalen Bereich der Kante
    if (point.latitude <= a.latitude || point.latitude > b.latitude) {
      return false;
    }

    // Berechne x-Koordinate des Schnittpunkts
    final double slope = (b.longitude - a.longitude) / (b.latitude - a.latitude);
    final double xIntersect = a.longitude + (point.latitude - a.latitude) * slope;

    // Punkt ist links vom Schnittpunkt = Strahl schneidet
    return point.longitude < xIntersect;
  }

  /// Prüft ob ein Punkt in mindestens einem der Polygone liegt
  /// Gibt das erste gefundene Polygon zurück, oder null
  static int? findContainingPolygonIndex(
    LatLng point,
    List<List<LatLng>> polygons,
  ) {
    for (int i = 0; i < polygons.length; i++) {
      if (isPointInPolygon(point, polygons[i])) {
        return i;
      }
    }
    return null;
  }
}
