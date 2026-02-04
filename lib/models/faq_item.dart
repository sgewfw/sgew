// lib/models/faq_item.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// FAQ-Eintrag für die FAQ-Sektion
class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String? imageUrl; // Optional: Firebase Storage URL
  final DateTime createdAt;

  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory aus Firestore-Dokument
  factory FaqItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;

    return FaqItem(
      id: doc.id,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  /// Konvertierung zu Firestore-Map
  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'answer': answer,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Placeholder-Bild wenn kein Bild vorhanden
  String get displayImageUrl => imageUrl ?? 'assets/images/logo.png';

  /// Gibt true zurück wenn ein echtes Bild vorhanden ist
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Prüft ob Suchbegriff in Frage oder Antwort vorkommt (case-insensitive)
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return question.toLowerCase().contains(lowerQuery) ||
           answer.toLowerCase().contains(lowerQuery);
  }

  @override
  String toString() => 'FaqItem(id: $id, question: $question)';
}
