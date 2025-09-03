import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';
import '../services/storage_service_impl.dart';

class StorageModuleRegistrar {
  static void register() {
    final getIt = GetIt.instance;
    print('💾 Registering storage module services...');
    if (!getIt.isRegistered<IStorageService>()) {
      getIt.registerLazySingleton<IStorageService>(() => StorageServiceImpl());
    }
    print('✅ Storage module services registered.');
  }

  static void unregister() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<IStorageService>()) {
      getIt.unregister<IStorageService>();
      print('🗑️ Storage module services unregistered.');
    }
  }
}
