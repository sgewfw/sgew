// lib/widgets/kostenvergleich_detail_table_mobile.dart

import 'package:flutter/material.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/kostenvergleich_data.dart';
import '../models/kostenvergleich_ergebnis.dart';

class KostenvergleichDetailTableMobile extends StatefulWidget {
  final KostenvergleichJahr stammdaten;
  final List<KostenberechnungErgebnis> ergebnisse;

  const KostenvergleichDetailTableMobile({
    Key? key,
    required this.stammdaten,
    required this.ergebnisse,
  }) : super(key: key);

  @override
  State<KostenvergleichDetailTableMobile> createState() => _KostenvergleichDetailTableMobileState();
}

class _KostenvergleichDetailTableMobileState extends State<KostenvergleichDetailTableMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.ergebnisse.length, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SuewagColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jahreskostenvergleich',
                style: SuewagTextStyles.headline4,
              ),
              const SizedBox(height: 4),
              Text(
                'Wärmekosten Einfamilienhaus Bestand',
                style: SuewagTextStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Stand: ${_formatiereDatum()} - Kostenvergleich auf Basis folgender Kennzahlen des Vorjahres',
                style: SuewagTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabs für Szenarien
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SuewagColors.divider),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: SuewagColors.fasergruen,
            indicatorWeight: 3,
            labelColor: SuewagColors.quartzgrau100,
            unselectedLabelColor: SuewagColors.quartzgrau50,
            labelStyle: SuewagTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: SuewagTextStyles.bodySmall.copyWith(
              fontSize: 12,
            ),
            tabs: widget.ergebnisse.map((e) {
              return Tab(
                text: _getSzenarioKurz(e.szenarioBezeichnung),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // PageView mit Szenarien
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _tabController.animateTo(index);
            },
            itemCount: widget.ergebnisse.length,
            itemBuilder: (context, index) {
              return _buildSzenarioDetail(widget.ergebnisse[index]);
            },
          ),
        ),
      ],
    );
  }
  String _formatiereDatum() {
    final jahr = widget.stammdaten.jahr;
    return 'Jahr $jahr';
  }
  String _getSzenarioKurz(String bezeichnung) {
    if (bezeichnung.contains('Wärmepumpe')) return 'Wärmepumpe';
    if (bezeichnung.contains('ohne')) return 'Netz ohne ÜGS';
    if (bezeichnung.contains('Kunde')) return 'Netz Kunde';
    if (bezeichnung.contains('Süwag')) return 'Netz Süwag';
    return bezeichnung;
  }

  Widget _buildSzenarioDetail(KostenberechnungErgebnis ergebnis) {
    final szenario = widget.stammdaten.szenarien.values.firstWhere(
          (s) => s.id == ergebnis.szenarioId,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Szenario-Info
        _buildInfoCard(szenario),
        const SizedBox(height: 12),

        // A. Grunddaten
        _buildAbschnittCard(
          'A',
          'Grunddaten',
          [
            _buildWertZeile(
              'Beheizte Fläche',
              widget.stammdaten.grunddaten.beheizteFlaeche.wert,
              'm²',
              2,
              widget.stammdaten.grunddaten.beheizteFlaeche.quelle,
            ),
            _buildWertZeile(
              'Spez. Heizenergiebedarf',
              widget.stammdaten.grunddaten.spezHeizenergiebedarf.wert,
              'kWh/m²a',
              0,
              widget.stammdaten.grunddaten.spezHeizenergiebedarf.quelle,
            ),
            _buildWertZeile(
              'Heizenergiebedarf',
              widget.stammdaten.grunddaten.heizenergiebedarf.wert,
              'kWh/a',
              0,
              widget.stammdaten.grunddaten.heizenergiebedarf.quelle,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // B. Investitionskosten
        _buildAbschnittCard(
          'B',
          'Investitionskosten',
          _buildInvestitionskostenZeilen(szenario),
        ),
        const SizedBox(height: 12),

        // C. Wärmekosten
        _buildAbschnittCard(
          'C',
          'Wärmekosten (laufend)',
          _buildWaermekostenZeilen(szenario, ergebnis),
        ),
        const SizedBox(height: 12),

        // D. Nebenkosten
        _buildAbschnittCard(
          'D',
          'Nebenkosten (laufend)',
          _buildNebenkostenZeilen(szenario, ergebnis),
        ),
        const SizedBox(height: 12),

        // E. Jahreskosten
        _buildAbschnittCard(
          'E',
          'Jahreskosten',
          [
            _buildWertZeile(
              'Wärmevollkostenpreis netto',
              ergebnis.waermevollkostenpreisNetto,
              '€/MWh',
              2,
              QuellenInfo(
                titel: 'Vollkostenpreis netto',
                beschreibung: 'Jahreskosten / Wärmebedarf × 1000',
              ),
              isBold: true,
              farbe: SuewagColors.indiablau,
            ),
            _buildWertZeile(
              'Wärmevollkostenpreis brutto',
              ergebnis.waermevollkostenpreisBrutto,
              '€/MWh',
              2,
              QuellenInfo(
                titel: 'Vollkostenpreis brutto',
                beschreibung: 'Inkl. 19% MwSt.',
              ),
            ),
            const Divider(),
            _buildWertZeile(
              'Jahreskosten netto',
              ergebnis.jahreskosten,
              '€/a',
              2,
              QuellenInfo(
                titel: 'Jahreskosten netto',
                beschreibung: 'Wärme- + Nebenkosten',
              ),
              isBold: true,
              farbe: SuewagColors.verkehrsorange,
            ),
            _buildWertZeile(
              'Jahreskosten brutto',
              ergebnis.jahreskosten_brutto,
              '€/a',
              2,
              QuellenInfo(
                titel: 'Jahreskosten brutto',
                beschreibung: 'Inkl. 19% MwSt.',
              ),
            ),
            _buildWertZeile(
              'Kosten pro m²',
              ergebnis.kostenProQuadratmeter * 1.19,
              '€/m²',
              2,
              QuellenInfo(
                titel: 'Kosten pro m²',
                beschreibung: 'Jahreskosten brutto / Fläche',
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildInvestitionskostenZeilen(SzenarioStammdaten szenario) {
    final zeilen = <Widget>[];

    // Wärmepumpe
    if (szenario.investition.waermepumpe != null) {
      zeilen.add(_buildWertZeile(
        szenario.investition.waermepumpe!.bezeichnung,
        szenario.investition.waermepumpe!.betrag.wert,
        '€',
        0,
        szenario.investition.waermepumpe!.betrag.quelle,
      ));
    }

    // Übergabestation
    if (szenario.investition.uebergabestation != null) {
      zeilen.add(_buildWertZeile(
        szenario.investition.uebergabestation!.bezeichnung,
        szenario.investition.uebergabestation!.betrag.wert,
        '€',
        0,
        szenario.investition.uebergabestation!.betrag.quelle,
      ));
    }

    // TWW-Speicher
    if (szenario.investition.twwSpeicher != null) {
      zeilen.add(_buildWertZeile(
        szenario.investition.twwSpeicher!.bezeichnung,
        szenario.investition.twwSpeicher!.betrag.wert,
        '€',
        0,
        szenario.investition.twwSpeicher!.betrag.quelle,
      ));
    }

    // Heizlastberechnung
    if (szenario.investition.heizlastberechnung != null) {
      zeilen.add(_buildWertZeile(
        szenario.investition.heizlastberechnung!.bezeichnung,
        szenario.investition.heizlastberechnung!.betrag.wert,
        '€',
        0,
        szenario.investition.heizlastberechnung!.betrag.quelle,
      ));
    }

    // Zählerschrank
    if (szenario.investition.zaehlerschrank != null) {
      zeilen.add(_buildWertZeile(
        szenario.investition.zaehlerschrank!.bezeichnung,
        szenario.investition.zaehlerschrank!.betrag.wert,
        '€',
        0,
        szenario.investition.zaehlerschrank!.betrag.quelle,
      ));
    }

    // BKZ
    if (szenario.investition.bkz != null) {
      zeilen.add(_buildWertZeile(
        szenario.investition.bkz!.bezeichnung,
        szenario.investition.bkz!.betrag.wert,
        '€',
        0,
        szenario.investition.bkz!.betrag.quelle,
      ));
    }

    // Förderung
    if (szenario.investition.foerderbetrag > 0) {
      zeilen.add(_buildWertZeile(
        'Förderung ${szenario.investition.foerderungsTyp == FoerderungsTyp.beg ? "BEG" : "BEW"}',
        -szenario.investition.foerderbetrag,
        '€',
        2,
        QuellenInfo(
          titel: 'Förderung',
          beschreibung: '${(szenario.investition.foerderquote * 100).toInt()}% Förderung',
          link: 'https://www.energiewechsel.de/KAENEF/Redaktion/DE/FAQ/FAQ-Uebersicht/Richtlinien/bundesfoerderung-fuer-effiziente-gebaeude-beg.html',
        ),
        farbe: Colors.red,
      ));
    }

    zeilen.add(const Divider());

    // Gesamt
    zeilen.add(_buildWertZeile(
      'Gesamt inkl. Förderung',
      szenario.investition.nettoNachFoerderung,
      '€',
      2,
      QuellenInfo(
        titel: 'Investition mit Förderung',
        beschreibung: 'Nach Abzug der Förderung',
      ),
      isBold: true,
      farbe: SuewagColors.fasergruen,
    ));

    return zeilen;
  }

  List<Widget> _buildWaermekostenZeilen(
      SzenarioStammdaten szenario,
      KostenberechnungErgebnis ergebnis,
      ) {
    final zeilen = <Widget>[];

    if (szenario.id == 'waermepumpe') {
      // Wärmepumpe
      if (szenario.waermekosten.stromverbrauchKWh != null) {
        zeilen.add(_buildWertZeile(
          'Stromverbrauch',
          szenario.waermekosten.stromverbrauchKWh!.wert,
          'kWh/a',
          0,
          szenario.waermekosten.stromverbrauchKWh!.quelle,
        ));
      }

      if (szenario.waermekosten.stromarbeitspreisCtKWh != null) {
        zeilen.add(_buildWertZeile(
          'Arbeitspreis Strom',
          szenario.waermekosten.stromarbeitspreisCtKWh!.wert,
          'ct/kWh',
          2,
          szenario.waermekosten.stromarbeitspreisCtKWh!.quelle,
        ));
      }

      if (szenario.waermekosten.stromGrundpreisEuroMonat != null) {
        zeilen.add(_buildWertZeile(
          'Grundpreis Strom',
          szenario.waermekosten.stromGrundpreisEuroMonat!.wert * 12,
          '€/a',
          0,
          szenario.waermekosten.stromGrundpreisEuroMonat!.quelle,
        ));
      }
    } else {
      // Wärmenetz
      if (szenario.waermekosten.waermeVerbrauchGasKWh != null) {
        zeilen.add(_buildWertZeile(
          'Wärme aus Gas',
          szenario.waermekosten.waermeVerbrauchGasKWh!.wert,
          'kWh/a',
          0,
          szenario.waermekosten.waermeVerbrauchGasKWh!.quelle,
        ));
      }

      if (szenario.waermekosten.waermeVerbrauchStromKWh != null) {
        zeilen.add(_buildWertZeile(
          'Wärme aus Strom',
          szenario.waermekosten.waermeVerbrauchStromKWh!.wert,
          'kWh/a',
          0,
          szenario.waermekosten.waermeVerbrauchStromKWh!.quelle,
        ));
      }

      if (szenario.waermekosten.waermeGasArbeitspreisCtKWh != null) {
        zeilen.add(_buildWertZeile(
          'Arbeitspreis Gas',
          szenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
          'ct/kWh',
          2,
          szenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
        ));
      }

      if (szenario.waermekosten.waermeStromArbeitspreisCtKWh != null) {
        zeilen.add(_buildWertZeile(
          'Arbeitspreis Strom',
          szenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
          'ct/kWh',
          2,
          szenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
        ));
      }

      if (szenario.waermekosten.waermeGrundpreisEuroJahr != null) {
        zeilen.add(_buildWertZeile(
          'Grundpreis Wärme',
          szenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
          '€/a',
          0,
          szenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
        ));
      }

      if (szenario.waermekosten.waermeMesspreisEuroJahr != null &&
          szenario.waermekosten.waermeMesspreisEuroJahr!.wert > 0) {
        zeilen.add(_buildWertZeile(
          'Messpreis',
          szenario.waermekosten.waermeMesspreisEuroJahr!.wert,
          '€/a',
          2,
          szenario.waermekosten.waermeMesspreisEuroJahr!.quelle,
        ));
      }
    }

    zeilen.add(const Divider());

    zeilen.add(_buildWertZeile(
      'Summe Wärmekosten',
      ergebnis.kosten.arbeitspreis + ergebnis.kosten.grundUndMesspreis,
      '€/a',
      2,
      QuellenInfo(
        titel: 'Summe Wärmekosten',
        beschreibung: 'Arbeits- + Grund- + Messpreis',
      ),
      isBold: true,
      farbe: SuewagColors.fasergruen,
    ));

    return zeilen;
  }

  List<Widget> _buildNebenkostenZeilen(
      SzenarioStammdaten szenario,
      KostenberechnungErgebnis ergebnis,
      ) {
    final zeilen = <Widget>[];

    if (szenario.nebenkosten.wartungEuroJahr != null &&
        szenario.nebenkosten.wartungEuroJahr!.wert > 0) {
      zeilen.add(_buildWertZeile(
        'Wartung & Instandhaltung',
        szenario.nebenkosten.wartungEuroJahr!.wert,
        '€/a',
        2,
        szenario.nebenkosten.wartungEuroJahr!.quelle,
      ));
    }

    if (szenario.nebenkosten.grundpreisUebergabestationEuroJahr != null &&
        szenario.nebenkosten.grundpreisUebergabestationEuroJahr!.wert > 0) {
      zeilen.add(_buildWertZeile(
        'Zusätzl. Grundpreis ÜGS',
        szenario.nebenkosten.grundpreisUebergabestationEuroJahr!.wert,
        '€/a',
        2,
        szenario.nebenkosten.grundpreisUebergabestationEuroJahr!.quelle,
      ));
    }

    zeilen.add(_buildWertZeile(
      'Kapitaldienst',
      ergebnis.kosten.kapitalkosten,
      '€/a',
      2,
      QuellenInfo(
        titel: 'Kapitaldienst',
        beschreibung: 'Annuitätenmethode, Zinssatz ${widget.stammdaten.finanzierung.zinssatz.wert.toStringAsFixed(2).replaceAll('.', ',')}%',
        link: 'https://www.bundesbank.de/de/statistiken',
      ),
    ));

    zeilen.add(const Divider());

    zeilen.add(_buildWertZeile(
      'Summe Nebenkosten',
      ergebnis.kosten.betriebskosten +
          ergebnis.kosten.kapitalkosten +
          ergebnis.kosten.zusaetzlicherGrundpreisUebergabestation,
      '€/a',
      2,
      QuellenInfo(
        titel: 'Summe Nebenkosten',
        beschreibung: 'Wartung + Kapitaldienst + ÜGS',
      ),
      isBold: true,
      farbe: SuewagColors.fasergruen,
    ));

    return zeilen;
  }

  Widget _buildInfoCard(SzenarioStammdaten szenario) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuewagColors.indiablau.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.indiablau),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            szenario.bezeichnung,
            style: SuewagTextStyles.headline4.copyWith(
              color: SuewagColors.indiablau,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            szenario.beschreibung,
            style: SuewagTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAbschnittCard(String buchstabe, String titel, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SuewagColors.indiablau.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SuewagColors.indiablau,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      buchstabe,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titel,
                    style: SuewagTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SuewagColors.indiablau,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWertZeile(
      String label,
      double wert,
      String einheit,
      int nachkommastellen,
      QuellenInfo quelle, {
        bool isBold = false,
        Color? farbe,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: SuewagTextStyles.bodySmall.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            _formatiereDeutsch(wert, nachkommastellen),
            style: SuewagTextStyles.bodySmall.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: farbe,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            einheit,
            style: SuewagTextStyles.bodySmall.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: farbe,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _zeigeQuelle(quelle),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: SuewagColors.primary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatiereDeutsch(double wert, int nachkommastellen) {
    final parts = wert.toStringAsFixed(nachkommastellen).split('.');
    final vorkomma = parts[0];
    final nachkomma = nachkommastellen > 0 ? parts[1] : '';

    String formatted = '';
    int count = 0;
    for (int i = vorkomma.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = vorkomma[i] + formatted;
      count++;
    }

    if (nachkommastellen > 0) {
      formatted += ',$nachkomma';
    }

    return formatted;
  }

  void _zeigeQuelle(QuellenInfo quelle) {
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
                    // Link öffnen mit url_launcher
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
}