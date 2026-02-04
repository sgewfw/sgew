// lib/services/faq_service.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/faq_item.dart';

/// Service für FAQ-Operationen in Firestore und Storage
class FaqService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Collection-Referenz
  CollectionReference<Map<String, dynamic>> get _faqRef =>
      _firestore.collection('faqs');

  /// Stream aller FAQs (neueste zuerst)
  Stream<List<FaqItem>> getFaqStream() {
    return _faqRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FaqItem.fromFirestore(doc))
          .toList();
    });
  }

  /// Einzelnes FAQ abrufen
  Future<FaqItem?> getFaqById(String id) async {
    try {
      final doc = await _faqRef.doc(id).get();
      if (doc.exists) {
        return FaqItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('🔴 Fehler beim Laden des FAQs: $e');
      return null;
    }
  }

  /// Bild zu Firebase Storage hochladen
  Future<String?> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final ref = _storage.ref().child('faq_images/$fileName');
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      print('✅ FAQ-Bild hochgeladen: $url');
      return url;
    } catch (e) {
      print('🔴 Fehler beim Hochladen des FAQ-Bildes: $e');
      return null;
    }
  }

  /// Neues FAQ erstellen
  Future<String?> createFaq({
    required String question,
    required String answer,
    String? imageUrl,
  }) async {
    try {
      final faq = FaqItem(
        id: '',
        question: question,
        answer: answer,
        imageUrl: imageUrl,
      );
      final docRef = await _faqRef.add(faq.toFirestore());
      print('✅ FAQ erstellt: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('🔴 Fehler beim Erstellen des FAQs: $e');
      return null;
    }
  }

  /// FAQ aktualisieren
  Future<bool> updateFaq({
    required String id,
    required String question,
    required String answer,
    String? imageUrl,
  }) async {
    try {
      await _faqRef.doc(id).update({
        'question': question,
        'answer': answer,
        'imageUrl': imageUrl,
      });
      print('✅ FAQ aktualisiert: $id');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Aktualisieren des FAQs: $e');
      return false;
    }
  }

  /// FAQ löschen
  Future<bool> deleteFaq(String id) async {
    try {
      // Hole FAQ um imageUrl zu bekommen
      final faq = await getFaqById(id);
      
      // Lösche Bild aus Storage wenn vorhanden
      if (faq?.hasImage == true && faq!.imageUrl!.contains('firebase')) {
        try {
          final ref = _storage.refFromURL(faq.imageUrl!);
          await ref.delete();
          print('✅ FAQ-Bild gelöscht aus Storage');
        } catch (e) {
          print('⚠️ FAQ-Bild konnte nicht gelöscht werden: $e');
        }
      }
      
      // Lösche Dokument
      await _faqRef.doc(id).delete();
      print('✅ FAQ gelöscht: $id');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Löschen des FAQs: $e');
      return false;
    }
  }
}
