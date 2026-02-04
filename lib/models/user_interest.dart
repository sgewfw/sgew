// lib/models/user_interest.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// User-Interesse für Fernwärme an einem bestimmten Standort
class UserInterest {
  final String? id;
  final String cityId;
  final LatLng location;
  final String? userId;
  final DateTime createdAt;

  UserInterest({
    this.id,
    required this.cityId,
    required this.location,
    this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory aus Firestore-Dokument
  factory UserInterest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint;
    final timestamp = data['createdAt'] as Timestamp?;

    return UserInterest(
      id: doc.id,
      cityId: data['cityId'] ?? '',
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      userId: data['userId'],
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  /// Konvertierung zu Firestore-Map
  Map<String, dynamic> toFirestore() {
    return {
      'cityId': cityId,
      'location': GeoPoint(location.latitude, location.longitude),
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  String toString() =>
      'UserInterest(id: $id, cityId: $cityId, location: $location)';
}
