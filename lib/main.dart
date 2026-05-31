/// NearLink 星闪跌倒检测 — 高端健康监测 App
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'pages/avatar_page.dart';
import 'pages/dashboard_page.dart';
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
        title: 'NearLink 星闪监护',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          scaffoldBackgroundColor: AppTheme.lightBg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.accent,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(elevation: 0),
          navigationBarTheme: NavigationBarThemeData(
            elevation: 0,
            height: 56.h,
            backgroundColor: AppTheme.lightCard.withValues(alpha: 0.95),
            indicatorColor: AppTheme.accent.withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith((s) =>
              AppTheme.caption(Brightness.light)),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: AppTheme.darkBg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.accent,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(elevation: 0),
          navigationBarTheme: NavigationBarThemeData(
            elevation: 0,
            height: 56.h,
            backgroundColor: AppTheme.darkCard.withValues(alpha: 0.95),
            indicatorColor: AppTheme.accent.withValues(alpha: 0.2),
            labelTextStyle: WidgetStateProperty.resolveWith((s) =>
              AppTheme.caption(Brightness.dark)),
          ),
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

  double _theta = 8.0, _phi = 0.0, _vdp = 1.0, _hhadm = 100.0, _fallProb = 0.0;
  String _mode = "standing", _status = "connecting";
  AvatarCharacter _character = AvatarCharacter.male;

  Map<String, dynamic> _pillboxData = {};
  Map<String, dynamic> _scaleData = {};
  Map<String, dynamic> _braceletData = {};

  Timer? _simTimer, _animTimer;
  double _simFrame = 0, _animTime = 0, _prevFallProb = 0;

  @override
  void initState() {
    super.initState();
    _startDataFlow();
  }

  void _startDataFlow() {
    _api.statusStream.listen((s) => mounted ? setState(() => _status = s) : null);
    _api.dataStream.listen(_onDataReceived);
    _api.start();

    _animTimer = Timer.periodic(50.ms, (_) {
      if (mounted) setState(() => _animTime += 0.05);
    });

    Future.delayed(2.seconds, () {
      if (_status != "connected" && mounted) {
        setState(() => _status = "simulated");
        _startSimulation();
      }
    });
  }

  void _onDataReceived(Map<String, dynamic> all) {
    if (!mounted) return;
    setState(() {
      final fall = all["fall_detection"] as Map<String, dynamic>?;
      if (fall != null) {
        _theta = (fall["theta"] as num?)?.toDouble() ?? _theta;
        _phi = (fall["phi"] as num?)?.toDouble() ?? _phi;
        _vdp = (fall["v_delta_phi"] as num?)?.toDouble() ?? _vdp;
        _hhadm = (fall["hhadm"] as num?)?.toDouble() ?? _hhadm;
        _fallProb = (fall["fall_probability"] as num?)?.toDouble() ?? _fallProb;
        _mode = fall["mode"] as String? ?? _mode;
      }
      _pillboxData = all["pillbox"] as Map<String, dynamic>? ?? {};
      _scaleData = all["scale"] as Map<String, dynamic>? ?? {};
      _braceletData = all["bracelet"] as Map<String, dynamic>? ?? {};
    });
    _checkAlert();
  }

  void _startSimulation() {
    const fps = 20;
    _simTimer = Timer.periodic((1000 ~/ fps).ms, (_) {
      _simFrame += 1.0 / fps;
      _generateSimulatedData();
    });
  }

  void _generateSimulatedData() {
    final t = _simFrame, phase = t % 8.0;
    double th = 8.0, ph = _phi, v = 1.0, hh = 100.0, fp = 0.0;
    String md = "standing";

    if (phase < 3) {
      md = "walking"; th = 8.0 + 3 * math.sin(t * 2.0);
      ph = (t * 15) % 360; v = 1.5; fp = 0.02;
    } else if (phase < 4) {
      final p = phase - 3; md = "bending";
      th = 8 + p * 35; v = 3 + p * 2; hh = 100 - p * 10; fp = 0.1 + p * 0.15;
    } else if (phase < 5) {
      final p = phase - 4; md = "falling";
      th = 8 + p * 55; v = 5 + p * 10; hh = 100 - p * 75; fp = 0.3 + p * 0.7;
    } else if (phase < 6.5) {
      md = "fallen"; th = 63; ph += 0.3; hh = 20; fp = 0.95;
    } else {
      final p = (phase - 6.5) / 1.5; md = "recovering";
      th = 63 - p * 55; hh = 20 + p * 80; fp = 0.95 - p * 0.9;
    }

    setState(() {
      _theta = th; _phi = ph % 360; _vdp = v; _hhadm = hh;
      _fallProb = fp; _mode = md;
      _pillboxData = {"compartment_open": t % 4 > 3.8, "servo_angle": (t % 4 > 3.8) ? 90.0 : 0.0, "body_temp": 36.5 + math.sin(t * 0.1) * 0.3, "voice_playing": t % 4 > 3.8, "voice_text": "请服用晚间维生素"};
      _scaleData = {"weight_kg": 70.5 + math.sin(t * 0.3) * 0.5, "pressure_raw": 2467.5 + math.sin(t * 0.3) * 17.5};
      _braceletData = {"heart_rate": (72 + math.sin(t * 0.5) * 8).toInt(), "spo2": (98 + math.sin(t * 0.3) * 1).toInt(), "step_count": (t * 2).toInt(), "touch_active": t % 3 < 0.2, "accel_x": double.parse((math.sin(t * 2) * 0.3).toStringAsFixed(3)), "accel_y": double.parse((math.cos(t * 2.5) * 0.2).toStringAsFixed(3)), "accel_z": double.parse((1.0 + math.sin(t * 1.5) * 0.1).toStringAsFixed(3)), "gyro_x": double.parse((math.sin(t * 1.5) * 5).toStringAsFixed(1)), "gyro_y": double.parse((math.cos(t * 2) * 3).toStringAsFixed(1)), "gyro_z": double.parse((math.sin(t * 3) * 2).toStringAsFixed(1))};
    });
    _checkAlert();
  }

  void _checkAlert() {
    if (_fallProb > 0.7 && _prevFallProb <= 0.7) {
      _alert.triggerFallAlert(probability: _fallProb, mode: _mode);
    } else if (_fallProb < 0.3 && _prevFallProb > 0.3) {
      _alert.cancelAlert();
    }
    _prevFallProb = _fallProb;
  }

  @override
  void dispose() {
    _api.dispose(); _simTimer?.cancel(); _animTimer?.cancel();
    _pageCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Scaffold(
      body: PageView(
        controller: _pageCtrl,
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          AvatarPage(
            theta: _theta, phi: _phi, vDeltaPhi: _vdp, hhadm: _hhadm,
            fallProbability: _fallProb, mode: _mode, status: _status,
            time: _animTime, character: _character,
            onCharacterChanged: (c) => setState(() => _character = c),
          ),
          DashboardPage(
            pillboxData: _pillboxData, scaleData: _scaleData,
            braceletData: _braceletData,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: AppTheme.cardBg(b),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: NavigationBar(
            selectedIndex: _currentPage,
            height: 54.h,
            onDestinationSelected: (i) => _pageCtrl.animateToPage(i, duration: 300.ms, curve: Curves.easeOutCubic),
            indicatorColor: AppTheme.accent.withValues(alpha: 0.12),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.accessibility_new_rounded), label: "姿态监测"),
              NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: "数据仪表盘"),
            ],
          ),
        ),
      ),
    );
  }
}
