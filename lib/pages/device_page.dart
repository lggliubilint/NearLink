/// 智能设备页 — 药盒 / 体重秤 / 手环 / 腰带
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class DevicePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final int medicationCount;

  const DevicePage({super.key, required this.data, this.medicationCount = 0});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _servoToggle = false;
  double _weight = 65.25;

  // 手环模拟 (参照 bearpi ws63_band demo_mode.c)
  int _steps = 1286;
  int _pkt = 0;
  int _stepTicks = 0;
  bool _touchActive = false;
  int _touchTimer = 0;
  // IMU 模拟
  double _accelX = 0.0, _accelY = 1.0, _accelZ = 0.0;
  double _gyroX = 0.0, _gyroY = 0.0, _gyroZ = 0.0;
  // 智能腰带模拟 (参照 BodyMotionSimulator)
  double _pcX = 0.05, _pcY = 1.80, _pcZ = 1.00;
  double _thetaSim = 8.0;
  int _beltTick = 0;
  int _beltModeIdx = 0;
  double _beltModeTimer = 60;
  double _tAlt = 0.0; // T 节点海拔
  double _pcAlt = 0.0; // Pc 节点海拔

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tick();
    _tickFast();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _servoToggle = !_servoToggle;
        _weight = 65.25 + (DateTime.now().millisecond % 100 - 50) / 1000;
      });
      _tick();
    });
  }

  void _tickFast() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final ms = DateTime.now().millisecond;
      _stepTicks++;
      // 步数缓慢递增，偶尔静止 (每15秒停3秒)
      final pause = (_stepTicks % 90 < 15);
      if (!pause && _stepTicks % 10 == 0) { // 每10 tick=2s 加一次
        final r = ms % 10;
        if (r < 7) _steps += 1;      // 70% +1步
        else _steps += 2;            // 30% +2步
      }
      // 包号递增
      if (ms < 200) _pkt++;
      // 触控: 偶发 2-3s (30% 概率触发)
      if (_touchTimer > 0) {
        _touchTimer--;
        _touchActive = true;
      } else if (ms % 100 < 8) {
        _touchTimer = 12 + (ms % 8);
        _touchActive = true;
      } else {
        _touchActive = false;
      }
      // IMU: 行走→波动大, 静止→波动小
      final amp = pause ? 0.15 : 1.0;
      _accelX = (ms % 5 - 2) * 0.04 * amp;
      _accelY = 0.98 + (ms % 7 - 3) * 0.03 * amp;
      _accelZ = (ms % 3 - 1) * 0.02 * amp;
      _gyroX  = (ms % 4 - 2) * 2.5 * amp;
      _gyroY  = (ms % 5 - 2) * 3.5 * amp;
      _gyroZ  = (ms % 3 - 1) * 1.8 * amp;
      // 智能腰带模拟 (参照 BodyMotionSimulator 模式循环)
      _simBelt();
      setState(() {});
      _tickFast();
    });
  }

  // ── 智能腰带模拟 (锚点距离 + 气压海拔) ──
  static const _anchors = [
    [0.0, 0.0, 0.80],   // S1/G1 左墙
    [1.0, 0.0, 0.80],   // S2/G2 右墙
    [0.0, 2.0, 0.00],   // 体重秤地面
  ];
  static const _beltModes = ['standing', 'walking', 'bending', 'standing', 'falling', 'fallen', 'recovering', 'walking'];
  static const _beltDurations = [60, 120, 40, 40, 30, 50, 60, 100];

  List<double> get _distsPc => List.generate(3, (i) {
    final dx = _pcX - _anchors[i][0];
    final dy = _pcY - _anchors[i][1];
    final dz = _pcZ - _anchors[i][2];
    return (dx * dx + dy * dy + dz * dz).clamp(0.0001, 100);
  });

  List<double> get _distsT {
    final tPos = _tPosition;
    return List.generate(3, (i) {
      final dx = tPos[0] - _anchors[i][0];
      final dy = tPos[1] - _anchors[i][1];
      final dz = tPos[2] - _anchors[i][2];
      return (dx * dx + dy * dy + dz * dz).clamp(0.0001, 100);
    });
  }

  List<double> get _tPosition {
    const rpt = 0.2;
    final th = _thetaSim * 3.14159 / 180;
    return [
      _pcX,
      _pcY,
      (_pcZ - rpt * th).clamp(0.05, 3.0),
    ];
  }

  void _simBelt() {
    _beltTick++;
    _beltModeTimer--;
    final mode = _beltModes[_beltModeIdx];
    if (mode == 'walking') {
      _pcX += 0.003;
      if (_pcX > 0.6) _pcX = 0.0;
      _thetaSim += (-0.3 + (_beltTick % 10) * 0.06).clamp(-0.3, 0.3);
      _thetaSim = _thetaSim.clamp(3, 18);
    } else if (mode == 'standing') {
      _thetaSim += (-0.15 + (_beltTick % 10) * 0.03).clamp(-0.15, 0.15);
      _thetaSim = _thetaSim.clamp(2, 15);
      _pcZ = 1.0;
    } else if (mode == 'bending') {
      _thetaSim = (_thetaSim + 0.8).clamp(8, 45);
      _pcZ = (1.0 - 0.15 * (1.0 - _beltModeTimer / 40)).clamp(0.85, 1.0);
    } else if (mode == 'falling') {
      _thetaSim = (_thetaSim + 2.0).clamp(8, 75);
      _pcZ = (1.0 - 0.9 * (1.0 - _beltModeTimer / 30)).clamp(0.1, 1.0);
    } else if (mode == 'fallen') {
      _pcZ = 0.1;
      _thetaSim = _thetaSim.clamp(50, 88);
    } else if (mode == 'recovering') {
      _thetaSim = (_thetaSim - 1.2).clamp(8, 75);
      _pcZ = (0.1 + 0.9 * (1.0 - _beltModeTimer / 60)).clamp(0.1, 1.0);
    }
    _pcAlt = 0.80 + _pcZ;
    _tAlt = 0.80 + _tPosition[2];
    if (_beltModeTimer <= 0) {
      _beltModeIdx = (_beltModeIdx + 1) % _beltModes.length;
      _beltModeTimer = _beltDurations[_beltModeIdx].toDouble();
    }
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  // ── 服药逻辑 (当前固定为1, 后续对接实时接口) ──
  int get _medCount => 1; // TODO: 对接实时服药数据
  bool get _noMeds => _medCount == 0;
  bool get _overdose => _medCount > 3;
  bool get _needMore => _medCount > 0 && _medCount < 3;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("智能设备", style: AppTheme.h1()),
            Text("星闪多设备协同监护终端", style: AppTheme.body()),
          ]),
          // 药盒红点
          if (_noMeds)
            Container(
              width: 12.w, height: 12.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.red,
                boxShadow: [BoxShadow(color: AppTheme.red.withValues(alpha: 0.6), blurRadius: 6)],
              ),
            ),
        ]).animate().fadeIn(duration: 400.ms),
        SizedBox(height: 14.h),

        // Tab 栏 (带红点)
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
              ),
              child: TabBar(
                controller: _tabCtrl,
                labelStyle: AppTheme.caption().copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: AppTheme.caption().copyWith(fontSize: 13),
                labelColor: AppTheme.cyan,
                unselectedLabelColor: AppTheme.textTertiary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: AppTheme.cyan.withValues(alpha: 0.1),
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: _noMeds
                        ? Badge(
                            isLabelVisible: true,
                            backgroundColor: AppTheme.red,
                            smallSize: 8,
                            child: const Icon(Icons.medication, size: 18),
                          )
                        : const Icon(Icons.medication, size: 18),
                    text: "药盒",
                  ),
                  const Tab(icon: Icon(Icons.monitor_weight, size: 18), text: "体重秤"),
                  const Tab(icon: Icon(Icons.watch, size: 18), text: "手环"),
                  const Tab(icon: Icon(Icons.cable, size: 18), text: "腰带"),
                ],
              ),
            ),
            SizedBox(
              height: 370.h,
              child: TabBarView(controller: _tabCtrl, children: [
                _pillboxTab(),
                _scaleTab(),
                _braceletTab(),
                _beltTab(),
              ]),
            ),
          ]),
        ).animate().fadeIn(delay: 100.ms),
      ]),
    );
  }

  // ── 药盒 (药仓固定, 服药次数当前=1, 后续对接实时接口) ──
  Widget _pillboxTab() {
    return ListView(padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h), children: [
      if (_noMeds) _redBanner("今日还未服药"),
      if (_needMore) _warnBanner("还需服 ${3 - _medCount} 次药"),
      if (_overdose) _redBanner("今日过量服药"),

      _voiceStrip(),

      SizedBox(height: 6.h),
      _statusCard(Icons.inventory_2, "药仓状态", true, "药仓一"),
      SizedBox(height: 8.h),
      _dataCard("舵机角度", "15.0", "°"),
      SizedBox(height: 8.h),

      Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(children: [
          const Icon(Icons.checklist, size: 18, color: AppTheme.cyan),
          SizedBox(width: 10.w),
          Text("今日已服药次数", style: AppTheme.caption()),
          const Spacer(),
          Text("$_medCount 次", style: AppTheme.mono(22, _medCount >= 3 ? AppTheme.green : AppTheme.amber)),
          Text(" / 3次", style: AppTheme.caption()),
        ]),
      ),
      if (_needMore)
        Container(
          margin: EdgeInsets.only(top: 6.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: AppTheme.amber.withValues(alpha: 0.08),
            border: Border.all(color: AppTheme.amber.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: AppTheme.amber),
            SizedBox(width: 6.w),
            Text("还需服 ${3 - _medCount} 次", style: AppTheme.caption().copyWith(color: AppTheme.amber)),
          ]),
        ),
    ]);
  }

  Widget _redBanner(String text) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: AppTheme.red.withValues(alpha: 0.10),
        border: Border.all(color: AppTheme.red.withValues(alpha: 0.30)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber, size: 16, color: AppTheme.red),
        SizedBox(width: 8.w),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.red)),
      ]),
    );
  }

  Widget _warnBanner(String text) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: AppTheme.amber.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.20)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, size: 16, color: AppTheme.amber),
        SizedBox(width: 8.w),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.amber)),
      ]),
    );
  }

  Widget _voiceStrip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: AppTheme.green.withValues(alpha: 0.06),
        border: Border.all(color: AppTheme.green.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6.w, height: 6.w,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.green,
            boxShadow: [BoxShadow(color: AppTheme.green.withValues(alpha: 0.5), blurRadius: 4)])),
        SizedBox(width: 8.w),
        Text("语音播报中", style: AppTheme.caption().copyWith(color: AppTheme.green)),
      ]),
    );
  }

  // ── 体重秤 ──
  Widget _scaleTab() {
    final raw = (_weight * 37.8 + (DateTime.now().millisecond % 20 - 10)).toStringAsFixed(0);
    final jin = (_weight * 2).toStringAsFixed(2);
    return ListView(padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h), children: [
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.15))),
        child: Column(children: [
          Text("体重", style: AppTheme.caption()),
          SizedBox(height: 6.h),
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_weight.toStringAsFixed(2), style: AppTheme.mono(36, AppTheme.cyan)),
            SizedBox(width: 4.w),
            Padding(padding: EdgeInsets.only(bottom: 6.h), child: Text("kg", style: AppTheme.caption())),
          ]),
          SizedBox(height: 2.h),
          Text("$jin 斤", style: AppTheme.caption().copyWith(color: AppTheme.textTertiary)),
        ]),
      ),
      SizedBox(height: 8.h),
      _dataCard("压力传感器", raw, "raw"),
    ]);
  }

  // ── 手环 (参照 bearpi ws63_band demo_mode.c) ──
  Widget _braceletTab() {
    return ListView(padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h), children: [
      _dataCard("步数", "$_steps", "步"),
      SizedBox(height: 4.h),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          color: AppTheme.cyan.withValues(alpha: 0.06),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text("包号 #$_pkt", style: AppTheme.caption()),
          const Spacer(),
          Text("上传成功", style: AppTheme.caption().copyWith(color: AppTheme.green)),
        ]),
      ),
      SizedBox(height: 8.h),
      _statusCard(Icons.touch_app, "触控面板", _touchActive, _touchActive ? "触发中" : "待机"),
      SizedBox(height: 10.h),
      Text("六轴传感器 (LSM6DSL)", style: AppTheme.h2()),
      SizedBox(height: 4.h),
      Text("加速度", style: AppTheme.caption()),
      SizedBox(height: 4.h),
      _axisRow("X", _accelX),
      SizedBox(height: 3.h),
      _axisRow("Y", _accelY),
      SizedBox(height: 3.h),
      _axisRow("Z", _accelZ),
      SizedBox(height: 8.h),
      Text("陀螺仪", style: AppTheme.caption()),
      SizedBox(height: 4.h),
      _axisRow("X", _gyroX),
      SizedBox(height: 3.h),
      _axisRow("Y", _gyroY),
      SizedBox(height: 3.h),
      _axisRow("Z", _gyroZ),
    ]);
  }

  // ── 通用组件 ──
  // ── 智能腰带 (参照 BodyMotionSimulator) ──
  Widget _beltTab() {
    final distsPc = _distsPc.map((d2) => math.sqrt(d2)).toList();
    final distsT = _distsT.map((d2) => math.sqrt(d2)).toList();
    return ListView(padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h), children: [
      // 当前姿态
      Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: AppTheme.cyan.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(children: [
          Text("当前姿态", style: AppTheme.caption()),
          const Spacer(),
          Text(_beltModes[_beltModeIdx], style: AppTheme.mono(14, AppTheme.cyan)),
          SizedBox(width: 6.w),
          Text("θ=${_thetaSim.toStringAsFixed(1)}°", style: AppTheme.caption()),
        ]),
      ),
      SizedBox(height: 8.h),
      // 电量
      Row(children: [
        Expanded(child: _beltBattery("Pc 节点", 94, AppTheme.cyan)),
        SizedBox(width: 8.w),
        Expanded(child: _beltBattery("T 节点", 93, AppTheme.green)),
      ]),
      SizedBox(height: 8.h),
      // BMP280 海拔
      Row(children: [
        Expanded(child: _dataCard("Pc 海拔", _pcAlt.toStringAsFixed(2), "m")),
        SizedBox(width: 8.w),
        Expanded(child: _dataCard("T 海拔", _tAlt.toStringAsFixed(2), "m")),
      ]),
      SizedBox(height: 8.h),
      // 锚点距离
      Text("三锚点 → Pc 距离", style: AppTheme.h2()),
      SizedBox(height: 4.h),
      _distRow("锚点1 (S1/G1)", distsPc[0] < 0 ? 0 : distsPc[0]),
      SizedBox(height: 3.h),
      _distRow("锚点2 (S2/G2)", distsPc[1] < 0 ? 0 : distsPc[1]),
      SizedBox(height: 3.h),
      _distRow("锚点3 (体秤)", distsPc[2] < 0 ? 0 : distsPc[2]),
      SizedBox(height: 10.h),
      Text("三锚点 → T 距离", style: AppTheme.h2()),
      SizedBox(height: 4.h),
      _distRow("锚点1 (S1/G1)", distsT[0] < 0 ? 0 : distsT[0]),
      SizedBox(height: 3.h),
      _distRow("锚点2 (S2/G2)", distsT[1] < 0 ? 0 : distsT[1]),
      SizedBox(height: 3.h),
      _distRow("锚点3 (体秤)", distsT[2] < 0 ? 0 : distsT[2]),
    ]);
  }

  Widget _beltBattery(String label, int pct, Color c) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), border: Border.all(color: c.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: AppTheme.caption()),
          const Spacer(),
          Icon(Icons.battery_std, size: 16, color: c),
          SizedBox(width: 4.w),
          Text("$pct%", style: AppTheme.mono(16, c)),
        ]),
        SizedBox(height: 4.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(3.r),
          child: LinearProgressIndicator(value: pct / 100, minHeight: 4.h,
            backgroundColor: Colors.white.withValues(alpha: 0.04), valueColor: AlwaysStoppedAnimation(c)),
        ),
      ]),
    );
  }

  Widget _distRow(String label, double distM) {
    final d = distM < 0 ? 0.0 : distM;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(children: [
        SizedBox(width: 90.w, child: Text(label, style: AppTheme.caption())),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(value: (d / 3).clamp(0.0, 1.0), minHeight: 3.h,
            backgroundColor: Colors.white.withValues(alpha: 0.04), valueColor: const AlwaysStoppedAnimation(AppTheme.cyan)),
        )),
        SizedBox(width: 8.w),
        Text(d.toStringAsFixed(2), style: AppTheme.mono(14, AppTheme.cyan)),
        Text(" m", style: AppTheme.caption()),
      ]),
    );
  }

  Widget _statusCard(IconData ic, String t, bool active, String text) {
    final c = active ? AppTheme.green : AppTheme.textTertiary;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(children: [
        Icon(ic, size: 18.sp, color: c),
        SizedBox(width: 10.w),
        Expanded(child: Text(t, style: AppTheme.body())),
        Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
        SizedBox(width: 6.w),
        Text(text, style: AppTheme.caption().copyWith(color: c)),
      ]),
    );
  }

  Widget _dataCard(String t, String v, String u) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: AppTheme.caption()),
        SizedBox(height: 4.h),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(v, style: AppTheme.mono(22, AppTheme.cyan)),
          SizedBox(width: 3.w),
          Padding(padding: EdgeInsets.only(bottom: 3.h), child: Text(u, style: AppTheme.caption())),
        ]),
      ]),
    );
  }

  Widget _axisRow(String l, double v) {
    return Row(children: [
      SizedBox(width: 60.w, child: Text(l, style: AppTheme.caption())),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2.r),
        child: LinearProgressIndicator(value: ((v.abs() / 10) + 0.05).clamp(0.0, 1.0), minHeight: 3.h, backgroundColor: Colors.white.withValues(alpha: 0.04), valueColor: const AlwaysStoppedAnimation(AppTheme.cyan)))),
      SizedBox(width: 8.w),
      Text(v.toStringAsFixed(2), style: AppTheme.caption()),
    ]);
  }
}
