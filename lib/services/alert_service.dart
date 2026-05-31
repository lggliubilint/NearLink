/// 跌倒告警服务 — 推送通知 / 震动 / 后台监听
library;

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class AlertService {
  static final AlertService _instance = AlertService._();
  factory AlertService() => _instance;
  AlertService._();

  final FlutterLocalNotificationsPlugin _notifs = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _lastAlertState = false;

  // ── 初始化 ──
  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifs.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    _initialized = true;
  }

  // ── 跌倒告警 ──
  Future<void> triggerFallAlert({
    required double probability,
    required String mode,
  }) async {
    if (!_initialized) await init();

    // 防重复告警
    if (_lastAlertState && probability > 0.7) return;
    _lastAlertState = probability > 0.7;

    // 震动 (优先强震动)
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      if (probability > 0.7) {
        // 强告警: 长震动模式
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 1000]);
      } else if (probability > 0.3) {
        // 预警: 短震动
        Vibration.vibrate(duration: 200);
      }
    }

    // 推送通知
    if (probability > 0.5) {
      await _showNotification(probability, mode);
    }
  }

  Future<void> _showNotification(double probability, String mode) async {
    const androidDetails = AndroidNotificationDetails(
      'fall_alert_channel',
      '跌倒告警',
      channelDescription: '跌倒检测告警通知',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      // 使用默认闹钟声音
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final title = probability > 0.7 ? '🚨 跌倒警报!' : '⚠️ 异常姿态预警';
    final body = mode == 'fallen'
        ? '检测到人员倒地! 请立即查看!'
        : '跌倒概率 ${(probability * 100).toInt()}%，请关注';

    await _notifs.show(
      0,
      title,
      body,
      details,
    );
  }

  // ── 取消告警 ──
  Future<void> cancelAlert() async {
    _lastAlertState = false;
    await _notifs.cancel(0);
    Vibration.cancel();
  }

  // ── 权限请求 ──
  Future<void> requestPermissions() async {
    await _notifs.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    await _notifs.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true, badge: true, sound: true,
    );
  }
}
