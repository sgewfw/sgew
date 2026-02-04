// lib/services/news_service.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/news_article.dart';

/// Service für News-Operationen in Firestore und Storage
class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Collection-Referenz
  CollectionReference<Map<String, dynamic>> get _newsRef =>
      _firestore.collection('news');

  /// Stream aller News (neueste zuerst)
  Stream<List<NewsArticle>> getNewsStream() {
    return _newsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NewsArticle.fromFirestore(doc))
          .toList();
    });
  }

  /// Einzelne News abrufen
  Future<NewsArticle?> getNewsById(String id) async {
    try {
      final doc = await _newsRef.doc(id).get();
      if (doc.exists) {
        return NewsArticle.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('🔴 Fehler beim Laden der News: $e');
      return null;
    }
  }

  /// Bild zu Firebase Storage hochladen
  Future<String?> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final ref = _storage.ref().child('news_images/$fileName');
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      print('✅ Bild hochgeladen: $url');
      return url;
    } catch (e) {
      print('🔴 Fehler beim Hochladen des Bildes: $e');
      return null;
    }
  }

  /// Neue News erstellen
  Future<String?> createNews({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final news = NewsArticle(
        id: '',
        title: title,
        content: content,
        imageUrl: imageUrl,
      );
      final docRef = await _newsRef.add(news.toFirestore());
      print('✅ News erstellt: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('🔴 Fehler beim Erstellen der News: $e');
      return null;
    }
  }

  /// News aktualisieren
  Future<bool> updateNews({
    required String id,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      await _newsRef.doc(id).update({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
      });
      print('✅ News aktualisiert: $id');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Aktualisieren der News: $e');
      return false;
    }
  }

  /// News löschen
  Future<bool> deleteNews(String id) async {
    try {
      // Hole News um imageUrl zu bekommen
      final news = await getNewsById(id);
      
      // Lösche Bild aus Storage wenn vorhanden
      if (news?.hasImage == true && news!.imageUrl!.contains('firebase')) {
        try {
          final ref = _storage.refFromURL(news.imageUrl!);
          await ref.delete();
          print('✅ Bild gelöscht aus Storage');
        } catch (e) {
          print('⚠️ Bild konnte nicht gelöscht werden: $e');
        }
      }
      
      // Lösche Dokument
      await _newsRef.doc(id).delete();
      print('✅ News gelöscht: $id');
      return true;
    } catch (e) {
      print('🔴 Fehler beim Löschen der News: $e');
      return false;
    }
  }
}
