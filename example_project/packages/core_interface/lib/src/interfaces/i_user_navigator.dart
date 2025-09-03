/// Abstract interface for navigation commands within the user module.
///
/// This decouples feature modules from the concrete implementation of
/// user navigation, allowing them to navigate to user-related screens
/// without a direct dependency on the user module itself.
abstract class IUserNavigator {
  /// Navigates to the login page.
  Future<void> toLogin();

  /// Navigates to the register page.
  Future<void> toRegister();

  /// Navigates to the user profile page.
  Future<void> toUserProfile(String userId);
}
