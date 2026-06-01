/// 人物组件 — 网页版用手绘 / 移动端用3D模型
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'avatar_painter.dart';

class ModelAvatar extends StatelessWidget {
  final double theta, phi, fallProbability;
  final String mode;
  final double size;
  final AvatarCharacter character;

  const ModelAvatar({
    super.key,
    required this.theta, required this.phi,
    required this.fallProbability, required this.mode,
    this.size = 300, this.character = AvatarCharacter.male,
  });

  static const _models = <AvatarCharacter, String>{
    AvatarCharacter.male:
        'https://readyplayerme.github.io/visage/male.glb',
    AvatarCharacter.female:
        'https://readyplayerme.github.io/visage/female.glb',
    AvatarCharacter.child:
        'https://readyplayerme.github.io/visage/male.glb',
  };

  @override
  Widget build(BuildContext context) {
    // 网页版直接用 Painter（WebView 不能在浏览器里嵌套）
    if (kIsWeb) return _painter();

    final url = _models[character] ?? _models[AvatarCharacter.male]!;
    final az = (phi % 360).toStringAsFixed(0);
    final el = (90.0 - theta).clamp(0, 90).toStringAsFixed(0);

    return SizedBox(
      width: size, height: size,
      child: ModelViewer(
        key: ValueKey('${character.name}_$az$el'),
        src: url,
        alt: '3D Avatar',
        ar: false,
        autoRotate: false,
        cameraControls: false,
        cameraOrbit: "${az}deg ${el}deg 1.2m",
        cameraTarget: '0m 1.0m 0m',
        fieldOfView: '45deg',
        disableZoom: true,
        disableTap: true,
        interactionPrompt: InteractionPrompt.none,
        loading: Loading.eager,
      ),
    );
  }

  Widget _painter() {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: AvatarPainter(
          theta: theta, phi: phi,
          fallProbability: fallProbability,
          mode: mode, time: 0,
          character: character,
        ),
      ),
    );
  }
}
