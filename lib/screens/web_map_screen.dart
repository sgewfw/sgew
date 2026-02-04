// lib/screens/web_map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/city.dart';
import '../models/zone.dart';
import '../services/auth_service.dart';
import '../services/city_service.dart';
import '../services/zone_service.dart';
import '../services/user_interest_service.dart';
import '../models/user_interest.dart'; // 🆕 Fix: Import fehlte
import '../services/geocoding_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/map/city_selector_card.dart';
import '../widgets/map/admin_tools_panel.dart';
import '../widgets/map/user_interest_panel.dart';
import '../constants/suewag_colors.dart';

/// Web Map Screen für Fernwärme-Bedarfsabfrage
/// Stack-Layout mit Google Map, Sidebar und Admin-Tools
class WebMapScreen extends StatefulWidget {
  const WebMapScreen({Key? key}) : super(key: key);

  @override
  State<WebMapScreen> createState() => _WebMapScreenState();
}

class _WebMapScreenState extends State<WebMapScreen> with AutomaticKeepAliveClientMixin {
  // Keep alive when switching tabs to prevent map disposal errors
  @override
  bool get wantKeepAlive => true;

  // Services
  final CityService _cityService = CityService();
  final ZoneService _zoneService = ZoneService();
  final UserInterestService _interestService = UserInterestService();
  final AuthService _authService = AuthService();
  final GeocodingService _geocodingService = GeocodingService();

  // Map Controller
  GoogleMapController? _mapController;
  final FocusNode _focusNode = FocusNode();

  // State
  List<City> _cities = [];
  City? _selectedCity;
  List<Zone> _zones = [];
  bool _isLoadingCities = true;
  bool _isLoadingZones = false;

  // Admin Drawing State
  bool _isEditMode = false;
  ZoneType _selectedZoneType = ZoneType.existing;
  List<LatLng> _draftPolygonPoints = [];

  // User Interest State
  LatLng? _interestMarkerPosition;
  bool _showInterestOverlay = false;
  bool _isSubmittingInterest = false;
  bool _isSearchingAddress = false;
  bool _isInsidePotentialZone = false;
  bool _isDialogOpen = false; // Flag um Dialog-Klicks zu de-bouncen
  
  // 🆕 Existing Interests
  Set<Marker> _existingInterestMarkers = {};
  StreamSubscription? _interestsSubscription;
  
  // 🆕 Strukturierte Adressdaten
  String? _addressStreet;
  String? _addressNumber;
  String? _addressPlz;
  String? _addressCity;

  // Subscriptions
  StreamSubscription? _zonesSubscription;

  // Default Map Position (Deutschland Mitte)
  static const LatLng _defaultCenter = LatLng(50.1109, 8.6821); // Frankfurt
  static const double _defaultZoom = 6.0;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _zonesSubscription?.cancel();
    _interestsSubscription?.cancel();
    _mapController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Städte laden
  Future<void> _loadCities() async {
    _cityService.getCitiesStream().listen((cities) {
      if (mounted) {
        setState(() {
          _cities = cities;
          _isLoadingCities = false;

          // Erste Stadt automatisch auswählen
          if (_selectedCity == null && cities.isNotEmpty) {
            _selectCity(cities.first);
          }
        });
      }
    });
  }

  /// Stadt auswählen
  void _selectCity(City? city) {
    if (city == null) return;

    setState(() {
      _selectedCity = city;
      _isLoadingZones = true;
      _zones = [];
      _clearDraft();
      _clearInterestMarker();
    });

    // Karte auf Stadt zentrieren
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(city.center, city.zoom),
    );

    // Zonen-Stream abonnieren
    _zonesSubscription?.cancel();
    _zonesSubscription = _zoneService.getZonesStream(city.id).listen((zones) {
      if (mounted) {
        setState(() {
          _zones = zones;
          _isLoadingZones = false;
        });
      }
    });
    
    // Interessen laden
    _loadInterestsForCity(city.id);
  }

  /// Vorhandene Interessen laden
  void _loadInterestsForCity(String cityId) {
    _interestsSubscription?.cancel();
    _interestsSubscription = _interestService.getInterestsStream(cityId).listen((interests) {
      if (!mounted) return;
      
      setState(() {
        _existingInterestMarkers = interests.map((interest) {
          return Marker(
            markerId: MarkerId('interest_${interest.id}'),
            position: interest.location,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: 'Wärme-Interesse',
              snippet: 'Registriert am: ${interest.createdAt.toLocal().toString().split(' ')[0]}',
            ),
          );
        }).toSet();
      });
    });
  }

  /// Edit-Modus umschalten
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _clearDraft();
      }
      _clearInterestMarker();
    });
  }

  /// Draft-Polygon zurücksetzen
  void _clearDraft() {
    setState(() {
      _draftPolygonPoints = [];
    });
  }

  /// Letzten Punkt entfernen (Undo)
  void _undoLastPoint() {
    if (_draftPolygonPoints.isNotEmpty) {
      setState(() {
        _draftPolygonPoints = List.from(_draftPolygonPoints)..removeLast();
      });
    }
  }

  /// Interest-Marker zurücksetzen
  void _clearInterestMarker() {
    // Flag setzen um nächsten Map-Klick zu ignorieren
    _isDialogOpen = true;
    
    setState(() {
      _interestMarkerPosition = null;
      _showInterestOverlay = false;
      _isInsidePotentialZone = false;
      _addressStreet = null;
      _addressNumber = null;
      _addressPlz = null;
      _addressCity = null;
    });
    
    // Flag nach kurzer Verzögerung zurücksetzen
    Future.delayed(const Duration(milliseconds: 200), () {
      _isDialogOpen = false;
    });
  }

  /// Prüft ob eine Position in einem Ausbaugebiet liegt
  bool _checkIfInsidePotentialZone(LatLng position) {
    final potentialZones = _zones
        .where((z) => z.type == ZoneType.potential)
        .map((z) => z.points)
        .toList();

    return GeoUtils.findContainingPolygonIndex(position, potentialZones) != null;
  }

  /// Prüft ob eine Position in einem Bestandsgebiet liegt
  bool _checkIfInsideExistingZone(LatLng position) {
    final existingZones = _zones
        .where((z) => z.type == ZoneType.existing)
        .map((z) => z.points)
        .toList();

    return GeoUtils.findContainingPolygonIndex(position, existingZones) != null;
  }

  /// Setzt den Interest-Marker, prüft Zone und lädt Adresse
  Future<void> _setInterestMarkerWithAddress(LatLng position) async {
    final isInside = _checkIfInsidePotentialZone(position);
    
    // Sofort Marker setzen für visuelles Feedback
    setState(() {
      _interestMarkerPosition = position;
      _showInterestOverlay = true;
      _isInsidePotentialZone = isInside;
      // Stadt und PLZ aus der ausgewählten Stadt vorausfüllen
      _addressCity = _selectedCity?.name;
      _addressPlz = _selectedCity?.plz;
      _addressStreet = null;
      _addressNumber = null;
      _isSearchingAddress = true;
    });
    
    // Reverse Geocoding für Straße und Hausnummer
    final result = await _geocodingService.reverseGeocode(position);
    
    if (result != null && mounted) {
      setState(() {
        _addressStreet = result.street;
        _addressNumber = result.streetNumber;
        // PLZ und Stadt nur überschreiben wenn nicht von City vorgegeben
        if (_addressPlz == null || _addressPlz!.isEmpty) {
          _addressPlz = result.postalCode;
        }
        if (_addressCity == null || _addressCity!.isEmpty) {
          _addressCity = result.city;
        }
        _isSearchingAddress = false;
      });
      print('📍 Adresse gefunden: ${result.street} ${result.streetNumber}, ${result.postalCode} ${result.city}');
    } else {
      setState(() => _isSearchingAddress = false);
    }
    
    if (isInside) {
      print('✅ Marker liegt im Ausbaugebiet!');
    } else {
      print('⚠️ Marker liegt NICHT im Ausbaugebiet');
    }
  }

  /// Adresse suchen und Karte dorthin bewegen
  Future<void> _searchAddress(String address) async {
    if (address.isEmpty) return;

    setState(() => _isSearchingAddress = true);

    final result = await _geocodingService.searchAddress(address);

    setState(() => _isSearchingAddress = false);

    if (result != null) {
      // Karte zur gefundenen Position bewegen
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(result.position, 17),
      );

      // Marker setzen mit strukturierten Adressdaten
      final isInside = _checkIfInsidePotentialZone(result.position);
      setState(() {
        _interestMarkerPosition = result.position;
        _showInterestOverlay = true;
        _isInsidePotentialZone = isInside;
        _addressStreet = result.street;
        _addressNumber = result.streetNumber;
        _addressPlz = result.postalCode ?? _selectedCity?.plz;
        _addressCity = result.city ?? _selectedCity?.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 ${result.formattedAddress}'),
          backgroundColor: SuewagColors.karibikblau,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse nicht gefunden'),
          backgroundColor: SuewagColors.erdbeerrot,
        ),
      );
    }
  }
  
  /// Callback wenn User Adresse manuell ändert
  void _onAddressChanged(String street, String number, String plz, String city) {
    setState(() {
      _addressStreet = street;
      _addressNumber = number;
      _addressPlz = plz;
      _addressCity = city;
    });
  }

  /// Karten-Klick Handler
  void _onMapTap(LatLng position) {
    if (_selectedCity == null) return;
    
    // Verhindere Klick-Events direkt nach Dialog-Schließen
    if (_isDialogOpen) {
      _isDialogOpen = false;
      return;
    }
    
    // Wenn Interest-Overlay offen ist, ignorieren (User soll erst schließen)
    if (_showInterestOverlay) return;

    if (_isEditMode) {
      // Admin: Punkt zum Draft hinzufügen
      print('🔵 Map Tap - Position: $position, Punkte vorher: ${_draftPolygonPoints.length}');
      setState(() {
        _draftPolygonPoints = List.from(_draftPolygonPoints)..add(position);
      });
      print('🔵 Punkte nachher: ${_draftPolygonPoints.length}');
    } else {
      // User: Prüfen in welcher Zone der Klick war
      final insidePotential = _checkIfInsidePotentialZone(position);
      final insideExisting = _checkIfInsideExistingZone(position);
      
      if (insidePotential) {
        // ✅ Klick im Ausbaugebiet (rot) → Interest-Formular öffnen
        _setInterestMarkerWithAddress(position);
      } else if (insideExisting) {
        // ⚠️ Klick im Bestandsgebiet (grün) → Info anzeigen
        _showExistingZoneInfo();
      }
      // Klick außerhalb → ignorieren (nichts tun)
    }
  }

  /// Info-Dialog für Bestandsgebiet
  void _showExistingZoneInfo() {
    _isDialogOpen = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: SuewagColors.leuchtendgruen),
            const SizedBox(width: 12),
            const Text('Bestandsgebiet'),
          ],
        ),
        content: const Text(
          'Dieser Bereich wird bereits mit Fernwärme versorgt.\n\n'
          'Wenn Sie Interesse an einem Anschluss haben, wenden Sie sich bitte direkt an unseren Kundenservice.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Kurze Verzögerung um Klick-Event zu verhindern
              Future.delayed(const Duration(milliseconds: 100), () {
                _isDialogOpen = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SuewagColors.primary,
            ),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  /// Polygon auf bestehende Zone geklickt
  void _onZoneTap(Zone zone) {
    if (!_isEditMode) return;

    // Löschen-Dialog anzeigen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zone löschen?'),
        content: Text(
          'Möchten Sie diese ${zone.type.displayName}-Zone wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _zoneService.deleteZone(_selectedCity!.id, zone.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Zone gelöscht')),
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

  /// Polygon speichern
  Future<void> _savePolygon() async {
    if (_selectedCity == null || _draftPolygonPoints.length < 3) return;

    final zone = Zone(
      id: '', // Wird von Firestore generiert
      type: _selectedZoneType,
      points: _draftPolygonPoints,
      color: Zone.getDefaultColor(_selectedZoneType),
    );

    final result = await _zoneService.addZone(_selectedCity!.id, zone);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedZoneType.displayName}-Zone gespeichert!'),
          backgroundColor: SuewagColors.leuchtendgruen,
        ),
      );
      _clearDraft();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Speichern der Zone'),
          backgroundColor: SuewagColors.erdbeerrot,
        ),
      );
    }
  }

  /// User-Interesse absenden
  Future<void> _submitInterest() async {
    if (_selectedCity == null || _interestMarkerPosition == null) return;
    
    // Prüfen ob User eingeloggt ist
    if (!_authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte melden Sie sich an um Ihr Interesse zu registrieren.'),
          backgroundColor: SuewagColors.verkehrsorange,
        ),
      );
      return;
    }
    
    // Prüfen ob Marker im Ausbaugebiet liegt
    if (!_isInsidePotentialZone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wählen Sie einen Standort innerhalb eines Ausbaugebiets.'),
          backgroundColor: SuewagColors.verkehrsorange,
        ),
      );
      return;
    }

    setState(() => _isSubmittingInterest = true);

    final success = await _interestService.submitInterest(
      cityId: _selectedCity!.id,
      location: _interestMarkerPosition!,
      street: _addressStreet,
      streetNumber: _addressNumber,
      plz: _addressPlz,
      city: _addressCity,
    );

    setState(() => _isSubmittingInterest = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vielen Dank! Ihr Interesse wurde registriert.'),
          backgroundColor: SuewagColors.leuchtendgruen,
        ),
      );
      _clearInterestMarker();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Senden. Bitte erneut versuchen.'),
          backgroundColor: SuewagColors.erdbeerrot,
        ),
      );
    }
  }

  /// Tastatur-Handler
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (_isEditMode) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_draftPolygonPoints.length >= 3) {
          _savePolygon();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _undoLastPoint();
      }
    }
  }

  /// Polygone für die Karte erstellen
  Set<Polygon> _buildPolygons() {
    final polygons = <Polygon>{};

    // Gespeicherte Zonen
    for (final zone in _zones) {
      polygons.add(zone.toGooglePolygon(
        onTap: _isEditMode ? () => _onZoneTap(zone) : null,
      ));
    }

    // Draft-Polygon (während des Zeichnens)
    if (_draftPolygonPoints.length >= 3) {
      polygons.add(Polygon(
        polygonId: const PolygonId('draft'),
        points: _draftPolygonPoints,
        fillColor: Zone.getDefaultColor(_selectedZoneType).withOpacity(0.25),
        strokeColor: Zone.getDefaultColor(_selectedZoneType),
        strokeWidth: 3,
      ));
    }

    return polygons;
  }

  /// Polylines für Draft-Vorschau
  Set<Polyline> _buildPolylines() {
    // Polyline erst ab 2 Punkten anzeigen (sonst kein Strich möglich)
    if (_draftPolygonPoints.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('draft_line'),
        points: _draftPolygonPoints,
        color: Zone.getDefaultColor(_selectedZoneType),
        width: 3,
      ),
    };
  }

  /// Circle-Marker für Draft-Punkte (größerer Radius für Sichtbarkeit)
  Set<Circle> _buildCircles() {
    // Circles werden parallel zu den draggable Markern angezeigt
    // für bessere visuelle Darstellung der Polygonfläche
    final circles = <Circle>{};

    for (int i = 0; i < _draftPolygonPoints.length; i++) {
      circles.add(Circle(
        circleId: CircleId('draft_point_$i'),
        center: _draftPolygonPoints[i],
        radius: 30, // Etwas kleiner, da wir jetzt auch Marker haben
        fillColor: Zone.getDefaultColor(_selectedZoneType).withOpacity(0.5),
        strokeColor: Colors.white,
        strokeWidth: 2,
      ));
    }

    return circles;
  }

  /// Punkt per Drag & Drop verschieben
  void _onDraftPointDragEnd(int index, LatLng newPosition) {
    setState(() {
      _draftPolygonPoints = List.from(_draftPolygonPoints);
      _draftPolygonPoints[index] = newPosition;
    });
    print('📍 Punkt $index verschoben nach: $newPosition');
  }

  /// Marker für User-Interesse UND draggable Draft-Punkte
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Bestehende Interessen
    markers.addAll(_existingInterestMarkers);
    
    // User Interest Marker
    if (_interestMarkerPosition != null && !_isEditMode) {
      markers.add(Marker(
        markerId: const MarkerId('interest'),
        position: _interestMarkerPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    
    // Draft Polygon Punkte als DRAGGABLE Marker
    if (_isEditMode) {
      for (int i = 0; i < _draftPolygonPoints.length; i++) {
        markers.add(Marker(
          markerId: MarkerId('draft_point_$i'),
          position: _draftPolygonPoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _selectedZoneType == ZoneType.existing 
              ? BitmapDescriptor.hueGreen 
              : BitmapDescriptor.hueOrange,
          ),
          draggable: true, // 🆕 Drag & Drop aktiviert!
          onDragEnd: (newPosition) => _onDraftPointDragEnd(i, newPosition),
        ));
      }
    }
    
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    // Nur klemmerro@gmail.com ist Admin!
    final isAdmin = _authService.isAdmin;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          // Layer 1: Google Map (Fullscreen)
          MouseRegion(
            cursor: _isEditMode
                ? SystemMouseCursors.precise
                : SystemMouseCursors.click,
            child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedCity?.center ?? _defaultCenter,
                  zoom: _selectedCity?.zoom ?? _defaultZoom,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_selectedCity != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        _selectedCity!.center,
                        _selectedCity!.zoom,
                      ),
                    );
                  }
                },
                onTap: _onMapTap,
                polygons: _buildPolygons(),
                polylines: _buildPolylines(),
                circles: _buildCircles(),
                markers: _buildMarkers(),
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),
            ),

            // Layer 2: Sidebar Card (Top-Left)
            Positioned(
              top: 16,
              left: 16,
              child: CitySelectorCard(
                cities: _cities,
                selectedCity: _selectedCity,
                onCityChanged: _selectCity,
                isLoading: _isLoadingCities,
              ),
            ),

            // Layer 3: Admin Tools (Top-Right) - nur für Admins
            if (isAdmin)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {}, // Klicks absorbieren
                  behavior: HitTestBehavior.opaque,
                  child: AdminToolsPanel(
                    isEditModeActive: _isEditMode,
                    selectedZoneType: _selectedZoneType,
                    currentPointCount: _draftPolygonPoints.length,
                    onToggleEditMode: _toggleEditMode,
                    onZoneTypeChanged: (type) {
                      setState(() => _selectedZoneType = type);
                    },
                    onSavePolygon: _savePolygon,
                    onCancelDrawing: _clearDraft,
                    onUndoPoint: _undoLastPoint,
                  ),
                ),
              ),

            // User Interest Panel (Center) - nur wenn nicht im Edit-Mode
            // GestureDetector absorbiert Klicks damit sie nicht zur Map durchgehen
            if (_showInterestOverlay && _interestMarkerPosition != null && !_isEditMode)
              Center(
                child: GestureDetector(
                  onTap: () {}, // Klicks absorbieren
                  behavior: HitTestBehavior.opaque,
                  child: UserInterestPanel(
                    isInsideZone: _isInsidePotentialZone,
                    zoneName: _isInsidePotentialZone ? 'Ausbaugebiet' : null,
                    onSubmit: _submitInterest,
                    onCancel: _clearInterestMarker,
                    onAddressSearch: _searchAddress,
                    isSubmitting: _isSubmittingInterest,
                    isSearching: _isSearchingAddress,
                    prefillStreet: _addressStreet,
                    prefillStreetNumber: _addressNumber,
                    prefillPlz: _addressPlz,
                    prefillCity: _addressCity,
                    onAddressChanged: _onAddressChanged,
                  ),
                ),
              ),

            // Loading Indicator for Zones
            if (_isLoadingZones)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SuewagColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Zonen werden geladen...'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

  /// Login-Dialog anzeigen
  void _showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Passwort',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = await _authService.signInWithEmailAndPassword(
                emailController.text,
                passwordController.text,
              );

              Navigator.pop(context);

              if (user != null) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erfolgreich eingeloggt!'),
                    backgroundColor: SuewagColors.leuchtendgruen,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login fehlgeschlagen'),
                    backgroundColor: SuewagColors.erdbeerrot,
                  ),
                );
              }
            },
            child: const Text('Einloggen'),
          ),
        ],
      ),
    );
  }
}
