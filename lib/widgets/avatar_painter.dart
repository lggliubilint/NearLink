/// 数字孪生全息骨架 — CustomPainter 科幻风格
///
/// 头部: 空心光环圆环
/// 关节: 发光圆点
/// 骨骼: 发光线段连接
/// 风险: LOW=青蓝 / MID=琥珀 / HIGH=红+脉冲
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AvatarCharacter { male, female, child }

class AvatarPainter extends CustomPainter {
  final double theta, phi, fallProbability;
  final String mode;
  final double time;
  final AvatarCharacter character;

  AvatarPainter({
    required this.theta,
    required this.phi,
    this.fallProbability = 0.0,
    this.mode = 'standing',
    this.time = 0,
    this.character = AvatarCharacter.male,
  });

  // ── 风险颜色 ──
  Color get glowColor {
    if (fallProbability > 0.7) return const Color(0xFFFF3864); // HIGH 红
    if (fallProbability > 0.3) return const Color(0xFFFFC247); // MID 黄
    return const Color(0xFF12F7FF); // LOW 青蓝
  }

  bool get isHighRisk => fallProbability > 0.7;

  // ── 姿态判断 ──
  bool get isWalking => mode == 'walking';
  bool get isBending => mode == 'bending';
  bool get isFalling => mode == 'falling' || mode == 'fallen';
  bool get isRecovering => mode == 'recovering';
  bool get isStanding => !isWalking && !isBending && !isFalling && !isRecovering;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 280;
    final cx = size.width / 2;

    // 跌倒进度 (0→1): theta 偏离越大 → 身体越接近水平
    // fall 时 theta 从 8→83, recover 时 theta 从 83→8, 共用同一个映射
    final fallProgress = (isFalling || isRecovering)
        ? ((theta - 8).clamp(0, 75) / 75)
        : 0.0;
    final effectiveFall = fallProgress.clamp(0.0, 1.0);

    // 跌倒时画面往上移 + 身体下沉
    final fallLift = effectiveFall * 55 * scale;
    final fallDrop = effectiveFall * 50 * scale;
    final cy = size.height / 2 - fallLift;

    canvas.save();
    canvas.translate(cx, cy);

    // 行走参数
    final wp = time * 5.0;
    final armSwing = isWalking ? math.sin(wp) * 14.0 : 0.0;
    final legSwing = isWalking ? math.sin(wp + math.pi) * 10.0 : 0.0;
    final bodyBob = isWalking ? math.sin(wp * 2).abs() * 2.5 : 0.0;

    // 体型缩放 (儿童小一号)
    final bodyScale = character == AvatarCharacter.child ? 0.65 : 1.0;
    final bs = bodyScale;

    // ── 关节坐标计算 ──
    // 3D → 2D 投影 (简单的正交+轻微透视)
    final phiRad = phi * math.pi / 180;
    final cosP = math.cos(phiRad), sinP = math.sin(phiRad);

    // 旋转角度: 弯腰最大45°, 跌倒最大90° (完全水平)
    final bendDeg = isBending ? ((theta - 8).clamp(0, 45)) : effectiveFall * 90;
    final bendRad = bendDeg * math.pi / 180;

    Offset proj(double x, double y, double z) {
      final rx = x * cosP + z * sinP;
      final rz = -x * sinP + z * cosP;
      final ry = y - rz * 0.04;
      return Offset(rx * scale * bs, ry * scale * bs);
    }

    // 绕X轴旋转 (躯干前倾 / 跌倒)
    (double, double, double) rotX(double x, double y, double z) {
      final c = math.cos(bendRad), s = math.sin(bendRad);
      return (x, y * c - z * s, y * s + z * c);
    }

    Offset J(String id, double x, double y, double z) {
      var rx = x, ry = y, rz = z;
      // 跌倒/恢复: 全身旋转 (不再只转上半身)
      if (effectiveFall > 0.01) {
        (rx, ry, rz) = rotX(rx, ry, rz);
      } else if (y < 2) {
        (rx, ry, rz) = rotX(rx, ry, rz); // 站立时只上半身弯曲
      }
      // 行走动画
      if (isWalking) {
        switch (id) {
          case 'lh': rz -= armSwing; ry -= armSwing.abs() * 0.08; break;
          case 'rh': rz += armSwing; ry -= armSwing.abs() * 0.08; break;
          case 'le': rz -= armSwing * 0.4; break;
          case 're': rz += armSwing * 0.4; break;
          case 'lft': rz += legSwing; ry -= bodyBob; break;
          case 'rft': rz -= legSwing; ry -= bodyBob; break;
          case 'lkn': rz += legSwing * 0.4; break;
          case 'rkn': rz -= legSwing * 0.4; break;
        }
        if (y < 0) ry -= bodyBob * 0.4;
      }
      // 跌倒: 膝盖弯曲 + 手臂前伸 (更明显的姿势)
      if (effectiveFall > 0.1) {
        switch (id) {
          case 'lkn': case 'rkn': ry += effectiveFall * 24; break;
          case 'lft': case 'rft': ry += effectiveFall * 12;  break;
          case 'lh': case 'rh': ry -= effectiveFall * 28; break;
          case 'le': case 're': ry -= effectiveFall * 18; break;
        }
      }
      final p = proj(rx, ry, rz);
      return Offset(p.dx, p.dy + fallDrop);
    }

    // 关节定义
    final head = J('hd', 0, -92, 0);
    final neck = J('nk', 0, -65, 0);
    final lSh = J('ls', -18, -56, -1);
    final rSh = J('rs', 18, -56, -1);
    final lEl = J('le', -23, -34, -4);
    final rEl = J('re', 23, -34, -4);
    final lWr = J('lh', -25, -12, -3);
    final rWr = J('rh', 25, -12, -3);
    final midHip = J('hp', 0, 2, 0);
    final lHi = J('lhi', -8, 2, -1);
    final rHi = J('rhi', 8, 2, -1);
    final lKn = J('lkn', -10, 44, -1);
    final rKn = J('rkn', 10, 44, -1);
    final lAn = J('lft', -10, 84, 0);
    final rAn = J('rft', 10, 84, 0);

    // ── 绘制 ──

    // 脉冲强度 (HIGH 风险)
    final pulse = isHighRisk ? 0.55 + 0.45 * math.sin(time * 6.0) : 1.0;
    final glowAlpha = (0.6 + 0.4 * pulse).clamp(0.3, 1.0);

    // 骨架线样式
    final bonePaint = Paint()
      ..color = glowColor.withValues(alpha: 0.7 * glowAlpha)
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final boneGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.18 * glowAlpha)
      ..strokeWidth = 6.0 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final jointPaint = Paint()
      ..color = glowColor.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.fill;

    final jointGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.35 * glowAlpha)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    void bone(Offset a, Offset b) {
      if ((a - b).distance < 1) return;
      canvas.drawLine(a, b, boneGlowPaint);
      canvas.drawLine(a, b, bonePaint);
    }

    void joint(Offset p, double r) {
      canvas.drawCircle(p, r * 2.8, jointGlowPaint);
      canvas.drawCircle(p, r, jointPaint);
    }

    // ── 头部光环 ──
    final headR = 14.0 * scale * bs;
    // 外发光
    canvas.drawCircle(head, headR * 1.5, Paint()
      ..color = glowColor.withValues(alpha: 0.12 * glowAlpha)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    // 光环
    canvas.drawCircle(head, headR, Paint()
      ..color = glowColor.withValues(alpha: 0.6 * glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale);
    // 内点
    canvas.drawCircle(head, 3.0 * scale, jointPaint);

    // ── 颈部 ──
    bone(neck, Offset(0, head.dy + headR));
    joint(neck, 2.5 * scale);

    // ── 躯干 ──
    // 脊柱
    bone(neck, midHip);
    // 锁骨
    bone(neck, lSh);
    bone(neck, rSh);

    // ── 髋部横线 ──
    bone(lHi, rHi);

    // ── 骨盆连接 ──
    bone(midHip, lHi);
    bone(midHip, rHi);

    // ── 手臂 ──
    bone(lSh, lEl); bone(lEl, lWr);
    bone(rSh, rEl); bone(rEl, rWr);

    // ── 腿 ──
    bone(lHi, lKn); bone(lKn, lAn);
    bone(rHi, rKn); bone(rKn, rAn);

    // ── 关节发光点 ──
    const jR = 3.2; // 基础关节半径
    joint(lSh, jR * scale);
    joint(rSh, jR * scale);
    joint(lEl, jR * 0.85 * scale);
    joint(rEl, jR * 0.85 * scale);
    joint(lWr, jR * 0.7 * scale);
    joint(rWr, jR * 0.7 * scale);
    joint(midHip, jR * 1.2 * scale);
    joint(lHi, jR * scale);
    joint(rHi, jR * scale);
    joint(lKn, jR * 0.85 * scale);
    joint(rKn, jR * 0.85 * scale);
    joint(lAn, jR * 0.7 * scale);
    joint(rAn, jR * 0.7 * scale);

    // ── 地面参考线 ──
    final groundY = (lAn.dy + rAn.dy).abs() / 2 + 14 * scale + fallLift;
    // 只在站立/行走时显示更明显
    if (effectiveFall < 0.5) {
      canvas.drawLine(
        Offset(-50 * scale, groundY),
        Offset(50 * scale, groundY),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              glowColor.withValues(alpha: 0.25 * glowAlpha),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTRB(-50 * scale, groundY, 50 * scale, groundY + 1))
          ..strokeWidth = 0.8,
      );
    }

    // ── HIGH 风险脉冲光环 ──
    if (isHighRisk) {
      final pulseR = 95 * scale + math.sin(time * 5.5) * 18 * scale;
      canvas.drawCircle(
        proj(0, 10, 0),
        pulseR,
        Paint()
          ..color = glowColor.withValues(alpha: 0.09 * (0.6 + 0.4 * math.sin(time * 6)))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * scale
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AvatarPainter old) {
    return old.theta != theta ||
        old.phi != phi ||
        old.fallProbability != fallProbability ||
        old.mode != mode ||
        old.time != time ||
        old.character != character;
  }
}
