import 'package:core_interface/core_interface.dart';
import 'dart:async';

/// An in-memory implementation of the [IUserRepository].
/// In a real application, this would be replaced with a database or network implementation.
class UserRepositoryImpl implements IUserRepository {
  User? _user;
  final _controller = StreamController<User?>.broadcast();

  @override
  Future<void> clearAll() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteUser() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<User?> getCurrentUser() async {
    return _user;
  }

  @override
  Future<void> saveUser(User user) async {
    _user = user;
    _controller.add(user);
  }

  @override
  Stream<User?> get userStream => _controller.stream;
}
