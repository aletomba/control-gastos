import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers.dart';
import '../widgets/month_selector.dart';

class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final categories = ref.watch(categoriesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MonthSelector(
          selected: month,
          onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m,
        ),
        const SizedBox(height: 24),
        Text('Gastos por categoría',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: categoryTotals.when(
            data: (totals) => categories.when(
              data: (cats) {
                if (totals.isEmpty) {
                  return const Center(child: Text('Sin datos este mes'));
                }
                final catMap = {for (final c in cats) c.id: c};
                final sections = totals.entries
                    .where((e) => e.value > 0 && catMap.containsKey(e.key))
                    .map((e) {
                  final cat = catMap[e.key]!;
                  final color = _hexToColor(cat.colorHex);
                  return PieChartSectionData(
                    value: e.value,
                    title: cat.name,
                    color: color,
                    radius: 80,
                    titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  );
                }).toList();
                return PieChart(PieChartData(sections: sections));
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Error'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ),
        const SizedBox(height: 24),
        // Leyenda
        categoryTotals.maybeWhen(
          data: (totals) => categories.maybeWhen(
            data: (cats) {
              final catMap = {for (final c in cats) c.id: c};
              final currencyFmt =
                  NumberFormat.currency(locale: 'es_AR', symbol: '\$');
              return Column(
                children: totals.entries
                    .where((e) => catMap.containsKey(e.key))
                    .map((e) {
                  final cat = catMap[e.key]!;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _hexToColor(cat.colorHex),
                      radius: 10,
                    ),
                    title: Text(cat.name),
                    trailing: Text(currencyFmt.format(e.value),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    dense: true,
                  );
                }).toList(),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
