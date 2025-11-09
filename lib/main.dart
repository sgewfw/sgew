// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sgew/services/kostenvergleich_setup_service.dart';

import 'firebase_options.dart';
import 'constants/suewag_colors.dart';
import 'constants/suewag_text_styles.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 🆕 Initial-Setup für Kostenvergleich
  final setupService = KostenvergleichSetupService();
  await setupService.pruefeUndErstelleInitialDaten();
  // Deutsche Datumsformatierung initialisieren
  await initializeDateFormatting('de', null);

  runApp(const FernwaermeApp());
}

class FernwaermeApp extends StatelessWidget {
  const FernwaermeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ========================================
      // APP KONFIGURATION
      // ========================================
      title: 'Fernwärme Info',
      debugShowCheckedModeBanner: false,

      // ========================================
      // LOKALISIERUNG
      // ========================================
      locale: const Locale('de', 'DE'),
      supportedLocales: const [
        Locale('de', 'DE'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ========================================
      // THEME
      // ========================================
      theme: ThemeData(
        // Farben
        primaryColor: SuewagColors.primary,
        scaffoldBackgroundColor: SuewagColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SuewagColors.primary,
          primary: SuewagColors.primary,
          secondary: SuewagColors.secondary,
          error: SuewagColors.erdbeerrot,
          surface: Colors.white,
          background: SuewagColors.background,
        ),

        // App Bar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: SuewagColors.quartzgrau100, // Dunkle Icons & Text
          elevation: 0,
          centerTitle: false,
          titleTextStyle: SuewagTextStyles.headline2.copyWith(
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(
            color: SuewagColors.quartzgrau100,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
        ),

        // Input Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SuewagColors.quartzgrau10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: SuewagColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: SuewagColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: SuewagColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: SuewagColors.erdbeerrot),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // Button Themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SuewagColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: SuewagTextStyles.buttonMedium,
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: SuewagColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: SuewagTextStyles.buttonMedium,
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: SuewagColors.primary,
            side: BorderSide(color: SuewagColors.primary, width: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: SuewagTextStyles.buttonMedium,
          ),
        ),

        // Floating Action Button Theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: SuewagColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),

        // Tab Bar Theme
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: SuewagTextStyles.labelMedium,
          unselectedLabelStyle: SuewagTextStyles.labelMedium,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              color: Colors.white,
              width: 3,
            ),
          ),
        ),

        // Divider Theme
        dividerTheme: DividerThemeData(
          color: SuewagColors.divider,
          thickness: 1,
          space: 1,
        ),

        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: SuewagColors.quartzgrau10,
          selectedColor: SuewagColors.primary.withOpacity(0.2),
          labelStyle: SuewagTextStyles.labelSmall,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: SuewagColors.divider),
          ),
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: SuewagColors.primary,
          unselectedItemColor: SuewagColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          titleTextStyle: SuewagTextStyles.headline3,
          contentTextStyle: SuewagTextStyles.bodyMedium,
        ),

        // Snackbar Theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: SuewagColors.quartzgrau100,
          contentTextStyle: SuewagTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // Progress Indicator Theme
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: SuewagColors.primary,
        ),

        // Text Theme (Fallback)
        textTheme: TextTheme(
          displayLarge: SuewagTextStyles.headline1,
          displayMedium: SuewagTextStyles.headline2,
          displaySmall: SuewagTextStyles.headline3,
          headlineMedium: SuewagTextStyles.headline3,
          headlineSmall: SuewagTextStyles.headline4,
          titleLarge: SuewagTextStyles.headline3,
          titleMedium: SuewagTextStyles.headline4,
          titleSmall: SuewagTextStyles.labelLarge,
          bodyLarge: SuewagTextStyles.bodyLarge,
          bodyMedium: SuewagTextStyles.bodyMedium,
          bodySmall: SuewagTextStyles.bodySmall,
          labelLarge: SuewagTextStyles.labelLarge,
          labelMedium: SuewagTextStyles.labelMedium,
          labelSmall: SuewagTextStyles.labelSmall,
        ),

        // Font Family (falls spezielle Schrift gewünscht)
        fontFamily: 'Roboto', // oder andere Süwag Corporate Font

        // Verwendung von Material 3
        useMaterial3: true,
      ),

      // ========================================
      // HOME SCREEN
      // ========================================
      home: const HomeScreen(),
    );
  }
}