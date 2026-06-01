/// 数字孪生姿态页 — Med-Tech 暗色
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/glass_card.dart';
import '../widgets/model_avatar.dart';

class AvatarPage extends StatelessWidget {
  final double theta, phi, vDeltaPhi, hhadm, fallProbability;
  final String mode, status;
  final double time;
  final AvatarCharacter character;

  const AvatarPage({
    super.key,
    required this.theta, required this.phi, required this.vDeltaPhi,
    required this.hhadm, required this.fallProbability,
    required this.mode, required this.status, required this.time,
    this.character = AvatarCharacter.male,
  });

  Color _accent() => fallProbability > 0.7 ? AppTheme.red : fallProbability > 0.3 ? AppTheme.amber : AppTheme.cyan;

  @override
  Widget build(BuildContext context) {
    final ac = _accent();
    final isDanger = fallProbability > 0.7;

    return Stack(children: [
      // 背景呼吸脉冲（跌倒>80%时触发）
      if (isDanger)
        Positioned.fill(
          child: _BreathingBg(),
        ),

      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(children: [
            SizedBox(height: 12.h),
            _appBar(ac),
            SizedBox(height: 16.h),

            // ── 3D 数字孪生 ──
            GlassCard(
              padding: EdgeInsets.zero,
              borderColor: ac.withValues(alpha: 0.15),
              child: SizedBox(
                width: double.infinity, height: 320.h,
                child: Stack(alignment: Alignment.center, children: [
                  Positioned(bottom: 20.h,
                    child: Container(width: 120.w, height: 12.h,
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: ac.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 12)]))),
                  ModelAvatar(theta: theta, phi: phi, fallProbability: fallProbability, mode: mode, size: 280.w, character: character),
                  Positioned(top: 10.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r), border: Border.all(color: ac.withValues(alpha: 0.2))),
                      child: Text(status.toUpperCase(), style: AppTheme.caption().copyWith(color: ac))),
                  ),
                ]),
              ),
            ).animate().fadeIn(duration: 500.ms),

            SizedBox(height: 16.h),

            // ── 姿态数据 ──
            GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _num("θ 俯仰", theta.toStringAsFixed(1), "°", AppTheme.cyan, Icons.height),
                _num("φ 转向", (phi % 360).toStringAsFixed(0), "°", const Color(0xFF7C4DFF), Icons.explore),
                _num("vΔΦ", vDeltaPhi.toStringAsFixed(1), "/s", AppTheme.amber, Icons.speed),
              ]),
            ).animate().fadeIn(delay: 100.ms),

            SizedBox(height: 12.h),

            // ── HHADM 高度 ──
            GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(children: [
                Container(padding: EdgeInsets.all(8.w), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.green.withValues(alpha: 0.2))),
                  child: const Icon(Icons.height, size: 18, color: AppTheme.green)),
                SizedBox(width: 12.w),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("HHADM", style: AppTheme.caption().copyWith(letterSpacing: 2)),
                  SizedBox(height: 2.h),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(hhadm.toStringAsFixed(0), style: AppTheme.mono(24, AppTheme.green)),
                    SizedBox(width: 4.w),
                    Padding(padding: EdgeInsets.only(bottom: 4.h), child: Text("cm", style: AppTheme.caption()))]),
                ]),
              ]),
            ).animate().fadeIn(delay: 150.ms),

            SizedBox(height: 12.h),

            // ── 跌倒风险 ──
            GlassCard(
              borderColor: ac.withValues(alpha: 0.15),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("FALL RISK", style: AppTheme.caption().copyWith(letterSpacing: 3)),
                  Text("${(fallProbability * 100).toInt()}%", style: AppTheme.mono(28, ac)),
                ]),
                SizedBox(height: 8.h),
                ClipRRect(borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(value: fallProbability, minHeight: 6.h, backgroundColor: ac.withValues(alpha: 0.08), valueColor: AlwaysStoppedAnimation(ac))),
                SizedBox(height: 8.h),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("NORMAL", style: AppTheme.caption().copyWith(color: fallProbability < 0.25 ? AppTheme.cyan : AppTheme.textTertiary)),
                  Text("WARNING", style: AppTheme.caption().copyWith(color: fallProbability >= 0.25 && fallProbability < 0.5 ? AppTheme.amber : AppTheme.textTertiary)),
                  Text("DANGER", style: AppTheme.caption().copyWith(color: fallProbability >= 0.5 ? AppTheme.red : AppTheme.textTertiary)),
                ]),
              ]),
            ).animate().fadeIn(delay: 200.ms),

            SizedBox(height: 20.h),
          ]),
        ),
      ),
    ]);
  }

  Widget _appBar(Color ac) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("DIGITAL TWIN", style: AppTheme.caption().copyWith(letterSpacing: 3)),
        SizedBox(height: 4.h),
        Text("数字孪生", style: AppTheme.h1()),
        SizedBox(height: 2.h),
        Row(children: [
          Container(width: 6.w, height: 6.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: status == "connected" ? AppTheme.green : AppTheme.amber,
              boxShadow: [BoxShadow(color: (status == "connected" ? AppTheme.green : AppTheme.amber).withValues(alpha: 0.5), blurRadius: 6)])),
          SizedBox(width: 6.w),
          Text(status == "connected" ? "LIVE" : "SIM", style: AppTheme.caption()),
        ]),
      ]),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), border: Border.all(color: ac.withValues(alpha: 0.2))),
        child: Text(_modeText.toUpperCase(), style: AppTheme.caption().copyWith(color: ac, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _num(String l, String v, String u, Color c, IconData ic) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(ic, size: 14.sp, color: c.withValues(alpha: 0.6)),
      SizedBox(height: 4.h),
      Text(l, style: AppTheme.caption()),
      SizedBox(height: 2.h),
      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(v, style: AppTheme.mono(20, c)),
        SizedBox(width: 2.w),
        Padding(padding: EdgeInsets.only(bottom: 3.h), child: Text(u, style: AppTheme.caption().copyWith(color: c))),
      ]),
    ]);
  }

  String get _modeText {
    if (fallProbability > 0.7) return "FALL DETECTED";
    if (fallProbability > 0.3) return "ABNORMAL";
    return switch (mode) { "walking" => "Walking", "bending" => "Bending", "falling" => "Falling", "fallen" => "Fallen", "recovering" => "Recovering", _ => "Standing" };
  }
}

// ── 呼吸闪烁背景 ──
class _BreathingBg extends StatefulWidget {
  @override
  State<_BreathingBg> createState() => _BreathingBgState();
}

class _BreathingBgState extends State<_BreathingBg> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1.seconds)..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        color: AppTheme.red.withValues(alpha: 0.03 + _ctrl.value * 0.06),
      ),
    );
  }
}
