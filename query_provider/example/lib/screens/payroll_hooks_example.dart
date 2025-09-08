import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:query_provider/query_provider.dart';

// import '../../api_requests/get_payroll.dart';
// import '../../models/payroll_check_model.f.dart';

/// 🚀 使用 flutter_hooks 实现的 PayrollCheck
/// 比 @riverpod 版本更加简洁和直观
class PayrollHooksExample extends HookConsumerWidget {
  const PayrollHooksExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 使用 hooks 版本 - 超级简洁！
    // final payrollQuery = useSmartQuery<Result<GetPayrollResponse>>(
    //   ref: ref,
    //   fetchFn: () => ref.read(apiClientProvider).getPayroll(),
    //   cacheKey: 'payroll-data-hooks',
    //   staleTime: const Duration(minutes: 5),
    //   enableBackgroundRefresh: true,
    //   enableWindowFocusRefresh: true,
    // );

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎣 Hooks 版本'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ComparisonCard(),
            const SizedBox(height: 16),
            _HooksImplementation(),
            const SizedBox(height: 16),
            _StatusCard(/* payrollQuery */),
            const SizedBox(height: 16),
            _ActionButtons(/* payrollQuery */),
            const SizedBox(height: 16),
            _EmployeesList(/* payrollQuery */),
          ],
        ),
      ),
    );
  }
}

/// 对比说明卡片
class _ComparisonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎣 Hooks vs @riverpod 对比',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            _ComparisonRow(
              label: '代码行数',
              hooksValue: '5 行',
              riverpodValue: '25 行',
              hooksWins: true,
            ),
            _ComparisonRow(
              label: '学习曲线',
              hooksValue: 'React 开发者熟悉',
              riverpodValue: '需要学习 @riverpod',
              hooksWins: true,
            ),
            _ComparisonRow(
              label: '类型安全',
              hooksValue: '完全类型安全',
              riverpodValue: '完全类型安全',
              hooksWins: false,
            ),
            _ComparisonRow(
              label: '性能',
              hooksValue: '相同（底层一致）',
              riverpodValue: '相同（底层一致）',
              hooksWins: false,
            ),
            _ComparisonRow(
              label: '功能完整性',
              hooksValue: '完整（包装层）',
              riverpodValue: '完整（原生）',
              hooksWins: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String hooksValue;
  final String riverpodValue;
  final bool hooksWins;

  const _ComparisonRow({
    required this.label,
    required this.hooksValue,
    required this.riverpodValue,
    required this.hooksWins,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  hooksWins ? Icons.star : Icons.star_border,
                  color: hooksWins ? Colors.amber : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hooksValue,
                    style: TextStyle(
                      color: hooksWins ? Colors.green[700] : Colors.grey[700],
                      fontWeight: hooksWins ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              riverpodValue,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hooks 实现代码展示
class _HooksImplementation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💻 Hooks 实现代码',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Text(
                '''class PayrollWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 一个 hook 搞定所有逻辑！
    final payrollQuery = useSmartQuery<Result<GetPayrollResponse>>(
      ref: ref,
      fetchFn: () => ref.read(apiClientProvider).getPayroll(),
      cacheKey: 'payroll-data-hooks',
      staleTime: const Duration(minutes: 5),
      enableBackgroundRefresh: true,
      enableWindowFocusRefresh: true,
    );

    // 🎯 直接使用查询结果
    if (payrollQuery.isLoading) return CircularProgressIndicator();
    if (payrollQuery.hasError) return Text('Error: \${payrollQuery.error}');
    
    final employees = payrollQuery.data?.response?.employees ?? [];
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(employees[index].name),
        trailing: ElevatedButton(
          onPressed: payrollQuery.refetch, // 🔄 一键刷新
          child: Text('Refresh'),
        ),
      ),
    );
  }
}''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '✨ 只需 5 行核心代码，就能获得完整的缓存、刷新、生命周期管理功能！',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 状态显示卡片
class _StatusCard extends StatelessWidget {
  // final SmartQueryResult<Result<GetPayrollResponse>>? payrollQuery;
  
  const _StatusCard(/* this.payrollQuery */);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 查询状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // 取消注释以显示实际状态：
            /*
            _StatusRow('数据状态', payrollQuery?.hasData == true ? '✅ 有数据' : '❌ 无数据'),
            _StatusRow('加载状态', payrollQuery?.isLoading == true ? '🔄 加载中' : '⏸️ 空闲'),
            _StatusRow('获取状态', payrollQuery?.isFetching == true ? '🔄 获取中' : '⏸️ 空闲'),
            _StatusRow('缓存状态', payrollQuery?.isCached == true ? '✅ 已缓存' : '❌ 无缓存'),
            _StatusRow('过期状态', payrollQuery?.isStale == true ? '⚠️ 已过期' : '✅ 新鲜'),
            _StatusRow('错误状态', payrollQuery?.hasError == true ? '❌ 有错误' : '✅ 无错误'),
            if (payrollQuery?.data?.response?.employees != null)
              _StatusRow('员工数量', '${payrollQuery!.data!.response!.employees!.length}'),
            */
            
            // 演示数据
            _StatusRow('数据状态', '需要取消注释以查看实际状态'),
            _StatusRow('加载状态', '演示模式'),
            _StatusRow('获取状态', '演示模式'),
            _StatusRow('缓存状态', '演示模式'),
            _StatusRow('过期状态', '演示模式'),
            _StatusRow('错误状态', '演示模式'),
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
class _ActionButtons extends StatelessWidget {
  // final SmartQueryResult<Result<GetPayrollResponse>>? payrollQuery;
  
  const _ActionButtons(/* this.payrollQuery */);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // payrollQuery?.refetch();
                  _showSnackBar(context, '重新获取数据！（演示模式）');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重新获取'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // payrollQuery?.refresh();
                  _showSnackBar(context, '强制刷新！（演示模式）');
                },
                icon: const Icon(Icons.refresh_outlined),
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // payrollQuery?.clearCache();
              _showSnackBar(context, '缓存已清除！（演示模式）');
            },
            icon: const Icon(Icons.clear),
            label: const Text('清除缓存'),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// 员工列表
class _EmployeesList extends StatelessWidget {
  // final SmartQueryResult<Result<GetPayrollResponse>>? payrollQuery;
  
  const _EmployeesList(/* this.payrollQuery */);

  @override
  Widget build(BuildContext context) {
    // final employees = payrollQuery?.data?.response?.employees;
    
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
            
            // 根据查询状态显示不同内容
            // if (payrollQuery?.isLoading == true)
            //   const Center(
            //     child: Padding(
            //       padding: EdgeInsets.all(32),
            //       child: CircularProgressIndicator(),
            //     ),
            //   )
            // else if (payrollQuery?.hasError == true)
            //   Container(
            //     padding: const EdgeInsets.all(16),
            //     decoration: BoxDecoration(
            //       color: Colors.red.withValues(alpha: 0.1),
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            //     ),
            //     child: Row(
            //       children: [
            //         const Icon(Icons.error_outline, color: Colors.red),
            //         const SizedBox(width: 8),
            //         Expanded(
            //           child: Text('加载失败: ${payrollQuery!.error}'),
            //         ),
            //       ],
            //     ),
            //   )
            // else if (employees == null || employees.isEmpty)
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
                      '暂无员工数据\n取消注释以查看实际数据',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
            // else
            //   Container(
            //     height: 200,
            //     child: ListView.builder(
            //       itemCount: employees.length,
            //       itemBuilder: (context, index) {
            //         final employee = employees[index];
            //         return ListTile(
            //           leading: CircleAvatar(
            //             child: Text(employee.name[0]),
            //           ),
            //           title: Text(employee.name),
            //           subtitle: Text(employee.position ?? '未知职位'),
            //           trailing: Row(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               if (payrollQuery?.isFetching == true)
            //                 const SizedBox(
            //                   width: 16,
            //                   height: 16,
            //                   child: CircularProgressIndicator(strokeWidth: 2),
            //                 ),
            //               const Icon(Icons.arrow_forward_ios, size: 16),
            //             ],
            //           ),
            //         );
            //       },
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
