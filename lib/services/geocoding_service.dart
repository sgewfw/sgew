// lib/services/geocoding_service.dart

import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Service für Adress-Geocoding mit Google Geocoding API
class GeocodingService {
  // API Key - gleicher wie in index.html
  static const String _apiKey = 'AIzaSyAvSopq1vP3SyFuswZf6W6Y3YR4Q5o_QMo';

  /// Sucht eine Adresse und gibt die Koordinaten zurück
  Future<GeocodingResult?> searchAddress(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$encodedAddress'
        '&region=de'
        '&language=de'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('❌ Geocoding Fehler: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || (data['results'] as List).isEmpty) {
        print('❌ Keine Ergebnisse für: $address (Status: ${data['status']})');
        return null;
      }

      return _parseGeocodingResult(data['results'][0]);
    } catch (e) {
      print('❌ Geocoding Exception: $e');
      return null;
    }
  }

  /// Reverse Geocoding: Koordinaten zu Adresse
  Future<GeocodingResult?> reverseGeocode(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&region=de'
        '&language=de'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('❌ Reverse Geocoding Fehler: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || (data['results'] as List).isEmpty) {
        print('❌ Keine Adresse für Position: $position');
        return null;
      }

      return _parseGeocodingResult(data['results'][0]);
    } catch (e) {
      print('❌ Reverse Geocoding Exception: $e');
      return null;
    }
  }

  /// Parst ein Geocoding-Ergebnis in strukturierte Adressdaten
  GeocodingResult _parseGeocodingResult(Map<String, dynamic> result) {
    final location = result['geometry']['location'];
    final formattedAddress = result['formatted_address'] as String;
    final components = result['address_components'] as List;

    String? streetNumber;
    String? street;
    String? postalCode;
    String? city;

    for (final component in components) {
      final types = (component['types'] as List).cast<String>();
      final longName = component['long_name'] as String;

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        street = longName;
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      } else if (types.contains('locality')) {
        city = longName;
      } else if (types.contains('administrative_area_level_3') && city == null) {
        // Fallback für kleinere Orte
        city = longName;
      }
    }

    return GeocodingResult(
      position: LatLng(location['lat'], location['lng']),
      formattedAddress: formattedAddress,
      street: street,
      streetNumber: streetNumber,
      postalCode: postalCode,
      city: city,
    );
  }
}

/// Ergebnis einer Geocoding-Suche mit strukturierten Adressdaten
class GeocodingResult {
  final LatLng position;
  final String formattedAddress;
  final String? street;
  final String? streetNumber;
  final String? postalCode;
  final String? city;

  const GeocodingResult({
    required this.position,
    required this.formattedAddress,
    this.street,
    this.streetNumber,
    this.postalCode,
    this.city,
  });

  @override
  String toString() => 'GeocodingResult(street: $street $streetNumber, $postalCode $city)';
}
