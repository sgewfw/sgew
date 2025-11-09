// lib/screens/kostenvergleich_rechner_tab.dart

import 'package:flutter/material.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/kostenvergleich_data.dart';
import '../models/kostenvergleich_ergebnis.dart';
import '../models/szenario_rechner_eingabe.dart';
import '../services/kostenvergleich_berechnung_service.dart';
import '../widgets/kostenvergleich_chart_widget.dart';

class KostenvergleichRechnerTab extends StatefulWidget {
  final KostenvergleichJahr stammdaten;
  final KostenvergleichBerechnungService berechnungService;

  const KostenvergleichRechnerTab({
    Key? key,
    required this.stammdaten,
    required this.berechnungService,
  }) : super(key: key);

  @override
  State<KostenvergleichRechnerTab> createState() => _KostenvergleichRechnerTabState();
}

class _KostenvergleichRechnerTabState extends State<KostenvergleichRechnerTab> {
  late SzenarioRechnerEingabe _eingabe;
  KostenvergleichErgebnis? _ergebnis;

  @override
  void initState() {
    super.initState();
    _eingabe = SzenarioRechnerEingabe.vonStammdaten(
      waermebedarf: widget.stammdaten.grunddaten.heizenergiebedarf,
      beheizteFlaeche: widget.stammdaten.grunddaten.beheizteFlaeche,
      spezHeizenergiebedarf: widget.stammdaten.grunddaten.spezHeizenergiebedarf,
      defaultJAZ: 3.0,
      defaultStrompreis: 16.52,
      defaultStromGrundpreis: 9.0,
      defaultAnteilWaermeAusStrom: 0.30,
    );
    _berechnen();
  }

  void _berechnen() {
    final ergebnis = widget.berechnungService.berechneVergleich(
      stammdaten: widget.stammdaten,
      benutzerEingabe: _eingabe,
    );

    setState(() {
      _ergebnis = ergebnis;
    });
  }

  void _updateEingabe(SzenarioRechnerEingabe neueEingabe) {
    setState(() {
      _eingabe = neueEingabe;
    });
    _berechnen();
  }

  void _resetEingabe() {
    setState(() {
      _eingabe = SzenarioRechnerEingabe.vonStammdaten(
        waermebedarf: widget.stammdaten.grunddaten.heizenergiebedarf,
        beheizteFlaeche: widget.stammdaten.grunddaten.beheizteFlaeche,
        spezHeizenergiebedarf: widget.stammdaten.grunddaten.spezHeizenergiebedarf,
        defaultJAZ: 3.0,
        defaultStrompreis: 16.52,
        defaultStromGrundpreis: 9.0,
        defaultAnteilWaermeAusStrom: 0.30,
      );
    });
    _berechnen();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info-Banner
              _buildInfoBanner(),
              const SizedBox(height: 24),

              // Eingabe + Ergebnis
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildEingabeCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 600,
                            child: _buildChartCard(),
                          ),
                          const SizedBox(height: 16),
                          _buildErgebnisTabelle(),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _buildEingabeCard(),
                const SizedBox(height: 16),
                _buildChartCard(),
                const SizedBox(height: 16),
                _buildErgebnisTabelle(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuewagColors.verkehrsorange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.verkehrsorange),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate, color: SuewagColors.verkehrsorange, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interaktiver Szenario-Rechner',
                  style: SuewagTextStyles.headline4.copyWith(
                    color: SuewagColors.verkehrsorange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Passen Sie die Parameter an Ihre individuelle Situation an. Die Berechnung erfolgt in Echtzeit.',
                  style: SuewagTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEingabeCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: SuewagColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Parameter anpassen', style: SuewagTextStyles.headline4),
                ],
              ),
              TextButton.icon(
                onPressed: _resetEingabe,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Zurücksetzen'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Wärmebedarf
          _buildSliderParameter(
            label: 'Wärmebedarf',
            wert: _eingabe.waermebedarf,
            min: SzenarioRechnerGrenzen.waermebedarfMin,
            max: SzenarioRechnerGrenzen.waermebedarfMax,
            einheit: 'kWh/a',
            nachkommastellen: 0,
            onChanged: (wert) => _updateEingabe(_eingabe.copyWith(waermebedarf: wert)),
          ),

          const Divider(),

          // JAZ
          _buildSliderParameter(
            label: 'Jahresarbeitszahl (JAZ)',
            wert: _eingabe.jahresarbeitszahl ?? SzenarioRechnerGrenzen.jazDefault,
            min: SzenarioRechnerGrenzen.jazMin,
            max: SzenarioRechnerGrenzen.jazMax,
            einheit: '',
            nachkommastellen: 1,
            onChanged: (wert) => _updateEingabe(_eingabe.copyWith(jahresarbeitszahl: wert)),
            helperText: 'Nur für Wärmepumpe',
          ),

          // Strompreis
          _buildSliderParameter(
            label: 'Stromarbeitspreis',
            wert: _eingabe.stromarbeitspreisCtKWh ?? SzenarioRechnerGrenzen.strompreisDefault,
            min: SzenarioRechnerGrenzen.strompreisMin,
            max: SzenarioRechnerGrenzen.strompreisMax,
            einheit: 'ct/kWh',
            nachkommastellen: 2,
            onChanged: (wert) => _updateEingabe(_eingabe.copyWith(stromarbeitspreisCtKWh: wert)),
          ),

          // Strom-Grundpreis
          _buildSliderParameter(
            label: 'Strom-Grundpreis',
            wert: _eingabe.stromGrundpreisEuroMonat ?? SzenarioRechnerGrenzen.stromGrundpreisDefault,
            min: SzenarioRechnerGrenzen.stromGrundpreisMin,
            max: SzenarioRechnerGrenzen.stromGrundpreisMax,
            einheit: '€/Monat',
            nachkommastellen: 2,
            onChanged: (wert) => _updateEingabe(_eingabe.copyWith(stromGrundpreisEuroMonat: wert)),
            helperText: 'Nur für Wärmepumpe',
          ),

          const Divider(),

          // Anteil Wärme aus Strom
          _buildSliderParameter(
            label: 'Anteil Wärme aus Strom',
            wert: (_eingabe.anteilWaermeAusStrom ?? 0.30) * 100,
            min: 0,
            max: 100,
            einheit: '%',
            nachkommastellen: 0,
            onChanged: (wert) => _updateEingabe(_eingabe.copyWith(anteilWaermeAusStrom: wert / 100)),
            helperText: 'Nur für Wärmenetz',
          ),

          const Divider(),
          //
          // // Investitionskosten-Anpassung
          // SwitchListTile(
          //   title: const Text('Eigene Investitionskosten'),
          //   subtitle: const Text('Anpassung der Investitionskosten (±20%)'),
          //   value: _eingabe.eigenInvestitionskostenNutzen,
          //   onChanged: (wert) => _updateEingabe(
          //     _eingabe.copyWith(
          //       eigenInvestitionskostenNutzen: wert,
          //       investitionskostenAnpassungProzent: wert ? 0 : null,
          //     ),
          //   ),
          // ),

          if (_eingabe.eigenInvestitionskostenNutzen) ...[
            const SizedBox(height: 8),
            _buildSliderParameter(
              label: 'Investitionskosten-Anpassung',
              wert: _eingabe.investitionskostenAnpassungProzent ?? 0,
              min: SzenarioRechnerGrenzen.investAnpassungMin,
              max: SzenarioRechnerGrenzen.investAnpassungMax,
              einheit: '%',
              nachkommastellen: 0,
              onChanged: (wert) => _updateEingabe(
                _eingabe.copyWith(investitionskostenAnpassungProzent: wert),
              ),
            ),
          ],

          const Divider(),

          // Förderung
          SwitchListTile(
            title: const Text('Förderung berücksichtigen'),
            subtitle: const Text('BEG/BEW-Förderung in Berechnung einbeziehen'),
            value: _eingabe.foerderungBeruecksichtigen,
            onChanged: (wert) => _updateEingabe(_eingabe.copyWith(foerderungBeruecksichtigen: wert)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderParameter({
    required String label,
    required double wert,
    required double min,
    required double max,
    required String einheit,
    required int nachkommastellen,
    required Function(double) onChanged,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: SuewagTextStyles.bodyMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SuewagColors.fasergruen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${wert.toStringAsFixed(nachkommastellen)} $einheit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SuewagColors.fasergruen,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: wert,
          min: min,
          max: max,
          divisions: ((max - min) / (nachkommastellen == 0 ? 100 : 0.5)).round(),
          activeColor: SuewagColors.fasergruen,
          onChanged: onChanged,
        ),
        if (helperText != null) ...[
          Text(
            helperText,
            style: SuewagTextStyles.caption.copyWith(
              color: SuewagColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildChartCard() {
    if (_ergebnis == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.bar_chart, color: SuewagColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ihr Ergebnis',
                style: SuewagTextStyles.headline4.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: KostenvergleichChartWidget(
              ergebnisse: _ergebnis!.szenarien,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErgebnisTabelle() {
    if (_ergebnis == null) return const SizedBox.shrink();

    final sortiert = _ergebnis!.szenarienSortiertNachPreis;
    final guenstigste = sortiert.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Günstigstes Highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.green, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günstigstes für Ihre Parameter:',
                        style: SuewagTextStyles.caption,
                      ),
                      Text(
                        guenstigste.szenarioBezeichnung,
                        style: SuewagTextStyles.headline4.copyWith(color: Colors.green),
                      ),
                      Text(
                        '${guenstigste.waermevollkostenpreisNetto.toStringAsFixed(2)} €/MWh',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tabelle
          ...sortiert.map((e) {
            final istGuenstigste = e.szenarioId == guenstigste.szenarioId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: istGuenstigste ? Colors.green.withOpacity(0.05) : null,
                border: Border.all(
                  color: istGuenstigste ? Colors.green : SuewagColors.divider,
                  width: istGuenstigste ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      e.szenarioBezeichnung,
                      style: SuewagTextStyles.bodyMedium.copyWith(
                        fontWeight: istGuenstigste ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${e.waermevollkostenpreisNetto.toStringAsFixed(2)} €/MWh',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: istGuenstigste ? Colors.green : SuewagColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${e.jahreskosten.toStringAsFixed(2)} €/a',
                        style: SuewagTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}