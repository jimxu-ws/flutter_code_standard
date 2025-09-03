import 'package:core_interface/core_interface.dart';

/// 用户服务实现
/// 
/// 提供用户认证和用户信息管理功能
class UserServiceImpl implements IUserService {
  User? _currentUser;

  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 模拟登录验证
    if (email.isEmpty || password.isEmpty) {
      throw ValidationException('邮箱和密码不能为空');
    }
    
    if (password.length < 6) {
      throw ValidationException('密码长度不能少于6位');
    }
    
    // 模拟用户
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: email.split('@').first,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    
    print('[UserService] User logged in: ${_currentUser!.email}');
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (_currentUser != null) {
      print('[UserService] User logged out: ${_currentUser!.email}');
      _currentUser = null;
    }
  }

  @override
  Stream<User?> get userStream {
    // 简化的用户状态流
    return Stream.periodic(
      const Duration(seconds: 1),
      (count) => _currentUser,
    );
  }

  @override
  Future<void> updateUser(User user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_currentUser?.id != user.id) {
      throw BusinessException('只能更新当前用户的信息');
    }
    
    _currentUser = user.copyWith(updatedAt: DateTime.now());
    print('[UserService] User updated: ${user.email}');
  }

  @override
  Future<bool> isLoggedIn() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser != null;
  }
}
