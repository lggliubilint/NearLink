/// 卡片组件 — 纯色 + 阴影 (无 BackdropFilter，高性能)
library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;

  const GlassCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.color,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        color: color ?? AppTheme.cardBg(b),
        gradient: gradient,
        border: border ?? Border.all(
          color: AppTheme.divider(b), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: b == Brightness.dark ? 0.15 : 0.04),
            blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// 页面容器
class PageScaffold extends StatelessWidget {
  final Widget child;
  const PageScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      color: AppTheme.pageBg(b),
      child: SafeArea(child: child),
    );
  }
}
