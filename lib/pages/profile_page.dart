/// 个人档案页 — Med-Tech 暗色设计
/// 配置的数据通过 UserProfile 传回 main 供整个 App 使用
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/glass_card.dart';

class UserProfile {
  AvatarCharacter character;
  int age;
  double heightCm;
  double weightKg;

  UserProfile({
    this.character = AvatarCharacter.male,
    this.age = 30,
    this.heightCm = 170,
    this.weightKg = 70,
  });

  // 根据档案计算跌倒检测灵敏度
  double get fallSensitivity {
    if (age > 65) return 0.85;
    if (age > 45) return 0.75;
    return 0.65;
  }

  // 重心高度估计 (cm) — 用于 HHADM 参考
  double get estimatedCenterOfMass => heightCm * 0.56;
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
    if (_step == 3) {
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
                children: [_gender(), _age(), _body(), _confirm()],
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
                          Text(_step == 3 ? "开始监护" : "下一步",
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          SizedBox(width: 8.w),
                          Icon(_step == 3 ? Icons.play_arrow : Icons.arrow_forward, color: Colors.white, size: 20.sp),
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

  // ── 性别 ──
  Widget _gender() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 160.w, height: 160.w,
            child: CustomPaint(painter: AvatarPainter(
              theta: 8, phi: 30, mode: 'standing',
              character: _profile.character, fallProbability: 0, time: 0)),
          ).animate().scale(duration: 500.ms, begin: const Offset(0.85, 0.85)),
          SizedBox(height: 24.h),
          Text("选择身份", style: AppTheme.h1()),
          SizedBox(height: 32.h),
          Row(children: [
            _btn(AvatarCharacter.male, Icons.man, "男性"),
            SizedBox(width: 12.w),
            _btn(AvatarCharacter.female, Icons.woman, "女性"),
            SizedBox(width: 12.w),
            _btn(AvatarCharacter.child, Icons.child_care, "儿童"),
          ]),
        ]),
      ),
    );
  }

  Widget _btn(AvatarCharacter c, IconData ic, String label) {
    final sel = _profile.character == c;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _profile.character = c),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: EdgeInsets.symmetric(vertical: 20.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? AppTheme.cyan : Colors.white.withValues(alpha: 0.06), width: sel ? 1 : 0.5),
            color: sel ? AppTheme.cyan.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
            boxShadow: sel ? [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.15), blurRadius: 16)] : null,
          ),
          child: Column(children: [
            Icon(ic, size: 32.sp, color: sel ? AppTheme.cyan : AppTheme.textTertiary),
            SizedBox(height: 8.h),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: sel ? AppTheme.cyan : AppTheme.textTertiary)),
          ]),
        ),
      ),
    );
  }

  // ── 年龄 ──
  Widget _age() {
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
          Text("${_profile.age}", style: AppTheme.mono(72, AppTheme.cyan)),
          SizedBox(height: 4.h),
          Text("岁", style: AppTheme.caption()),
          SizedBox(height: 16.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: AppTheme.cyan, thumbColor: AppTheme.cyan, trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
            child: Slider(value: _profile.age.toDouble(), min: 1, max: 120, divisions: 119, onChanged: (v) => setState(() => _profile.age = v.round())),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("1", style: AppTheme.caption()), Text("120", style: AppTheme.caption())]),
        ]),
      ),
    );
  }

  // ── 身高体重 ──
  Widget _body() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2), width: 1)),
            child: Center(child: Icon(Icons.monitor_weight, size: 36.sp, color: AppTheme.cyan))),
          SizedBox(height: 24.h),
          Text("身体数据", style: AppTheme.h1()),
          SizedBox(height: 32.h),
          _num("身高", _profile.heightCm, "cm", 100, 250),
          SizedBox(height: 24.h),
          _num("体重", _profile.weightKg, "kg", 30, 200),
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
    final cLabel = _profile.character == AvatarCharacter.male ? "男性" : _profile.character == AvatarCharacter.female ? "女性" : "儿童";
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
                Text("身份", style: AppTheme.body()), const Spacer(),
                Text(cLabel, style: AppTheme.mono(14, AppTheme.cyan)),
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
        _Dot(step >= 3),
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

