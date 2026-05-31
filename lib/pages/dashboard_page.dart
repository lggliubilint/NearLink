/// 数据仪表盘页 — fl_chart 趋势图 + 纯色卡片
library;

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> pillboxData, scaleData, braceletData;
  const DashboardPage({super.key, required this.pillboxData, required this.scaleData, required this.braceletData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final List<double> _hrHistory = List.generate(15, (_) => 0, growable: true);
  final List<double> _weightHistory = List.generate(10, (_) => 70.5, growable: true);
  double _prevWeight = 70.5;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _tickHistory() {
    final hr = (widget.braceletData["heart_rate"] as num?)?.toInt() ?? 72;
    final wt = (widget.scaleData["weight_kg"] as num?)?.toDouble() ?? 70.5;
    _hrHistory.removeAt(0); _hrHistory.add(hr.toDouble());
    if ((wt - _prevWeight).abs() > 0.01) { _weightHistory.removeAt(0); _weightHistory.add(wt); _prevWeight = wt; }
  }

  @override
  Widget build(BuildContext context) {
    _tickHistory();
    final b = Theme.of(context).brightness;
    final hr = (widget.braceletData["heart_rate"] as num?)?.toInt() ?? 0;
    final spo2 = (widget.braceletData["spo2"] as num?)?.toInt() ?? 0;
    final steps = (widget.braceletData["step_count"] as num?)?.toInt() ?? 0;
    final temp = (widget.pillboxData["body_temp"] as num?)?.toDouble() ?? 36.5;
    final weight = (widget.scaleData["weight_kg"] as num?)?.toDouble() ?? 0;

    return Column(children: [
      // App Bar
      Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("设备仪表盘", style: AppTheme.h1(b)),
            Text("全设备实时数据", style: AppTheme.body(b)),
          ]),
          Container(width: 44.w, height: 44.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.green.withValues(alpha: 0.12)),
            child: Icon(Icons.check_rounded, color: AppTheme.green, size: 22.sp)),
        ]).animate().fadeIn(duration: 300.ms),
      ),
      SizedBox(height: 16.h),

      // 生命体征摘要
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: GlassCard(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _vital("心率", "$hr", "BPM", hr > 120 ? AppTheme.red : AppTheme.accent, b),
            _div(b),
            _vital("血氧", "$spo2", "%", spo2 < 95 ? AppTheme.orange : AppTheme.green, b),
            _div(b),
            _vital("体温", temp.toStringAsFixed(1), "°C", temp > 37.3 ? AppTheme.red : AppTheme.accent, b),
            _div(b),
            _vital("体重", weight.toStringAsFixed(1), "kg", AppTheme.accent, b),
          ]),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
      ),
      SizedBox(height: 12.h),

      // 心率趋势图
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: EdgeInsets.all(5.w), decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent.withValues(alpha: 0.12)), child: Icon(Icons.show_chart_rounded, color: AppTheme.accent, size: 14.sp)),
              SizedBox(width: 8.w),
              Text("心率趋势", style: AppTheme.h2(b)),
              const Spacer(),
              Text("$hr BPM", style: AppTheme.mono(16, hr > 120 ? AppTheme.red : AppTheme.accent)),
            ]),
            SizedBox(height: 10.h),
            SizedBox(height: 90.h, child: LineChart(_hrChart(b), duration: 300.ms, curve: Curves.easeOut)),
          ]),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
      ),
      SizedBox(height: 12.h),

      // Tab 切换
      Expanded(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: TabBar(
                controller: _tabCtrl,
                labelStyle: AppTheme.caption(b).copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTheme.caption(b),
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textDim(b),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(borderRadius: BorderRadius.circular(10.r), color: AppTheme.accent.withValues(alpha: 0.1)),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(icon: Icon(Icons.medication_rounded, size: 18), text: "药盒"),
                  Tab(icon: Icon(Icons.monitor_weight_rounded, size: 18), text: "体重秤"),
                  Tab(icon: Icon(Icons.watch_rounded, size: 18), text: "手环"),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _pillboxTab(b),
              _scaleTab(b),
              _braceletTab(b, steps),
            ]),
          ),
        ]),
      ),
    ]);
  }

  LineChartData _hrChart(Brightness b) {
    final c = AppTheme.accent;
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20,
        getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.divider(b), strokeWidth: 0.5)),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minY: 0, maxY: 150,
      lineBarsData: [LineChartBarData(
        spots: List.generate(_hrHistory.length, (i) => FlSpot(i.toDouble(), _hrHistory[i])),
        isCurved: true, color: c, barWidth: 2.5, isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [c.withValues(alpha: 0.15), c.withValues(alpha: 0.0)]))),
      ],
    );
  }

  Widget _vital(String l, String v, String u, Color c, Brightness b) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l, style: AppTheme.caption(b)),
        SizedBox(height: 4.h),
        Text(v, style: AppTheme.mono(20, c)),
        Text(u, style: AppTheme.caption(b).copyWith(color: c, fontSize: 10)),
      ]),
    );
  }

  Widget _div(Brightness b) => Container(width: 0.5, height: 36.h, color: AppTheme.divider(b));

  Widget _pillboxTab(Brightness b) {
    final data = widget.pillboxData;
    final open = data["compartment_open"] == true || data["compartment_open"] == 1;
    final angle = (data["servo_angle"] as num?)?.toDouble() ?? 0;
    final temp = (data["body_temp"] as num?)?.toDouble() ?? 36.5;
    final playing = data["voice_playing"] == true || data["voice_playing"] == 1;
    final text = data["voice_text"] as String? ?? "";

    return ListView(padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h), children: [
      _statusCard(Icons.inventory_2_rounded, "药仓状态", open, "已打开 · 药仓解锁", "已关闭 · 药仓锁定", open ? AppTheme.green : Colors.grey, b),
      SizedBox(height: 8.h),
      Row(children: [
        Expanded(child: _metricCard("舵机角度", "${angle.toInt()}", "°", b)),
        SizedBox(width: 8.w),
        Expanded(child: _metricCard("红外体温", temp.toStringAsFixed(1), "°C", b)),
      ]),
      SizedBox(height: 8.h),
      _statusCard(Icons.record_voice_over_rounded, "语音播报", playing, text.isEmpty ? "播报中..." : text, "待机", playing ? AppTheme.orange : Colors.grey, b),
    ]);
  }

  Widget _scaleTab(Brightness b) {
    final data = widget.scaleData;
    final weight = (data["weight_kg"] as num?)?.toDouble() ?? 0;
    final onScale = weight > 1.0;

    return ListView(padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h), children: [
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: EdgeInsets.all(5.w), decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.green.withValues(alpha: 0.12)), child: Icon(Icons.trending_down_rounded, color: AppTheme.green, size: 14.sp)),
            SizedBox(width: 8.w),
            Text("体重趋势", style: AppTheme.h2(b)),
            const Spacer(),
            Text("${weight.toStringAsFixed(1)} kg", style: AppTheme.mono(16, AppTheme.green)),
          ]),
          SizedBox(height: 8.h),
          SizedBox(height: 70.h, child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false),
              minY: _weightHistory.reduce(math.min) - 0.5, maxY: _weightHistory.reduce(math.max) + 0.5,
              lineBarsData: [LineChartBarData(
                spots: List.generate(_weightHistory.length, (i) => FlSpot(i.toDouble(), _weightHistory[i])),
                isCurved: true, color: AppTheme.green, barWidth: 2.5, isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppTheme.green.withValues(alpha: 0.12), AppTheme.green.withValues(alpha: 0.0)]))),
              ],
            ), duration: 300.ms, curve: Curves.easeOut)),
        ]),
      ),
      SizedBox(height: 8.h),
      _statusCard(Icons.person_rounded, "称重状态", onScale, "称重中 · 传感器受力", "空载 · 请站上去", onScale ? AppTheme.green : Colors.grey, b),
    ]);
  }

  Widget _braceletTab(Brightness b, int steps) {
    final data = widget.braceletData;
    final hr = (data["heart_rate"] as num?)?.toInt() ?? 0;
    final spo2 = (data["spo2"] as num?)?.toInt() ?? 0;
    final touch = data["touch_active"] == true || data["touch_active"] == 1;
    final ax = (data["accel_x"] as num?)?.toDouble() ?? 0;
    final ay = (data["accel_y"] as num?)?.toDouble() ?? 0;
    final az = (data["accel_z"] as num?)?.toDouble() ?? 0;
    final gx = (data["gyro_x"] as num?)?.toDouble() ?? 0;
    final gy = (data["gyro_y"] as num?)?.toDouble() ?? 0;
    final gz = (data["gyro_z"] as num?)?.toDouble() ?? 0;

    return ListView(padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h), children: [
      GlassCard(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ring(hr / 200, hr > 120 ? AppTheme.red : AppTheme.accent, "$hr", "心率", "BPM"),
          _ring(spo2 / 100, spo2 < 95 ? AppTheme.orange : AppTheme.green, "$spo2", "血氧", "%"),
          _ring((steps % 10000) / 10000, AppTheme.green, "${(steps % 10000).toString().padLeft(4, '0')}", "步数", "步"),
        ]),
      ),
      SizedBox(height: 8.h),
      _statusCard(Icons.touch_app_rounded, "触控面板", touch, "触摸中", "待机", touch ? AppTheme.accent : Colors.grey, b),
      SizedBox(height: 8.h),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("六轴传感器", style: AppTheme.h2(b)),
          SizedBox(height: 8.h),
          _axisRow("加速度", ax, ay, az, b),
          SizedBox(height: 6.h),
          _axisRow("陀螺仪", gx, gy, gz, b),
        ]),
      ),
    ]);
  }

  Widget _ring(double v, Color c, String t, String l, String u) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 62.w, height: 62.w,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 56.w, height: 56.w,
            child: CircularProgressIndicator(value: v.clamp(0.0, 1.0), strokeWidth: 5, backgroundColor: c.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(c), strokeCap: StrokeCap.round)),
          Text(t, style: AppTheme.mono(16, c)),
        ])),
      SizedBox(height: 4.h),
      Text(l, style: AppTheme.caption(Theme.of(context).brightness)),
    ]);
  }

  Widget _axisRow(String label, double x, double y, double z, Brightness b) {
    return Row(children: [
      SizedBox(width: 45.w, child: Text(label, style: AppTheme.caption(b))),
      Expanded(child: _axisBar("X", x, b)),
      SizedBox(width: 4.w),
      Expanded(child: _axisBar("Y", y, b)),
      SizedBox(width: 4.w),
      Expanded(child: _axisBar("Z", z, b)),
    ]);
  }

  Widget _axisBar(String a, double v, Brightness b) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text("$a ${v.toStringAsFixed(v.abs() < 1 ? 2 : 1)}", style: AppTheme.caption(b).copyWith(fontSize: 9)),
      SizedBox(height: 2.h),
      ClipRRect(borderRadius: BorderRadius.circular(2.r),
        child: LinearProgressIndicator(value: ((v.abs() / 8) + 0.05).clamp(0.0, 1.0), minHeight: 3.h, backgroundColor: AppTheme.divider(b), valueColor: const AlwaysStoppedAnimation(AppTheme.accent))),
    ]);
  }

  Widget _statusCard(IconData ic, String title, bool active, String onT, String offT, Color c, Brightness b) {
    return GlassCard(
      child: Row(children: [
        Container(padding: EdgeInsets.all(7.w), decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.1)), child: Icon(ic, size: 18.sp, color: c)),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTheme.h2(b)),
          Text(active ? onT : offT, style: AppTheme.body(b).copyWith(color: active ? c : AppTheme.textDim(b), fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ])),
        Container(width: 10.w, height: 10.w, decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: active ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6)] : null)),
      ]),
    );
  }

  Widget _metricCard(String t, String v, String u, Brightness b) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: AppTheme.caption(b)),
        SizedBox(height: 4.h),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(v, style: AppTheme.mono(22, AppTheme.accent)),
          SizedBox(width: 2.w),
          Padding(padding: EdgeInsets.only(bottom: 3.h), child: Text(u, style: AppTheme.caption(b))),
        ]),
      ]),
    );
  }
}
