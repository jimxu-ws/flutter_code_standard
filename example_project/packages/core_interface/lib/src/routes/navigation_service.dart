import 'package:core_interface/core_interface.dart';

/// Navigation Service Interface
///
/// Provides a unified interface for page navigation, abstracting the underlying
/// routing implementation.
abstract class NavigationService {
  /// Navigates to the specified route.
  Future<void> navigateTo(
    String routeName, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  });

  /// Goes back to the previous page.
  void goBack();

  /// Goes back to the specified route.
  void goBackUntil(String routeName);

  /// Pushes a new page and removes all pages until the specified route.
  Future<void> pushAndRemoveUntil(
    String newRouteName,
    String routeNameToRemove,
  );

  /// Replaces the current page with a new one.
  Future<void> replace(String routeName, {Map<String, String>? params});

  /// The name of the current route.
  String? get currentRouteName;

  /// The path of the current route.
  String? get currentRoutePath;

  /// Whether it is possible to go back to a previous page.
  bool get canGoBack;
}
