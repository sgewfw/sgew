// lib/screens/news_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../services/auth_service.dart';
import '../constants/suewag_colors.dart';
import 'admin/news_admin_screen.dart';

/// Detail-Ansicht für einen News-Artikel
class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        backgroundColor: Colors.white,
        foregroundColor: SuewagColors.textPrimary,
        elevation: 1,
        actions: isAdmin
            ? [
                IconButton(
                  onPressed: () => _openEditScreen(context),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Bearbeiten',
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(Icons.delete, color: SuewagColors.erdbeerrot),
                  tooltip: 'Löschen',
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header-Bild
            if (article.hasImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildPlaceholderImage(),
              ),

            // Artikel-Inhalt
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Datum
                  Text(
                    _formatDate(article.createdAt),
                    style: TextStyle(
                      color: SuewagColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Titel
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Inhalt
                  Text(
                    article.content,
                    style: TextStyle(
                      color: SuewagColors.textPrimary,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: SuewagColors.quartzgrau25,
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 
                    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
    return '${date.day}. ${months[date.month - 1]} ${date.year}';
  }

  void _openEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsAdminScreen(article: article),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('News löschen?'),
        content: Text('Möchten Sie "${article.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Dialog schließen
              await NewsService().deleteNews(article.id);
              Navigator.pop(context); // Zurück zur Liste
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('News gelöscht')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SuewagColors.erdbeerrot,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
