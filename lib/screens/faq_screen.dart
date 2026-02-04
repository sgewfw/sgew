// lib/screens/faq_screen.dart

import 'package:flutter/material.dart';
import '../models/faq_item.dart';
import '../services/faq_service.dart';
import '../services/auth_service.dart';
import '../constants/suewag_colors.dart';
import 'admin/faq_admin_screen.dart';

/// FAQ-Screen mit Volltextsuche
class FaqScreen extends StatefulWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final FaqService _faqService = FaqService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _authService.isAdmin;

    return Scaffold(
      body: Column(
        children: [
          // Suchleiste
          Container(
            padding: const EdgeInsets.all(16),
            color: SuewagColors.quartzgrau25,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'FAQ durchsuchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // FAQ Liste
          Expanded(
            child: StreamBuilder<List<FaqItem>>(
              stream: _faqService.getFaqStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Fehler: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter nach Suchbegriff
                final allFaqs = snapshot.data!;
                final filteredFaqs = allFaqs
                    .where((faq) => faq.matchesSearch(_searchQuery))
                    .toList();

                if (filteredFaqs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.help_outline,
                          size: 64,
                          color: SuewagColors.quartzgrau50,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Keine FAQs gefunden für "$_searchQuery"'
                              : 'Noch keine FAQs vorhanden',
                          style: TextStyle(
                            color: SuewagColors.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (context, index) {
                    return _buildFaqCard(filteredFaqs[index]);
                  },
                );
              },
            ),
          ),
        ],
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

  Widget _buildFaqCard(FaqItem faq) {
    final isAdmin = _authService.isAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SuewagColors.karibikblau.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.help_outline,
            color: SuewagColors.karibikblau,
          ),
        ),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          // Antwort
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SuewagColors.quartzgrau25,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              faq.answer,
              style: TextStyle(
                color: SuewagColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

          // Bild wenn vorhanden
          if (faq.hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                faq.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ],

          // Admin Actions
          if (isAdmin) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openAdminScreen(faq),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Bearbeiten'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(faq),
                  icon: Icon(Icons.delete, size: 18, color: SuewagColors.erdbeerrot),
                  label: Text('Löschen', style: TextStyle(color: SuewagColors.erdbeerrot)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openAdminScreen(FaqItem? faq) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaqAdminScreen(faq: faq),
      ),
    );
  }

  void _confirmDelete(FaqItem faq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FAQ löschen?'),
        content: Text('Möchten Sie diese FAQ wirklich löschen?\n\n"${faq.question}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _faqService.deleteFaq(faq.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FAQ gelöscht')),
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
