/// 个人档案配置页 — 性别/年龄/身高/体重
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_painter.dart';

/// 用户档案数据
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
}

class ProfilePage extends StatefulWidget {
  final VoidCallback onComplete;

  const ProfilePage({super.key, required this.onComplete});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final UserProfile _profile;
  final _pageCtrl = PageController();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _profile = UserProfile();
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page ?? 0;
      if ((p - _step).abs() > 0.5 && mounted) {
        setState(() => _step = p.round());
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppTheme.pageBg(b),
      body: SafeArea(
        child: Column(children: [
          // 进度条
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
            child: Row(children: List.generate(4, (i) {
              final active = i <= _step;
              return Expanded(
                child: Container(
                  height: 3.h,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.r),
                    color: active ? AppTheme.accent : AppTheme.divider(b),
                  ),
                ),
              );
            })),
          ),

          // 步骤内容
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _stepGender(b),
                _stepAge(b),
                _stepBody(b),
                _stepConfirm(b),
              ],
            ),
          ),

          // 底部按钮
          _bottomBar(b),
        ]),
      ),
    );
  }

  // ── Step 1: 性别 ──
  Widget _stepGender(Brightness b) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // 人物预览
        SizedBox(
          width: 200.w, height: 200.w,
          child: CustomPaint(
            painter: AvatarPainter(
              theta: 8, phi: 30, mode: 'standing',
              character: _profile.character, time: 0,
              fallProbability: 0,
            ),
          ),
        ).animate().scale(duration: 400.ms, begin: const Offset(0.9, 0.9)),

        SizedBox(height: 32.h),
        Text("选择您的身份", style: AppTheme.h1(b)),
        SizedBox(height: 8.h),
        Text("这将用于匹配最适合的姿态检测模型",
          style: AppTheme.body(b), textAlign: TextAlign.center),
        SizedBox(height: 32.h),

        Row(children: [
          Expanded(child: _genderBtn(AvatarCharacter.male, Icons.man_rounded, "男性", b)),
          SizedBox(width: 12.w),
          Expanded(child: _genderBtn(AvatarCharacter.female, Icons.woman_rounded, "女性", b)),
          SizedBox(width: 12.w),
          Expanded(child: _genderBtn(AvatarCharacter.child, Icons.child_care_rounded, "儿童", b)),
        ]),
      ]),
    );
  }

  Widget _genderBtn(AvatarCharacter c, IconData ic, String label, Brightness b) {
    final sel = _profile.character == c;
    return GestureDetector(
      onTap: () => setState(() => _profile.character = c),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          color: sel ? AppTheme.accent.withValues(alpha: 0.1) : AppTheme.cardBg(b),
          border: Border.all(
            color: sel ? AppTheme.accent : AppTheme.divider(b),
            width: sel ? 1.5 : 0.8),
          boxShadow: sel ? [
            BoxShadow(color: AppTheme.accent.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Column(children: [
          Icon(ic, size: 36.sp, color: sel ? AppTheme.accent : AppTheme.textDim(b)),
          SizedBox(height: 6.h),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: sel ? AppTheme.accent : AppTheme.textDim(b))),
        ]),
      ),
    );
  }

  // ── Step 2: 年龄 ──
  Widget _stepAge(Brightness b) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cake_rounded, size: 48.sp, color: AppTheme.accent),
        SizedBox(height: 16.h),
        Text("您的年龄", style: AppTheme.h1(b)),
        SizedBox(height: 8.h),
        Text("年龄影响跌倒风险阈值判定",
          style: AppTheme.body(b), textAlign: TextAlign.center),
        SizedBox(height: 40.h),
        Text(_profile.age.toString(),
          style: AppTheme.mono(64, AppTheme.accent)),
        SizedBox(height: 8.h),
        Text("岁", style: AppTheme.h2(b)),
        SizedBox(height: 20.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.accent,
            thumbColor: AppTheme.accent,
            trackHeight: 4,
          ),
          child: Slider(
            value: _profile.age.toDouble(),
            min: 1, max: 120, divisions: 119,
            label: "${_profile.age} 岁",
            onChanged: (v) => setState(() => _profile.age = v.round()),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("1", style: AppTheme.caption(b)),
          Text("120", style: AppTheme.caption(b)),
        ]),
      ]),
    );
  }

  // ── Step 3: 身高体重 ──
  Widget _stepBody(Brightness b) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.monitor_weight_rounded, size: 48.sp, color: AppTheme.accent),
        SizedBox(height: 16.h),
        Text("身体数据", style: AppTheme.h1(b)),
        SizedBox(height: 8.h),
        Text("用于精确计算跌倒时的姿态偏移",
          style: AppTheme.body(b), textAlign: TextAlign.center),
        SizedBox(height: 40.h),

        // 身高
        _numField("身高", _profile.heightCm, "cm", 100, 250,
          (v) => setState(() => _profile.heightCm = v), b),
        SizedBox(height: 20.h),

        // 体重
        _numField("体重", _profile.weightKg, "kg", 30, 200,
          (v) => setState(() => _profile.weightKg = v), b),
      ]),
    );
  }

  Widget _numField(String label, double val, String unit, double min, double max, ValueChanged<double> onChanged, Brightness b) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTheme.h2(b)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: AppTheme.accent.withValues(alpha: 0.1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: () { if (val > min) onChanged(val - 1); },
              child: Icon(Icons.remove, size: 20.sp, color: AppTheme.accent)),
            SizedBox(width: 12.w),
            Text(val.toStringAsFixed(0), style: AppTheme.mono(22, AppTheme.accent)),
            SizedBox(width: 4.w),
            Text(unit, style: AppTheme.caption(b)),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: () { if (val < max) onChanged(val + 1); },
              child: Icon(Icons.add, size: 20.sp, color: AppTheme.accent)),
          ]),
        ),
      ]),
      SizedBox(height: 8.h),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(activeTrackColor: AppTheme.accent, thumbColor: AppTheme.accent, trackHeight: 4),
        child: Slider(value: val, min: min, max: max, onChanged: onChanged),
      ),
    ]);
  }

  // ── Step 4: 确认 ──
  Widget _stepConfirm(Brightness b) {
    final charLabel = _profile.character == AvatarCharacter.male ? "男性"
        : _profile.character == AvatarCharacter.female ? "女性" : "儿童";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_rounded, size: 64.sp, color: AppTheme.green),
        SizedBox(height: 16.h),
        Text("确认信息", style: AppTheme.h1(b)),
        SizedBox(height: 8.h),
        Text("以下数据将用于跌倒检测", style: AppTheme.body(b)),
        SizedBox(height: 32.h),

        GlassCard(
          child: Column(children: [
            _infoRow("性别", charLabel, Icons.person, b),
            const Divider(height: 1),
            _infoRow("年龄", "${_profile.age} 岁", Icons.cake, b),
            const Divider(height: 1),
            _infoRow("身高", "${_profile.heightCm.toInt()} cm", Icons.height, b),
            const Divider(height: 1),
            _infoRow("体重", "${_profile.weightKg.toInt()} kg", Icons.monitor_weight, b),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(String label, String value, IconData ic, Brightness b) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(children: [
        Icon(ic, size: 20.sp, color: AppTheme.accent),
        SizedBox(width: 12.w),
        Text(label, style: AppTheme.body(b)),
        const Spacer(),
        Text(value, style: AppTheme.h2(b).copyWith(color: AppTheme.accent)),
      ]),
    );
  }

  // ── 底部按钮 ──
  Widget _bottomBar(Brightness b) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
      child: Row(children: [
        if (_step > 0)
          GestureDetector(
            onTap: () => _pageCtrl.previousPage(duration: 300.ms, curve: Curves.easeOut),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardBg(b),
                border: Border.all(color: AppTheme.divider(b))),
              child: Icon(Icons.arrow_back_rounded, color: AppTheme.textDim(b))),
          ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            if (_step < 3) {
              _pageCtrl.nextPage(duration: 300.ms, curve: Curves.easeOut);
            } else {
              widget.onComplete();
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)]),
              boxShadow: [
                BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_step < 3 ? "下一步" : "开始监护",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(width: 6.w),
              Icon(_step < 3 ? Icons.arrow_forward : Icons.check, color: Colors.white, size: 20.sp),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── 复用 GlassCard ──
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        color: AppTheme.cardBg(b),
        border: Border.all(color: AppTheme.divider(b), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
