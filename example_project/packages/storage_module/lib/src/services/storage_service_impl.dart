import 'package:core_interface/core_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 存储服务实现
/// 
/// 基于 shared_preferences 的持久化存储服务实现
class StorageServiceImpl implements IStorageService {
  late final SharedPreferences _prefs;

  StorageServiceImpl() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e) {
      throw BusinessException('存储字符串失败：$e');
    }
  }

  @override
  Future<String?> getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      throw BusinessException('获取字符串失败：$e');
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e) {
      throw BusinessException('存储整数失败：$e');
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      throw BusinessException('获取整数失败：$e');
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e) {
      throw BusinessException('存储布尔值失败：$e');
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      throw BusinessException('获取布尔值失败：$e');
    }
  }

  @override
  Future<void> setDouble(String key, double value) async {
    try {
      await _prefs.setDouble(key, value);
    } catch (e) {
      throw BusinessException('存储双精度值失败：$e');
    }
  }

  @override
  Future<double?> getDouble(String key) async {
    try {
      return _prefs.getDouble(key);
    } catch (e) {
      throw BusinessException('获取双精度值失败：$e');
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    try {
      await _prefs.setStringList(key, value);
    } catch (e) {
      throw BusinessException('存储字符串列表失败：$e');
    }
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    try {
      return _prefs.getStringList(key);
    } catch (e) {
      throw BusinessException('获取字符串列表失败：$e');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e) {
      throw BusinessException('删除存储项失败：$e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _prefs.clear();
    } catch (e) {
      throw BusinessException('清空存储失败：$e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return _prefs.containsKey(key);
    } catch (e) {
      throw BusinessException('检查键是否存在失败：$e');
    }
  }

  @override
  Future<Set<String>> getKeys() async {
    try {
      return _prefs.getKeys();
    } catch (e) {
      throw BusinessException('获取所有键失败：$e');
    }
  }
}
