import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🎣 Hooks vs @riverpod 对比演示
class HooksComparison extends StatelessWidget {
  const HooksComparison({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎣 Hooks vs @riverpod'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OverviewCard(),
            const SizedBox(height: 16),
            _CodeComparisonCard(),
            const SizedBox(height: 16),
            _AdvantagesCard(),
            const SizedBox(height: 16),
            _UseCasesCard(),
          ],
        ),
      ),
    );
  }
}

/// 概览卡片
class _OverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 方案对比概览',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _SolutionCard(
                    title: '🎣 Hooks 方案',
                    subtitle: 'React 风格',
                    color: Colors.blue,
                    features: [
                      '5 行代码',
                      'React 开发者熟悉',
                      '函数式编程',
                      '自动状态管理',
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SolutionCard(
                    title: '🏗️ @riverpod 方案',
                    subtitle: 'Flutter 原生',
                    color: Colors.green,
                    features: [
                      '25 行代码',
                      'Flutter 官方推荐',
                      '面向对象',
                      '手动状态管理',
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<String> features;

  const _SolutionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Icon(Icons.check, size: 12, color: color.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// 代码对比卡片
class _CodeComparisonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💻 代码对比',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Hooks 版本
            _CodeBlock(
              title: '🎣 Hooks 版本 (5 行)',
              color: Colors.blue,
              code: '''class PayrollWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payroll = useSmartQuery<PayrollData>(
      ref: ref,
      fetchFn: () => ApiService.getPayroll(),
      staleTime: Duration(minutes: 5),
    );

    if (payroll.isLoading) return CircularProgressIndicator();
    if (payroll.hasError) return Text('Error: \${payroll.error}');
    
    return ListView(
      children: payroll.data!.employees.map((e) => 
        ListTile(title: Text(e.name))
      ).toList(),
    );
  }
}''',
            ),
            
            SizedBox(height: 16),
            
            // @riverpod 版本
            _CodeBlock(
              title: '🏗️ @riverpod 版本 (25+ 行)',
              color: Colors.green,
              code: '''@Riverpod(keepAlive: true)
class PayrollCheck extends _\$PayrollCheck {
  late final _fetcher = ref.cachedFetcher<PayrollData>(
    fetchFn: () => ref.read(apiClientProvider).getPayroll(),
    onData: (result) => state = state.copyWith(
      payrollResult: result,
      employees: result.employees,
    ),
    onLoading: () => state = state.copyWith(
      payrollResult: Result.pending(),
    ),
    onError: (error) => state = state.copyWith(
      payrollResult: Result.fail(),
    ),
    cacheKey: 'payroll-data',
    staleTime: Duration(minutes: 5),
  );

  @override
  PayrollCheckModel build() => PayrollCheckModel();

  Future<void> getPayroll() => _fetcher.fetch();
  Future<void> refreshPayroll() => _fetcher.refresh();
  void clearCache() => _fetcher.clearCache();
}

class PayrollWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(payrollCheckProvider);
    
    if (state.payrollResult?.isLoading == true) 
      return CircularProgressIndicator();
    if (state.payrollResult?.hasError == true) 
      return Text('Error');
      
    return ListView(
      children: state.employees?.map((e) => 
        ListTile(title: Text(e.name))
      ).toList() ?? [],
    );
  }
}''',
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String title;
  final Color color;
  final String code;

  const _CodeBlock({
    required this.title,
    required this.color,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// 优势分析卡片
class _AdvantagesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚖️ 优势对比',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _AdvantageComparison(
              category: '开发效率',
              hooksAdvantage: '极高 - 5行代码完成',
              riverpodAdvantage: '中等 - 需要更多样板代码',
              winner: 'hooks',
            ),
            _AdvantageComparison(
              category: '学习曲线',
              hooksAdvantage: '低 - React开发者无缝切换',
              riverpodAdvantage: '中 - 需要学习Flutter特有概念',
              winner: 'hooks',
            ),
            _AdvantageComparison(
              category: '代码可读性',
              hooksAdvantage: '高 - 线性逻辑，易理解',
              riverpodAdvantage: '中 - 分散在多个方法中',
              winner: 'hooks',
            ),
            _AdvantageComparison(
              category: '类型安全',
              hooksAdvantage: '完全类型安全',
              riverpodAdvantage: '完全类型安全',
              winner: 'tie',
            ),
            _AdvantageComparison(
              category: '性能',
              hooksAdvantage: '优秀 - 底层相同',
              riverpodAdvantage: '优秀 - 底层相同',
              winner: 'tie',
            ),
            _AdvantageComparison(
              category: 'Flutter 集成',
              hooksAdvantage: '好 - 需要额外依赖',
              riverpodAdvantage: '优秀 - 官方推荐方案',
              winner: 'riverpod',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvantageComparison extends StatelessWidget {
  final String category;
  final String hooksAdvantage;
  final String riverpodAdvantage;
  final String winner; // 'hooks', 'riverpod', 'tie'

  const _AdvantageComparison({
    required this.category,
    required this.hooksAdvantage,
    required this.riverpodAdvantage,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ComparisonItem(
                  title: '🎣 Hooks',
                  content: hooksAdvantage,
                  isWinner: winner == 'hooks',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ComparisonItem(
                  title: '🏗️ @riverpod',
                  content: riverpodAdvantage,
                  isWinner: winner == 'riverpod',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  final String title;
  final String content;
  final bool isWinner;
  final Color color;

  const _ComparisonItem({
    required this.title,
    required this.content,
    required this.isWinner,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isWinner 
          ? color.withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isWinner 
            ? color.withValues(alpha: 0.4)
            : Colors.grey.withValues(alpha: 0.2),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? color.withValues(alpha: 0.7) : Colors.grey.withValues(alpha: 0.7),
                ),
              ),
              if (isWinner) ...[
                const SizedBox(width: 4),
                Icon(Icons.star, size: 12, color: Colors.amber[600]),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// 使用场景卡片
class _UseCasesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 使用场景建议',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            _UseCaseItem(
              icon: '🎣',
              title: '推荐使用 Hooks 的场景',
              color: Colors.blue,
              scenarios: [
                '团队有 React 开发经验',
                '追求极简的代码风格',
                '快速原型开发',
                '简单到中等复杂度的状态管理',
                '偏好函数式编程风格',
              ],
            ),
            
            SizedBox(height: 16),
            
            _UseCaseItem(
              icon: '🏗️',
              title: '推荐使用 @riverpod 的场景',
              color: Colors.green,
              scenarios: [
                '大型企业级应用',
                '需要最大化 Flutter 生态集成',
                '团队偏好面向对象编程',
                '需要复杂的状态管理逻辑',
                '长期维护的项目',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UseCaseItem extends StatelessWidget {
  final String icon;
  final String title;
  final Color color;
  final List<String> scenarios;

  const _UseCaseItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.scenarios,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...scenarios.map((scenario) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: color.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scenario,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
