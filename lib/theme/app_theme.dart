/// Med-Tech 暗色医疗科技风 — 数字孪生终端设计语言
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── 背景色系 ──
  static const bg = Color(0xFF0A0E21);
  static const surface = Color(0xFF141830);
  static const card = Color(0x1AFFFFFF); // 毛玻璃半透

  // ── 荧光强调色 ──
  static const cyan = Color(0xFF00E5FF);    // 正常
  static const amber = Color(0xFFFFB300);   // 预警
  static const red = Color(0xFFFF1744);     // 跌倒
  static const green = Color(0xFF00E676);

  // ── 文字色 ──
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0x8AEBEBF5);
  static const textTertiary = Color(0x6AEBEBF5);

  // ── 字体 ──
  static TextStyle h1() => GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textPrimary);
  static TextStyle h2() => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle body() => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5);
  static TextStyle caption() => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500, color: textTertiary, letterSpacing: 0.5);
  static TextStyle mono(double size, Color c) => GoogleFonts.jetBrainsMono(
    fontSize: size, fontWeight: FontWeight.w700, color: c, letterSpacing: -0.5);

  static const cardRadius = 16.0;
}
