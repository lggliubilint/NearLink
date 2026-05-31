/// Huawei Cloud IoT 影子数据 API 服务
///
/// 通过 IAM token 获取设备影子, 解析所有服务属性。
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HuaweiApiService {
  // ---- 华为云认证信息 (与 main.dart 保持一致) ----
  static const String _domainName = "hid_y7o8dk0md7lrl65";
  static const String _userName = "monitor_app";
  static const String _password = "LBL030311bl";
  static const String _projectId = "019dadb5ff4e738ab10cca98e2300534";
  static const String _deviceId = "G1_NearLink_Csi";
  static const String _instanceId = "1acf0650-c893-45dd-ac43-65745677a649";

  static const String _iamUrl =
      "https://iam.cn-south-1.myhuaweicloud.com/v3/auth/tokens";
  static const String _iotdaBase =
      "https://54c1ff5a34.st1.iotda-app.cn-south-1.myhuaweicloud.com:443";

  String? _token;
  Timer? _timer;
  bool _fetching = false;

  /// 数据回调: Map<String, dynamic> 包含所有设备属性
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;

  /// 连接状态
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  /// 启动自动轮询
  void start({Duration interval = const Duration(seconds: 1)}) {
    _login().then((ok) {
      if (ok) {
        _timer = Timer.periodic(interval, (_) => _fetchData());
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _token = null;
  }

  // ----------------------------------------------------------
  // IAM 登录
  // ----------------------------------------------------------
  Future<bool> _login() async {
    try {
      final body = jsonEncode({
        "auth": {
          "identity": {
            "methods": ["password"],
            "password": {
              "user": {
                "domain": {"name": _domainName},
                "name": _userName,
                "password": _password,
              }
            }
          },
          "scope": {"project": {"id": _projectId}}
        }
      });

      final resp = await http.post(
        Uri.parse(_iamUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode == 201) {
        _token = resp.headers["x-subject-token"];
        _statusController.add("connected");
        return true;
      }
      _statusController.add("auth_failed: ${resp.statusCode}");
      return false;
    } catch (e) {
      _statusController.add("error: $e");
      return false;
    }
  }

  // ----------------------------------------------------------
  // 获取设备影子
  // ----------------------------------------------------------
  Future<void> _fetchData() async {
    if (_token == null || _fetching) return;
    _fetching = true;

    try {
      final url =
          "$_iotdaBase/v5/iot/$_projectId/devices/$_deviceId/shadow";
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          "X-Auth-Token": _token!,
          "Instance-Id": _instanceId,
        },
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final parsed = _parseShadow(body);
        _dataController.add(parsed);
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        _statusController.add("reconnecting");
        _token = null;
        await _login();
      }
    } catch (_) {
      // 网络超时静默忽略
    } finally {
      _fetching = false;
    }
  }

  // ----------------------------------------------------------
  // 影子解析 → 统一 Map
  //
  // 华为云影子格式:
  //   {"shadow": [{"service_id": "fall_detection",
  //                "reported": {"properties": {...}, "event_time": "..."}}]}
  // 输出: {"fall_detection": {theta: 7.9, ...}, "fall_detection_event_time": "..."}
  // ----------------------------------------------------------
  Map<String, dynamic> _parseShadow(dynamic body) {
    final result = <String, dynamic>{};

    try {
      final shadowList = body["shadow"] as List?;
      if (shadowList == null || shadowList.isEmpty) return result;

      for (var svc in shadowList) {
        final sid = svc["service_id"] as String? ?? "";
        final reported = svc["reported"] as Map<String, dynamic>?;
        final props = reported?["properties"] as Map<String, dynamic>?;
        if (sid.isNotEmpty && props != null) {
          result[sid] = props;
          result["${sid}_event_time"] = reported?["event_time"] ?? "";
        }
      }
    } catch (_) {}

    return result;
  }

  void dispose() {
    stop();
    _dataController.close();
    _statusController.close();
  }
}
