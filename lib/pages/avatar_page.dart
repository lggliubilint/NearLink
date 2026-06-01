/// 3D 小人姿态页
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/model_avatar.dart';
import '../widgets/glass_card.dart';

class AvatarPage extends StatelessWidget {
  final double theta, phi, vDeltaPhi, hhadm, fallProbability;
  final String mode, status;
  final double time;
  final AvatarCharacter character;
  final ValueChanged<AvatarCharacter>? onCharacterChanged;

  const AvatarPage({
    super.key,
    required this.theta, required this.phi, required this.vDeltaPhi,
    required this.hhadm, required this.fallProbability,
    required this.mode, required this.status, required this.time,
    this.character = AvatarCharacter.male,
    this.onCharacterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final dangerColor = fallProbability > 0.5 ? AppTheme.red
        : fallProbability > 0.2 ? AppTheme.orange : AppTheme.teal;

    return Column(
      children: [
        _appBar(context, b, dangerColor),
        if (onCharacterChanged != null)
          _charChips(b),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(children: [
              SizedBox(height: 16.h),
              _avatarCard(b, dangerColor),
              SizedBox(height: 16.h),
              _dataRow(b),
              SizedBox(height: 12.h),
              _heightCard(b),
              SizedBox(height: 12.h),
              _fallRiskCard(b, dangerColor),
              SizedBox(height: 16.h),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _appBar(BuildContext context, Brightness b, Color dc) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("NearLink 星闪", style: AppTheme.h1(b)),
            SizedBox(height: 2.h),
            Row(children: [
              Container(width: 7.w, height: 7.w,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: status == "connected" ? AppTheme.green
                      : status == "simulated" ? AppTheme.orange : Colors.grey,
                  boxShadow: status == "connected"
                      ? [BoxShadow(color: AppTheme.green.withValues(alpha: 0.5), blurRadius: 6)]
                      : null)),
              SizedBox(width: 6.w),
              Text(status == "connected" ? "华为云在线" : status == "simulated" ? "模拟模式" : "连接中...",
                style: AppTheme.body(b)),
            ]),
          ]),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: dc.withValues(alpha: 0.12),
            ),
            child: Text(_modeText, style: AppTheme.caption(b).copyWith(color: dc, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _avatarCard(Brightness b, Color dc) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: 320.h,
        child: Stack(alignment: Alignment.center, children: [
          // 背景光晕（静态，无 AnimatedBuilder）
          Positioned(
            bottom: 20.h,
            child: Container(
              width: 150.w, height: 15.h,
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(
                  color: dc.withValues(alpha: 0.15),
                  blurRadius: 30, spreadRadius: 8)]),
            ),
          ),
          ModelAvatar(
            theta: theta, phi: phi, fallProbability: fallProbability,
            mode: mode, size: 280.w, character: character,
          ),
          Positioned(
            top: 10.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: dc.withValues(alpha: 0.1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person, size: 12.sp, color: dc),
                SizedBox(width: 4.w),
                Text("实时姿态", style: AppTheme.caption(b).copyWith(color: dc)),
              ]),
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _dataRow(Brightness b) {
    return GlassCard(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _num(Icons.height_rounded, "俯仰角 θ", theta.toStringAsFixed(1), "°", AppTheme.accent, b),
        Container(width: 0.5, height: 35.h, color: AppTheme.divider(b)),
        _num(Icons.explore_rounded, "转向角 φ", (phi % 360).toStringAsFixed(0), "°", const Color(0xFF5856D6), b),
        Container(width: 0.5, height: 35.h, color: AppTheme.divider(b)),
        _num(Icons.speed_rounded, "速率 vΔΦ", vDeltaPhi.toStringAsFixed(1), "/s", AppTheme.orange, b),
      ]),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _num(IconData ic, String label, String val, String unit, Color c, Brightness b) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(ic, size: 14.sp, color: c.withValues(alpha: 0.7)),
      SizedBox(height: 4.h),
      Text(label, style: AppTheme.caption(b)),
      SizedBox(height: 2.h),
      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(val, style: AppTheme.mono(22, c)),
        SizedBox(width: 2.w),
        Padding(padding: EdgeInsets.only(bottom: 3.h), child: Text(unit, style: AppTheme.caption(b).copyWith(color: c))),
      ]),
    ]);
  }

  Widget _heightCard(Brightness b) {
    return GlassCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(children: [
        Container(padding: EdgeInsets.all(7.w), decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.green.withValues(alpha: 0.12)), child: Icon(Icons.height_rounded, color: AppTheme.green, size: 18.sp)),
        SizedBox(width: 12.w),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("胸部距地高度", style: AppTheme.caption(b)),
          SizedBox(height: 2.h),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(hhadm.toStringAsFixed(0), style: AppTheme.mono(22, AppTheme.green)),
            SizedBox(width: 3.w),
            Padding(padding: EdgeInsets.only(bottom: 3.h), child: Text("cm", style: AppTheme.caption(b).copyWith(color: AppTheme.green))),
          ]),
        ]),
        const Spacer(),
        SizedBox(width: 70.w, height: 5.h,
          child: ClipRRect(borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(value: (hhadm / 120).clamp(0.0, 1.0), backgroundColor: AppTheme.green.withValues(alpha: 0.12), valueColor: const AlwaysStoppedAnimation(AppTheme.green)))),
      ]),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _fallRiskCard(Brightness b, Color dc) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(Icons.warning_amber_rounded, size: 16.sp, color: dc), SizedBox(width: 6.w), Text("跌倒风险", style: AppTheme.h2(b))]),
          Text("${(fallProbability * 100).toInt()}%", style: AppTheme.mono(26, dc)),
        ]),
        SizedBox(height: 8.h),
        ClipRRect(borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(value: fallProbability, minHeight: 7.h, backgroundColor: dc.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(dc))),
        SizedBox(height: 6.h),
        Row(children: [
          Expanded(child: Text("安全", textAlign: TextAlign.center, style: AppTheme.caption(b).copyWith(color: fallProbability >= 0.25 ? AppTheme.textDim(b) : AppTheme.green, fontWeight: fallProbability < 0.25 ? FontWeight.w600 : FontWeight.w400))),
          Expanded(child: Text("注意", textAlign: TextAlign.center, style: AppTheme.caption(b).copyWith(color: fallProbability >= 0.5 ? AppTheme.textDim(b) : AppTheme.orange, fontWeight: fallProbability >= 0.25 && fallProbability < 0.5 ? FontWeight.w600 : FontWeight.w400))),
          Expanded(child: Text("危险", textAlign: TextAlign.center, style: AppTheme.caption(b).copyWith(color: fallProbability >= 0.8 ? AppTheme.red : AppTheme.textDim(b), fontWeight: fallProbability >= 0.5 ? FontWeight.w600 : FontWeight.w400))),
        ]),
      ]),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _charChips(Brightness b) {
    final items = [
      (AvatarCharacter.male, Icons.man_rounded, "男性"),
      (AvatarCharacter.female, Icons.woman_rounded, "女性"),
      (AvatarCharacter.child, Icons.child_care_rounded, "儿童"),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((item) {
          final sel = character == item.$1;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () => onCharacterChanged?.call(item.$1),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  color: sel ? AppTheme.accent.withValues(alpha: 0.1) : AppTheme.cardBg(b),
                  border: Border.all(color: sel ? AppTheme.accent.withValues(alpha: 0.3) : AppTheme.divider(b)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(item.$2, size: 16.sp, color: sel ? AppTheme.accent : AppTheme.textDim(b)),
                  SizedBox(width: 4.w),
                  Text(item.$3, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? AppTheme.accent : AppTheme.textDim(b))),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  String get _modeText {
    if (fallProbability > 0.7) return "跌倒警告";
    if (fallProbability > 0.3) return "异常姿态";
    return switch (mode) {
      "walking" => "行走中", "bending" => "弯腰中",
      "falling" => "正在跌倒", "fallen" => "已倒地",
      "recovering" => "恢复中", _ => "正常站立",
    };
  }
}
