// lib/screens/admin/tabs/waermenetz_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../../../models/kostenvergleich_data.dart';

class WaermenetzTab extends StatelessWidget {
  final String szenarioId;
  final KostenvergleichJahr stammdaten;
  final Function(KostenvergleichJahr) onChanged;

  const WaermenetzTab({
    Key? key,
    required this.szenarioId,
    required this.stammdaten,
    required this.onChanged,
  }) : super(key: key);

  SzenarioStammdaten get _szenario => stammdaten.szenarien[szenarioId]!;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Investitionskosten',
                icon: Icons.euro,
                children: [
                  _buildInvestitionsGesamtInfo(),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Wärmekosten (laufend)',
                icon: Icons.payments,
                children: [
                  _buildNumberField(
                    label: 'Wärmearbeitspreis Gas',
                    einheit: 'ct/kWh',
                    wert: _szenario.waermekosten.waermeGasArbeitspreisCtKWh ?? 11.68,
                    onChanged: (wert) => _updateWaermekosten(
                      _szenario.waermekosten.copyWith(waermeGasArbeitspreisCtKWh: wert),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Wärmearbeitspreis Strom',
                    einheit: 'ct/kWh',
                    wert: _szenario.waermekosten.waermeStromArbeitspreisCtKWh ?? 8.52,
                    onChanged: (wert) => _updateWaermekosten(
                      _szenario.waermekosten.copyWith(waermeStromArbeitspreisCtKWh: wert),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Grundpreis "o. Wärme"',
                    einheit: '€/Jahr',
                    wert: _szenario.waermekosten.waermeGrundpreisEuroJahr ?? 471.0,
                    nachkommastellen: 0,
                    onChanged: (wert) => _updateWaermekosten(
                      _szenario.waermekosten.copyWith(waermeGrundpreisEuroJahr: wert),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Messpreis',
                    einheit: '€/Jahr',
                    wert: _szenario.waermekosten.waermeMesspreisEuroJahr ?? 109.55,
                    nachkommastellen: 2,
                    onChanged: (wert) => _updateWaermekosten(
                      _szenario.waermekosten.copyWith(waermeMesspreisEuroJahr: wert),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Nebenkosten (laufend)',
                icon: Icons.build,
                children: [
                  _buildNumberField(
                    label: 'Wartung & Instandhaltung',
                    einheit: '€/Jahr',
                    wert: _szenario.nebenkosten.wartungEuroJahr ?? 50.0,
                    nachkommastellen: 0,
                    onChanged: (wert) => _updateNebenkosten(
                      NebenkostenDaten(
                        wartungEuroJahr: wert,
                        grundpreisUebergabestationEuroJahr:
                        _szenario.nebenkosten.grundpreisUebergabestationEuroJahr,
                      ),
                    ),
                  ),
                  if (szenarioId == 'waermenetzSuewag') ...[
                    const SizedBox(height: 16),
                    _buildNumberField(
                      label: 'Zusätzlicher Grundpreis Übergabestation',
                      einheit: '€/Jahr',
                      wert: _szenario.nebenkosten.grundpreisUebergabestationEuroJahr ?? 150.0,
                      nachkommastellen: 0,
                      onChanged: (wert) => _updateNebenkosten(
                        NebenkostenDaten(
                          wartungEuroJahr: _szenario.nebenkosten.wartungEuroJahr,
                          grundpreisUebergabestationEuroJahr: wert,
                        ),
                      ),
                      helperText: 'Nur bei Süwag-Station',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvestitionsGesamtInfo() {
    final foerderquote = szenarioId == 'waermenetzKunde'
        ? stammdaten.finanzierung.foerderungBEG
        : szenarioId == 'waermenetzSuewag'
        ? stammdaten.finanzierung.foerderungBEW
        : 0.0;

    final gesamtBrutto = _szenario.investition.gesamtBrutto;
    final foerderbetrag = gesamtBrutto * foerderquote;
    final netto = gesamtBrutto - foerderbetrag;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuewagColors.fasergruen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SuewagColors.fasergruen),
      ),
      child: Column(
        children: [
          _buildBetragInput(
            label: 'Investition brutto',
            wert: gesamtBrutto,
            onChanged: (wert) => _updateInvestition(wert),
          ),
          const SizedBox(height: 12),
          _buildSummenZeile(
            'Förderung ${_foerderTypLabel()} (${(foerderquote * 100).toStringAsFixed(0)}%):',
            -foerderbetrag,
            color: Colors.green,
          ),
          const Divider(),
          _buildSummenZeile(
            'Investition netto:',
            netto,
            istGesamt: true,
          ),
        ],
      ),
    );
  }

  String _foerderTypLabel() {
    if (szenarioId == 'waermenetzKunde') return 'BEG';
    if (szenarioId == 'waermenetzSuewag') return 'BEW';
    return '';
  }

  Widget _buildBetragInput({
    required String label,
    required double wert,
    required Function(double) onChanged,
  }) {
    final controller = TextEditingController(
      text: wert.toStringAsFixed(0),
    );

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: '€',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }

  Widget _buildSummenZeile(String label, double betrag,
      {Color? color, bool istGesamt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: istGesamt
                ? SuewagTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.bold)
                : SuewagTextStyles.bodyMedium,
          ),
          Text(
            '${betrag.toStringAsFixed(0)} €',
            style: TextStyle(
              fontWeight: istGesamt ? FontWeight.bold : FontWeight.normal,
              fontSize: istGesamt ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _updateInvestition(double gesamtBrutto) {
    final foerderquote = szenarioId == 'waermenetzKunde'
        ? stammdaten.finanzierung.foerderungBEG
        : szenarioId == 'waermenetzSuewag'
        ? stammdaten.finanzierung.foerderungBEW
        : 0.0;

    final foerderbetrag = gesamtBrutto * foerderquote;
    final netto = gesamtBrutto - foerderbetrag;

    final foerderungsTyp = szenarioId == 'waermenetzKunde'
        ? FoerderungsTyp.beg
        : szenarioId == 'waermenetzSuewag'
        ? FoerderungsTyp.bew
        : FoerderungsTyp.keine;

    final neueInvestition = InvestitionskostenDaten(
      positionen: _szenario.investition.positionen,
      gesamtBrutto: gesamtBrutto,
      foerderungsTyp: foerderungsTyp,
      foerderquote: foerderquote,
      foerderbetrag: foerderbetrag,
      nettoNachFoerderung: netto,
    );

    final neuesSzenario = SzenarioStammdaten(
      id: _szenario.id,
      bezeichnung: _szenario.bezeichnung,
      beschreibung: _szenario.beschreibung,
      typ: _szenario.typ,
      sortierung: _szenario.sortierung,
      investition: neueInvestition,
      waermekosten: _szenario.waermekosten,
      nebenkosten: _szenario.nebenkosten,
    );

    final neueSzenarien =
    Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien[szenarioId] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  void _updateWaermekosten(WaermekostenDaten neueWaermekosten) {
    final neuesSzenario = SzenarioStammdaten(
      id: _szenario.id,
      bezeichnung: _szenario.bezeichnung,
      beschreibung: _szenario.beschreibung,
      typ: _szenario.typ,
      sortierung: _szenario.sortierung,
      investition: _szenario.investition,
      waermekosten: neueWaermekosten,
      nebenkosten: _szenario.nebenkosten,
    );

    final neueSzenarien =
    Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien[szenarioId] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  void _updateNebenkosten(NebenkostenDaten neueNebenkosten) {
    final neuesSzenario = SzenarioStammdaten(
      id: _szenario.id,
      bezeichnung: _szenario.bezeichnung,
      beschreibung: _szenario.beschreibung,
      typ: _szenario.typ,
      sortierung: _szenario.sortierung,
      investition: _szenario.investition,
      waermekosten: _szenario.waermekosten,
      nebenkosten: neueNebenkosten,
    );

    final neueSzenarien =
    Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien[szenarioId] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
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
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required double wert,
    required Function(double) onChanged,
    String? einheit,
    int nachkommastellen = 2,
    String? helperText,
  }) {
    final controller = TextEditingController(
      text: wert.toStringAsFixed(nachkommastellen),
    );

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: einheit,
        helperText: helperText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }
}