// lib/services/city_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city.dart';

/// Service für Stadt-Operationen in Firestore
class CityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Collection-Referenz
  CollectionReference<Map<String, dynamic>> get _citiesRef =>
      _firestore.collection('cities');

  /// Stream aller Städte (Echtzeit)
  Stream<List<City>> getCitiesStream() {
    return _citiesRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => City.fromFirestore(doc)).toList();
    });
  }

  /// Einzelne Stadt abrufen
  Future<City?> getCity(String cityId) async {
    try {
      final doc = await _citiesRef.doc(cityId).get();
      if (doc.exists) {
        return City.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('🔴 Fehler beim Laden der Stadt: $e');
      return null;
    }
  }

  /// Stadt hinzufügen (Admin)
  Future<String?> addCity(City city) async {
    try {
      final docRef = await _citiesRef.add(city.toFirestore());
      print('✅ Stadt hinzugefügt: ${city.name}');
      return docRef.id;
    } catch (e) {
      print('🔴 Fehler beim Hinzufügen der Stadt: $e');
      return null;
    }
  }

  /// Stadt aktualisieren (Admin)
  Future<bool> updateCity(City city) async {
    try {
      await _citiesRef.doc(city.id).update(city.toFirestore());
      print('✅ Stadt aktualisiert: ${city.name}');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Aktualisieren der Stadt: $e');
      return false;
    }
  }

  /// Stadt löschen (Admin)
  Future<bool> deleteCity(String cityId) async {
    try {
      await _citiesRef.doc(cityId).delete();
      print('✅ Stadt gelöscht: $cityId');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Löschen der Stadt: $e');
      return false;
    }
  }
}
