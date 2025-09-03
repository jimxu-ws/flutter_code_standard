import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';
import '../routes/home_route_register.dart';

class HomeModuleRegistrar {
  static void register() {
    final getIt = GetIt.instance;
    print('🏠 Registering home module services...');
    
    // Register the route registrar for the home module
    getIt.registerLazySingleton<RouteRegister>(() => HomeRouteRegister());
    
    print('✅ Home module services registered.');
  }

  static void unregister() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<RouteRegister>(instanceName: 'HomeRouteRegister')) {
      getIt.unregister<RouteRegister>(instanceName: 'HomeRouteRegister');
      print('🗑️ Home module services unregistered.');
    }
  }
}
