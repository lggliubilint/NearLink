/// NearLink 星闪跌倒检测 — Med-Tech 数字孪生终端
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'pages/avatar_page.dart';
import 'pages/dashboard_page.dart';
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
  Timer? _simTimer, _animTimer;
  double _simFrame = 0, _animTime = 0, _prevFallProb = 0;

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
    final t = _simFrame, p = t % 8;
    double th = 8, ph = _phi, v = 1, hh = 100;
    double pw = 1.0, pb = 0.0, pf = 0.0, pr = 0.0;
    int cid = 0;
    String cn = 'walking', md = "standing";
    if (p < 3) {
      md = "walking"; th = 8 + 3 * math.sin(t * 2); ph = (t * 15) % 360; v = 1.5;
      pw = 0.85; pb = 0.05; pf = 0.02; pr = 0.08; cid = 0; cn = 'walking';
    }
    else if (p < 4) {
      final x = p - 3; md = "bending"; th = 8 + x * 35; v = 3 + x * 2; hh = 100 - x * 10;
      pw = 0.2 - x * 0.15; pb = 0.6 + x * 0.3; pf = 0.1 + x * 0.15; pr = 0.1 - x * 0.05;
      cid = 1; cn = 'bending';
    }
    else if (p < 5) {
      final x = p - 4; md = "falling"; th = 8 + x * 55; v = 5 + x * 10; hh = 100 - x * 75;
      pw = 0.05; pb = 0.1 - x * 0.08; pf = 0.3 + x * 0.7; pr = 0.05;
      cid = 2; cn = 'fall';
    }
    else if (p < 6.5) {
      md = "fallen"; th = 63; ph += 0.3; hh = 20;
      pw = 0.02; pb = 0.03; pf = 0.92; pr = 0.03; cid = 2; cn = 'fall';
    }
    else {
      final x = (p - 6.5) / 1.5; md = "recovering"; th = 63 - x * 55; hh = 20 + x * 80;
      pw = 0.05 + x * 0.15; pb = 0.05; pf = 0.9 - x * 0.85; pr = 0.0 + x * 0.85;
      cid = 3; cn = 'recovery';
    }
    if (mounted) setState(() {
      _theta = th; _phi = ph % 360; _vdp = v; _hhadm = hh;
      _fallProb = pf; _probWalking = pw; _probBending = pb; _probRecovery = pr;
      _classId = cid; _className = cn; _mode = md;
    });
    _checkAlert();
  }

  void _checkAlert() {
    if (_fallProb > 0.7 && _prevFallProb <= 0.7) _alert.triggerFallAlert(probability: _fallProb, mode: _mode);
    else if (_fallProb < 0.3 && _prevFallProb > 0.3) _alert.cancelAlert();
    _prevFallProb = _fallProb;
  }

  @override
  void dispose() { _api.dispose(); _simTimer?.cancel(); _animTimer?.cancel(); _pageCtrl.dispose(); super.dispose(); }

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
              NavigationDestination(icon: Icon(Icons.person_search), label: "数字孪生"),
              NavigationDestination(icon: Icon(Icons.ssid_chart), label: "仪表盘"),
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
