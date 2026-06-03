/// 人物组件 — 3D 模型 + 全息座舱包装；Web 自动降级手绘数字孪生
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../theme/app_theme.dart';
import 'avatar_painter.dart';

class ModelAvatar extends StatelessWidget {
  final double theta, phi, fallProbability;
  final String mode;
  final double size;
  final AvatarCharacter character;

  const ModelAvatar({
    super.key,
    required this.theta,
    required this.phi,
    required this.fallProbability,
    required this.mode,
    this.size = 300,
    this.character = AvatarCharacter.male,
  });

  static const _models = <AvatarCharacter, String>{
    AvatarCharacter.male: 'https://readyplayerme.github.io/visage/male.glb',
    AvatarCharacter.female: 'https://readyplayerme.github.io/visage/female.glb',
    AvatarCharacter.child: 'https://readyplayerme.github.io/visage/male.glb',
  };

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
        CustomPaint(size: Size(size, size), painter: _HologramPainter(_accent, fallProbability)),
        Transform.translate(
          offset: Offset(0, -size * 0.015),
          child: kIsWeb ? _painter() : _model(),
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

  Widget _model() {
    final url = _models[character] ?? _models[AvatarCharacter.male]!;
    final az = (phi % 360).toStringAsFixed(0);
    final el = (82.0 - theta * 0.48).clamp(42, 88).toStringAsFixed(0);

    return SizedBox(
      width: size * 0.9,
      height: size * 0.94,
      child: ModelViewer(
        key: ValueKey('${character.name}_${az}_$el'),
        src: url,
        alt: '3D Avatar',
        ar: false,
        autoRotate: false,
        cameraControls: false,
        cameraOrbit: '${az}deg ${el}deg 1.35m',
        cameraTarget: '0m 1.02m 0m',
        fieldOfView: '36deg',
        exposure: 1.08,
        shadowIntensity: 0.75,
        shadowSoftness: 0.88,
        disableZoom: true,
        disableTap: true,
        interactionPrompt: InteractionPrompt.none,
        loading: Loading.eager,
      ),
    );
  }

  Widget _painter() {
    return SizedBox(
      width: size * 0.86,
      height: size * 0.86,
      child: CustomPaint(
        painter: AvatarPainter(
          theta: theta,
          phi: phi,
          fallProbability: fallProbability,
          mode: mode,
          time: 0,
          character: character,
        ),
      ),
    );
  }
}

class _HologramPainter extends CustomPainter {
  final Color accent;
  final double risk;
  _HologramPainter(this.accent, this.risk);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.39;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = SweepGradient(
        colors: [accent.withValues(alpha: 0.05), accent.withValues(alpha: 0.55), AppTheme.violet.withValues(alpha: 0.28), accent.withValues(alpha: 0.05)],
      ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawCircle(c.translate(0, size.height * 0.1), r, ringPaint);
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, size.height * 0.285), width: size.width * 0.62, height: size.height * 0.12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.32),
    );

    final dotPaint = Paint()..color = accent.withValues(alpha: 0.5);
    for (var i = 0; i < 24; i++) {
      final a = i / 24 * math.pi * 2;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r + size.height * 0.1);
      canvas.drawCircle(p, i % 3 == 0 ? 1.7 : 1.0, dotPaint);
    }

    if (risk > 0.3) {
      canvas.drawCircle(
        c.translate(0, size.height * 0.1),
        r + 8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: risk * 0.22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HologramPainter oldDelegate) => oldDelegate.accent != accent || oldDelegate.risk != risk;
}
