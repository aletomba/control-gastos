import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../providers.dart';
import '../transactions/transactions_screen.dart';
import '../charts/charts_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentTab = 0;
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final count = await ref.read(syncEmailsUseCaseProvider).execute();
      ref.invalidate(transactionsByMonthProvider);
      ref.invalidate(monthlyTotalProvider);
      ref.invalidate(categoryTotalsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 ? '$count transacciones nuevas' : 'Sin novedades'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Gastos'),
        actions: [
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _syncing ? null : _sync,
            tooltip: 'Sincronizar emails',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: const [
          _DashboardTab(),
          TransactionsScreen(),
          ChartsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Gastos'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Gráficos'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(monthlyTotalProvider);
    final transactions = ref.watch(transactionsByMonthProvider);
    final month = ref.watch(selectedMonthProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionsByMonthProvider);
        ref.invalidate(monthlyTotalProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MonthSelector(
            selected: month,
            onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m,
          ),
          const SizedBox(height: 16),
          // Total del mes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Total del mes',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  total.when(
                    data: (value) => Text(
                      NumberFormat.currency(locale: 'es_AR', symbol: '\$').format(value),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, _) => const Text('Error'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Últimas transacciones',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          transactions.when(
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Sin transacciones este mes.\nPresioná sync para importar.'),
                  ),
                );
              }
              final recent = list.take(10).toList();
              return Column(
                children: recent
                    .map((t) => TransactionTile(transaction: t as Transaction))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}
