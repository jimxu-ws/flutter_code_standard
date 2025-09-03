import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';

/// 主页屏幕
/// 
/// 展示应用的主要功能入口
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 模块解耦示例'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 欢迎信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '欢迎使用模块解耦示例',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '这是一个展示 Flutter 模块解耦最佳实践的示例应用。',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '主要特性：',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem('🎯', '接口包设计'),
                      _buildFeatureItem('🔧', '依赖注入管理'),
                      _buildFeatureItem('🏗️', '路由解耦'),
                      _buildFeatureItem('📊', '状态管理'),
                      _buildFeatureItem('⚠️', '异常处理'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 功能按钮
              const Text(
                '模块功能',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 用户模块
              _buildModuleButton(
                context,
                title: '用户模块',
                subtitle: '登录、注册、用户信息管理',
                icon: Icons.person,
                color: Colors.blue,
                onTap: () => _navigateToLogin(context),
              ),
              
              const SizedBox(height: 12),
              
              // 支付模块（暂未实现）
              _buildModuleButton(
                context,
                title: '支付模块',
                subtitle: '支付处理、订单管理（开发中）',
                icon: Icons.payment,
                color: Colors.green,
                onTap: () => _showComingSoon(context, '支付模块'),
                enabled: false,
              ),
              
              const SizedBox(height: 12),
              
              // 通知模块（暂未实现）
              _buildModuleButton(
                context,
                title: '通知模块',
                subtitle: '推送通知、消息管理（开发中）',
                icon: Icons.notifications,
                color: Colors.orange,
                onTap: () => _showComingSoon(context, '通知模块'),
                enabled: false,
              ),
              
              const SizedBox(height: 12),
              
              // 埋点模块（暂未实现）
              _buildModuleButton(
                context,
                title: '埋点模块',
                subtitle: '数据分析、用户行为追踪（开发中）',
                icon: Icons.analytics,
                color: Colors.purple,
                onTap: () => _showComingSoon(context, '埋点模块'),
                enabled: false,
              ),
              
              const Spacer(),
              
              // 底部信息
              const Text(
                '🚀 Flutter 模块解耦最佳实践示例\n版本 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
  
  Widget _buildModuleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: enabled ? 2 : 0,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: enabled ? Colors.grey : Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigateToLogin(BuildContext context) {
    try {
      GetIt.instance<IUserNavigator>().toLogin();
    } catch (e) {
      _showError(context, '导航失败：$e');
    }
  }
  
  void _showComingSoon(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName 即将推出，敬请期待！'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
