/// 全息骨架人 — CustomPainter 绘制 + 姿态动画 + 风险光环
library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'avatar_painter.dart';

class ModelAvatar extends StatelessWidget {
  final double theta, phi, fallProbability;
  final String mode;
  final double size;
  final AvatarCharacter character;
  final int age;
  final double time;

  const ModelAvatar({
    super.key,
    required this.theta,
    required this.phi,
    required this.fallProbability,
    required this.mode,
    this.size = 300,
    this.character = AvatarCharacter.male,
    this.age = 30,
    this.time = 0,
  });

  Color get _accent => fallProbability > 0.7
      ? AppTheme.red
      : fallProbability > 0.3
          ? AppTheme.amber
          : AppTheme.cyan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        // 骨架人 (AvatarPainter 内置了风险颜色逻辑)
        SizedBox(
          width: size * 0.9,
          height: size * 0.94,
          child: CustomPaint(
            painter: AvatarPainter(
              theta: theta,
              phi: phi,
              fallProbability: fallProbability,
              mode: mode,
              time: time,
              character: character,
            ),
          ),
        ),
        Positioned(
          bottom: size * 0.12,
          child: Container(
            width: size * 0.44,
            height: size * 0.035,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: _accent.withValues(alpha: 0.42), blurRadius: 34, spreadRadius: 10),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
