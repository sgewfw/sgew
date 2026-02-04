// lib/screens/admin/faq_admin_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/faq_item.dart';
import '../../services/faq_service.dart';
import '../../constants/suewag_colors.dart';

/// Admin-Screen zum Erstellen/Bearbeiten von FAQs
class FaqAdminScreen extends StatefulWidget {
  final FaqItem? faq; // null = neu erstellen

  const FaqAdminScreen({Key? key, this.faq}) : super(key: key);

  @override
  State<FaqAdminScreen> createState() => _FaqAdminScreenState();
}

class _FaqAdminScreenState extends State<FaqAdminScreen> {
  final FaqService _faqService = FaqService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _questionController;
  late TextEditingController _answerController;

  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;

  bool get isEditing => widget.faq != null;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.faq?.question ?? '');
    _answerController = TextEditingController(text: widget.faq?.answer ?? '');
    _imageUrl = widget.faq?.imageUrl;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
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

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _imageUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _imageUrl;

      // Neues Bild hochladen wenn ausgewählt
      if (_selectedImageBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_selectedImageName';
        finalImageUrl = await _faqService.uploadImage(_selectedImageBytes!, fileName);
        
        if (finalImageUrl == null) {
          throw Exception('Bild-Upload fehlgeschlagen');
        }
      }

      if (isEditing) {
        // Aktualisieren
        await _faqService.updateFaq(
          id: widget.faq!.id,
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
          imageUrl: finalImageUrl,
        );
      } else {
        // Neu erstellen
        await _faqService.createFaq(
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
          imageUrl: finalImageUrl,
        );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'FAQ aktualisiert' : 'FAQ erstellt'),
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
        title: Text(isEditing ? 'FAQ bearbeiten' : 'Neue FAQ'),
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
              // Frage
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Frage *',
                  hintText: 'z.B. Wie funktioniert Fernwärme?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Frage ist erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Antwort
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Antwort *',
                  hintText: 'Geben Sie eine ausführliche Antwort ein',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Antwort ist erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Optionales Bild
              _buildImagePicker(),
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
    final hasImage = _selectedImageBytes != null || _imageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bild (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: _removeImage,
                icon: Icon(Icons.delete, size: 18, color: SuewagColors.erdbeerrot),
                label: Text('Entfernen', style: TextStyle(color: SuewagColors.erdbeerrot)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: SuewagColors.divider),
              borderRadius: BorderRadius.circular(12),
              color: SuewagColors.quartzgrau25,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage ? _buildImagePreview() : _buildUploadHint(),
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

  Widget _buildImagePreview() {
    if (_selectedImageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
          _buildOverlay(),
        ],
      );
    } else if (_imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildUploadHint(),
          ),
          _buildOverlay(),
        ],
      );
    }
    return _buildUploadHint();
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text('Ändern', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 40, color: SuewagColors.quartzgrau75),
          const SizedBox(height: 8),
          Text(
            'Bild hinzufügen',
            style: TextStyle(color: SuewagColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
