import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_AR');
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _sourceColor(transaction.source),
          child: Icon(_sourceIcon(transaction.source),
              color: Colors.white, size: 18),
        ),
        title: Text(
          transaction.merchant,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          dateFormat.format(transaction.date) +
              (transaction.cardLast4 != null
                  ? ' · *${transaction.cardLast4}'
                  : ''),
        ),
        trailing: Text(
          currencyFormat.format(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  Color _sourceColor(TransactionSource source) {
    switch (source) {
      case TransactionSource.santanderCredito:
        return const Color(0xFFE53935);
      case TransactionSource.santanderDebito:
        return const Color(0xFFFF7043);
      case TransactionSource.mercadoPago:
        return const Color(0xFF1E88E5);
      case TransactionSource.manual:
        return const Color(0xFF43A047);
    }
  }

  IconData _sourceIcon(TransactionSource source) {
    switch (source) {
      case TransactionSource.santanderCredito:
        return Icons.credit_card;
      case TransactionSource.santanderDebito:
        return Icons.payment;
      case TransactionSource.mercadoPago:
        return Icons.account_balance_wallet;
      case TransactionSource.manual:
        return Icons.edit;
    }
  }
}
