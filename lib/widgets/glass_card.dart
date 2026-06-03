/// 高级毛玻璃卡片 — BackdropFilter + 渐变描边 + 柔和投影
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding, margin;
  final double? width, height, radius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool glow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.radius,
    this.borderColor,
    this.onTap,
    this.gradient,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppTheme.cardRadius;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: gradient ?? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.115),
            Colors.white.withValues(alpha: 0.035),
            Colors.white.withValues(alpha: 0.018),
          ],
        ),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.095),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          if (glow)
            BoxShadow(
              color: (borderColor ?? AppTheme.cyan).withValues(alpha: 0.18),
              blurRadius: 26,
              spreadRadius: -4,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Stack(children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.75, -0.9),
                    radius: 1.15,
                    colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
          ]),
        ),
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
