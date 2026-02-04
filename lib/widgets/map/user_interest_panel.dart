// lib/widgets/map/user_interest_panel.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/suewag_colors.dart';
import '../../services/auth_service.dart';
import '../../services/geocoding_service.dart';

/// Panel für User-Interesse mit strukturierter Adresseingabe
class UserInterestPanel extends StatefulWidget {
  final bool isInsideZone;
  final String? zoneName;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final ValueChanged<String> onAddressSearch;
  final bool isSubmitting;
  final bool isSearching;
  
  // 🆕 Vorausgefüllte Werte
  final String? prefillCity;
  final String? prefillPlz;
  final String? prefillStreet;
  final String? prefillStreetNumber;
  
  // 🆕 Callback für Adressänderung
  final Function(String street, String number, String plz, String city)? onAddressChanged;

  const UserInterestPanel({
    Key? key,
    required this.isInsideZone,
    this.zoneName,
    required this.onSubmit,
    required this.onCancel,
    required this.onAddressSearch,
    this.isSubmitting = false,
    this.isSearching = false,
    this.prefillCity,
    this.prefillPlz,
    this.prefillStreet,
    this.prefillStreetNumber,
    this.onAddressChanged,
  }) : super(key: key);

  @override
  State<UserInterestPanel> createState() => _UserInterestPanelState();
}

class _UserInterestPanelState extends State<UserInterestPanel> {
  final AuthService _authService = AuthService();
  
  // Adress-Controller
  late TextEditingController _streetController;
  late TextEditingController _numberController;
  late TextEditingController _plzController;
  late TextEditingController _cityController;
  
  // Auth-Controller
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoginMode = true;
  bool _isAuthenticating = false;
  String? _authError;

  bool get _isLoggedIn => _authService.isAuthenticated;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(text: widget.prefillStreet ?? '');
    _numberController = TextEditingController(text: widget.prefillStreetNumber ?? '');
    _plzController = TextEditingController(text: widget.prefillPlz ?? '');
    _cityController = TextEditingController(text: widget.prefillCity ?? '');
  }

  @override
  void didUpdateWidget(UserInterestPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Aktualisiere Felder wenn sich prefill-Werte ändern
    if (widget.prefillStreet != oldWidget.prefillStreet) {
      _streetController.text = widget.prefillStreet ?? '';
    }
    if (widget.prefillStreetNumber != oldWidget.prefillStreetNumber) {
      _numberController.text = widget.prefillStreetNumber ?? '';
    }
    if (widget.prefillPlz != oldWidget.prefillPlz) {
      _plzController.text = widget.prefillPlz ?? '';
    }
    if (widget.prefillCity != oldWidget.prefillCity) {
      _cityController.text = widget.prefillCity ?? '';
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _plzController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _notifyAddressChange() {
    widget.onAddressChanged?.call(
      _streetController.text,
      _numberController.text,
      _plzController.text,
      _cityController.text,
    );
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _authError = 'Bitte E-Mail und Passwort eingeben');
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      if (_isLoginMode) {
        final user = await _authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        if (user == null) {
          setState(() => _authError = 'Login fehlgeschlagen. Prüfe deine Daten.');
        }
      } else {
        final auth = FirebaseAuth.instance;
        await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _authError = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _authError = 'Ein Fehler ist aufgetreten: $e');
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Kein Benutzer mit dieser E-Mail gefunden';
      case 'wrong-password':
        return 'Falsches Passwort';
      case 'email-already-in-use':
        return 'Diese E-Mail ist bereits registriert';
      case 'weak-password':
        return 'Das Passwort ist zu schwach (min. 6 Zeichen)';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse';
      default:
        return 'Fehler: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (!_isLoggedIn)
              _buildAuthSection()
            else
              _buildInterestSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isInsideZone
              ? [SuewagColors.leuchtendgruen, SuewagColors.arktisgruen]
              : [SuewagColors.quartzgrau75, SuewagColors.quartzgrau50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.isInsideZone 
                ? Icons.local_fire_department 
                : Icons.location_off,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isInsideZone
                      ? 'Fernwärme-Interesse'
                      : 'Außerhalb des Gebiets',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.zoneName != null)
                  Text(
                    widget.zoneName!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SuewagColors.karibikblau.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, 
                  color: SuewagColors.alpenblau, 
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bitte registriere dich oder melde dich an, um dein Interesse anzumelden.',
                    style: TextStyle(
                      color: SuewagColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildAuthToggle('Anmelden', true)),
              const SizedBox(width: 8),
              Expanded(child: _buildAuthToggle('Registrieren', false)),
            ],
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-Mail',
              prefixIcon: Icon(Icons.email_outlined),
              isDense: true,
            ),
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Passwort',
              prefixIcon: Icon(Icons.lock_outlined),
              isDense: true,
            ),
            obscureText: true,
          ),

          if (_authError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SuewagColors.erdbeerrot.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _authError!,
                style: TextStyle(color: SuewagColors.erdbeerrot, fontSize: 12),
              ),
            ),
          ],

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isAuthenticating ? null : _handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: SuewagColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isAuthenticating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isLoginMode ? 'Anmelden' : 'Registrieren'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthToggle(String label, bool isLogin) {
    final isSelected = _isLoginMode == isLogin;
    return Material(
      color: isSelected ? SuewagColors.primary.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _isLoginMode = isLogin),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? SuewagColors.primary : SuewagColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? SuewagColors.primary : SuewagColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logged in Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SuewagColors.leuchtendgruen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: SuewagColors.leuchtendgruen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Angemeldet als ${_authService.currentUser?.email}',
                    style: TextStyle(color: SuewagColors.textPrimary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await _authService.signOut();
                    setState(() {});
                  },
                  child: const Text('Logout', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🆕 Adress-Felder
          Text(
            'Ihre Adresse',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: SuewagColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Straße + Hausnummer
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _streetController,
                  decoration: const InputDecoration(
                    labelText: 'Straße',
                    isDense: true,
                  ),
                  onChanged: (_) => _notifyAddressChange(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Nr.',
                    isDense: true,
                  ),
                  onChanged: (_) => _notifyAddressChange(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // PLZ + Stadt
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _plzController,
                  decoration: const InputDecoration(
                    labelText: 'PLZ',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _notifyAddressChange(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Stadt',
                    isDense: true,
                  ),
                  onChanged: (_) => _notifyAddressChange(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status-Anzeige
          if (!widget.isInsideZone)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SuewagColors.verkehrsorange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SuewagColors.verkehrsorange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: SuewagColors.verkehrsorange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dieser Standort liegt außerhalb unserer Ausbaugebiete. Bitte wählen Sie einen Standort innerhalb eines orangenen Gebiets.',
                      style: TextStyle(color: SuewagColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SuewagColors.leuchtendgruen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓ Ihr Standort liegt in einem Ausbaugebiet für Fernwärme!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SuewagColors.leuchtendgruen,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Submit Button
          ElevatedButton.icon(
            onPressed: widget.isInsideZone && !widget.isSubmitting
                ? widget.onSubmit
                : null,
            icon: widget.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text(
              widget.isSubmitting ? 'Wird gesendet...' : 'Interesse anmelden',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isInsideZone
                  ? SuewagColors.leuchtendgruen
                  : SuewagColors.quartzgrau50,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
