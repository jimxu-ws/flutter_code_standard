import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';
import 'package:go_router/go_router.dart';
import '../services/go_router_navigation_service.dart';

class GoRouterServiceRegistrar {
  static void register() {
    final getIt = GetIt.instance;
    print('🚦 Registering GoRouter and navigation service...');

    // 1. Create the GoRouter instance.
    // This is now self-contained within the module.
    final router = _createAppRouter();
    getIt.registerSingleton<GoRouter>(router);
    getIt.registerSingleton<RouterConfig<Object>>(router);

    // 2. Register the NavigationService implementation.
    if (!getIt.isRegistered<NavigationService>()) {
      getIt.registerLazySingleton<NavigationService>(
        () => GoRouterNavigationService(getIt<GoRouter>()),
      );
    }
    
    print('✅ GoRouter and navigation service registered.');
  }

  static void unregister() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<NavigationService>()) {
      getIt.unregister<NavigationService>();
    }
    if (getIt.isRegistered<GoRouter>()) {
      getIt.unregister<GoRouter>();
    }
    if (getIt.isRegistered<RouterConfig<Object>>()) {
      getIt.unregister<RouterConfig<Object>>();
    }
    print('🗑️ GoRouter and navigation service unregistered.');
  }
}

// This logic is moved from the main app's app_router.dart
GoRouter _createAppRouter() {
  final routes = _generateRoutes();
  
  return GoRouter(
    initialLocation: '/',
    routes: routes,
    // A generic error builder can be defined here, or you can pass one in.
    // For now, a simple text error is sufficient.
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text('The route ${state.uri} could not be found.'),
        ),
      );
    },
  );
}

List<GoRoute> _generateRoutes() {
  print('🚦 Generating all module routes...');
  final registrars = GetIt.instance.getAll<RouteRegister>().toList();
  registrars.sort((a, b) => b.priority.compareTo(a.priority));
  
  final List<GoRoute> allRoutes = [];
  for (final registrar in registrars) {
    print('  -> Registering routes from [${registrar.moduleName}] (Priority: ${registrar.priority})...');
    registrar.registerRoutes(allRoutes);
  }
  
  print('✅ Route generation complete. Found ${allRoutes.length} routes.');
  return allRoutes;
}
