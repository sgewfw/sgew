// lib/services/zone_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/zone.dart';

/// Service für Zonen-Operationen in Firestore
/// Zonen sind Sub-Collections unter cities/{cityId}/zones
class ZoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Zones Collection-Referenz für eine Stadt
  CollectionReference<Map<String, dynamic>> _zonesRef(String cityId) =>
      _firestore.collection('cities').doc(cityId).collection('zones');

  /// Stream aller Zonen einer Stadt (Echtzeit)
  Stream<List<Zone>> getZonesStream(String cityId) {
    return _zonesRef(cityId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Zone.fromFirestore(doc)).toList();
    });
  }

  /// Einzelne Zone abrufen
  Future<Zone?> getZone(String cityId, String zoneId) async {
    try {
      final doc = await _zonesRef(cityId).doc(zoneId).get();
      if (doc.exists) {
        return Zone.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('🔴 Fehler beim Laden der Zone: $e');
      return null;
    }
  }

  /// Zone hinzufügen (Admin)
  Future<String?> addZone(String cityId, Zone zone) async {
    try {
      final docRef = await _zonesRef(cityId).add(zone.toFirestore());
      print('✅ Zone hinzugefügt: ${zone.type.displayName}');
      return docRef.id;
    } catch (e) {
      print('🔴 Fehler beim Hinzufügen der Zone: $e');
      return null;
    }
  }

  /// Zone aktualisieren (Admin)
  Future<bool> updateZone(String cityId, Zone zone) async {
    try {
      await _zonesRef(cityId).doc(zone.id).update(zone.toFirestore());
      print('✅ Zone aktualisiert: ${zone.id}');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Aktualisieren der Zone: $e');
      return false;
    }
  }

  /// Zone löschen (Admin)
  Future<bool> deleteZone(String cityId, String zoneId) async {
    try {
      await _zonesRef(cityId).doc(zoneId).delete();
      print('✅ Zone gelöscht: $zoneId');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Löschen der Zone: $e');
      return false;
    }
  }
}
