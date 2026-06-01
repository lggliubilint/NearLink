/// 仪表盘页 — Med-Tech 暗色 + 环形扫描仪 + 动态波形
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
  const DashboardPage({super.key, required this.data, required this.hhadm, required this.fallProb});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  final List<double> _hrHistory = List.generate(20, (_) => 72.0, growable: true);

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: 3.seconds)..repeat();
  }

  @override
  void dispose() { _scanCtrl.dispose(); super.dispose(); }

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
        // ── 头部 ──
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("VITAL SIGNS", style: AppTheme.caption().copyWith(letterSpacing: 3)),
            SizedBox(height: 4.h),
            Text("生命体征", style: AppTheme.h1()),
          ]),
          _scanRing(),
        ]).animate().fadeIn(duration: 400.ms),
        SizedBox(height: 20.h),

        // ── 核心指标 ──
        Row(children: [
          Expanded(child: _metric("HEART RATE", "$hr", "BPM", hr > 120 ? AppTheme.red : AppTheme.cyan, Icons.favorite)),
          SizedBox(width: 8.w),
          Expanded(child: _metric("SpO2", "$spo2", "%", spo2 < 95 ? AppTheme.amber : AppTheme.green, Icons.bloodtype)),
          SizedBox(width: 8.w),
          Expanded(child: _metric("TEMP", temp.toStringAsFixed(1), "°C", temp > 37.3 ? AppTheme.red : AppTheme.cyan, Icons.thermostat)),
        ]).animate().fadeIn(delay: 100.ms),

        SizedBox(height: 16.h),

        // ── 心率波形 ──
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cyan, boxShadow: [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.5), blurRadius: 8)])),
              SizedBox(width: 8.w),
              Text("心率波形", style: AppTheme.h2()),
              const Spacer(),
              Text("$hr BPM", style: AppTheme.mono(14, AppTheme.cyan)),
            ]),
            SizedBox(height: 12.h),
            SizedBox(height: 100.h, child: LineChart(_hrChart(), duration: 300.ms, curve: Curves.easeOut)),
          ]),
        ).animate().fadeIn(delay: 200.ms),

        SizedBox(height: 12.h),

        // ── 跌倒概率环形扫描仪 ──
        GlassCard(
          child: Column(children: [
            Text("FALL RISK", style: AppTheme.caption().copyWith(letterSpacing: 3)),
            SizedBox(height: 12.h),
            _fallGauge(),
            SizedBox(height: 8.h),
            Text("${(widget.fallProb * 100).toInt()}%", style: AppTheme.mono(36, _gaugeColor())),
            SizedBox(height: 4.h),
            Text(widget.fallProb > 0.7 ? "DANGER" : widget.fallProb > 0.3 ? "WARNING" : "NORMAL",
              style: AppTheme.caption().copyWith(color: _gaugeColor())),
          ]),
        ).animate().fadeIn(delay: 300.ms),
      ]),
    );
  }

  Widget _metric(String label, String val, String unit, Color c, IconData ic) {
    return GlassCard(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
      child: Column(children: [
        Icon(ic, size: 20.sp, color: c),
        SizedBox(height: 6.h),
        Text(val, style: AppTheme.mono(22, c)),
        Text(unit, style: AppTheme.caption()),
        SizedBox(height: 2.h),
        Text(label, style: AppTheme.caption().copyWith(fontSize: 9, letterSpacing: 1)),
      ]),
    );
  }

  Color _gaugeColor() => widget.fallProb > 0.7 ? AppTheme.red : widget.fallProb > 0.3 ? AppTheme.amber : AppTheme.cyan;

  LineChartData _hrChart() {
    final spots = List.generate(_hrHistory.length, (i) => FlSpot(i.toDouble(), _hrHistory[i]));
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 0.5)),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minY: 0, maxY: 150,
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: AppTheme.cyan, barWidth: 2, isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppTheme.cyan.withValues(alpha: 0.15), AppTheme.cyan.withValues(alpha: 0.0)]))),
      ],
    );
  }

  Widget _fallGauge() {
    final c = _gaugeColor();
    return SizedBox(
      width: 160.w, height: 160.w,
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
        width: 40.w, height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3), width: 1),
        ),
        child: Center(
          child: Container(
            width: 8.w, height: 8.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: AppTheme.cyan,
              boxShadow: [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.6), blurRadius: 8)]),
          ),
        ),
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
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.04)..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final sweep = (progress * 2 * math.pi).clamp(0.0, 2 * math.pi);
    final fgPaint = Paint()
      ..shader = SweepGradient(colors: [color.withValues(alpha: 0.3), color, color]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -math.pi / 2, sweep, false, fgPaint);

    // 扫描线
    final scanX = cx + math.cos(colorAngle - math.pi / 2) * (r - 6);
    final scanY = cy + math.sin(colorAngle - math.pi / 2) * (r - 6);
    canvas.drawLine(Offset(cx, cy), Offset(scanX, scanY), Paint()..color = color.withValues(alpha: 0.15)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.progress != progress || o.colorAngle != colorAngle || o.color != color;
}
