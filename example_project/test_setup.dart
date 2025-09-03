import 'package:core_interface/core_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'lib/src/di/app_service_registrar.dart';

/// 测试依赖注入设置
void main() {
  group('Dependency Injection Tests', () {
    setUp(() {
      // 清理 GetIt 实例
      GetIt.instance.reset();
    });

    test('should register all core services', () {
      // 测试服务注册
      expect(() => AppServiceRegistrar.registerAll(), returnsNormally);
      
      // 验证核心服务是否已注册
      expect(GetIt.instance.isRegistered<INetworkService>(), true);
      expect(GetIt.instance.isRegistered<IStorageService>(), true);
      expect(GetIt.instance.isRegistered<NavigationService>(), true);
      expect(GetIt.instance.isRegistered<GoRouter>(), true);
    });

    test('should create services without errors', () {
      AppServiceRegistrar.registerAll();
      
      // 测试服务创建
      expect(() => GetIt.instance<INetworkService>(), returnsNormally);
      expect(() => GetIt.instance<IStorageService>(), returnsNormally);
      expect(() => GetIt.instance<NavigationService>(), returnsNormally);
      expect(() => GetIt.instance<GoRouter>(), returnsNormally);
    });
  });
}
