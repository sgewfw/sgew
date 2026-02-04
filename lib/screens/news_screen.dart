// lib/screens/news_screen.dart

import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../services/auth_service.dart';
import '../constants/suewag_colors.dart';
import 'admin/news_admin_screen.dart';
import 'news_detail_screen.dart';

/// News-Screen zeigt alle News-Artikel als kompakte Liste an
class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final isAdmin = _authService.isAdmin;

    return Scaffold(
      body: StreamBuilder<List<NewsArticle>>(
        stream: _newsService.getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Fehler: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final news = snapshot.data!;

          if (news.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.newspaper,
                    size: 64,
                    color: SuewagColors.quartzgrau50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Noch keine News vorhanden',
                    style: TextStyle(
                      color: SuewagColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: news.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildNewsListItem(news[index]);
            },
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openAdminScreen(null),
              icon: const Icon(Icons.add),
              label: const Text('Neu'),
              backgroundColor: SuewagColors.primary,
            )
          : null,
    );
  }

  /// Kompakte News-Zeile: kleines Bild links, Titel + Datum rechts
  Widget _buildNewsListItem(NewsArticle article) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openDetailScreen(article),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Kleines Thumbnail links
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: article.hasImage
                      ? Image.network(
                          article.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              const SizedBox(width: 16),

              // Titel und Datum rechts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(article.createdAt),
                      style: TextStyle(
                        color: SuewagColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Pfeil-Icon rechts
              Icon(
                Icons.chevron_right,
                color: SuewagColors.textSecondary,
              ),
            ],
          ),
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
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _openDetailScreen(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(article: article),
      ),
    );
  }

  void _openAdminScreen(NewsArticle? article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsAdminScreen(article: article),
      ),
    );
  }
}
