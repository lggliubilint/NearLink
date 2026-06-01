/// 毛玻璃卡片 — 真·BackdropFilter + 荧光描边
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding, margin;
  final double? width, height;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key, required this.child,
    this.padding, this.margin, this.width, this.height,
    this.borderColor, this.onTap, this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width, height: height, margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        gradient: gradient,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.06), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: child,
          ),
        ),
      ),
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}
