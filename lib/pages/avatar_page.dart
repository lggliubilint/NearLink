/// 数字孪生姿态页 — NearLink Pro 全息监护舱
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
  final int age;

  const AvatarPage({
    super.key,
    required this.theta,
    required this.phi,
    required this.vDeltaPhi,
    required this.hhadm,
    required this.fallProbability,
    required this.mode,
    required this.status,
    required this.time,
    this.character = AvatarCharacter.male,
    this.age = 30,
  });

  Color _accent() => fallProbability > 0.7 ? AppTheme.red : fallProbability > 0.3 ? AppTheme.amber : AppTheme.cyan;

  String get _modeText {
    if (fallProbability > 0.7) return '跌倒警告';
    if (fallProbability > 0.3) return '异常姿态';
    return switch (mode) {
      'walking' => '行走中',
      'bending' => '弯腰中',
      'falling' => '正在跌倒',
      'fallen' => '已倒地',
      'recovering' => '恢复中',
      _ => '正常站立',
    };
  }

  @override
  Widget build(BuildContext context) {
    final ac = _accent();
    final isDanger = fallProbability > 0.7;

    return Stack(children: [
      if (isDanger) Positioned.fill(child: _BreathingBg(color: ac)),
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 94.h),
        child: Column(children: [
          _appBar(ac).animate().fadeIn(duration: 420.ms).slideY(begin: -0.08),
          SizedBox(height: 16.h),
          _hero(ac).animate().fadeIn(duration: 520.ms).scale(begin: const Offset(0.98, 0.98)),
          SizedBox(height: 14.h),
          Row(children: [
            Expanded(child: _stat('俯仰角 θ', theta.toStringAsFixed(1), '°', AppTheme.cyan, Icons.straighten)),
            SizedBox(width: 10.w),
            Expanded(child: _stat('转向角 φ', (phi % 360).toStringAsFixed(0), '°', AppTheme.violet, Icons.explore)),
            SizedBox(width: 10.w),
            Expanded(child: _stat('速率 vΔΦ', vDeltaPhi.toStringAsFixed(1), '/s', AppTheme.amber, Icons.speed)),
          ]).animate().fadeIn(delay: 100.ms),
          SizedBox(height: 12.h),
          Row(children: [
            Expanded(child: _heightCard()),
            SizedBox(width: 10.w),
            Expanded(child: _riskMini(ac)),
          ]).animate().fadeIn(delay: 160.ms),
          SizedBox(height: 12.h),
          _riskPanel(ac).animate().fadeIn(delay: 220.ms),
        ]),
      ),
    ]);
  }

  Widget _hero(Color ac) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: ac.withValues(alpha: 0.22),
      glow: true,
      child: SizedBox(
        width: double.infinity,
        height: 356.h,
        child: Stack(alignment: Alignment.center, children: [
          Positioned(top: 18.h, left: 18.w, child: _tag('NEARLINK DIGITAL TWIN', ac)),
          Positioned(top: 18.h, right: 18.w, child: _tag('${(fallProbability * 100).toInt()}% RISK', ac)),
          Positioned.fill(child: CustomPaint(painter: _ScanLinesPainter(ac))),
          ModelAvatar(theta: theta, phi: phi, fallProbability: fallProbability, mode: mode, size: 310.w, character: character, age: age),
          Positioned(bottom: 18.h, left: 18.w, right: 18.w, child: _poseRail(ac)),
        ]),
      ),
    );
  }

  Widget _poseRail(Color ac) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Icon(Icons.accessibility_new, color: ac, size: 18.sp),
        SizedBox(width: 8.w),
        Text(_modeText, style: AppTheme.body().copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        const Spacer(),
        Text('HHADM ${hhadm.toStringAsFixed(0)}cm', style: AppTheme.caption().copyWith(color: AppTheme.green)),
      ]),
    );
  }

  Widget _appBar(Color ac) {
    final online = status == 'connected';
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('数字孪生', style: AppTheme.h1()),
        SizedBox(height: 4.h),
        Row(children: [
          Container(width: 7.w, height: 7.w, decoration: BoxDecoration(shape: BoxShape.circle, color: online ? AppTheme.green : AppTheme.amber, boxShadow: [BoxShadow(color: (online ? AppTheme.green : AppTheme.amber).withValues(alpha: 0.65), blurRadius: 9)])),
          SizedBox(width: 7.w),
          Text(online ? '华为云实时在线' : '离线仿真演示', style: AppTheme.caption()),
        ]),
      ]),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(colors: [ac.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.035)]),
          border: Border.all(color: ac.withValues(alpha: 0.28)),
        ),
        child: Text(_modeText, style: AppTheme.caption().copyWith(color: ac, fontWeight: FontWeight.w900)),
      ),
    ]);
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.18)), color: Colors.black.withValues(alpha: 0.15)),
      child: Text(text, style: AppTheme.caption().copyWith(color: color, fontSize: 9.sp)),
    );
  }

  Widget _stat(String l, String v, String u, Color c, IconData ic) {
    return GlassCard(
      padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 10.w),
      borderColor: c.withValues(alpha: 0.13),
      child: Column(children: [
        Icon(ic, size: 17.sp, color: c),
        SizedBox(height: 7.h),
        Text(l, style: AppTheme.caption().copyWith(fontSize: 9.sp)),
        SizedBox(height: 2.h),
        Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(v, style: AppTheme.mono(19.sp, c)),
          SizedBox(width: 2.w),
          Padding(padding: EdgeInsets.only(bottom: 3.h), child: Text(u, style: AppTheme.caption().copyWith(color: c))),
        ]),
      ]),
    );
  }

  Widget _heightCard() {
    return GlassCard(
      padding: EdgeInsets.all(14.w),
      borderColor: AppTheme.green.withValues(alpha: 0.14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.height, color: AppTheme.green, size: 18.sp), SizedBox(width: 8.w), Text('胸部距地高度', style: AppTheme.caption())]),
        SizedBox(height: 8.h),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(hhadm.toStringAsFixed(0), style: AppTheme.mono(30.sp, AppTheme.green)),
          SizedBox(width: 4.w),
          Padding(padding: EdgeInsets.only(bottom: 5.h), child: Text('cm', style: AppTheme.caption())),
        ]),
      ]),
    );
  }

  Widget _riskMini(Color ac) {
    return GlassCard(
      padding: EdgeInsets.all(14.w),
      borderColor: ac.withValues(alpha: 0.14),
      glow: fallProbability > 0.7,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.shield_outlined, color: ac, size: 18.sp), SizedBox(width: 8.w), Text('风险等级', style: AppTheme.caption())]),
        SizedBox(height: 8.h),
        Text(fallProbability > 0.7 ? 'HIGH' : fallProbability > 0.3 ? 'MID' : 'LOW', style: AppTheme.mono(30.sp, ac)),
      ]),
    );
  }

  Widget _riskPanel(Color ac) {
    return GlassCard(
      borderColor: ac.withValues(alpha: 0.18),
      glow: fallProbability > 0.7,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('跌倒风险分析', style: AppTheme.h2()),
          Text('${(fallProbability * 100).toInt()}%', style: AppTheme.mono(28.sp, ac)),
        ]),
        SizedBox(height: 12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fallProbability.clamp(0.0, 1.0),
            minHeight: 9.h,
            backgroundColor: Colors.white.withValues(alpha: 0.055),
            valueColor: AlwaysStoppedAnimation(ac),
          ),
        ),
        SizedBox(height: 10.h),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _level('安全', fallProbability < 0.25, AppTheme.cyan),
          _level('注意', fallProbability >= 0.25 && fallProbability < 0.5, AppTheme.amber),
          _level('危险', fallProbability >= 0.5, AppTheme.red),
        ]),
      ]),
    );
  }

  Widget _level(String text, bool on, Color color) {
    return Text(text, style: AppTheme.caption().copyWith(color: on ? color : AppTheme.textTertiary, fontWeight: on ? FontWeight.w900 : FontWeight.w600));
  }
}

class _ScanLinesPainter extends CustomPainter {
  final Color color;
  _ScanLinesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.045)..strokeWidth = 0.8;
    for (double y = 28; y < size.height - 50; y += 18) {
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanLinesPainter oldDelegate) => oldDelegate.color != color;
}

class _BreathingBg extends StatefulWidget {
  final Color color;
  const _BreathingBg({required this.color});
  @override
  State<_BreathingBg> createState() => _BreathingBgState();
}

class _BreathingBgState extends State<_BreathingBg> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: 900.ms)..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(color: widget.color.withValues(alpha: 0.035 + _ctrl.value * 0.08)),
    );
  }
}
