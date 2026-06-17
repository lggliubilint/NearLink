/// NearLink 星闪跌倒检测 — Med-Tech 实时姿态终端
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'pages/avatar_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/device_page.dart';
import 'pages/profile_page.dart';
import 'services/alert_service.dart';
import 'services/huawei_api.dart';
import 'theme/app_theme.dart';
import 'widgets/avatar_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlertService().init();
  await AlertService().requestPermissions();
  runApp(const NearLinkApp());
}

class NearLinkApp extends StatelessWidget {
  const NearLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        title: 'NearLink DT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(primary: AppTheme.cyan, surface: AppTheme.surface),
          appBarTheme: const AppBarTheme(elevation: 0, backgroundColor: Colors.transparent),
          navigationBarTheme: NavigationBarThemeData(
            elevation: 0, height: 56.h, backgroundColor: AppTheme.surface,
            indicatorColor: AppTheme.cyan.withValues(alpha: 0.15),
            labelTextStyle: WidgetStateProperty.resolveWith((s) => AppTheme.caption())),
        ),
        home: const MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  final _api = HuaweiApiService();
  final _alert = AlertService();

  double _theta = 8, _phi = 0, _vdp = 1, _hhadm = 100, _fallProb = 0;
  double _probWalking = 1.0, _probBending = 0.0, _probRecovery = 0.0;
  int _classId = 0;
  String _className = 'walking';
  String _mode = "standing", _status = "connecting";
  UserProfile? _profile;
  bool _profileDone = false;
  Timer? _simTimer, _animTimer, _medTimer;
  double _simFrame = 0, _animTime = 0, _prevFallProb = 0;
  int _medicationCount = 0;

  @override
  void initState() {
    super.initState();
    _startDataFlow();
  }

  void _startDataFlow() {
    _api.statusStream.listen((s) => mounted ? setState(() => _status = s) : null);
    _api.dataStream.listen(_onData);
    _api.start();
    _animTimer = Timer.periodic(50.ms, (_) => mounted ? setState(() => _animTime += 0.05) : null);
    // 服药次数 0-4 循环, 每3秒
    _medTimer = Timer.periodic(3.seconds, (_) {
      if (mounted) setState(() => _medicationCount = (_medicationCount + 1) % 5);
    });
    Future.delayed(2.seconds, () {
      if (_status != "connected" && mounted) { setState(() => _status = "simulated"); _startSim(); }
    });
  }

  void _onData(Map<String, dynamic> all) {
    if (!mounted) return;
    setState(() {
      final f = all["fall_detection"] as Map<String, dynamic>?;
      if (f != null) {
        _theta = (f["theta"] as num?)?.toDouble() ?? _theta;
        _phi = (f["phi"] as num?)?.toDouble() ?? _phi;
        _vdp = (f["v_delta_phi"] as num?)?.toDouble() ?? _vdp;
        _hhadm = (f["hhadm"] as num?)?.toDouble() ?? _hhadm;
        _fallProb = (f["fall_probability"] as num?)?.toDouble() ?? _fallProb;
        _probWalking = (f["prob_walking"] as num?)?.toDouble() ?? _probWalking;
        _probBending = (f["prob_bending"] as num?)?.toDouble() ?? _probBending;
        _probRecovery = (f["prob_recovery"] as num?)?.toDouble() ?? _probRecovery;
        _classId = (f["class_id"] as num?)?.toInt() ?? _classId;
        _className = f["class_name"] as String? ?? _className;
        _mode = f["mode"] as String? ?? _mode;
      }
    });
    _checkAlert();
  }

  void _startSim() {
    const fps = 20;
    _simTimer = Timer.periodic((1000 ~/ fps).ms, (_) { _simFrame += 1.0 / fps; _genSim(); });
  }

  void _genSim() {
    final t = _simFrame;
    // 每 5 秒切换一次: 行走(5s) → 弯腰(5s) → 跌倒(5s) → 恢复(3s) → 循环
    const cycle = 18.0;  // 5+5+5+3 = 18s 一个完整周期
    final p = t % cycle;
    final hhBase = _profile?.hhadmBaseline ?? 100.0;
    final angleTh = _profile?.fallAngleThreshold ?? 20.0;
    final sens = _profile?.riskSensitivity ?? 0.6;

    double th = 8, ph = _phi, v = 1, hh = hhBase;
    double pw = 1.0, pb = 0.0, pf = 0.0, pr = 0.0;
    int cid = 0;
    String cn = 'walking', md = "standing";
    if (p < 5) {
      // 行走 5s
      md = "walking"; th = 8 + 3 * math.sin(t * 2); ph = (t * 15) % 360; v = 1.5;
      pw = 0.85; pb = 0.05; pf = 0.02; pr = 0.08; cid = 0; cn = 'walking';
    } else if (p < 10) {
      // 弯腰 5s
      final x = (p - 5) / 5.0; md = "bending";
      th = angleTh + x * (angleTh * 1.6); v = 3 + x * 2;
      hh = hhBase - x * (hhBase * 0.5);
      pw = 0.2 - x * 0.15; pb = 0.6 + x * 0.3; pf = 0.1 + x * 0.15 * sens; pr = 0.1 - x * 0.05;
      cid = 1; cn = 'bending';
    } else if (p < 15) {
      // 跌倒 5s
      final x = (p - 10) / 5.0; md = x > 0.6 ? "fallen" : "falling";
      th = angleTh + x * (80 - angleTh); v = 5 + x * 10;
      hh = hhBase - x * (hhBase * 0.88);
      pw = 0.05; pb = 0.1 - x * 0.08; pf = 0.3 * sens + x * 0.7 * sens; pr = 0.05;
      cid = 2; cn = 'fall';
    } else {
      // 恢复 3s
      final x = (p - 15) / 3.0; md = "recovering";
      th = 83 - x * (83 - angleTh * 0.4); hh = hhBase * 0.12 + x * (hhBase * 0.88);
      pw = 0.05 + x * 0.15; pb = 0.05; pf = (0.9 - x * 0.85) * sens; pr = 0.0 + x * 0.85;
      cid = 3; cn = 'recovery';
    }
    final fp = pf.clamp(0.0, 1.0);
    if (mounted) setState(() {
      _theta = th; _phi = ph % 360; _vdp = v; _hhadm = hh;
      _fallProb = fp; _probWalking = pw; _probBending = pb; _probRecovery = pr;
      _classId = cid; _className = cn; _mode = md;
    });
    _checkAlert();
  }

  void _checkAlert() {
    final alertTh = (_profile?.riskSensitivity ?? 0.6) * 1.05;
    if (_fallProb > alertTh && _prevFallProb <= alertTh) _alert.triggerFallAlert(probability: _fallProb, mode: _mode);
    else if (_fallProb < alertTh * 0.45 && _prevFallProb > alertTh * 0.45) _alert.cancelAlert();
    _prevFallProb = _fallProb;
  }

  @override
  void dispose() { _api.dispose(); _simTimer?.cancel(); _animTimer?.cancel(); _medTimer?.cancel(); _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_profileDone) {
      return ProfilePage(onComplete: (p) => setState(() { _profile = p; _profileDone = true; }));
    }

    final char = _profile?.character ?? AvatarCharacter.male;
    final age = _profile?.age ?? 30;
    return Scaffold(
      extendBody: true,
      body: AppScaffoldBackground(
        child: PageView(
        controller: _pageCtrl,
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          AvatarPage(theta: _theta, phi: _phi, vDeltaPhi: _vdp, hhadm: _hhadm,
            fallProbability: _fallProb, mode: _mode, status: _status,
            time: _animTime, character: char, age: age),
          DashboardPage(
            data: _genDashData(),
            hhadm: _hhadm,
            fallProb: _fallProb,
            probWalking: _probWalking,
            probBending: _probBending,
            probRecovery: _probRecovery,
            classId: _classId,
            className: _className,
          ),
          DevicePage(data: _genDashData(), medicationCount: _medicationCount),
        ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.045)]),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 28, offset: const Offset(0, 14))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: NavigationBar(
            selectedIndex: _currentPage, height: 58.h, backgroundColor: Colors.transparent,
            onDestinationSelected: (i) => _pageCtrl.animateToPage(i, duration: 300.ms, curve: Curves.easeOutCubic),
            indicatorColor: AppTheme.cyan.withValues(alpha: 0.12),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.accessibility_new), label: "实时姿态"),
              NavigationDestination(icon: Icon(Icons.ssid_chart), label: "仪表盘"),
              NavigationDestination(icon: Icon(Icons.devices_other), label: "智能设备"),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _genDashData() {
    final t = _simFrame;
    return {
      "heart_rate": (72 + math.sin(t * 0.5) * 8).toInt(),
      "spo2": (98 + math.sin(t * 0.3) * 1).toInt(),
      "step_count": (t * 2).toInt(),
      "body_temp": 36.5 + math.sin(t * 0.1) * 0.3,
    };
  }
}
