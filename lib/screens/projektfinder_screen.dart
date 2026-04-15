// lib/screens/projektfinder_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjektfinderScreen extends StatefulWidget {
  const ProjektfinderScreen({Key? key}) : super(key: key);

  @override
  State<ProjektfinderScreen> createState() => _ProjektfinderScreenState();
}

class _ProjektfinderScreenState extends State<ProjektfinderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kundennummerController = TextEditingController();
  final _ortController = TextEditingController();
  final _projectService = ProjectService();

  bool _isLoading = false;
  bool _hasSearched = false;
  Project? _foundProject;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _projectService.initializeIfEmpty();
  }

  @override
  void dispose() {
    _kundennummerController.dispose();
    _ortController.dispose();
    super.dispose();
  }

  Future<void> _searchProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final project = await _projectService.findProject(
        _kundennummerController.text.trim(),
        _ortController.text.trim(),
      );

      setState(() {
        _hasSearched = true;
        _foundProject = project;
        _isLoading = false;
        if (project == null) {
          _errorMessage =
          'Kein Projekt mit dieser Kundennummer und Ort gefunden.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler bei der Suche: $e';
      });
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;
    // Auf breiten Screens Seitenabstand hinzufügen
    final horizontalPadding = isWideScreen
        ? (screenWidth - 1100).clamp(0.0, double.infinity) / 2 + 32.0
        : 16.0;

    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: AppBar(
        title: const Text(
          'Projektfinder',
          style: TextStyle(color: SuewagColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        foregroundColor: SuewagColors.textPrimary,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchCard(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorCard()
            else if (_foundProject != null)
                _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Card(
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.search, color: SuewagColors.primary),
                      const SizedBox(width: 12),
                      Text('Projekt suchen',
                          style: SuewagTextStyles.headline3),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Geben Sie Ihre Kundennummer und den Ort ein, um Ihr Projekt zu finden.',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Felder: nebeneinander auf breiten Screens
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildKundennummerField(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildOrtField(),
                        ),
                        const SizedBox(width: 16),
                        // Button auf gleicher Höhe wie Felder
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _searchProject,
                            icon: const Icon(Icons.search),
                            label: const Text('Suchen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SuewagColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildKundennummerField(),
                    const SizedBox(height: 16),
                    _buildOrtField(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _searchProject,
                        icon: const Icon(Icons.search),
                        label: const Text('Projekt suchen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SuewagColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKundennummerField() {
    return TextFormField(
      controller: _kundennummerController,
      decoration: InputDecoration(
        labelText: 'Kundennummer',
        hintText: 'z.B. 31100049',
        prefixIcon: const Icon(Icons.badge_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte Kundennummer eingeben';
        }
        if (value.length < 3) {
          return 'Mindestens 3 Ziffern erforderlich';
        }
        return null;
      },
    );
  }

  Widget _buildOrtField() {
    return TextFormField(
      controller: _ortController,
      decoration: InputDecoration(
        labelText: 'Ort',
        hintText: 'z.B. Mainz',
        prefixIcon: const Icon(Icons.location_city),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte Ort eingeben';
        }
        return null;
      },
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 2,
      color: SuewagColors.erdbeerrot.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: SuewagColors.erdbeerrot, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: SuewagColors.erdbeerrot, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _errorMessage!,
                style: SuewagTextStyles.bodyMedium.copyWith(
                  color: SuewagColors.erdbeerrot,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final project = _foundProject!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    if (isWideScreen) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildGoogleMapCard(project)),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildStammdatenCard(project)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildNetztypCard(project)),
              const SizedBox(width: 16),
              Expanded(child: _buildAnsprechpartnerCard(project)),
            ],
          ),
          const SizedBox(height: 16),
          _buildBeschreibungCard(project),
          const SizedBox(height: 16),
          _buildRechtlicheHinweiseCard(project),
        ],
      );
    } else {
      return Column(
        children: [
          _buildGoogleMapCard(project),
          const SizedBox(height: 16),
          _buildStammdatenCard(project),
          const SizedBox(height: 16),
          _buildNetztypCard(project),
          const SizedBox(height: 16),
          _buildAnsprechpartnerCard(project),
          const SizedBox(height: 16),
          _buildBeschreibungCard(project),
          const SizedBox(height: 16),
          _buildRechtlicheHinweiseCard(project),
        ],
      );
    }
  }

  Widget _buildGoogleMapCard(Project project) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: project.hasImage
            ? Image.network(
          project.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildMap(project),
        )
            : _buildMap(project),
      ),
    );
  }

  Widget _buildMap(Project project) {
    final position = LatLng(project.lat, project.lng);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('project'),
              position: position,
              infoWindow: InfoWindow(
                title: project.projektName,
                snippet: '${project.plz} ${project.ort}',
              ),
            ),
          },
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on,
                    size: 16, color: SuewagColors.erdbeerrot),
                const SizedBox(width: 4),
                Text(
                  '${project.plz} ${project.ort}',
                  style: SuewagTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!project.hasCoordinates) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                      SuewagColors.verkehrsorange.withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Demo',
                      style: SuewagTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: SuewagColors.verkehrsorange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStammdatenCard(Project project) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SuewagColors.leuchtendgruen.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: SuewagColors.leuchtendgruen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Projekt gefunden',
                          style: SuewagTextStyles.bodySmall),
                      Text(project.projektName,
                          style: SuewagTextStyles.headline3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.numbers, 'Projektnummer', project.projektNummer),
            _buildInfoRow(Icons.location_on, 'Ort',
                '${project.plz} ${project.ort}'),
            _buildInfoRow(Icons.engineering, 'Anlagentyp',
                project.installierterAnlagentyp),
            if (project.zusatzInfo != null &&
                project.zusatzInfo!.isNotEmpty)
              _buildInfoRow(
                  Icons.info_outline, 'Zusatzinfo', project.zusatzInfo!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: SuewagColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: SuewagTextStyles.bodySmall.copyWith(
                color: SuewagColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SuewagTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetztypCard(Project project) {
    final isWaermenetz = project.type == Project.typeWaermenetz;
    final color =
    isWaermenetz ? SuewagColors.verkehrsorange : SuewagColors.indiablau;
    final icon =
    isWaermenetz ? Icons.local_fire_department : Icons.home_work;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.type,
                    style: SuewagTextStyles.headline2.copyWith(color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isWaermenetz
                        ? 'Großes Fernwärmenetz (>16 Gebäude)'
                        : 'Nahwärmenetz (2-16 Gebäude)',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.textSecondary,
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

  Widget _buildAnsprechpartnerCard(Project project) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _launchEmail(project.ansprechpartnerEmail),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SuewagColors.indiablau.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: SuewagColors.indiablau,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ihr Ansprechpartner',
                      style: SuewagTextStyles.bodySmall.copyWith(
                        color: SuewagColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.ansprechpartnerName,
                      style: SuewagTextStyles.headline4,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 16,
                          color: SuewagColors.indiablau,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            project.ansprechpartnerEmail,
                            style: SuewagTextStyles.bodySmall.copyWith(
                              color: SuewagColors.indiablau,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: SuewagColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeschreibungCard(Project project) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: SuewagColors.primary),
                const SizedBox(width: 12),
                Text('Projektbeschreibung',
                    style: SuewagTextStyles.headline4),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              project.beschreibung,
              style:
              SuewagTextStyles.bodyMedium.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRechtlicheHinweiseCard(Project project) {
    final isWaermenetz = project.type == Project.typeWaermenetz;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding:
          const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Icon(Icons.gavel, color: SuewagColors.indiablau),
          title: Text('Rechtliche Anforderungen',
              style: SuewagTextStyles.headline4),
          subtitle: Text(
            isWaermenetz
                ? 'Wärmeplanungsgesetz (WPG)'
                : 'Gebäudeenergiegesetz (GEG)',
            style: SuewagTextStyles.bodySmall.copyWith(
              color: SuewagColors.textSecondary,
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SuewagColors.quartzgrau10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWaermenetz)
                    ..._buildWaermenetzInfo()
                  else
                    ..._buildGebaeudenetzInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWaermenetzInfo() {
    return [
      _buildLegalItem(
        'Definition nach WPG',
        'Ein Wärmenetz versorgt mehr als 16 Gebäude oder mehr als 100 Wohneinheiten und fällt unter die kommunale Wärmeplanung.',
      ),
      const SizedBox(height: 12),
      _buildLegalItem(
        'Erneuerbare Energien',
        'Ab 2030 müssen mindestens 30% der Wärme aus erneuerbaren Energien stammen. Bis 2040 steigt dieser Anteil auf 80%.',
      ),
      const SizedBox(height: 12),
      _buildLegalItem(
        'Transformationsplan',
        'Der Wärmenetzbetreiber muss einen Transformationsplan erstellen, der den Weg zur klimaneutralen Wärmeversorgung bis 2045 aufzeigt.',
      ),
      const SizedBox(height: 12),
      _buildLegalItem(
        'Kommunale Wärmeplanung',
        'Städte >100.000 Einwohner: Wärmeplan bis 30.06.2026\nStädte >10.000 Einwohner: Wärmeplan bis 30.06.2028',
      ),
    ];
  }

  List<Widget> _buildGebaeudenetzInfo() {
    return [
      _buildLegalItem(
        'Definition nach GEG § 3 Nr. 9a',
        'Ein Gebäudenetz versorgt 2 bis 16 Gebäude mit maximal 100 Wohneinheiten.',
      ),
      const SizedBox(height: 12),
      _buildLegalItem(
        '65%-Regel für Neubauten',
        'Seit 01.01.2024 müssen neue Heizungen in Neubaugebieten mindestens 65% erneuerbare Energien nutzen.',
      ),
      const SizedBox(height: 12),
      _buildLegalItem(
        'Übergangsfristen Bestand',
        'Für Bestandsgebäude gelten Übergangsfristen, die an die kommunale Wärmeplanung gekoppelt sind.',
      ),
      const SizedBox(height: 12),
      _buildLegalItem(
        'Erfüllungsoptionen',
        '• Anschluss an Wärmenetz\n• Elektrische Wärmepumpe\n• Biomasseheizung (Pellets)\n• Solarthermie\n• Hybridheizungen',
      ),
    ];
  }

  Widget _buildLegalItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SuewagTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: SuewagColors.indiablau,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: SuewagTextStyles.bodySmall.copyWith(height: 1.5),
        ),
      ],
    );
  }
}