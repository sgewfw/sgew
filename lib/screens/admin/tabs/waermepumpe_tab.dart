// lib/screens/admin/tabs/waermepumpe_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/suewag_colors.dart';
import '../../../models/kostenvergleich_data.dart';

class WaermepumpeTab extends StatelessWidget {
  final KostenvergleichJahr stammdaten;
  final Function(KostenvergleichJahr) onChanged;

  const WaermepumpeTab({
    Key? key,
    required this.stammdaten,
    required this.onChanged,
  }) : super(key: key);

  SzenarioStammdaten get _szenario => stammdaten.szenarien['waermepumpe']!;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Block 1: INVESTITION
          _buildSection(
            title: 'Investitionskosten',
            icon: Icons.euro,
            children: [
              if (_szenario.investition.waermepumpe != null)
                _buildInvestitionsPosition(
                  position: _szenario.investition.waermepumpe!,
                  onChanged: (neuePosition) {
                    _updateInvestitionsPosition('waermepumpe', neuePosition);
                  },
                ),
              const SizedBox(height: 16),

              if (_szenario.investition.twwSpeicher != null)
                _buildInvestitionsPosition(
                  position: _szenario.investition.twwSpeicher!,
                  onChanged: (neuePosition) {
                    _updateInvestitionsPosition('twwSpeicher', neuePosition);
                  },
                ),
              const SizedBox(height: 16),

              if (_szenario.investition.zaehlerschrank != null)
                _buildInvestitionsPosition(
                  position: _szenario.investition.zaehlerschrank!,
                  onChanged: (neuePosition) {
                    _updateInvestitionsPosition('zaehlerschrank', neuePosition);
                  },
                ),
              const SizedBox(height: 16),

              const Divider(),
              _buildInvestitionsSumme(),
            ],
          ),

          const SizedBox(height: 20),

          // Block 2: WÄRMEKOSTEN
          _buildSection(
            title: 'Wärmekosten',
            icon: Icons.payments,
            children: [
              if (_szenario.waermekosten.jahresarbeitszahl != null)
                _buildNumberFieldMitQuelle(
                  label: 'JAZ',
                  wertMitQuelle: _szenario.waermekosten.jahresarbeitszahl!,
                  nachkommastellen: 2,
                  onChanged: (neuerWert) {
                    final neueWaermekosten = _szenario.waermekosten.copyWith(
                      jahresarbeitszahl: neuerWert,
                      stromverbrauchKWh: WertMitQuelle(
                        wert: stammdaten.grunddaten.heizenergiebedarf.wert / neuerWert.wert,
                        quelle: _szenario.waermekosten.stromverbrauchKWh?.quelle ??
                            QuellenInfo(titel: 'Stromverbrauch', beschreibung: 'Berechnet'),
                      ),
                    );
                    _updateWaermekosten(neueWaermekosten);
                  },
                ),
              const SizedBox(height: 16),

              if (_szenario.waermekosten.stromverbrauchKWh != null)
                _buildReadOnlyFieldMitQuelle(
                  label: 'Verbrauch',
                  einheit: 'kWh/a',
                  wertMitQuelle: _szenario.waermekosten.stromverbrauchKWh!,
                ),
              const SizedBox(height: 16),

              if (_szenario.waermekosten.stromarbeitspreisCtKWh != null)
                _buildNumberFieldMitQuelle(
                  label: 'AP Strom',
                  einheit: 'ct/kWh',
                  wertMitQuelle: _szenario.waermekosten.stromarbeitspreisCtKWh!,
                  onChanged: (neuerWert) {
                    _updateWaermekosten(
                      _szenario.waermekosten.copyWith(stromarbeitspreisCtKWh: neuerWert),
                    );
                  },
                ),
              const SizedBox(height: 16),

              if (_szenario.waermekosten.stromGrundpreisEuroMonat != null)
                _buildNumberFieldMitQuelle(
                  label: 'GP Strom',
                  einheit: '€/Monat',
                  wertMitQuelle: _szenario.waermekosten.stromGrundpreisEuroMonat!,
                  onChanged: (neuerWert) {
                    _updateWaermekosten(
                      _szenario.waermekosten.copyWith(stromGrundpreisEuroMonat: neuerWert),
                    );
                  },
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Block 3: NEBENKOSTEN
          _buildSection(
            title: 'Nebenkosten',
            icon: Icons.build,
            children: [
              if (_szenario.nebenkosten.wartungEuroJahr != null)
                _buildNumberFieldMitQuelle(
                  label: 'Wartung',
                  einheit: '€/Jahr',
                  wertMitQuelle: _szenario.nebenkosten.wartungEuroJahr!,
                  nachkommastellen: 0,
                  onChanged: (neuerWert) {
                    _updateNebenkosten(
                      NebenkostenDaten(wartungEuroJahr: neuerWert),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: SuewagColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInvestitionsPosition({
    required InvestitionsPosition position,
    required Function(InvestitionsPosition) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bezeichnung mit Edit-Button
        Row(
          children: [
            Expanded(
              child: Text(
                position.bezeichnung,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Builder(
              builder: (context) => InkWell(
                onTap: () => _zeigePositionBearbeitenDialog(context, position, onChanged),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SuewagColors.verkehrsorange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 18,
                    color: SuewagColors.verkehrsorange,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildNumberFieldMitQuelle(
          label: 'Betrag',
          einheit: '€',
          wertMitQuelle: position.betrag,
          nachkommastellen: 0,
          onChanged: (neuerWert) {
            onChanged(InvestitionsPosition(
              bezeichnung: position.bezeichnung,
              betrag: neuerWert,
              bemerkung: position.bemerkung,
            ));
          },
        ),
      ],
    );
  }

// Dialog zum Bearbeiten der Position (Bezeichnung + Quelle)
  void _zeigePositionBearbeitenDialog(
      BuildContext context,
      InvestitionsPosition position,
      Function(InvestitionsPosition) onChanged,
      ) {
    final bezeichnungController = TextEditingController(text: position.bezeichnung);
    final titelController = TextEditingController(text: position.betrag.quelle.titel);
    final beschreibungController = TextEditingController(text: position.betrag.quelle.beschreibung);
    final linkController = TextEditingController(text: position.betrag.quelle.link ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Position bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bezeichnung',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bezeichnungController,
                decoration: const InputDecoration(
                  labelText: 'Bezeichnung der Position',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quelle für den Betrag',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titelController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: beschreibungController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final neueQuelle = QuellenInfo(
                titel: titelController.text,
                beschreibung: beschreibungController.text,
                link: linkController.text.isEmpty ? null : linkController.text,
              );

              onChanged(InvestitionsPosition(
                bezeichnung: bezeichnungController.text,
                betrag: WertMitQuelle(
                  wert: position.betrag.wert,
                  quelle: neueQuelle,
                ),
                bemerkung: position.bemerkung,
              ));
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

// Dialog zum Bearbeiten der Bezeichnung
  void _zeigeBezeichnungBearbeitenDialog(
      BuildContext context,
      InvestitionsPosition position,
      Function(InvestitionsPosition) onChanged,
      ) {
    final controller = TextEditingController(text: position.bezeichnung);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bezeichnung bearbeiten'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Bezeichnung',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(InvestitionsPosition(
                bezeichnung: controller.text,
                betrag: position.betrag,
                bemerkung: position.bemerkung,
              ));
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestitionsSumme() {
    final gesamtBrutto = _berechneGesamtBrutto();
    final foerderquote = stammdaten.finanzierung.foerderungBEG.wert;
    final foerderbetrag = gesamtBrutto * foerderquote;
    final netto = gesamtBrutto - foerderbetrag;

    return Column(
      children: [
        _buildSummenZeile('Gesamt brutto:', gesamtBrutto),
        _buildSummenZeile(
          'Förderung (${(foerderquote * 100).toStringAsFixed(0)}%):',
          -foerderbetrag,
          color: Colors.red,
        ),
        const Divider(height: 12),
        _buildSummenZeile(
          'Netto nach Förderung:',
          netto,
          istGesamt: true,
        ),
      ],
    );
  }

  double _berechneGesamtBrutto() {
    double summe = 0;
    if (_szenario.investition.waermepumpe != null) {
      summe += _szenario.investition.waermepumpe!.betrag.wert;
    }
    if (_szenario.investition.twwSpeicher != null) {
      summe += _szenario.investition.twwSpeicher!.betrag.wert;
    }
    if (_szenario.investition.zaehlerschrank != null) {
      summe += _szenario.investition.zaehlerschrank!.betrag.wert;
    }
    return summe;
  }

  Widget _buildSummenZeile(String label, double betrag,
      {Color? color, bool istGesamt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: istGesamt ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${betrag.toStringAsFixed(0)} €',
            style: TextStyle(
              fontWeight: istGesamt ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _updateInvestitionsPosition(String key, InvestitionsPosition neuePosition) {
    final gesamtBrutto = _berechneNeuenGesamtBrutto(key, neuePosition);
    final foerderquote = stammdaten.finanzierung.foerderungBEG.wert;
    final foerderbetrag = gesamtBrutto * foerderquote;
    final netto = gesamtBrutto - foerderbetrag;

    InvestitionskostenDaten neueInvestition;

    switch (key) {
      case 'waermepumpe':
        neueInvestition = InvestitionskostenDaten(
          waermepumpe: neuePosition,
          twwSpeicher: _szenario.investition.twwSpeicher,
          hydraulik: _szenario.investition.hydraulik,
          zaehlerschrank: _szenario.investition.zaehlerschrank,
          gesamtBrutto: gesamtBrutto,
          foerderungsTyp: FoerderungsTyp.beg,
          foerderquote: foerderquote,
          foerderbetrag: foerderbetrag,
          nettoNachFoerderung: netto,
        );
        break;
      case 'twwSpeicher':
        neueInvestition = InvestitionskostenDaten(
          waermepumpe: _szenario.investition.waermepumpe,
          twwSpeicher: neuePosition,
          hydraulik: _szenario.investition.hydraulik,
          zaehlerschrank: _szenario.investition.zaehlerschrank,
          gesamtBrutto: gesamtBrutto,
          foerderungsTyp: FoerderungsTyp.beg,
          foerderquote: foerderquote,
          foerderbetrag: foerderbetrag,
          nettoNachFoerderung: netto,
        );
        break;
      case 'zaehlerschrank':
        neueInvestition = InvestitionskostenDaten(
          waermepumpe: _szenario.investition.waermepumpe,
          twwSpeicher: _szenario.investition.twwSpeicher,
          hydraulik: _szenario.investition.hydraulik,
          zaehlerschrank: neuePosition,
          gesamtBrutto: gesamtBrutto,
          foerderungsTyp: FoerderungsTyp.beg,
          foerderquote: foerderquote,
          foerderbetrag: foerderbetrag,
          nettoNachFoerderung: netto,
        );
        break;
      default:
        return;
    }

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

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien['waermepumpe'] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  double _berechneNeuenGesamtBrutto(String key, InvestitionsPosition neuePosition) {
    double summe = 0;

    if (key == 'waermepumpe') {
      summe += neuePosition.betrag.wert;
    } else if (_szenario.investition.waermepumpe != null) {
      summe += _szenario.investition.waermepumpe!.betrag.wert;
    }

    if (key == 'twwSpeicher') {
      summe += neuePosition.betrag.wert;
    } else if (_szenario.investition.twwSpeicher != null) {
      summe += _szenario.investition.twwSpeicher!.betrag.wert;
    }

    if (key == 'zaehlerschrank') {
      summe += neuePosition.betrag.wert;
    } else if (_szenario.investition.zaehlerschrank != null) {
      summe += _szenario.investition.zaehlerschrank!.betrag.wert;
    }

    return summe;
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

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien['waermepumpe'] = neuesSzenario;

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

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien['waermepumpe'] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  // Zahlenfeld mit Quelle
  Widget _buildNumberFieldMitQuelle({
    required String label,
    required WertMitQuelle<double> wertMitQuelle,
    required Function(WertMitQuelle<double>) onChanged,
    String? einheit,
    int nachkommastellen = 2,
  }) {
    final controller = TextEditingController(
      text: wertMitQuelle.wert.toStringAsFixed(nachkommastellen),
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 14),
              suffixText: einheit,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onChanged: (text) {
              final parsed = double.tryParse(text);
              if (parsed != null) {
                onChanged(WertMitQuelle(
                  wert: parsed,
                  quelle: wertMitQuelle.quelle,
                ));
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        _buildInfoButton(wertMitQuelle.quelle),
        const SizedBox(width: 8),
        _buildEditQuelleButton(
          quelle: wertMitQuelle.quelle,
          onQuelleChanged: (neueQuelle) {
            onChanged(WertMitQuelle(
              wert: wertMitQuelle.wert,
              quelle: neueQuelle,
            ));
          },
        ),
      ],
    );
  }

  // Read-Only Feld mit Quelle
  Widget _buildReadOnlyFieldMitQuelle({
    required String label,
    required String einheit,
    required WertMitQuelle<double> wertMitQuelle,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: TextEditingController(
              text: wertMitQuelle.wert.toStringAsFixed(0),
            ),
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 14),
              suffixText: einheit,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              filled: true,
              fillColor: SuewagColors.background,
            ),
            enabled: false,
          ),
        ),
        const SizedBox(width: 8),
        _buildInfoButton(wertMitQuelle.quelle),
        const SizedBox(width: 8),
        const SizedBox(width: 32), // Platzhalter für Edit-Button
      ],
    );
  }

  // Info-Button (zeigt Quelle an)
  Widget _buildInfoButton(QuellenInfo quelle) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => _zeigeQuellenDialog(context, quelle),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: SuewagColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: SuewagColors.primary,
          ),
        ),
      ),
    );
  }

  // Edit-Button (bearbeitet Quelle)
  Widget _buildEditQuelleButton({
    required QuellenInfo quelle,
    required Function(QuellenInfo) onQuelleChanged,
  }) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => _zeigeQuelleBearbeitenDialog(context, quelle, onQuelleChanged),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: SuewagColors.verkehrsorange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.edit,
            size: 18,
            color: SuewagColors.verkehrsorange,
          ),
        ),
      ),
    );
  }

  // Dialog: Quelle anzeigen
  void _zeigeQuellenDialog(BuildContext context, QuellenInfo quelle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quelle.titel),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quelle.beschreibung),
              if (quelle.link != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    // Link öffnen (url_launcher)
                  },
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 16, color: SuewagColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          quelle.link!,
                          style: TextStyle(
                            color: SuewagColors.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  // Dialog: Quelle bearbeiten
  void _zeigeQuelleBearbeitenDialog(
      BuildContext context,
      QuellenInfo quelle,
      Function(QuellenInfo) onQuelleChanged,
      ) {
    final titelController = TextEditingController(text: quelle.titel);
    final beschreibungController = TextEditingController(text: quelle.beschreibung);
    final linkController = TextEditingController(text: quelle.link ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quelle bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titelController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: beschreibungController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final neueQuelle = QuellenInfo(
                titel: titelController.text,
                beschreibung: beschreibungController.text,
                link: linkController.text.isEmpty ? null : linkController.text,
              );
              onQuelleChanged(neueQuelle);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}