import 'package:flutter/material.dart';

class AppColors {
  static const wood950 = Color(0xFF241609);
  static const wood900 = Color(0xFF3A2413);
  static const wood800 = Color(0xFF55341E);
  static const wood700 = Color(0xFF71481F);
  static const wood600 = Color(0xFF8A5A2C);
  static const gold300 = Color(0xFFE7C988);
  static const gold400 = Color(0xFFC9974F);
  static const cream100 = Color(0xFFFBF7EF);
  static const cream200 = Color(0xFFF4ECDB);
  static const cream300 = Color(0xFFECDFC4);
  static const canvas = Color(0xFFF2EAD9);
  static const ink = Color(0xFF2A1E10);
  static const inkSoft = Color(0xFF6F5A3C);
  static const line = Color(0xFFE5D7B8);
  static const danger = Color(0xFFAC3B3B);
  static const ok = Color(0xFF3F7D4A);
  static const wait = Color(0xFFB5822A);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.wood800,
    primary: AppColors.wood800,
    secondary: AppColors.gold400,
    surface: AppColors.cream100,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.wood900,
        ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.wood800,
        foregroundColor: AppColors.cream100,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.wood800,
        side: const BorderSide(color: AppColors.gold400, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.wood700),
    ),
  );
}

/// Dekorasi input yang seragam (tanpa bergantung pada tema global).
InputDecoration inputDec(String label, {String? hint}) {
  OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.gold400, 2),
    labelStyle: const TextStyle(color: AppColors.inkSoft),
  );
}
