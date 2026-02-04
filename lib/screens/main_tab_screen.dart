// lib/screens/main_tab_screen.dart

import 'package:flutter/material.dart';
import '../constants/suewag_colors.dart';
import '../services/auth_service.dart';
import 'web_map_screen.dart';
import 'news_screen.dart';
import 'faq_screen.dart';

/// Haupt-Screen mit Tabs für Karte, News und FAQ
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: Text('Angemeldet als: ${_authService.currentUser?.email}\n\nMöchten Sie sich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SuewagColors.erdbeerrot,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: TextStyle(color: SuewagColors.erdbeerrot, fontSize: 12),
                ),
              ],
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
                  emailController.text.trim(),
                  passwordController.text,
                );
                if (user != null) {
                  Navigator.pop(context);
                  setState(() {});
                } else {
                  setDialogState(() => errorMessage = 'Login fehlgeschlagen');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SuewagColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Anmelden'),
            ),
          ],
        ),
      ),
    );
  }

  /// Baut einen Tab-Button mit Hover-Effekt (schwarze Pill nur bei Hover/aktiv)
  Widget _buildTabButton(String label, int index) {
    final isSelected = _tabController.index == index;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: isSelected ? null : Border.all(color: Colors.transparent),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : SuewagColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SÜWAG Fernwärme',
          style: TextStyle(
            color: SuewagColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: SuewagColors.textPrimary,
        elevation: 1,
        toolbarHeight: 70, // Mehr Höhe für Padding
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton('Karte', 0),
                const SizedBox(width: 8),
                _buildTabButton('News', 1),
                const SizedBox(width: 8),
                _buildTabButton('FAQ', 2),
              ],
            ),
          ),
        ),
        actions: [
          // User Status / Login
          if (_authService.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showLogoutDialog,
                icon: Icon(Icons.account_circle, color: SuewagColors.primary),
                label: Text(
                  _authService.currentUser?.email ?? 'User',
                  style: TextStyle(color: SuewagColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _showLoginDialog,
              icon: Icon(Icons.login, color: SuewagColors.textSecondary),
              label: Text(
                'Admin Login',
                style: TextStyle(color: SuewagColors.textSecondary),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WebMapScreen(),
          NewsScreen(),
          FaqScreen(),
        ],
      ),
    );
  }
}
