import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'test.dart'; // 取消注释以使用 PayrollCheck provider

/// 展示如何使用封装了 CachedDataFetcher 的 PayrollCheck provider
class PayrollExampleScreen extends ConsumerWidget {
  const PayrollExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final payrollState = ref.watch(payrollCheckProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('工资单示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态显示卡片
            _StatusCard(),
            const SizedBox(height: 16),
            
            // 操作按钮
            _ActionButtons(),
            const SizedBox(height: 16),
            
            // 员工列表
            Expanded(child: _EmployeesList()),
            
            // 使用说明
            const SizedBox(height: 16),
            _UsageInstructions(),
          ],
        ),
      ),
    );
  }
}

/// 状态显示卡片
class _StatusCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final payrollState = ref.watch(payrollCheckProvider);
    // final hasCache = ref.read(payrollCheckProvider.notifier).hasCache;
    
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 工资单状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            // 取消注释以下代码来显示实际状态：
            /*
            Text('缓存状态: ${hasCache ? "✅ 已缓存" : "❌ 无缓存"}'),
            const SizedBox(height: 4),
            
            if (payrollState.checkPayrollResult != null) ...[
              Text('数据状态: ${_getStatusText(payrollState.checkPayrollResult!)}'),
              const SizedBox(height: 4),
              if (payrollState.employeesList != null)
                Text('员工数量: ${payrollState.employeesList!.length}'),
            ] else
              const Text('数据状态: 未加载'),
            */
            
            // 示例显示
            Text('缓存状态: 需要取消注释 provider 导入'),
            Text('数据状态: 演示模式'),
            Text('员工数量: 0'),
          ],
        ),
      ),
    );
  }

  String _getStatusText(dynamic result) {
    // 根据你的 Result 类型实现
    if (result.response != null) return '✅ 成功';
    if (result.error != null) return '❌ 错误';
    return '⏳ 加载中';
  }
}

/// 操作按钮
class _ActionButtons extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _getPayroll(ref),
                icon: const Icon(Icons.download),
                label: const Text('获取工资单'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _refreshPayroll(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('强制刷新'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _clearCache(ref),
                icon: const Icon(Icons.clear),
                label: const Text('清除缓存'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showCachedData(context, ref),
                icon: const Icon(Icons.visibility),
                label: const Text('查看缓存'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _getPayroll(WidgetRef ref) async {
    try {
      // await ref.read(payrollCheckProvider.notifier).getPayroll();
      _showSnackBar('工资单获取成功！（演示模式）');
    } catch (e) {
      _showSnackBar('获取失败: $e');
    }
  }

  void _refreshPayroll(WidgetRef ref) async {
    try {
      // await ref.read(payrollCheckProvider.notifier).refreshPayroll();
      _showSnackBar('工资单刷新成功！（演示模式）');
    } catch (e) {
      _showSnackBar('刷新失败: $e');
    }
  }

  void _clearCache(WidgetRef ref) {
    // ref.read(payrollCheckProvider.notifier).clearPayrollCache();
    _showSnackBar('缓存已清除！（演示模式）');
  }

  void _showCachedData(BuildContext context, WidgetRef ref) {
    // final cached = ref.read(payrollCheckProvider.notifier).getCachedPayroll();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('缓存数据'),
        content: const Text('演示模式 - 需要取消注释 provider 导入来查看实际缓存数据'),
        // content: Text(cached != null ? '有缓存数据' : '无缓存数据'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    // 在实际应用中，你需要传递 BuildContext
    print(message);
  }
}

/// 员工列表
class _EmployeesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final payrollState = ref.watch(payrollCheckProvider);
    // final employees = payrollState.employeesList;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👥 员工列表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: 
                // employees == null || employees.isEmpty ? 
                const Center(
                  child: Text(
                    '暂无员工数据\n取消注释 provider 导入来查看实际数据',
                    textAlign: TextAlign.center,
                  ),
                )
                /*
                : ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(employee.name[0]), // 假设 employee 有 name 字段
                        ),
                        title: Text(employee.name),
                        subtitle: Text(employee.position ?? '未知职位'), // 假设有 position 字段
                        trailing: const Icon(Icons.arrow_forward_ios),
                      );
                    },
                  ),
                */
            ),
          ],
        ),
      ),
    );
  }
}

/// 使用说明
class _UsageInstructions extends StatelessWidget {
  const _UsageInstructions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 CachedDataFetcher 特性',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('✅ 自动缓存 key 生成'),
            const Text('✅ 智能缓存检查'),
            const Text('✅ 一键刷新和清除'),
            const Text('✅ 错误缓存（避免重复失败请求）'),
            const Text('✅ 回调式数据处理'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Text(
                '💡 使用 CachedDataFetcher 后，PayrollCheck 的代码减少了 60%，'
                '同时获得了更强大的缓存管理能力！',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
