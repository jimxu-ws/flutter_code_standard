/// 存储服务接口
/// 
/// 提供统一的本地存储功能
abstract class IStorageService {
  /// 存储字符串值
  Future<void> setString(String key, String value);
  
  /// 获取字符串值
  Future<String?> getString(String key);
  
  /// 存储整数值
  Future<void> setInt(String key, int value);
  
  /// 获取整数值
  Future<int?> getInt(String key);
  
  /// 存储布尔值
  Future<void> setBool(String key, bool value);
  
  /// 获取布尔值
  Future<bool?> getBool(String key);
  
  /// 存储双精度值
  Future<void> setDouble(String key, double value);
  
  /// 获取双精度值
  Future<double?> getDouble(String key);
  
  /// 存储字符串列表
  Future<void> setStringList(String key, List<String> value);
  
  /// 获取字符串列表
  Future<List<String>?> getStringList(String key);
  
  /// 移除指定键的值
  Future<void> remove(String key);
  
  /// 清除所有存储的值
  Future<void> clear();
  
  /// 检查是否包含指定键
  Future<bool> containsKey(String key);
  
  /// 获取所有键
  Future<Set<String>> getKeys();
}
