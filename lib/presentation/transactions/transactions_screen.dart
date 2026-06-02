import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction.dart';
import '../providers.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsByMonthProvider);
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: MonthSelector(
              selected: month,
              onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m,
            ),
          ),
          Expanded(
            child: transactions.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Sin transacciones este mes.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) =>
                      TransactionTile(transaction: list[i] as Transaction),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ).then((_) {
          ref.invalidate(transactionsByMonthProvider);
          ref.invalidate(monthlyTotalProvider);
        }),
        tooltip: 'Agregar gasto manual',
        child: const Icon(Icons.add),
      ),
    );
  }
}
