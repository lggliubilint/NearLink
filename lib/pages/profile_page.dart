/// 个人档案页 — 身份控制风险参数，非模型
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/glass_card.dart';

enum AgeGroup { child, youth, middle, elderly }

class UserProfile {
  AvatarCharacter character;
  int age;
  double heightCm;
  double weightKg;
  AgeGroup selectedGroup; // 用户显式选择的身份
  bool _ageDefaultsApplied = false;

  UserProfile({
    this.character = AvatarCharacter.male,
    this.age = 28,
    this.heightCm = 170,
    this.weightKg = 65,
    this.selectedGroup = AgeGroup.youth,
  });

  /// 直接返回用户选择的身份，不再从年龄推导
  AgeGroup get ageGroup => selectedGroup;

  String get ageGroupLabel => switch (ageGroup) {
    AgeGroup.child   => '儿童',
    AgeGroup.youth   => '青年',
    AgeGroup.middle  => '中年',
    AgeGroup.elderly => '老人',
  };

  /// 各年龄段默认年龄
  static int defaultAgeFor(AgeGroup g) => switch (g) {
    AgeGroup.child   => 8,
    AgeGroup.youth   => 28,
    AgeGroup.middle  => 50,
    AgeGroup.elderly => 72,
  };

  /// HHADM 基准高度 (cm)
  double get hhadmBaseline => switch (ageGroup) {
    AgeGroup.child   => 80.0,
    AgeGroup.youth   => 120.0,
    AgeGroup.middle  => 110.0,
    AgeGroup.elderly => 100.0,
  };

  /// 跌倒角度阈值 (°)
  double get fallAngleThreshold => switch (ageGroup) {
    AgeGroup.child   => 35.0,
    AgeGroup.youth   => 22.0,
    AgeGroup.middle  => 20.0,
    AgeGroup.elderly => 16.0,
  };

  /// 风险敏感度 (0~1)
  double get riskSensitivity => switch (ageGroup) {
    AgeGroup.child   => 0.45,
    AgeGroup.youth   => 0.55,
    AgeGroup.middle  => 0.70,
    AgeGroup.elderly => 0.90,
  };

  void applyAgeDefaults() {
    if (_ageDefaultsApplied) return;
    switch (ageGroup) {
      case AgeGroup.child:  heightCm = 120; weightKg = 25; break;
      case AgeGroup.youth:  heightCm = 170; weightKg = 65; break;
      case AgeGroup.middle: heightCm = 170; weightKg = 72; break;
      case AgeGroup.elderly:heightCm = 165; weightKg = 62; break;
    }
    _ageDefaultsApplied = true;
  }

  void markDefaultsApplied() => _ageDefaultsApplied = true;
}

class ProfilePage extends StatefulWidget {
  final void Function(UserProfile) onComplete;
  const ProfilePage({super.key, required this.onComplete});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profile = UserProfile();
  final _pageCtrl = PageController();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() {
      final p = (_pageCtrl.page ?? 0).round();
      if (p != _step && mounted) setState(() => _step = p);
    });
  }

  void _onNext() {
    if (_step == 4) {
      widget.onComplete(_profile);
    } else {
      _pageCtrl.nextPage(duration: 300.ms, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppScaffoldBackground(
        child: SafeArea(
        child: Stack(children: [
          // 内容区
          Column(children: [
            _ProgressBar(step: _step),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [_gender(), _identity(), _age(), _body(), _confirm()],
              ),
            ),
            const SizedBox(height: 80),
          ]),
          // 底部按钮
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
              child: Row(children: [
                if (_step > 0)
                  GestureDetector(
                    onTap: () => _pageCtrl.previousPage(duration: 300.ms, curve: Curves.easeOutCubic),
                    child: Container(
                      width: 48.w, height: 48.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: const Icon(Icons.arrow_back, color: AppTheme.textSecondary, size: 22),
                    ),
                  ),
                if (_step > 0) SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: AppTheme.accentGradient(),
                        boxShadow: [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_step == 4 ? "开始监护" : "下一步",
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          SizedBox(width: 8.w),
                          Icon(_step == 4 ? Icons.play_arrow : Icons.arrow_forward, color: Colors.white, size: 20.sp),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
        ),
      ),
    );
  }

  // ── 第一步: 性别 ──
  Widget _gender() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("选择身份", style: AppTheme.h1()),
          SizedBox(height: 8.h),
          Text("身份决定风险判定参数，不控制模型外观", style: AppTheme.body()),
          SizedBox(height: 28.h),
          Row(children: [
            _genderBtn(AvatarCharacter.male, Icons.man, "男性"),
            SizedBox(width: 10.w),
            _genderBtn(AvatarCharacter.female, Icons.woman, "女性"),
          ]),
          SizedBox(height: 20.h),
          Text("下一步将选择身份类型", style: AppTheme.caption()),
        ]),
      ),
    );
  }

  Widget _genderBtn(AvatarCharacter c, IconData ic, String label) {
    final sel = _profile.character == c;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _profile.character = c),
        child: AnimatedContainer(
          duration: 300.ms,
          height: 120.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? AppTheme.cyan : Colors.white.withValues(alpha: 0.06), width: sel ? 1 : 0.5),
            color: sel ? AppTheme.cyan.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
            boxShadow: sel ? [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.15), blurRadius: 16)] : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(ic, size: 40.sp, color: sel ? AppTheme.cyan : AppTheme.textTertiary),
            SizedBox(height: 8.h),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: sel ? AppTheme.cyan : AppTheme.textTertiary)),
          ]),
        ),
      ),
    );
  }

  // ── 第二步: 身份类型 ──
  Widget _identity() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("选择身份类型", style: AppTheme.h1()),
          SizedBox(height: 8.h),
          Text("决定风险判定参数体系", style: AppTheme.body()),
          SizedBox(height: 24.h),
          _idCard(AgeGroup.child, Icons.child_care, "儿童",
            "HHADM 80cm", "阈值 35°", "敏感度 45%", AppTheme.green),
          SizedBox(height: 10.h),
          _idCard(AgeGroup.youth, Icons.person, "青年",
            "HHADM 120cm", "阈值 22°", "敏感度 55%", AppTheme.cyan),
          SizedBox(height: 10.h),
          _idCard(AgeGroup.middle, Icons.person_outline, "中年",
            "HHADM 110cm", "阈值 20°", "敏感度 70%", AppTheme.amber),
          SizedBox(height: 10.h),
          _idCard(AgeGroup.elderly, Icons.elderly, "老人",
            "HHADM 100cm", "阈值 16°", "敏感度 90%", AppTheme.red),
        ]),
      ),
    );
  }

  Widget _idCard(AgeGroup g, IconData ic, String label, String hh, String th, String sens, Color c) {
    final sel = _profile.selectedGroup == g;
    return GestureDetector(
      onTap: () => setState(() { _profile.selectedGroup = g; _profile.age = UserProfile.defaultAgeFor(g); _profile._ageDefaultsApplied = false; }),
      child: AnimatedContainer(
        duration: 250.ms,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? c : Colors.white.withValues(alpha: 0.06), width: sel ? 1.2 : 0.5),
          color: sel ? c.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
          boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.12), blurRadius: 12)] : null,
        ),
        child: Row(children: [
          Icon(ic, size: 28.sp, color: sel ? c : AppTheme.textTertiary),
          SizedBox(width: 14.w),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: sel ? c : AppTheme.textSecondary))),
          Text(hh, style: AppTheme.caption().copyWith(color: sel ? c : AppTheme.textTertiary)),
          SizedBox(width: 10.w),
          Text(th, style: AppTheme.caption().copyWith(color: sel ? AppTheme.amber : AppTheme.textTertiary)),
          SizedBox(width: 10.w),
          Text(sens, style: AppTheme.caption().copyWith(color: sel ? AppTheme.red : AppTheme.textTertiary)),
        ]),
      ),
    );
  }

  double _ageMin() => switch (_profile.ageGroup) {
    AgeGroup.child => 1, AgeGroup.youth => 13, AgeGroup.middle => 35, AgeGroup.elderly => 55,
  };
  double _ageMax() => switch (_profile.ageGroup) {
    AgeGroup.child => 17, AgeGroup.youth => 39, AgeGroup.middle => 65, AgeGroup.elderly => 120,
  };

  // ── 第三步: 年龄 ──
  Widget _age() {
    final group = _profile.ageGroup;
    final groupColor = switch (group) {
      AgeGroup.child   => AppTheme.green,
      AgeGroup.youth   => AppTheme.cyan,
      AgeGroup.middle  => AppTheme.amber,
      AgeGroup.elderly => AppTheme.red,
    };

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2), width: 1)),
            child: Center(child: Icon(Icons.cake, size: 36.sp, color: AppTheme.cyan))),
          SizedBox(height: 24.h),
          Text("年龄", style: AppTheme.h1()),
          SizedBox(height: 8.h),
          Text("影响跌倒风险阈值判定", style: AppTheme.body()),
          SizedBox(height: 32.h),
          // 自动归类标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: groupColor.withValues(alpha: 0.3)),
              color: groupColor.withValues(alpha: 0.08),
            ),
            child: Text(_profile.ageGroupLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: groupColor)),
          ),
          SizedBox(height: 20.h),
          Text("${_profile.age}", style: AppTheme.mono(72, AppTheme.cyan)),
          SizedBox(height: 4.h),
          Text("岁", style: AppTheme.caption()),
          SizedBox(height: 16.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: AppTheme.cyan, thumbColor: AppTheme.cyan, trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
            child: Slider(
              value: _profile.age.toDouble(),
              min: _ageMin(), max: _ageMax(),
              divisions: (_ageMax() - _ageMin()).toInt(),
              onChanged: (v) => setState(() { _profile.age = v.round(); _profile._ageDefaultsApplied = false; })),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("${_ageMin().toInt()}", style: AppTheme.caption()), Text("${_ageMax().toInt()}", style: AppTheme.caption())]),
        ]),
      ),
    );
  }

  // ── 身高体重 ──
  Widget _body() {
    // 进入此页时自动应用年龄段预设值
    _profile.applyAgeDefaults();

    // 根据年龄段设定滑块范围
    final isChild = _profile.ageGroup == AgeGroup.child;
    final hMin = isChild ? 60.0 : 100.0;
    final hMax = isChild ? 180.0 : 250.0;
    final wMin = isChild ? 10.0 : 30.0;
    final wMax = isChild ? 100.0 : 200.0;

    // 钳位到合法范围（切换年龄段时可能出现值越界）
    _profile.heightCm = _profile.heightCm.clamp(hMin, hMax);
    _profile.weightKg = _profile.weightKg.clamp(wMin, wMax);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2), width: 1)),
            child: Center(child: Icon(Icons.monitor_weight, size: 36.sp, color: AppTheme.cyan))),
          SizedBox(height: 24.h),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text("身体数据", style: AppTheme.h1()),
            SizedBox(width: 10.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2)),
              ),
              child: Text("${_profile.ageGroupLabel}预设", style: AppTheme.caption().copyWith(color: AppTheme.cyan)),
            ),
          ]),
          SizedBox(height: 32.h),
          _num("身高", _profile.heightCm, "cm", hMin, hMax),
          SizedBox(height: 24.h),
          _num("体重", _profile.weightKg, "kg", wMin, wMax),
        ]),
      ),
    );
  }

  Widget _num(String label, double val, String unit, double min, double max) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTheme.caption()),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(onTap: () { if (val > min) setState(() => val == _profile.heightCm ? _profile.heightCm -= 1 : _profile.weightKg -= 1); }, child: Icon(Icons.remove, size: 18.sp, color: AppTheme.textSecondary)),
            SizedBox(width: 16.w),
            Text(val.toStringAsFixed(0), style: AppTheme.mono(24, AppTheme.cyan)),
            SizedBox(width: 4.w),
            Text(unit, style: AppTheme.caption()),
            SizedBox(width: 16.w),
            GestureDetector(onTap: () { if (val < max) setState(() => val == _profile.heightCm ? _profile.heightCm += 1 : _profile.weightKg += 1); }, child: Icon(Icons.add, size: 18.sp, color: AppTheme.textSecondary)),
          ]),
        ),
      ]),
      SizedBox(height: 8.h),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(activeTrackColor: AppTheme.cyan, thumbColor: AppTheme.cyan, trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
        child: Slider(value: val, min: min, max: max, onChanged: (v) => setState(() { if (val == _profile.heightCm) _profile.heightCm = v; else _profile.weightKg = v; })),
      ),
    ]);
  }

  // ── 确认 ──
  Widget _confirm() {
    final genderLabel = _profile.character == AvatarCharacter.male ? "男性" : "女性";
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.green])),
            child: const Icon(Icons.check, size: 40, color: Colors.black)),
          SizedBox(height: 24.h),
          Text("确认档案", style: AppTheme.h1()),
          SizedBox(height: 32.h),
          GlassCard(
            child: Column(children: [
              Row(children: [
                const Icon(Icons.person, size: 18, color: AppTheme.cyan), SizedBox(width: 12.w),
                Text("性别", style: AppTheme.body()), const Spacer(),
                Text(genderLabel, style: AppTheme.mono(14, AppTheme.cyan)),
              ]),
              const Divider(height: 20, color: Color(0x1AFFFFFF)),
              Row(children: [
                const Icon(Icons.category, size: 18, color: AppTheme.cyan), SizedBox(width: 12.w),
                Text("身份", style: AppTheme.body()), const Spacer(),
                Text(_profile.ageGroupLabel, style: AppTheme.mono(14, AppTheme.cyan)),
              ]),
              const Divider(height: 20, color: Color(0x1AFFFFFF)),
              Row(children: [
                const Icon(Icons.cake, size: 18, color: AppTheme.cyan), SizedBox(width: 12.w),
                Text("年龄", style: AppTheme.body()), const Spacer(),
                Text("${_profile.age} 岁", style: AppTheme.mono(14, AppTheme.cyan)),
              ]),
              const Divider(height: 20, color: Color(0x1AFFFFFF)),
              Row(children: [
                const Icon(Icons.height, size: 18, color: AppTheme.cyan), SizedBox(width: 12.w),
                Text("身高", style: AppTheme.body()), const Spacer(),
                Text("${_profile.heightCm.toInt()} 厘米", style: AppTheme.mono(14, AppTheme.cyan)),
              ]),
              const Divider(height: 20, color: Color(0x1AFFFFFF)),
              Row(children: [
                const Icon(Icons.monitor_weight, size: 18, color: AppTheme.cyan), SizedBox(width: 12.w),
                Text("体重", style: AppTheme.body()), const Spacer(),
                Text("${_profile.weightKg.toInt()} KG", style: AppTheme.mono(14, AppTheme.cyan)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── 进度条 ──
class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
      child: Row(children: [
        _Dot(step >= 0), const _Line(),
        _Dot(step >= 1), const _Line(),
        _Dot(step >= 2), const _Line(),
        _Dot(step >= 3), const _Line(),
        _Dot(step >= 4),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot(this.active);
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 300.ms,
      width: active ? 12.w : 6.w, height: 6.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppTheme.cyan : Colors.white.withValues(alpha: 0.1)),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)));
  }
}

