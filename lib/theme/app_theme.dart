/// NearLink Pro 暗色医疗科技风 — 高级数字孪生设计语言
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const bg = Color(0xFF050712);
  static const bg2 = Color(0xFF090D1D);
  static const surface = Color(0xFF11172A);
  static const surface2 = Color(0xFF18213A);
  static const card = Color(0x22FFFFFF);

  static const cyan = Color(0xFF12F7FF);
  static const blue = Color(0xFF3478FF);
  static const violet = Color(0xFF8B5CFF);
  static const amber = Color(0xFFFFC247);
  static const red = Color(0xFFFF3864);
  static const green = Color(0xFF2DFFB3);

  static const textPrimary = Color(0xFFF7FAFF);
  static const textSecondary = Color(0xB8EAF2FF);
  static const textTertiary = Color(0x72EAF2FF);

  static const cardRadius = 22.0;
  static const pillRadius = 999.0;

  static LinearGradient get appBgGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF071023), Color(0xFF050712), Color(0xFF100A24)],
  );

  static LinearGradient accentGradient([Color? accent]) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent ?? cyan, blue, violet],
  );

  static TextStyle h1() => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: textPrimary,
  );

  static TextStyle h2() => GoogleFonts.inter(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: textPrimary,
  );

  static TextStyle body() => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.45,
  );

  static TextStyle caption() => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textTertiary,
    letterSpacing: 0.55,
  );

  static TextStyle mono(double size, Color c) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: c,
    letterSpacing: -0.75,
  );
}

class AppScaffoldBackground extends StatelessWidget {
  final Widget child;
  const AppScaffoldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.appBgGradient),
      child: Stack(children: [
        const Positioned(top: -120, left: -90, child: _Aura(size: 260, color: AppTheme.cyan)),
        const Positioned(top: 120, right: -150, child: _Aura(size: 320, color: AppTheme.violet)),
        const Positioned(bottom: -140, left: 60, child: _Aura(size: 280, color: AppTheme.blue)),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _GridPainter()),
          ),
        ),
        child,
      ]),
    );
  }
}

class _Aura extends StatelessWidget {
  final double size;
  final Color color;
  const _Aura({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.6;
    const gap = 34.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
