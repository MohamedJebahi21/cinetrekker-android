import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light Theme
  static const Color lightBg = Color(0xFFF9F7F6);
  static const Color lightFg = Color(0xFF1C1F27);
  static const Color lightCard = Color(0xFFFDFCFC);
  static const Color lightPrimary = Color(0xFFB3232D);
  static const Color lightMuted = Color(0xFFEFEDEB);
  static const Color lightBorder = Color(0xFFDDD9D5);

  // Dark Theme
  static const Color darkBg = Color(0xFF0F1115);
  static const Color darkFg = Color(0xFFF2F0ED);
  static const Color darkCard = Color(0xFF191B1F);
  static const Color darkPrimary = Color(0xFFCE2732);
  static const Color darkMuted = Color(0xFF202227);
  static const Color darkBorder = Color(0xFF2E3138);

  // OLED Theme
  static const Color oledBg = Color(0xFF000000);
  static const Color oledFg = Color(0xFFFFFFFF);
  static const Color oledCard = Color(0xFF0D0D0D);
  static const Color oledPrimary = Color(0xFFD62934);
  static const Color oledMuted = Color(0xFF141414);
  static const Color oledBorder = Color(0xFF242424);
}
