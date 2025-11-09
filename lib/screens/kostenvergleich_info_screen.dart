// lib/screens/kostenvergleich_info_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../widgets/logo_widget.dart';

class KostenvergleichInfoScreen extends StatelessWidget {
  const KostenvergleichInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Informationen & Quellen',
              style: SuewagTextStyles.headline2,
            ),
            const SizedBox(width: 12),
            const AppLogo(height: 32),


          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: SuewagColors.quartzgrau100,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: 'Systematik',
                  icon: Icons.info_outline,
                  children: [
                    _buildAbsatz(
                      'Der jährliche Kostenvergleich wird innerhalb des 2. Quartales eines Jahres veröffentlicht. '
                          'Ziel des Kostenvergleichs ist die transparente und nachvollziehbare Darstellung der '
                          'wirtschaftlichen Unterschiede der Versorgungssysteme Fernwärme sowie Wärmepumpe auf Basis '
                          'objektiver und allgemein anerkannter Parameter.',
                    ),
                    const SizedBox(height: 12),
                    _buildAbsatz(
                      'Sollten einzelne aufgeführten Quellen zukünftig nicht mehr zur Verfügung stehen, werden die '
                          'Stadt Schwalbach und die Süwag gemeinsam im Jahresgespräch gemäß §3 Ziffer 10 des '
                          'Kooperationsvertrages diese Quellen durch gleichwertige Quellen ersetzen.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSection(
                  title: 'Prämissen',
                  icon: Icons.settings,
                  children: [
                    _buildPraemisse(
                      label: 'Anteil Abwärme',
                      min: '30%',
                      max: '100%',
                      erlaeuterung: 'Mindestanteil gemäß Wärmeplanungsgesetz',
                    ),
                    _buildPraemisse(
                      label: 'Wärmebedarf in kWh',
                      min: '5.000 kWh/a',
                      max: '20.000 kWh/a',
                      erlaeuterung:
                      'Eingabebereich beschränkt, da bei >20.000 kWh Wärmebedarf eine größere Wärmepumpe benötigt wird',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSection(
                  title: 'Quellen',
                  icon: Icons.source,
                  children: [
                    _buildQuelle(
                      kategorie: 'Zinsen',
                      beschreibung:
                      'Mittelwert des Vorjahres, Zinsreihe Bundesbank: Effektivzinssätze Banken DE / Neugeschäft / '
                          'Wohnungsbaukredite an private Haushalte, anfängliche Zinsbindung über 10 Jahre / SUD119; 0,1',
                      url: 'https://www.bundesbank.de/de/statistiken',
                    ),
                    _buildQuelle(
                      kategorie: 'Strompreis',
                      beschreibung:
                      'Internetrecherche Wärmepumpentarif; Tarife ohne Bonus; Preis nach niedrigstem Preis sortiert, '
                          'Mittelwertbildung des Grundpreises sowie des Arbeitspreises der 5 günstigsten Angebote',
                      url: 'https://www.check24.de/heizstrom/waermepumpe/',
                    ),
                    _buildQuelle(
                      kategorie: 'Wärmepreis',
                      beschreibung:
                      'Veröffentlichter Wärmepreis des Fernwärmenetzes Schwalbach des 2. Quartals eines Jahres, '
                          'Abwärmeanteil: Vorjahreswerte',
                      url: 'https://www.suewag.com/energie/ihre-versorgung/fernwaermeversorgung',
                    ),
                    _buildQuelle(
                      kategorie: 'Investitionskosten',
                      beschreibung:
                      'Daten des im jeweiligen Quartal veröffentlichtem KWW-Technikkatalog der Deutschen Energie-Agentur GmbH',
                      url: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
                    ),
                    _buildQuelle(
                      kategorie: 'Wartung & Instandhaltung',
                      beschreibung:
                      'Deutsche Energie-Agentur GmbH (Hrsg.) (dena, 2025) KWW-Technikkatalog Wärmeplanung.',
                      url: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
                    ),
                    _buildQuelle(
                      kategorie: 'Förderung',
                      beschreibung:
                      'BEG - Richtlinien zur Bundesförderung für effiziente Gebäude (BEG)',
                      url:
                      'https://www.energiewechsel.de/KAENEF/Redaktion/DE/FAQ/FAQ-Uebersicht/Richtlinien/bundesfoerderung-fuer-effiziente-gebaeude-beg.html',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSection(
                  title: 'Kontakt',
                  icon: Icons.email,
                  children: [
                    _buildAbsatz(
                      'Für Fragen zum Kostenvergleich wenden Sie sich bitte an:',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.email, color: SuewagColors.primary, size: 20),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _launchEmail('fernwaerme@suewag.de'),
                          child: Text(
                            'fernwaerme@suewag.de',
                            style: TextStyle(
                              color: SuewagColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stichwort: Kostenvergleich',
                      style: SuewagTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Stand
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SuewagColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stand: November 2025',
                      style: SuewagTextStyles.caption.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: SuewagColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(title, style: SuewagTextStyles.headline3),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAbsatz(String text) {
    return Text(
      text,
      style: SuewagTextStyles.bodyMedium,
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildPraemisse({
    required String label,
    required String min,
    required String max,
    required String erlaeuterung,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SuewagColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: SuewagTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMinMaxBox('Min', min),
              const SizedBox(width: 16),
              _buildMinMaxBox('Max', max),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            erlaeuterung,
            style: SuewagTextStyles.bodySmall.copyWith(
              color: SuewagColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinMaxBox(String label, String wert) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: SuewagTextStyles.caption,
          ),
          Text(
            wert,
            style: SuewagTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuelle({
    required String kategorie,
    required String beschreibung,
    required String url,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SuewagColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kategorie,
            style: SuewagTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: SuewagColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            beschreibung,
            style: SuewagTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _launchUrl(url),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: SuewagColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    url,
                    style: TextStyle(
                      color: SuewagColors.primary,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}