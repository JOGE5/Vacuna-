import 'package:flutter/material.dart';

const ink = Color(0xFF123D30);
const green = Color(0xFF136F40);
const mint = Color(0xFFE6F4EC);
const muted = Color(0xFF5F6A69);
// Invierte la luminosidad y conserva la familia verde del diseño.
// Aplicado dos veces devuelve los colores originales de una ilustración.
const darkColorFilter = ColorFilter.matrix([
  0,
  -1,
  0,
  0,
  255,
  -1,
  0,
  0,
  0,
  255,
  0,
  0,
  -1,
  0,
  255,
  0,
  0,
  0,
  1,
  0,
]);
ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'VacunaSans',
  colorScheme: ColorScheme.fromSeed(
    seedColor: green,
    primary: green,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFFF7FBF9),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: ink, fontSize: 14),
    titleLarge: TextStyle(
      color: ink,
      fontWeight: FontWeight.bold,
      fontSize: 26,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDDE5E1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDDE5E1)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      side: BorderSide.none,
      shadowColor: Colors.transparent,
      backgroundColor: green,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: green,
      minimumSize: const Size(0, 48),
      side: const BorderSide(color: green),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);
