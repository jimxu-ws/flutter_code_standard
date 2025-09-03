# Flutter 模块解耦最佳实践示例项目

这是一个完整的 Flutter 项目示例，展示了模块解耦、路由解耦、依赖注入等最佳实践。

## 🏗️ 项目架构

```
example_project/
├── lib/                          # 主应用
│   ├── main.dart                 # 应用入口
│   ├── app_router.dart           # 路由聚合
│   ├── src/
│   │   ├── di/                   # 依赖注入配置
│   │   ├── services/             # 核心服务
│   │   └── screens/              # 主应用页面
├── packages/
│   ├── core_interface/           # 🎯 核心接口包
│   ├── user_module/              # 用户模块
│   ├── payment_module/           # 支付模块
│   ├── notification_module/      # 通知模块
│   └── analytics_module/         # 埋点模块
└── pubspec.yaml
```

## 🚀 最佳实践覆盖

- ✅ **模块解耦**：接口包设计、独立仓库管理
- ✅ **路由解耦**：GoRouter + DI 自动注册
- ✅ **依赖注入**：GetIt + Injectable + 跨包管理
- ✅ **状态管理**：Riverpod + Hooks
- ✅ **异常处理**：分层异常架构
- ✅ **JSON 序列化**：类型安全 + 错误处理
- ✅ **代码规范**：命名规范、项目结构

## 🛠️ 运行方式

```bash
# 1. 获取依赖
flutter pub get

# 2. 运行项目
flutter run

# 3. 运行测试
flutter test
```

## 📚 学习路径

1. 先阅读 `core_interface` 了解接口设计
2. 查看各模块的实现方式
3. 理解依赖注入的配置
4. 学习路由解耦的实现
5. 参考异常处理和状态管理
