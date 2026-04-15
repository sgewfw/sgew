// lib/screens/admin/projektfinder_admin_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/suewag_colors.dart';
import '../../constants/suewag_text_styles.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';
import '../../utils/csv_file_handler.dart' as csv_handler;
import '../../widgets/projekt_edit_dialog.dart';

/// Admin Screen für Projekt-Verwaltung
///
/// Features:
/// - Liste aller Projekte
/// - Projekt hinzufügen/bearbeiten/löschen
/// - CSV Import/Export (Web + Mobile)
class ProjektfinderAdminScreen extends StatefulWidget {
  const ProjektfinderAdminScreen({Key? key}) : super(key: key);

  @override
  State<ProjektfinderAdminScreen> createState() => _ProjektfinderAdminScreenState();
}

class _ProjektfinderAdminScreenState extends State<ProjektfinderAdminScreen> {
  final _projectService = ProjectService();
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await _projectService.getAllProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _addProject() async {
    final result = await showDialog<Project>(
      context: context,
      builder: (context) => const ProjektEditDialog(),
    );

    if (result != null) {
      await _projectService.createProject(result);
      _showSnackBar('✅ Projekt erstellt');
      _loadProjects();
    }
  }

  Future<void> _editProject(Project project) async {
    final result = await showDialog<Project>(
      context: context,
      builder: (context) => ProjektEditDialog(project: project),
    );

    if (result != null) {
      await _projectService.updateProject(result);
      _showSnackBar('✅ Projekt aktualisiert');
      _loadProjects();
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projekt löschen?'),
        content: Text('Möchten Sie "${project.projektName}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SuewagColors.erdbeerrot,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _projectService.deleteProject(project.id);
      _showSnackBar('✅ Projekt gelöscht');
      _loadProjects();
    }
  }

  Future<void> _exportCSV() async {
    try {
      final csv = await _projectService.exportToCSV();
      final fileName =
          'projekte_export_${DateTime.now().toIso8601String().split('T')[0]}.csv';

      await csv_handler.exportCSV(csv, fileName);
      _showSnackBar('✅ CSV Export erfolgreich');
    } catch (e) {
      _showSnackBar('❌ Export fehlgeschlagen: $e', isError: true);
    }
  }

  Future<void> _importCSV() async {
    try {
      final picked = await csv_handler.importCSV();
      if (picked == null) return;

      final overwrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('CSV Import'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datei: ${picked.name}'),
              const SizedBox(height: 16),
              const Text('Wie sollen bestehende Projekte behandelt werden?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Abbrechen'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nur neue hinzufügen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Überschreiben'),
            ),
          ],
        ),
      );

      if (overwrite == null) return;

      final count = await _projectService.importFromCSV(
        picked.content,
        overwrite: overwrite,
      );
      _showSnackBar('✅ $count Projekte importiert');
      _loadProjects();
    } catch (e) {
      _showSnackBar('❌ Import fehlgeschlagen: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? SuewagColors.erdbeerrot : SuewagColors.leuchtendgruen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: AppBar(
        title: const Text('Projekte verwalten'),
        backgroundColor: SuewagColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'CSV Export',
            onPressed: _exportCSV,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'CSV Import',
            onPressed: _importCSV,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProject,
        icon: const Icon(Icons.add),
        label: const Text('Neues Projekt'),
        backgroundColor: SuewagColors.leuchtendgruen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
          ? _buildEmptyState()
          : _buildProjectList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 80,
            color: SuewagColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Projekte vorhanden',
            style: SuewagTextStyles.headline3.copyWith(
              color: SuewagColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie ein neues Projekt oder importieren Sie eine CSV-Datei.',
            style: SuewagTextStyles.bodyMedium.copyWith(
              color: SuewagColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (context, index) => _buildProjectCard(_projects[index]),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final isWaermenetz = project.type == Project.typeWaermenetz;
    final typeColor =
    isWaermenetz ? SuewagColors.verkehrsorange : SuewagColors.indiablau;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: typeColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _editProject(project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isWaermenetz ? Icons.local_fire_department : Icons.home_work,
                  color: typeColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SuewagColors.quartzgrau25,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            project.projektNummer,
                            style: SuewagTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            project.type,
                            style: SuewagTextStyles.bodySmall.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.projektName,
                      style: SuewagTextStyles.headline4,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project.plz} ${project.ort}',
                      style: SuewagTextStyles.bodySmall.copyWith(
                        color: SuewagColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: SuewagColors.textSecondary),
                onPressed: () => _deleteProject(project),
              ),
            ],
          ),
        ),
      ),
    );
  }
}