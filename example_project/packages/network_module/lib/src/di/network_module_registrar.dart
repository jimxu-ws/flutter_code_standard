import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';
import '../services/network_service_impl.dart';

class NetworkModuleRegistrar {
  static void register() {
    final getIt = GetIt.instance;
    print('🌐 Registering network module services...');
    if (!getIt.isRegistered<INetworkService>()) {
      getIt.registerLazySingleton<INetworkService>(() => NetworkServiceImpl());
    }
    print('✅ Network module services registered.');
  }

  static void unregister() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<INetworkService>()) {
      getIt.unregister<INetworkService>();
      print('🗑️ Network module services unregistered.');
    }
  }
}
