/// 人物姿态画笔 — 男/女/儿童 三种体型 + 流畅动画
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

  static (double, double, double) _rotX(double x, double y, double z, double rad) {
    final c = math.cos(rad), s = math.sin(rad);
    return (x, y * c - z * s, y * s + z * c);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final scale = size.height / 250;
    canvas.save();
    canvas.translate(cx, cy);

    final phiRad = phi * math.pi / 180;
    final cosP = math.cos(phiRad);
    final sinP = math.sin(phiRad);

    const standTheta = 8.0;
    final bendDeg = (theta - standTheta).clamp(0, 80);
    final bendRad = bendDeg * math.pi / 180;

    final isFalling = mode == 'falling' || mode == 'fallen';
    final isWalking = mode == 'walking';
    final wp = time * 5.5;
    final armSwing = isWalking ? math.sin(wp) * 16.0 : 0.0;
    final legSwing = isWalking ? math.sin(wp + math.pi) * 10.0 : 0.0;
    final bodyBob = isWalking ? math.sin(wp * 2).abs() * 4.0 : 0.0;

    final fallProgress = isFalling ? ((bendDeg - 20) / 45).clamp(0.0, 1.0) : 0.0;
    final fallSink = fallProgress * 75.0 * scale;
    final kneeBend = fallProgress * 20.0;
    final armReach = fallProgress * 15.0;

    // 体型比例 (男/女/儿童)
    double bodyW = 1.0, bodyH = 1.0, headScale = 1.0;
    switch (character) {
      case AvatarCharacter.male:   bodyW = 1.0; bodyH = 1.0; headScale = 1.0; break;
      case AvatarCharacter.female: bodyW = 0.85; bodyH = 0.95; headScale = 0.95; break;
      case AvatarCharacter.child:  bodyW = 0.6; bodyH = 0.6; headScale = 1.25; break;
    }

    Offset project(double x, double y, double z) {
      final rx = x * bodyW * cosP + z * sinP;
      final rz = -x * bodyW * sinP + z * cosP;
      final ry = y * bodyH * (1.0 - bendRad * 0.08) - rz * 0.05;
      return Offset(rx * scale, ry * scale + fallSink);
    }

    (double, double, double) joint(double x, double y, double z, String n) {
      if (y < 2) (x, y, z) = _rotX(x, y, z, bendRad);
      if (isWalking) {
        switch (n) {
          case 'lh': z -= armSwing; y -= armSwing.abs() * 0.1; break;
          case 'rh': z += armSwing; y -= armSwing.abs() * 0.1; break;
          case 'lft': z += legSwing; y -= bodyBob; break;
          case 'rft': z -= legSwing; y -= bodyBob; break;
        }
        if (y < 0) y -= bodyBob * 0.5;
      }
      if (isFalling) {
        switch (n) {
          case 'lkn': case 'rkn': z -= kneeBend; y -= kneeBend * 0.2; break;
          case 'lh': case 'rh': z -= armReach; y += armReach * 0.15; break;
          case 'lft': case 'rft': y += fallProgress * 5; break;
        }
      }
      return (x, y, z);
    }

    Offset p(double x, double y, double z, [String n = '']) {
      final (jx, jy, jz) = joint(x, y, z, n);
      return project(jx, jy, jz);
    }

    final hd = p(0, -88 * bodyH, -2, 'hd');
    final nk = p(0, -60 * bodyH, -2, 'nk');
    final hp = p(0, 0, 0, 'hp');
    final ls = p(-18 * bodyW, -54 * bodyH, -4, 'ls');
    final rs = p(18 * bodyW, -54 * bodyH, -4, 'rs');
    final le = p(-22 * bodyW, -32 * bodyH, -10, 'le');
    final re = p(22 * bodyW, -32 * bodyH, -10, 're');
    final lh = p(-24 * bodyW, -12 * bodyH, -8, 'lh');
    final rh = p(24 * bodyW, -12 * bodyH, -8, 'rh');
    final lhi = p(-8 * bodyW, 0, -2, 'lhi');
    final rhi = p(8 * bodyW, 0, -2, 'rhi');
    final lkn = p(-10 * bodyW, 42 * bodyH, -4, 'lkn');
    final rkn = p(10 * bodyW, 42 * bodyH, -4, 'rkn');
    final lft = p(-10 * bodyW, 82 * bodyH, -2, 'lft');
    final rft = p(10 * bodyW, 82 * bodyH, -2, 'rft');

    // ── 颜色 ──
    final topColor = _statusColor();
    final skin = const Color(0xFFF5CBA7);
    final skinD = const Color(0xFFD4A878);
    final pants = const Color(0xFF34495E);
    final shoeC = const Color(0xFF2C2416);
    final lw = 8.5 * scale;

    double dist(Offset a, Offset b) => (a - b).distance;

    // 地面阴影
    final sCx = (lft.dx + rft.dx) / 2;
    final sCy = (lft.dy + rft.dy) / 2 + 6 * scale;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(sCx, sCy), width: 55 * scale * bodyW, height: 14 * scale),
      Paint()..color = const Color(0x18000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    void limb(Offset a, Offset b, Color fill, [double wa = 1.0, double wb = 1.0]) {
      final d = dist(a, b);
      if (d < 1) return;
      final dx = (b.dy - a.dy) / d, dy = -(b.dx - a.dx) / d;
      final path = Path()
        ..moveTo(a.dx + dx * lw * wa, a.dy + dy * lw * wa)
        ..lineTo(b.dx + dx * lw * wb, b.dy + dy * lw * wb)
        ..lineTo(b.dx - dx * lw * wb, b.dy - dy * lw * wb)
        ..lineTo(a.dx - dx * lw * wa, a.dy - dy * lw * wa)
        ..close();
      canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    }

    // 躯干
    final tLW = (ls - nk).distance * 0.85;
    final tRW = (rs - nk).distance * 0.85;
    final tBW = (lhi - hp).distance * 0.85;
    final torso = Path()
      ..moveTo(nk.dx - tLW, nk.dy)..lineTo(nk.dx + tRW, nk.dy)
      ..quadraticBezierTo(hp.dx + tBW + 4 * scale, (nk.dy + hp.dy) / 2, hp.dx + tBW, hp.dy)
      ..lineTo(hp.dx - tBW, hp.dy)
      ..quadraticBezierTo(hp.dx - tBW - 4 * scale, (nk.dy + hp.dy) / 2, nk.dx - tLW, nk.dy)
      ..close();
    canvas.drawPath(torso, Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.2, -1), end: const Alignment(0.2, 1),
        colors: [topColor, topColor.withValues(alpha: 0.55)])
        .createShader(Rect.fromPoints(nk, hp))..style = PaintingStyle.fill);

    // 头
    final headR = 16.0 * scale * headScale;
    canvas.drawCircle(hd, headR, Paint()
      ..shader = RadialGradient(center: const Alignment(-0.3, -0.3),
        colors: [const Color(0xFFFDE4D0), skin, skinD])
        .createShader(Rect.fromCircle(center: hd, radius: headR))..style = PaintingStyle.fill);

    // 头发 (只有 male/female 有)
    if (character != AvatarCharacter.child) {
      final hairColor = character == AvatarCharacter.female
          ? const Color(0xFF3A2010) : const Color(0xFF2A1608);
      final hairPath = Path()
        ..moveTo(hd.dx - headR * 0.9, hd.dy - headR * 0.1)
        ..quadraticBezierTo(hd.dx - headR, hd.dy - headR * 1.2, hd.dx, hd.dy - headR * 1.25)
        ..quadraticBezierTo(hd.dx + headR, hd.dy - headR * 1.2, hd.dx + headR * 0.9, hd.dy - headR * 0.1)
        ..quadraticBezierTo(hd.dx + headR * 0.6, hd.dy - headR * 0.6,
            hd.dx + headR * 0.4, hd.dy - headR * 1.0)
        ..quadraticBezierTo(hd.dx, hd.dy - headR * 0.3, hd.dx - headR * 0.4, hd.dy - headR * 1.0)
        ..quadraticBezierTo(hd.dx - headR * 0.6, hd.dy - headR * 0.6,
            hd.dx - headR * 0.9, hd.dy - headR * 0.1)
        ..close();
      canvas.drawPath(hairPath, Paint()..color = hairColor..style = PaintingStyle.fill);
    }

    // 眼睛
    final eyeR = 2.5 * scale * headScale;
    final eox = 5.5 * scale * headScale, eoy = -2.0 * scale * headScale;
    for (final ex in [-eox, eox]) {
      canvas.drawCircle(Offset(hd.dx + ex, hd.dy + eoy), eyeR,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(hd.dx + ex + 0.3 * scale, hd.dy + eoy + 0.3 * scale),
          eyeR * 0.5, Paint()..color = const Color(0xFF1A0E06)..style = PaintingStyle.fill);
    }

    // 嘴巴
    final mouthY = hd.dy + 5.5 * scale * headScale;
    canvas.drawPath(
      Path()..moveTo(hd.dx - 3 * scale, mouthY)
            ..quadraticBezierTo(hd.dx, mouthY + 2 * scale, hd.dx + 3 * scale, mouthY),
      Paint()..color = const Color(0xFFCC8888)..style = PaintingStyle.stroke
             ..strokeWidth = 1.5..strokeCap = StrokeCap.round);

    // 颈
    limb(nk, Offset((ls.dx + rs.dx) / 2, (ls.dy + rs.dy) / 2 + 3 * scale), skin, 0.5, 0.5);

    // 肩-髋连接
    limb(nk, ls, topColor.withValues(alpha: 0.7), 0.6, 0.85);
    limb(nk, rs, topColor.withValues(alpha: 0.7), 0.6, 0.85);
    limb(hp, lhi, pants, 0.7, 1.05);
    limb(hp, rhi, pants, 0.7, 1.05);

    // 腿
    limb(lhi, lkn, pants, 1.05, 0.8);
    limb(rhi, rkn, pants, 1.05, 0.8);
    limb(lkn, lft, pants, 0.8, 0.6);
    limb(rkn, rft, pants, 0.8, 0.6);

    // 臂
    final armC = topColor.withValues(alpha: 0.7);
    limb(ls, le, armC, 0.85, 0.7);
    limb(rs, re, armC, 0.85, 0.7);
    limb(le, lh, skin, 0.7, 0.55);
    limb(re, rh, skin, 0.7, 0.55);

    // 手
    for (final h in [lh, rh]) {
      canvas.drawCircle(h, 5 * scale, Paint()..color = skin..style = PaintingStyle.fill);
    }

    // 鞋
    for (final ft in [lft, rft]) {
      canvas.drawOval(Rect.fromCenter(center: ft, width: 14 * scale, height: 7 * scale),
          Paint()..color = shoeC..style = PaintingStyle.fill);
    }

    // 地面线
    final gy = (lft.dy + rft.dy) / 2 + 9 * scale;
    canvas.drawLine(Offset(-80 * scale, gy), Offset(80 * scale, gy),
      Paint()
        ..shader = LinearGradient(colors: [Colors.transparent, const Color(0x0A000000), Colors.transparent])
            .createShader(Rect.fromLTRB(-80 * scale, gy, 80 * scale, gy + 1))
        ..strokeWidth = 1.0);

    canvas.restore();
  }

  Color _statusColor() {
    if (fallProbability > 0.6) return const Color(0xFFE04040);
    if (fallProbability > 0.3) return const Color(0xFFF0A040);
    if (mode == "bending") return const Color(0xFFE0B830);
    if (mode == "walking") return const Color(0xFF40B880);
    return const Color(0xFF50A8D0);
  }

  @override
  bool shouldRepaint(covariant AvatarPainter old) {
    return old.theta != theta || old.phi != phi
        || old.fallProbability != fallProbability || old.mode != mode
        || old.time != time || old.character != character;
  }
}
