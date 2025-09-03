import 'package:example_project/src/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'src/di/app_service_registrar.dart';

/// 主应用入口
/// 
/// 负责初始化依赖注入、路由配置和启动应用
void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 启动 Flutter 模块解耦示例应用...');
  
  try {
    // 🎯 注册所有模块的服务
    print('📦 开始注册服务...');
    AppServiceRegistrar.registerAll();
    print('✅ 服务注册完成');
    
    // 启动应用
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('❌ 应用启动失败: $e');
    print('Stack trace: $stackTrace');
    
    // 显示错误页面
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '应用启动失败',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '错误信息: $e',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // 重新启动应用
                    main();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 主应用组件
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从服务定位器获取路由配置
    final routerConfig = GetIt.instance<RouterConfig<Object>>();
    
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      
      // 路由配置
      routerConfig: routerConfig,
      
      // 调试信息
      debugShowCheckedModeBanner: AppConfig.enableDebug,
      showPerformanceOverlay: AppConfig.enablePerformanceOverlay,
      debugShowMaterialGrid: AppConfig.enableGridDebug,
      showSemanticsDebugger: AppConfig.enableSemanticsDebug,
      
      // 错误处理
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling, // 防止系统字体大小影响布局
          ),
          child: child!,
        );
      },
    );
  }
}
