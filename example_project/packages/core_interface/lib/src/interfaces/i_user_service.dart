import 'package:core_interface/core_interface.dart';

/// 用户服务接口
/// 
/// 提供用户认证、用户信息管理等功能
/// 
/// 版本：1.0.0
/// 兼容性：向后兼容
/// 维护者：@team-user
/// 
/// 使用示例：
/// ```dart
/// final userService = ServiceLocator.get<IUserService>();
/// final user = await userService.getCurrentUser();
/// ```
abstract class IUserService {
  /// 获取当前用户
  /// 
  /// 如果用户未登录，返回 null
  /// 
  /// 返回值：
  /// - [User] 当前用户信息
  /// - null 用户未登录
  /// 
  /// 异常：
  /// - [AuthenticationException] 认证失败
  /// - [NetworkException] 网络错误
  Future<User?> getCurrentUser();
  
  /// 用户登录
  /// 
  /// 参数：
  /// - [email] 用户邮箱
  /// - [password] 用户密码
  /// 
  /// 异常：
  /// - [AuthenticationException] 认证失败
  /// - [NetworkException] 网络错误
  /// - [ValidationException] 参数验证失败
  Future<void> login(String email, String password);
  
  /// 用户登出
  /// 
  /// 异常：
  /// - [NetworkException] 网络错误
  Future<void> logout();
  
  /// 用户状态流
  /// 
  /// 监听用户登录状态变化
  Stream<User?> get userStream;
  
  /// 更新用户信息
  /// 
  /// 参数：
  /// - [user] 更新的用户信息
  /// 
  /// 异常：
  /// - [ValidationException] 数据验证失败
  /// - [NetworkException] 网络错误
  Future<void> updateUser(User user);
  
  /// 检查用户是否已登录
  Future<bool> isLoggedIn();
}

/// 用户仓库接口
/// 
/// 提供用户数据的持久化操作
abstract class IUserRepository {
  /// 获取当前用户
  Future<User?> getCurrentUser();
  
  /// 保存用户信息
  Future<void> saveUser(User user);
  
  /// 删除用户信息
  Future<void> deleteUser();
  
  /// 用户状态流
  Stream<User?> get userStream;
  
  /// 清除所有用户数据
  Future<void> clearAll();
}
