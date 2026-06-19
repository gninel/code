import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _keyDeviceId = 'mp_device_id';
  static const _keyToken = 'mp_token';

  final ApiService _api;

  String? _deviceId;
  String? _token;

  AuthService(this._api);

  String? get deviceId => _deviceId;
  String? get token => _token;
  bool get isRegistered => _token != null;

  /// 初始化：从本地存储恢复或首次注册
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_keyDeviceId);
    _token = prefs.getString(_keyToken);

    if (_token == null) {
      await _registerDevice();
    }
  }

  Future<void> _registerDevice() async {
    try {
      final result = await _api.submitConvert(url: ''); // placeholder
      // 实际调用注册接口
      // 这里简化处理，生产环境用专门的 auth 接口
    } catch (_) {
      // 离线模式：无需 token 也可使用本地功能
    }
  }

  Future<void> saveCredentials(String deviceId, String token) async {
    _deviceId = deviceId;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceId, deviceId);
    await prefs.setString(_keyToken, token);
  }

  Future<void> clear() async {
    _deviceId = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceId);
    await prefs.remove(_keyToken);
  }
}
