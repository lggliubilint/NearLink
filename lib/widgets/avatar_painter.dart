/// 人物姿态画笔 — 精致版
/// 修复: 跌倒不越界 / 行走更自然 / 五官更美观
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
    required this.theta, required this.phi,
    this.fallProbability = 0.0, this.mode = "standing",
    this.time = 0, this.character = AvatarCharacter.male,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 280;
    final cx = size.width / 2;
    // 跌倒时把整个画面往上移，保证人物不滑出
    final isFalling = mode == 'falling' || mode == 'fallen';
    final fallProgress = isFalling
        ? (((theta - 8).clamp(0, 65) - 20) / 45).clamp(0.0, 1.0)
        : 0.0;
    final cy = size.height / 2 - fallProgress * 55 * scale;

    canvas.save();
    canvas.translate(cx, cy);

    final phiRad = phi * math.pi / 180;
    final cosP = math.cos(phiRad), sinP = math.sin(phiRad);

    final bendDeg = (theta - 8.0).clamp(0, 70);
    final bendRad = bendDeg * math.pi / 180;

    final isWalking = mode == 'walking';
    final wp = time * 4.5; // 行走频率
    final armSwing = isWalking ? math.sin(wp) * 12.0 : 0.0;
    final legSwing = isWalking ? math.sin(wp + math.pi) * 8.0 : 0.0;
    final bodyBob = isWalking ? math.sin(wp * 2).abs() * 3.0 : 0.0;
    final kneeBend = fallProgress * 18.0;
    final armReach = fallProgress * 12.0;
    final fallSink = fallProgress * 30.0 * scale;

    // 体型
    double bw = 1.0, bh = 1.0, hs = 1.0;
    Color pantsColor, shoeColor;
    switch (character) {
      case AvatarCharacter.male:
        bw = 1.0; bh = 1.0; hs = 1.0;
        pantsColor = const Color(0xFF2C3E50);
        shoeColor = const Color(0xFF3D3025);
        break;
      case AvatarCharacter.female:
        bw = 0.85; bh = 0.95; hs = 0.92;
        pantsColor = const Color(0xFF6C3483);
        shoeColor = const Color(0xFF4A2C3D);
        break;
      case AvatarCharacter.child:
        bw = 0.6; bh = 0.6; hs = 1.3;
        pantsColor = const Color(0xFF2980B9);
        shoeColor = const Color(0xFF5DADE2);
        break;
    }

    Offset project(double x, double y, double z) {
      final rx = x * bw * cosP + z * sinP;
      final rz = -x * bw * sinP + z * cosP;
      final ry = y * bh * (1.0 - bendRad * 0.06) - rz * 0.04;
      return Offset(rx * scale, ry * scale + fallSink);
    }

    (double, double, double) joint(double x, double y, double z, String n) {
      if (y < 2) (x, y, z) = _rotX(x, y, z, bendRad);
      if (isWalking) {
        switch (n) {
          case 'lh': z -= armSwing; y -= armSwing.abs() * 0.08; break;
          case 'rh': z += armSwing; y -= armSwing.abs() * 0.08; break;
          case 'le': z -= armSwing * 0.4; break;
          case 're': z += armSwing * 0.4; break;
          case 'lft': z += legSwing; y -= bodyBob; break;
          case 'rft': z -= legSwing; y -= bodyBob; break;
          case 'lkn': z += legSwing * 0.4; break;
          case 'rkn': z -= legSwing * 0.4; break;
        }
        if (y < 0) y -= bodyBob * 0.4;
      }
      if (isFalling) {
        switch (n) {
          case 'lkn': case 'rkn': z -= kneeBend; y -= kneeBend * 0.15; break;
          case 'lh': case 'rh': z -= armReach; y += armReach * 0.12; break;
          case 'le': case 're': z -= armReach * 0.4; break;
          case 'lft': case 'rft': y += fallProgress * 3; break;
        }
      }
      return (x, y, z);
    }

    Offset p(double x, double y, double z, [String n = '']) {
      final (jx, jy, jz) = joint(x, y, z, n);
      return project(jx, jy, jz);
    }

    final hd = p(0, -90 * bh, -2, 'hd');
    final nk = p(0, -62 * bh, -2, 'nk');
    final hp = p(0, 0, 0, 'hp');
    final ls = p(-18 * bw, -56 * bh, -3, 'ls');
    final rs = p(18 * bw, -56 * bh, -3, 'rs');
    final le = p(-22 * bw, -33 * bh, -7, 'le');
    final re = p(22 * bw, -33 * bh, -7, 're');
    final lh = p(-24 * bw, -14 * bh, -6, 'lh');
    final rh = p(24 * bw, -14 * bh, -6, 'rh');
    final lhi = p(-8 * bw, 0, -2, 'lhi');
    final rhi = p(8 * bw, 0, -2, 'rhi');
    final lkn = p(-10 * bw, 42 * bh, -3, 'lkn');
    final rkn = p(10 * bw, 42 * bh, -3, 'rkn');
    final lft = p(-10 * bw, 82 * bh, -1, 'lft');
    final rft = p(10 * bw, 82 * bh, -1, 'rft');

    final topColor = _statusColor();
    final skin = const Color(0xFFF8D5B8);
    final skinDark = const Color(0xFFD4A878);
    final skinLight = const Color(0xFFFDE8D5);
    final lw = 8.0 * scale;
    final shoeC = shoeColor;

    double dist(Offset a, Offset b) => (a - b).distance;

    // ── 地面阴影 ──
    final sCx = (lft.dx + rft.dx) / 2;
    final sCy = (lft.dy + rft.dy) / 2 + 7 * scale;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(sCx, sCy), width: 50 * scale * bw, height: 12 * scale),
      Paint()..color = const Color(0x14000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    void limb(Offset a, Offset b, Color c, [double wa = 1.0, double wb = 1.0]) {
      final d = dist(a, b);
      if (d < 1) return;
      final dx = (b.dy - a.dy) / d, dy = -(b.dx - a.dx) / d;
      final path = Path()
        ..moveTo(a.dx + dx * lw * wa, a.dy + dy * lw * wa)
        ..lineTo(b.dx + dx * lw * wb, b.dy + dy * lw * wb)
        ..lineTo(b.dx - dx * lw * wb, b.dy - dy * lw * wb)
        ..lineTo(a.dx - dx * lw * wa, a.dy - dy * lw * wa)
        ..close();
      canvas.drawPath(path, Paint()..color = c..style = PaintingStyle.fill);
    }

    // ── 躯干 (圆角梯形) ──
    final tLW = (ls - nk).distance * 0.85;
    final tRW = (rs - nk).distance * 0.85;
    final tBW = (lhi - hp).distance * 0.85;
    final torso = Path()
      ..moveTo(nk.dx - tLW, nk.dy)..lineTo(nk.dx + tRW, nk.dy)
      ..quadraticBezierTo(hp.dx + tBW + 5 * scale, (nk.dy + hp.dy) / 2, hp.dx + tBW, hp.dy)
      ..lineTo(hp.dx - tBW, hp.dy)
      ..quadraticBezierTo(hp.dx - tBW - 5 * scale, (nk.dy + hp.dy) / 2, nk.dx - tLW, nk.dy)
      ..close();
    canvas.drawPath(torso, Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.2, -1), end: const Alignment(0.2, 1),
        colors: [topColor, topColor.withValues(alpha: 0.50)])
        .createShader(Rect.fromPoints(nk, hp))..style = PaintingStyle.fill);

    // ── 头部 ──
    final headR = 17.0 * scale * hs;
    canvas.drawCircle(hd, headR, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        radius: 0.95,
        colors: [skinLight, skin, skinDark])
        .createShader(Rect.fromCircle(center: hd, radius: headR))..style = PaintingStyle.fill);

    // ── 头发 ──
    if (character != AvatarCharacter.child) {
      final hc = character == AvatarCharacter.female
          ? const Color(0xFF3D1C0A) : const Color(0xFF1F1008);
      final hp = Path()
        ..moveTo(hd.dx - headR * 0.9, hd.dy - headR * 0.1)
        ..quadraticBezierTo(hd.dx - headR * 1.02, hd.dy - headR * 1.3, hd.dx, hd.dy - headR * 1.3)
        ..quadraticBezierTo(hd.dx + headR * 1.02, hd.dy - headR * 1.3, hd.dx + headR * 0.9, hd.dy - headR * 0.1)
        ..quadraticBezierTo(hd.dx + headR * 0.55, hd.dy - headR * 0.55,
            hd.dx + headR * 0.35, hd.dy - headR * 1.05)
        ..quadraticBezierTo(hd.dx, hd.dy - headR * 0.2, hd.dx - headR * 0.35, hd.dy - headR * 1.05)
        ..quadraticBezierTo(hd.dx - headR * 0.55, hd.dy - headR * 0.55,
            hd.dx - headR * 0.9, hd.dy - headR * 0.1)
        ..close();
      canvas.drawPath(hp, Paint()..color = hc..style = PaintingStyle.fill);
    }

    // ── 面部 ──
    final eyeR = 2.8 * scale * hs;
    final eox = 6.0 * scale * hs, eoy = -2.5 * scale * hs;
    for (final ex in [-eox, eox]) {
      // 眼白
      canvas.drawOval(
        Rect.fromCenter(center: Offset(hd.dx + ex, hd.dy + eoy),
          width: eyeR * 2.2, height: eyeR * 1.5),
        Paint()..color = Colors.white..style = PaintingStyle.fill);
      // 瞳孔
      canvas.drawCircle(
        Offset(hd.dx + ex + 0.4 * scale * hs, hd.dy + eoy + 0.3 * scale * hs),
        eyeR * 0.5, Paint()..color = const Color(0xFF1C0E04)..style = PaintingStyle.fill);
      // 高光
      canvas.drawCircle(
        Offset(hd.dx + ex - 0.6 * scale * hs, hd.dy + eoy - 0.8 * scale * hs),
        eyeR * 0.18, Paint()..color = Colors.white..style = PaintingStyle.fill);
    }
    // 眉毛
    for (final ex in [-eox, eox]) {
      canvas.drawLine(
        Offset(hd.dx + ex - eyeR * 1.0, hd.dy + eoy - eyeR * 1.5),
        Offset(hd.dx + ex + eyeR * 1.0, hd.dy + eoy - eyeR * 0.8),
        Paint()..color = const Color(0xFF3D1C0A)..strokeWidth = 1.8..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    }
    // 鼻子 (小圆点)
    canvas.drawCircle(Offset(hd.dx, hd.dy + 3.0 * scale * hs),
      1.8 * scale * hs, Paint()..color = skinDark.withValues(alpha: 0.4)..style = PaintingStyle.fill);
    // 嘴巴 (微笑弧线)
    final mouthY = hd.dy + 6.0 * scale * hs;
    canvas.drawPath(
      Path()..moveTo(hd.dx - 4.0 * scale, mouthY)
            ..quadraticBezierTo(hd.dx - 1.5 * scale, mouthY - 1.2 * scale,
                hd.dx, mouthY)
            ..quadraticBezierTo(hd.dx + 1.5 * scale, mouthY - 1.2 * scale,
                hd.dx + 4.0 * scale, mouthY),
      Paint()..color = const Color(0xFFD48888)..style = PaintingStyle.stroke
             ..strokeWidth = 1.8..strokeCap = StrokeCap.round);

    // ── 颈 ──
    final neckBot = Offset((ls.dx + rs.dx) / 2, (ls.dy + rs.dy) / 2 + 3 * scale);
    limb(nk, neckBot, skin, 0.5, 0.5);

    // ── 肩/髋 ──
    limb(nk, ls, topColor.withValues(alpha: 0.65), 0.55, 0.85);
    limb(nk, rs, topColor.withValues(alpha: 0.65), 0.55, 0.85);
    limb(hp, lhi, pantsColor, 0.65, 1.05);
    limb(hp, rhi, pantsColor, 0.65, 1.05);

    // ── 腿 ──
    limb(lhi, lkn, pantsColor, 1.05, 0.78);
    limb(rhi, rkn, pantsColor, 1.05, 0.78);
    limb(lkn, lft, pantsColor, 0.78, 0.55);
    limb(rkn, rft, pantsColor, 0.78, 0.55);

    // ── 臂 ──
    limb(ls, le, topColor.withValues(alpha: 0.65), 0.82, 0.68);
    limb(rs, re, topColor.withValues(alpha: 0.65), 0.82, 0.68);
    limb(le, lh, skin, 0.68, 0.52);
    limb(re, rh, skin, 0.68, 0.52);

    // ── 手 (椭圆更自然) ──
    for (final h in [lh, rh]) {
      canvas.drawOval(
        Rect.fromCenter(center: h, width: 10 * scale, height: 6 * scale),
        Paint()..color = skin..style = PaintingStyle.fill);
    }

    // ── 鞋 ──
    for (final ft in [lft, rft]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: ft, width: 16 * scale, height: 9 * scale),
          Radius.circular(3 * scale)),
        Paint()..color = shoeC..style = PaintingStyle.fill);
    }

    // ── 地面线 ──
    final gy = (lft.dy + rft.dy) / 2 + 10 * scale;
    canvas.drawLine(Offset(-90 * scale, gy), Offset(90 * scale, gy),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, const Color(0x08000000), Colors.transparent])
          .createShader(Rect.fromLTRB(-90 * scale, gy, 90 * scale, gy + 1))
        ..strokeWidth = 1.0);

    canvas.restore();
  }

  static (double, double, double) _rotX(double x, double y, double z, double rad) {
    final c = math.cos(rad), s = math.sin(rad);
    return (x, y * c - z * s, y * s + z * c);
  }

  Color _statusColor() {
    if (fallProbability > 0.6) return const Color(0xFFE04040);
    if (fallProbability > 0.3) return const Color(0xFFF0A040);
    if (mode == "bending") return const Color(0xFFE0B830);
    if (mode == "walking") return const Color(0xFF40B880);
    return const Color(0xFF3498DB);
  }

  @override
  bool shouldRepaint(covariant AvatarPainter old) {
    return old.theta != theta || old.phi != phi
        || old.fallProbability != fallProbability || old.mode != mode
        || old.time != time || old.character != character;
  }
}
