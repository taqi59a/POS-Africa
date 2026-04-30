import 'package:flutter/material.dart';

/// POS Africa — Midnight Commerce design system
class AppTheme {
  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF0070F3);  // Vercel blue
  static const Color primaryGlow    = Color(0x330070F3);
  static const Color accent         = Color(0xFF00CFFF);  // Cyan
  static const Color accentViolet   = Color(0xFF7B61FF);
  static const Color accentGreen    = Color(0xFF10B981);  // Emerald
  static const Color accentOrange   = Color(0xFFF59E0B);  // Amber
  static const Color accentRed      = Color(0xFFFF3D57);

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bgDeep         = Color(0xFF060912);
  static const Color bgBase         = Color(0xFF09111F);
  static const Color bgSurface      = Color(0xFF0D1627);
  static const Color bgCard         = Color(0xFF111E33);
  static const Color bgCardHover    = Color(0xFF172438);
  static const Color bgSidebar      = Color(0xFF070E1C);

  // ── Borders ─────────────────────────────────────────────────────────────── 
  static const Color borderSubtle   = Color(0x14FFFFFF);  // white 8%
  static const Color borderDefault  = Color(0x1FFFFFFF);  // white 12%
  static const Color borderAccent   = Color(0x4D0070F3);  // primary 30%

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFE8F0FF);
  static const Color textSecondary  = Color(0xFF7A8CA8);
  static const Color textMuted      = Color(0xFF3D4F66);

  static ThemeData get dark {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary:    primary,
      onPrimary:  Colors.white,
      primaryContainer:   Color(0xFF003380),
      onPrimaryContainer: Color(0xFFCCE0FF),
      secondary:    accentViolet,
      onSecondary:  Colors.white,
      secondaryContainer:   Color(0xFF3A2E99),
      onSecondaryContainer: Color(0xFFDDD8FF),
      tertiary:   accent,
      onTertiary: Color(0xFF003344),
      tertiaryContainer:   Color(0xFF003E5C),
      onTertiaryContainer: Color(0xCCF4FFFF),
      error:   accentRed,
      onError: Colors.white,
      errorContainer:   Color(0xFF60001E),
      onErrorContainer: Color(0xFFFFCDD5),
      surface:   bgSurface,
      onSurface: textPrimary,
      surfaceContainerLowest:  bgDeep,
      surfaceContainerLow:     bgBase,
      surfaceContainer:        bgCard,
      surfaceContainerHigh:    bgCardHover,
      surfaceContainerHighest: Color(0xFF1B2844),
      onSurfaceVariant: textSecondary,
      outline:        borderDefault,
      outlineVariant: borderSubtle,
      shadow:         Colors.black,
      scrim:          Colors.black,
      inverseSurface:   textPrimary,
      onInverseSurface: bgBase,
      inversePrimary:   primary,
    );

    return ThemeData(
      useMaterial3:           true,
      colorScheme:            cs,
      fontFamily:             'Inter',
      scaffoldBackgroundColor: bgBase,
      cardColor:              bgCard,
      dividerColor:           borderSubtle,

      appBarTheme: const AppBarTheme(
        backgroundColor:        bgSurface,
        foregroundColor:        textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        surfaceTintColor:       Colors.transparent,
        titleTextStyle: TextStyle(
          color:      textPrimary,
          fontSize:   18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme:        IconThemeData(color: textSecondary),
        actionsIconTheme: IconThemeData(color: textSecondary),
      ),

      cardTheme: CardThemeData(
        color:     bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentRed, width: 1.5),
        ),
        labelStyle:     const TextStyle(color: textSecondary),
        hintStyle:      const TextStyle(color: textMuted),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation:       0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation:       0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side:            const BorderSide(color: borderDefault),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        ),
      ),

      iconTheme: const IconThemeData(color: textSecondary, size: 20),

      dividerTheme: const DividerThemeData(
        color:     borderSubtle,
        thickness: 1,
        space:     1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: bgCard,
        side:            const BorderSide(color: borderSubtle),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      textTheme: const TextTheme(
        displayLarge:   TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 48),
        displayMedium:  TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 40),
        displaySmall:   TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 34),
        headlineLarge:  TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 28),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 24),
        headlineSmall:  TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge:  TextStyle(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: textPrimary,   fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall:  TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge:   TextStyle(color: textPrimary,   fontSize: 15),
        bodyMedium:  TextStyle(color: textSecondary, fontSize: 14),
        bodySmall:   TextStyle(color: textMuted,     fontSize: 12),
        labelLarge:  TextStyle(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall:  TextStyle(color: textMuted,     fontWeight: FontWeight.w400, fontSize: 11),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : textMuted),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryGlow : bgCard),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(bgCardHover),
        dataRowColor:    WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? bgCardHover : null),
        headingTextStyle: const TextStyle(color: textSecondary, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 0.8, fontFamily: 'Inter'),
        dataTextStyle:    const TextStyle(color: textPrimary, fontSize: 14, fontFamily: 'Inter'),
        dividerThickness: 0.5,
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columnSpacing:    20,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCardHover,
        contentTextStyle: const TextStyle(color: textPrimary, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        width: 420,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDefault),
        ),
        titleTextStyle: const TextStyle(color: textPrimary, fontSize: 18,
            fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        contentTextStyle: const TextStyle(color: textSecondary, fontSize: 14, fontFamily: 'Inter'),
      ),

      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor:        bgSidebar,
        unselectedIconTheme:    IconThemeData(color: textMuted, size: 22),
        selectedIconTheme:      IconThemeData(color: primary,   size: 22),
        unselectedLabelTextStyle: TextStyle(color: textMuted, fontSize: 12),
        selectedLabelTextStyle:   TextStyle(color: primary,   fontSize: 12, fontWeight: FontWeight.w600),
        indicatorColor: primaryGlow,
        elevation:      0,
      ),

      listTileTheme: const ListTileThemeData(
        tileColor:      Colors.transparent,
        textColor:      textPrimary,
        iconColor:      textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color:  bgCardHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderSubtle),
        ),
        textStyle: const TextStyle(color: textPrimary, fontSize: 12, fontFamily: 'Inter'),
        waitDuration: const Duration(milliseconds: 500),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    );
  }

  // ── Light palette ──────────────────────────────────────────────────────────
  static const Color lBgBase        = Color(0xFFF5F7FA);
  static const Color lBgSurface     = Color(0xFFFFFFFF);
  static const Color lBgCard        = Color(0xFFFFFFFF);
  static const Color lBgSidebar     = Color(0xFFFFFFFF);
  static const Color lBorderSubtle  = Color(0xFFE4E9F0);
  static const Color lBorderDefault = Color(0xFFCDD5E0);
  static const Color lTextPrimary   = Color(0xFF0F1728);
  static const Color lTextSecondary = Color(0xFF5A6880);
  static const Color lTextMuted     = Color(0xFF9AAABF);

  static ThemeData get light {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary:    primary,
      onPrimary:  Colors.white,
      primaryContainer:   Color(0xFFDCEAFF),
      onPrimaryContainer: Color(0xFF003380),
      secondary:    accentViolet,
      onSecondary:  Colors.white,
      secondaryContainer:   Color(0xFFEAE8FF),
      onSecondaryContainer: Color(0xFF3A2E99),
      tertiary:   accent,
      onTertiary: Colors.white,
      tertiaryContainer:   Color(0xFFCCF4FF),
      onTertiaryContainer: Color(0xFF003E5C),
      error:   Color(0xFFD32F2F),
      onError: Colors.white,
      errorContainer:   Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF60001E),
      surface:   lBgSurface,
      onSurface: lTextPrimary,
      surfaceContainerLowest:  Color(0xFFF0F3F8),
      surfaceContainerLow:     lBgBase,
      surfaceContainer:        Color(0xFFF8FAFC),
      surfaceContainerHigh:    lBgCard,
      surfaceContainerHighest: Color(0xFFEBF0F7),
      onSurfaceVariant: lTextSecondary,
      outline:        lBorderDefault,
      outlineVariant: lBorderSubtle,
      shadow:         Color(0x1A000000),
      scrim:          Color(0x4D000000),
      inverseSurface:   lTextPrimary,
      onInverseSurface: lBgSurface,
      inversePrimary:   primary,
    );

    return ThemeData(
      useMaterial3:            true,
      colorScheme:             cs,
      fontFamily:              'Inter',
      scaffoldBackgroundColor: lBgBase,
      cardColor:               lBgCard,
      dividerColor:            lBorderSubtle,

      appBarTheme: const AppBarTheme(
        backgroundColor:        lBgSurface,
        foregroundColor:        lTextPrimary,
        elevation:              0,
        scrolledUnderElevation: 1,
        shadowColor:            Color(0x0F000000),
        surfaceTintColor:       Colors.transparent,
        titleTextStyle: TextStyle(
          color:      lTextPrimary,
          fontSize:   18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme:        IconThemeData(color: lTextSecondary),
        actionsIconTheme: IconThemeData(color: lTextSecondary),
      ),

      cardTheme: CardThemeData(
        color:     lBgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lBorderSubtle),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Color(0x0A000000),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: lBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: lBorderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentRed, width: 1.5),
        ),
        labelStyle:     TextStyle(color: lTextSecondary),
        hintStyle:      TextStyle(color: lTextMuted),
        prefixIconColor: lTextSecondary,
        suffixIconColor: lTextSecondary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation:       0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation:       0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side:            BorderSide(color: lBorderDefault),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        ),
      ),

      iconTheme: const IconThemeData(color: lTextSecondary, size: 20),

      dividerTheme: DividerThemeData(
        color:     lBorderSubtle,
        thickness: 1,
        space:     1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: lBgCard,
        side:            BorderSide(color: lBorderSubtle),
        labelStyle: TextStyle(color: lTextSecondary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      textTheme: TextTheme(
        displayLarge:   TextStyle(color: lTextPrimary, fontWeight: FontWeight.w700, fontSize: 48),
        displayMedium:  TextStyle(color: lTextPrimary, fontWeight: FontWeight.w700, fontSize: 40),
        displaySmall:   TextStyle(color: lTextPrimary, fontWeight: FontWeight.w600, fontSize: 34),
        headlineLarge:  TextStyle(color: lTextPrimary, fontWeight: FontWeight.w600, fontSize: 28),
        headlineMedium: TextStyle(color: lTextPrimary, fontWeight: FontWeight.w600, fontSize: 24),
        headlineSmall:  TextStyle(color: lTextPrimary, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge:  TextStyle(color: lTextPrimary,   fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: lTextPrimary,   fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall:  TextStyle(color: lTextSecondary, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge:   TextStyle(color: lTextPrimary,   fontSize: 15),
        bodyMedium:  TextStyle(color: lTextSecondary, fontSize: 14),
        bodySmall:   TextStyle(color: lTextMuted,     fontSize: 12),
        labelLarge:  TextStyle(color: lTextPrimary,   fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: TextStyle(color: lTextSecondary, fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall:  TextStyle(color: lTextMuted,     fontWeight: FontWeight.w400, fontSize: 11),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : lTextMuted),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Color(0xFFD0E8FF) : lBorderSubtle),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F4FA)),
        dataRowColor:    WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? const Color(0xFFF5F8FF) : null),
        headingTextStyle: TextStyle(color: lTextSecondary, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 0.8, fontFamily: 'Inter'),
        dataTextStyle:    TextStyle(color: lTextPrimary, fontSize: 14, fontFamily: 'Inter'),
        dividerThickness: 0.5,
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columnSpacing:    20,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: lTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior:  SnackBarBehavior.floating,
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: lBgCard,
        surfaceTintColor: Colors.transparent,
        elevation:   4,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: lTextPrimary, fontSize: 18,
          fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        contentTextStyle: TextStyle(color: lTextSecondary, fontSize: 14, fontFamily: 'Inter'),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color:        lTextPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter'),
        waitDuration: const Duration(milliseconds: 500),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    );
  }

  /// Derive ThemeMode from a settings map. Defaults to light.
  static ThemeMode themeModeFromSettings(Map<String, String> settings) {
    return (settings['theme_mode'] ?? 'light') == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}
