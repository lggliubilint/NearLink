/// Apple-style design system — 纯色 + 阴影 (无 BackdropFilter)
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const accent = Color(0xFF007AFF);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFFF9500);
  static const red = Color(0xFFFF3B30);
  static const teal = Color(0xFF5AC8FA);

  static const lightBg = Color(0xFFF2F2F7);
  static const darkBg = Color(0xFF000000);

  static const lightCard = Color(0xFFFFFFFF);
  static const darkCard = Color(0xFF1C1C1E);

  // ── 字体 (充分使用 google_fonts) ──
  static TextStyle h1(Brightness b) => GoogleFonts.inter(
    fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5,
    color: b == Brightness.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000));
  static TextStyle h2(Brightness b) => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w600,
    color: b == Brightness.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000));
  static TextStyle body(Brightness b) => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: b == Brightness.dark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43));
  static TextStyle caption(Brightness b) => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3,
    color: b == Brightness.dark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93));
  static TextStyle mono(double size, Color c) => GoogleFonts.jetBrainsMono(
    fontSize: size, fontWeight: FontWeight.w700, color: c);

  static const cardRadius = 16.0;

  static Color cardBg(Brightness b) => b == Brightness.dark ? darkCard : lightCard;
  static Color pageBg(Brightness b) => b == Brightness.dark ? darkBg : lightBg;
  static Color divider(Brightness b) =>
      b == Brightness.dark ? const Color(0x1AFFFFFF) : const Color(0x1A000000);
  static Color textDim(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
}
