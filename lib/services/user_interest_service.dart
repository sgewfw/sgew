// lib/services/user_interest_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user_interest.dart';

/// Service für User-Interessen-Operationen in Firestore
class UserInterestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection-Referenz
  CollectionReference<Map<String, dynamic>> get _interestsRef =>
      _firestore.collection('user_interests');

  /// Interesse für Fernwärme an einem Standort anmelden
  Future<bool> submitInterest({
    required String cityId,
    required LatLng location,
    String? street,
    String? streetNumber,
    String? plz,
    String? city,
  }) async {
    try {
      final user = _auth.currentUser;
      
      // Strukturierte Adressdaten erstellen
      final data = {
        'cityId': cityId,
        'location': GeoPoint(location.latitude, location.longitude),
        'userId': user?.uid,
        'userEmail': user?.email,
        // Strukturierte Adresse
        'street': street,
        'streetNumber': streetNumber,
        'plz': plz,
        'city': city,
        // Formatierte Adresse für Anzeige
        'formattedAddress': [
          if (street != null) '$street ${streetNumber ?? ''}',
          if (plz != null || city != null) '${plz ?? ''} ${city ?? ''}'.trim(),
        ].where((s) => s.isNotEmpty).join(', '),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _interestsRef.add(data);
      print('✅ Interesse angemeldet: $street $streetNumber, $plz $city');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Anmelden des Interesses: $e');
      return false;
    }
  }

  /// Stream aller Interessen einer Stadt (Admin-Ansicht)
  Stream<List<UserInterest>> getInterestsStream(String cityId) {
    return _interestsRef
        .where('cityId', isEqualTo: cityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserInterest.fromFirestore(doc))
          .toList();
    });
  }

  /// Anzahl der Interessen pro Stadt
  Future<int> getInterestCount(String cityId) async {
    try {
      final snapshot =
          await _interestsRef.where('cityId', isEqualTo: cityId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('🔴 Fehler beim Zählen der Interessen: $e');
      return 0;
    }
  }

  /// Interesse löschen (Admin)
  Future<bool> deleteInterest(String interestId) async {
    try {
      await _interestsRef.doc(interestId).delete();
      print('✅ Interesse gelöscht: $interestId');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Löschen des Interesses: $e');
      return false;
    }
  }
}
