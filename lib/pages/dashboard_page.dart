/// 仪表盘页 — Med-Tech 暗色 + 环形扫描仪 + 全设备模块
library;

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final double hhadm, fallProb;
  final double probWalking, probBending, probRecovery;
  final int classId;
  final String className;
  const DashboardPage({
    super.key,
    required this.data,
    required this.hhadm,
    required this.fallProb,
    this.probWalking = 1.0,
    this.probBending = 0.0,
    this.probRecovery = 0.0,
    this.classId = 0,
    this.className = 'walking',
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  final List<double> _hrHistory = List.generate(20, (_) => 72.0, growable: true);

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: 3.seconds)..repeat();
  }

  @override
  void dispose() { _scanCtrl.dispose(); super.dispose(); }

  Color _accent() {
    return switch (widget.classId) {
      2 => AppTheme.red,       // fall
      3 => AppTheme.amber,      // recovery
      1 => AppTheme.orange,     // bending
      _ => AppTheme.cyan,       // walking
    };
  }

  @override
  Widget build(BuildContext context) {
    final hr = (widget.data["heart_rate"] as num?)?.toInt() ?? 72;
    final spo2 = (widget.data["spo2"] as num?)?.toInt() ?? 98;
    final temp = (widget.data["body_temp"] as num?)?.toDouble() ?? 36.5;
    _hrHistory.removeAt(0); _hrHistory.add(hr.toDouble());

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      child: Column(children: [
        // 头部
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("生命体征监测", style: AppTheme.h1()),
            Text("全设备实时数据", style: AppTheme.body()),
          ]),
          _scanRing(),
        ]).animate().fadeIn(duration: 400.ms),
        SizedBox(height: 16.h),

        // 核心指标
        Row(children: [
          Expanded(child: _metric("心率", "$hr", "BPM", hr > 120 ? AppTheme.red : AppTheme.cyan, Icons.favorite)),
          SizedBox(width: 8.w),
          Expanded(child: _metric("血氧", "$spo2", "%", spo2 < 95 ? AppTheme.amber : AppTheme.green, Icons.bloodtype)),
          SizedBox(width: 8.w),
          Expanded(child: _metric("体温", temp.toStringAsFixed(1), "°C", temp > 37.3 ? AppTheme.red : AppTheme.cyan, Icons.thermostat)),
        ]).animate().fadeIn(delay: 100.ms),
        SizedBox(height: 12.h),

        // 心率波形
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cyan, boxShadow: [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.5), blurRadius: 8)])),
              SizedBox(width: 8.w),
              Text("心率波形", style: AppTheme.h2()),
              const Spacer(),
              Text("$hr BPM", style: AppTheme.mono(14, AppTheme.cyan)),
            ]),
            SizedBox(height: 10.h),
            SizedBox(height: 90.h, child: LineChart(_hrChart(), duration: 300.ms, curve: Curves.easeOut)),
          ]),
        ).animate().fadeIn(delay: 150.ms),
        SizedBox(height: 12.h),

        // 四分类概率 + HHADM
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: _accent(), boxShadow: [BoxShadow(color: _accent().withValues(alpha: 0.5), blurRadius: 8)])),
              SizedBox(width: 8.w),
              Text("运动状态分类", style: AppTheme.h2()),
              const Spacer(),
              Text(widget.className.toUpperCase(), style: AppTheme.mono(16, _accent())),
            ]),
            SizedBox(height: 12.h),
            _classProbBar("行走/站立", widget.probWalking, AppTheme.cyan, 0),
            SizedBox(height: 6.h),
            _classProbBar("弯腰", widget.probBending, AppTheme.orange, 1),
            SizedBox(height: 6.h),
            _classProbBar("跌倒 ⚠", widget.fallProb, AppTheme.red, 2),
            SizedBox(height: 6.h),
            _classProbBar("恢复", widget.probRecovery, AppTheme.amber, 3),
          ]),
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(height: 12.h),

        // HHADM
        GlassCard(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                Text("前腰高度", style: AppTheme.caption()),
                SizedBox(height: 4.h),
                Text(widget.hhadm.toStringAsFixed(0), style: AppTheme.mono(36, AppTheme.green)),
                Text("cm", style: AppTheme.caption()),
              ]),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                width: 80.w, height: 80.w,
                child: AnimatedBuilder(
                  animation: _scanCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _GaugePainter(progress: widget.fallProb, color: _accent(), colorAngle: _scanCtrl.value * 2 * math.pi),
                  ),
                ),
              ),
            ),
          ]),
        ).animate().fadeIn(delay: 220.ms),
      ]),
    );
  }

  Widget _metric(String l, String v, String u, Color c, IconData ic) {
    return GlassCard(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
      child: Column(children: [
        Icon(ic, size: 18.sp, color: c),
        SizedBox(height: 4.h),
        Text(v, style: AppTheme.mono(20, c)),
        Text(u, style: AppTheme.caption()),
        Text(l, style: AppTheme.caption().copyWith(fontSize: 9)),
      ]),
    );
  }

  LineChartData _hrChart() {
    final spots = List.generate(_hrHistory.length, (i) => FlSpot(i.toDouble(), _hrHistory[i]));
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 0.5)),
      titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false),
      minY: 0, maxY: 150,
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: AppTheme.cyan, barWidth: 2, isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppTheme.cyan.withValues(alpha: 0.15), AppTheme.cyan.withValues(alpha: 0.0)])))],
    );
  }

  Widget _classProbBar(String label, double prob, Color color, int id) {
    final isActive = widget.classId == id;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SizedBox(
          width: 80.w,
          child: Text(label, style: AppTheme.caption().copyWith(color: isActive ? color : AppTheme.textTertiary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: prob.clamp(0.0, 1.0),
              minHeight: 8.h,
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 42.w,
          child: Text("${(prob * 100).toInt()}%", textAlign: TextAlign.right, style: AppTheme.mono(12, isActive ? color : AppTheme.textTertiary)),
        ),
      ]),
    ]);
  }

  Widget _fallGauge() {
    final c = _accent();
    return SizedBox(
      width: 100.w, height: 100.w,
      child: AnimatedBuilder(
        animation: _scanCtrl,
        builder: (_, __) => CustomPaint(
          painter: _GaugePainter(progress: widget.fallProb, color: c, colorAngle: _scanCtrl.value * 2 * math.pi),
        ),
      ),
    );
  }

  Widget _scanRing() {
    return AnimatedBuilder(
      animation: _scanCtrl,
      builder: (_, __) => Container(
        width: 36.w, height: 36.w,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3), width: 1)),
        child: Center(child: Container(width: 7.w, height: 7.w,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cyan,
            boxShadow: [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.6), blurRadius: 8)]))),
      ),
    );
  }

}

class _GaugePainter extends CustomPainter {
  final double progress, colorAngle;
  final Color color;
  _GaugePainter({required this.progress, required this.color, required this.colorAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.4;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white.withValues(alpha: 0.04)..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round);
    final sweep = (progress * 2 * math.pi).clamp(0.0, 2 * math.pi);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -math.pi / 2, sweep, false, Paint()
      ..shader = SweepGradient(colors: [color.withValues(alpha: 0.3), color, color]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round);
    final sx = cx + math.cos(colorAngle - math.pi / 2) * (r - 4);
    final sy = cy + math.sin(colorAngle - math.pi / 2) * (r - 4);
    canvas.drawLine(Offset(cx, cy), Offset(sx, sy), Paint()..color = color.withValues(alpha: 0.12)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.progress != progress || o.colorAngle != colorAngle || o.color != color;
}
