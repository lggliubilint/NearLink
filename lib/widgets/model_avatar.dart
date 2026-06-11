/// 人物组件 — 真实 GLB 3D 数字人 + 全息座舱包装
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../theme/app_theme.dart';
import 'avatar_painter.dart';

class ModelAvatar extends StatelessWidget {
  final double theta, phi, fallProbability;
  final String mode;
  final double size;
  final AvatarCharacter character;
  final int age;

  const ModelAvatar({
    super.key,
    required this.theta,
    required this.phi,
    required this.fallProbability,
    required this.mode,
    this.size = 300,
    this.character = AvatarCharacter.male,
    this.age = 30,
  });

  static const _youngMaleModel = 'assets/ready_player_me_male_avatar_nearlink_animated.glb';
  static const _youngFemaleModel = 'assets/ready_player_me_female_avatar__vrchatgame.glb';
  static const _middleMaleModel = 'assets/the_character_of_an_office_worker.glb';
  static const _oldMaleModel = 'assets/an_elderly_man.glb';
  static const _childModel = 'assets/fhc_crying_child.glb';

  String get _modelPath {
    if (character == AvatarCharacter.child || age <= 12) return _childModel;
    if (character == AvatarCharacter.female) return _youngFemaleModel;
    if (age >= 60) return _oldMaleModel;
    if (age >= 40) return _middleMaleModel;
    return _youngMaleModel;
  }

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
          // 关键修复：Web/Chrome 也直接加载 GLB，不再回退到手绘 AvatarPainter。
          child: _model(),
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

  String get _animationName {
    final m = mode.toLowerCase();
    if (m == 'standing' || m == 'stand' || m == 'normal') return 'Idle';
    if (m.contains('walk')) return 'Walk';
    if (m.contains('bend')) return 'Bend';
    if (m.contains('recover') || m.contains('recovery')) return 'Recover';
    if (m.contains('fall')) return 'Fall';
    return 'Idle';
  }

  Widget _model() {
    final az = (phi % 360).toStringAsFixed(0);
    // 保持 UI 布局不动，只修正 3D 相机：距离拉远，避免模型只剩一个点或被裁掉。
    final el = (76.0 - theta * 0.28).clamp(50, 82).toStringAsFixed(0);
    final anim = _animationName;

    return SizedBox(
      width: size * 0.9,
      height: size * 0.94,
      child: ModelViewer(
        // 只在人物/动作切换时重建，不能把实时角度放进 key，否则每帧都会重新加载 GLB。
        key: ValueKey('${character.name}_${age}_${_modelPath}_$anim'),
        src: _modelPath,
        alt: 'NearLink 3D Avatar',
        ar: false,
        autoPlay: true,
        animationName: anim,
        autoRotate: false,
        cameraControls: false,
        cameraOrbit: '${az}deg ${el}deg 3.15m',
        cameraTarget: '0m 0.78m 0m',
        fieldOfView: '40deg',
        exposure: 1.12,
        shadowIntensity: 0.75,
        shadowSoftness: 0.88,
        disableZoom: true,
        disableTap: true,
        interactionPrompt: InteractionPrompt.none,
        loading: Loading.eager,
        backgroundColor: Colors.transparent,
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
        colors: [
          accent.withValues(alpha: 0.05),
          accent.withValues(alpha: 0.55),
          AppTheme.violet.withValues(alpha: 0.28),
          accent.withValues(alpha: 0.05),
        ],
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
