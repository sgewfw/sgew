// lib/models/news_article.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// News-Artikel für die News-Sektion
class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String? imageUrl; // Firebase Storage URL oder null für Placeholder
  final DateTime createdAt;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory aus Firestore-Dokument
  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;

    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  /// Konvertierung zu Firestore-Map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Placeholder-Bild wenn kein Bild vorhanden
  String get displayImageUrl => imageUrl ?? 'assets/images/logo.png';

  /// Gibt true zurück wenn ein echtes Bild vorhanden ist
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  String toString() => 'NewsArticle(id: $id, title: $title)';
}
