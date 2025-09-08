import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'test.dart'; // 取消注释以使用 PayrollCheck provider

/// 🚀 SmartCachedFetcher 演示
/// 展示 stale-while-revalidate 策略 + 生命周期管理
class SmartPayrollDemo extends ConsumerWidget {
  const SmartPayrollDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Smart Cache 演示'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StrategyExplanation(),
            const SizedBox(height: 16),
            _StatusCard(),
            const SizedBox(height: 16),
            _ActionButtons(),
            const SizedBox(height: 16),
            _EmployeesSection(),
            const SizedBox(height: 16),
            _FeatureHighlights(),
          ],
        ),
      ),
    );
  }
}

/// 策略说明卡片
class _StrategyExplanation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Stale-While-Revalidate 策略',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _StrategyStep(
              icon: '⚡',
              title: '立即响应',
              description: '有缓存时立即显示数据，用户体验极佳',
            ),
            _StrategyStep(
              icon: '🔄',
              title: '后台刷新',
              description: '同时在后台获取最新数据，保证数据新鲜度',
            ),
            _StrategyStep(
              icon: '✨',
              title: '静默更新',
              description: '新数据到达时静默更新UI，无Loading干扰',
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyStep extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _StrategyStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 状态显示卡片
class _StatusCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final payrollState = ref.watch(payrollCheckProvider);
    // final notifier = ref.read(payrollCheckProvider.notifier);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 实时状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // 取消注释以显示实际状态：
            /*
            _StatusRow('缓存状态', notifier.hasCache ? '✅ 已缓存' : '❌ 无缓存'),
            _StatusRow('数据状态', notifier.isStale ? '⚠️ 已过期' : '✅ 新鲜'),
            _StatusRow('获取状态', notifier.isFetching ? '🔄 获取中' : '⏸️ 空闲'),
            _StatusRow('缓存键', notifier.cacheKey),
            if (payrollState.employeesList != null)
              _StatusRow('员工数量', '${payrollState.employeesList!.length}'),
            */
            
            // 演示数据
            _StatusRow('缓存状态', '需要取消注释 provider 导入'),
            _StatusRow('数据状态', '演示模式'),
            _StatusRow('获取状态', '演示模式'),
            _StatusRow('缓存键', 'smart-cached-demo'),
            _StatusRow('员工数量', '0'),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatusRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _refreshPayroll(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('强制刷新'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
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
                onPressed: () => _simulateWindowFocus(ref),
                icon: const Icon(Icons.visibility),
                label: const Text('模拟窗口聚焦'),
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
      _showSnackBar('强制刷新成功！（演示模式）');
    } catch (e) {
      _showSnackBar('刷新失败: $e');
    }
  }

  void _clearCache(WidgetRef ref) {
    // ref.read(payrollCheckProvider.notifier).clearPayrollCache();
    _showSnackBar('缓存已清除！（演示模式）');
  }

  void _simulateWindowFocus(WidgetRef ref) {
    // ref.read(payrollCheckProvider.notifier).onWindowFocus();
    _showSnackBar('已触发窗口聚焦刷新！（演示模式）');
  }

  void _showSnackBar(String message) {
    // 在实际应用中，你需要传递 BuildContext
    print(message);
  }
}

/// 员工列表部分
class _EmployeesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final payrollState = ref.watch(payrollCheckProvider);
    // final employees = payrollState.employeesList;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👥 员工列表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // employees == null || employees.isEmpty ? 
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      '暂无员工数据\n取消注释 provider 导入来查看实际数据',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
            /*
            : Container(
                height: 200,
                child: ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(employee.name[0]),
                      ),
                      title: Text(employee.name),
                      subtitle: Text(employee.position ?? '未知职位'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    );
                  },
                ),
              ),
            */
          ],
        ),
      ),
    );
  }
}

/// 功能亮点
class _FeatureHighlights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✨ SmartCachedFetcher 核心特性',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            _FeatureItem(
              icon: '⚡',
              title: 'Stale-While-Revalidate',
              description: '立即返回缓存，后台刷新数据',
              highlight: true,
            ),
            _FeatureItem(
              icon: '🔄',
              title: '智能后台刷新',
              description: '应用恢复时自动检查并刷新过期数据',
            ),
            _FeatureItem(
              icon: '👁️',
              title: '窗口聚焦刷新',
              description: '窗口重新聚焦时自动刷新过期数据',
            ),
            _FeatureItem(
              icon: '⏱️',
              title: '灵活的过期策略',
              description: 'staleTime 控制数据新鲜度判断',
            ),
            _FeatureItem(
              icon: '🎯',
              title: '极简接入',
              description: '一行配置，三行代码完成复杂缓存逻辑',
              highlight: true,
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '💡 代码对比：从原来的 113 行减少到 25 行核心代码，'
                '减少了 78% 的代码量，同时获得了更强大的缓存策略！',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool highlight;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: highlight ? BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: highlight ? Colors.amber[800] : null,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
