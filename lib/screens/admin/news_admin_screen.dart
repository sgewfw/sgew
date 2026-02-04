// lib/screens/admin/news_admin_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/news_article.dart';
import '../../services/news_service.dart';
import '../../constants/suewag_colors.dart';

/// Admin-Screen zum Erstellen/Bearbeiten von News
class NewsAdminScreen extends StatefulWidget {
  final NewsArticle? article; // null = neu erstellen

  const NewsAdminScreen({Key? key, this.article}) : super(key: key);

  @override
  State<NewsAdminScreen> createState() => _NewsAdminScreenState();
}

class _NewsAdminScreenState extends State<NewsAdminScreen> {
  final NewsService _newsService = NewsService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;

  bool get isEditing => widget.article != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _contentController = TextEditingController(text: widget.article?.content ?? '');
    _imageUrl = widget.article?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImageBytes = result.files.first.bytes;
          _selectedImageName = result.files.first.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Auswählen: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Bei neuer News: Bild ist Pflicht
    if (!isEditing && _selectedImageBytes == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte ein Bild auswählen (Pflichtfeld)'),
          backgroundColor: SuewagColors.erdbeerrot,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _imageUrl;

      // Neues Bild hochladen wenn ausgewählt
      if (_selectedImageBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_selectedImageName';
        finalImageUrl = await _newsService.uploadImage(_selectedImageBytes!, fileName);
        
        if (finalImageUrl == null) {
          throw Exception('Bild-Upload fehlgeschlagen');
        }
      }

      if (isEditing) {
        // Aktualisieren
        await _newsService.updateNews(
          id: widget.article!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageUrl: finalImageUrl,
        );
      } else {
        // Neu erstellen
        await _newsService.createNews(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageUrl: finalImageUrl,
        );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'News aktualisiert' : 'News erstellt'),
          backgroundColor: SuewagColors.leuchtendgruen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: SuewagColors.erdbeerrot,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'News bearbeiten' : 'Neue News'),
        backgroundColor: SuewagColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bild-Auswahl
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Titel
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Überschrift *',
                  hintText: 'Geben Sie eine Überschrift ein',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Überschrift ist erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Inhalt
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Inhalt *',
                  hintText: 'Schreiben Sie den Newstext',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inhalt ist erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Speichern Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Wird gespeichert...' : 'Speichern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SuewagColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    Widget imagePreview;

    if (_selectedImageBytes != null) {
      // Neu ausgewähltes Bild
      imagePreview = Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
      );
    } else if (_imageUrl != null) {
      // Bestehendes Bild
      imagePreview = Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      imagePreview = _buildPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bild ${isEditing ? '' : '*'}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: SuewagColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imagePreview,
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Bild auswählen',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedImageName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ausgewählt: $_selectedImageName',
              style: TextStyle(color: SuewagColors.textSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: SuewagColors.quartzgrau25,
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 80,
          height: 80,
        ),
      ),
    );
  }
}
