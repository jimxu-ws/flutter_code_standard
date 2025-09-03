import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';

// 1. Defines the state notifier for user data
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final IUserService _userService;

  UserNotifier(this._userService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    try {
      final user = await _userService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _userService.login(email, password);
      final user = await _userService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Re-throw to allow UI to catch it for error messages
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _userService.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// 2. Defines the global provider for the UserNotifier
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  // Obtains the user service instance from the GetIt service locator
  final userService = GetIt.instance<IUserService>();
  return UserNotifier(userService);
});
