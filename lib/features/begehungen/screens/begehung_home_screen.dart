import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../../../screens/admin/admin_login_screen.dart';
import '../models/begehung_enums.dart';
import '../providers/auth_providers.dart';
import '../providers/begehung_providers.dart';
import '../widgets/responsive_helper.dart';
import 'admin/begehung_admin_screen.dart';
import 'admin/user_verwaltung_screen.dart';
import 'public_dashboard_screen.dart';
import 'internes_dashboard_screen.dart';

class BegehungHomeScreen extends ConsumerStatefulWidget {
  const BegehungHomeScreen({super.key});
  @override
  ConsumerState<BegehungHomeScreen> createState() => _BegehungHomeScreenState();
}

class _BegehungHomeScreenState extends ConsumerState<BegehungHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    return authState.when(
      data: (user) => user == null ? _buildLoginRequired() : _buildMainLayout(isMobile),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _buildLoginRequired(),
    );
  }

  Widget _buildLoginRequired() {
    return Scaffold(
      appBar: AppBar(title: const Text('Begehungen')),
      body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline, size: 64, color: SuewagColors.quartzgrau50),
        const SizedBox(height: 24),
        Text('Anmeldung erforderlich', style: SuewagTextStyles.headline2),
        const SizedBox(height: 12),
        Text('Bitte melden Sie sich mit Ihrer @suewag.de E-Mail-Adresse an.', style: SuewagTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ElevatedButton.icon(
            onPressed: () async { final s = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())); if (s == true && mounted) setState(() {}); },
            icon: const Icon(Icons.login), label: const Text('Anmelden'),
            style: ElevatedButton.styleFrom(backgroundColor: SuewagColors.verkehrsorange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
      ]))),
    );
  }

  Widget _buildMainLayout(bool isMobile) {
    final userAsync = ref.watch(currentBegehungUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => _buildLoginRequired(),
      data: (user) {
        if (user == null) return _buildLoginRequired();
        if (!user.istAktiv) return _buildInactiveUserScreen(user.status);

        final istFK = user.istFuehrungskraft;
        final istAdmin = user.rolle.kannUserVerwalten;
        final tabs = <_NavItem>[
          const _NavItem(icon: Icons.dashboard, label: 'Dashboard'),
          if (istFK) const _NavItem(icon: Icons.analytics, label: 'Intern'),
          if (istAdmin) const _NavItem(icon: Icons.admin_panel_settings, label: 'Begehungen'),
          if (istAdmin) const _NavItem(icon: Icons.people, label: 'Benutzer'),
        ];
        final screens = <Widget>[
          const PublicDashboardScreen(),
          if (istFK) const InternesDashboardScreen(),
          if (istAdmin) const BegehungAdminScreen(),
          if (istAdmin) const UserVerwaltungScreen(),
        ];
        if (_selectedIndex >= screens.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _selectedIndex = 0); });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return isMobile ? _buildMobileLayout(tabs, screens) : _buildDesktopLayout(tabs, screens);
      },
    );
  }

  Widget _buildInactiveUserScreen(UserStatus status) {
    final (icon, iconColor, title, message) = switch (status) {
      UserStatus.ausstehend => (Icons.hourglass_empty_rounded, SuewagColors.verkehrsorange, 'Freigabe ausstehend', 'Dein Konto wartet auf Freigabe durch einen Administrator.'),
      UserStatus.gesperrt => (Icons.block_rounded, SuewagColors.erdbeerrot, 'Zugang gesperrt', 'Dein Zugang wurde von einem Administrator gesperrt.'),
      UserStatus.abgelehnt => (Icons.cancel_outlined, SuewagColors.erdbeerrot, 'Registrierung abgelehnt', 'Deine Registrierung wurde abgelehnt.'),
      UserStatus.aktiv => (Icons.info_outline, SuewagColors.textSecondary, 'Konto nicht aktiv', 'Bitte wende dich an einen Administrator.'),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Begehungen')),
      body: Center(child: Padding(padding: const EdgeInsets.all(32), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 64, color: iconColor)),
        const SizedBox(height: 32),
        Text(title, style: SuewagTextStyles.headline2, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(message, style: SuewagTextStyles.bodyMedium.copyWith(color: SuewagColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        OutlinedButton.icon(onPressed: () => _performLogout(), icon: const Icon(Icons.logout), label: const Text('Abmelden')),
      ])))),
    );
  }

  Widget _buildMobileLayout(List<_NavItem> tabs, List<Widget> screens) {
    return Scaffold(appBar: _buildAppBar(), body: screens[_selectedIndex],
        bottomNavigationBar: tabs.length > 1 ? BottomNavigationBar(currentIndex: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i), selectedItemColor: SuewagColors.verkehrsorange,
            items: tabs.map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label)).toList()) : null);
  }

  Widget _buildDesktopLayout(List<_NavItem> tabs, List<Widget> screens) {
    return Scaffold(appBar: _buildAppBar(), body: Row(children: [
      if (tabs.length > 1) NavigationRail(selectedIndex: _selectedIndex, onDestinationSelected: (i) => setState(() => _selectedIndex = i), labelType: NavigationRailLabelType.all,
          selectedIconTheme: const IconThemeData(color: SuewagColors.verkehrsorange), selectedLabelTextStyle: SuewagTextStyles.labelMedium.copyWith(color: SuewagColors.verkehrsorange),
          destinations: tabs.map((t) => NavigationRailDestination(icon: Icon(t.icon), label: Text(t.label))).toList()),
      if (tabs.length > 1) const VerticalDivider(width: 1),
      Expanded(child: screens[_selectedIndex]),
    ]));
  }

  Future<void> _performLogout() async {
    ref.read(isLoggingOutProvider.notifier).state = true;
    if (mounted) Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 100));
    await ref.read(logoutProvider)();
  }

  AppBar _buildAppBar() {
    final user = ref.watch(currentBegehungUserProvider);
    final isDark = ref.watch(darkModeProvider);
    final syncState = ref.watch(syncStateProvider);
    return AppBar(
      title: Row(children: [const Icon(Icons.construction, color: SuewagColors.verkehrsorange), const SizedBox(width: 12), const Text('Mission Zero')]),
      actions: [
        IconButton(icon: syncState.isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SuewagColors.verkehrsorange)) : const Icon(Icons.sync),
            tooltip: syncState.lastSyncTime != null ? 'Letzter Sync: ${_formatTime(syncState.lastSyncTime!)}' : 'Synchronisieren',
            onPressed: syncState.isLoading ? null : () async { final r = await ref.read(syncStateProvider.notifier).sync(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.statusText), backgroundColor: r.success ? Colors.green : Colors.red, behavior: SnackBarBehavior.floating)); }),
        user.when(data: (u) => Padding(padding: const EdgeInsets.only(right: 8), child: Center(child: Text(u?.name ?? '', style: SuewagTextStyles.bodySmall))), loading: () => const SizedBox.shrink(), error: (_, _) => const SizedBox.shrink()),
        IconButton(icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode), tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () async { final u = ref.read(currentBegehungUserProvider).value; if (u == null) return; try { await ref.read(userServiceProvider).updateDarkMode(u.uid, !isDark); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'))); } }),
        IconButton(icon: const Icon(Icons.logout), tooltip: 'Abmelden', onPressed: () => _performLogout()),
      ],
    );
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} Uhr';
}

class _NavItem { final IconData icon; final String label; const _NavItem({required this.icon, required this.label}); }