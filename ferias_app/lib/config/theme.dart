import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color primaryColor = Color(0xFF3169F5);
  static const Color primaryDarkColor = Color(0xFF1F4DD8);
  static const Color primarySoftColor = Color(0xFFEAF0FF);
  static const Color backgroundColor = Color(0xFFF6F7FB);
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF1E2128);
  static const Color mutedTextColor = Color(0xFF778091);
  static const Color hintColor = Color(0xFFA6AFBF);
  static const Color borderColor = Color(0xFFDCE3EF);
  static const Color shadowColor = Color(0xFF101828);
  static const Color successColor = Color(0xFF28B463);
  static const Color successSoftColor = Color(0xFFDDF7E7);
  static const Color warningColor = Color(0xFFF59E42);
  static const Color warningSoftColor = Color(0xFFFFEDD8);
  static const Color dangerColor = Color(0xFFEF5B57);
  static const Color dangerSoftColor = Color(0xFFFDE2E1);
  static const Color neutralColor = Color(0xFF98A2B3);
  static const Color neutralSoftColor = Color(0xFFF1F4F9);

  static const double radiusXs = 12;
  static const double radiusSm = 20;
  static const double radiusMd = 26;
  static const double radiusLg = 30;

  static const double spacingXs = 6;
  static const double spacingSm = 12;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  static List<BoxShadow> get softShadow => <BoxShadow>[
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: primarySoftColor,
      surface: surfaceColor,
      onSurface: textColor,
      onPrimary: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: const TextStyle(
          color: hintColor,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: mutedTextColor,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: textColor,
        suffixIconColor: mutedTextColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primaryColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: dangerColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: dangerColor, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 58),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 58),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B2230),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dividerColor: borderColor,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 29,
          height: 1.08,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          height: 1.12,
        ),
        headlineSmall: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          height: 1.18,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          height: 1.22,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          height: 1.28,
        ),
        bodyLarge: TextStyle(color: textColor, fontSize: 15, height: 1.42),
        bodyMedium: TextStyle(color: textColor, fontSize: 13.5, height: 1.42),
        bodySmall: TextStyle(
          color: mutedTextColor,
          fontSize: 12.5,
          height: 1.36,
        ),
        labelLarge: TextStyle(
          color: mutedTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          height: 1.2,
        ),
        labelMedium: TextStyle(
          color: mutedTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 10.5,
          height: 1.1,
        ),
      ),
    );
  }

  static Color statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'activo':
      case 'facturado':
      case 'aprobado':
      case 'finalizado':
      case 'pagada':
        return successColor;
      case 'borrador':
      case 'pendiente':
        return warningColor;
      case 'eliminado':
      case 'cancelado':
      case 'vencida':
      case 'error':
        return dangerColor;
      case 'inactivo':
      default:
        return neutralColor;
    }
  }

  static Color statusBackgroundColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'activo':
      case 'facturado':
      case 'aprobado':
      case 'finalizado':
      case 'pagada':
        return successSoftColor;
      case 'borrador':
      case 'pendiente':
        return warningSoftColor;
      case 'eliminado':
      case 'cancelado':
      case 'vencida':
      case 'error':
        return dangerSoftColor;
      case 'inactivo':
      default:
        return neutralSoftColor;
    }
  }
}
