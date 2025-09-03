import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';
import 'user_routes.dart';

/// Concrete implementation of the IUserNavigator interface.
class UserNavigatorImpl implements IUserNavigator {
  // Lazily retrieve the navigation service from GetIt.
  final NavigationService _nav = GetIt.instance<NavigationService>();

  @override
  Future<void> toLogin() async {
    await _nav.navigateTo(UserRoutes.login);
  }

  @override
  Future<void> toRegister() async {
    await _nav.navigateTo(UserRoutes.register);
  }

  @override
  Future<void> toUserProfile(String userId) async {
    await _nav.navigateTo(
      UserRoutes.userProfile,
      params: {'userId': userId},
    );
  }
}
