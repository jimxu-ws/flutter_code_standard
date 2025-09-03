import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:core_interface/core_interface.dart';
import '../providers/user_provider.dart';
import '../widgets/login_form_widget.dart';

/// 登录页面
/// 
/// 使用 Flutter Hooks 和 Riverpod 进行状态管理
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 Hooks 管理本地状态
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    
    // 监听用户状态变化
    final userState = ref.watch(userProvider);
    
    // 处理登录
    Future<void> handleLogin() async {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        errorMessage.value = '请输入邮箱和密码';
        return;
      }
      
      isLoading.value = true;
      errorMessage.value = null;
      
      try {
        await ref.read(userProvider.notifier).login(
          emailController.text,
          passwordController.text,
        );
        
        // 登录成功后导航到主页
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        if (e is AppException) {
          errorMessage.value = e.userMessage;
        } else {
          errorMessage.value = '登录失败，请重试';
        }
      } finally {
        isLoading.value = false;
      }
    }
    
    // 处理注册导航
    void handleRegister() {
      Navigator.of(context).pushNamed('/register');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo 或标题
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                '欢迎回来',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请登录您的账户',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // 登录表单
              LoginFormWidget(
                emailController: emailController,
                passwordController: passwordController,
                isLoading: isLoading.value,
                errorMessage: errorMessage.value,
                onLogin: handleLogin,
              ),
              
              const SizedBox(height: 24),
              
              // 注册链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有账户？'),
                  TextButton(
                    onPressed: handleRegister,
                    child: const Text('立即注册'),
                  ),
                ],
              ),
              
              // 错误消息显示
              if (errorMessage.value != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage.value!,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
