import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/entities/category.dart' as domain_cat;
import '../../domain/entities/transaction.dart' as domain;

part 'app_database.g.dart';

// ─── Tablas ──────────────────────────────────────────────────────────────────

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get colorHex => text().withLength(min: 7, max: 9)();
  TextColumn get icon => text().withLength(min: 1, max: 50)();
  TextColumn get keywords => text()(); // keywords separados por |
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get merchant => text().withLength(min: 1, max: 255)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => text().withLength(min: 1, max: 50)();
  TextColumn get cardLast4 => text().withLength(min: 4, max: 4).nullable()();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  TextColumn get gmailMessageId => text().nullable().unique()();
}

class SyncLog extends Table {
  TextColumn get source => text().withLength(min: 1, max: 50)();
  DateTimeColumn get lastSync => dateTime()();

  @override
  Set<Column> get primaryKey => {source};
}

// ─── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Categories, Transactions, SyncLog])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
        },
      );

  Future<void> _seedCategories() async {
    for (final data in domain_cat.DefaultCategories.values) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: data['name'] as String,
          colorHex: data['colorHex'] as String,
          icon: data['icon'] as String,
          keywords: (data['keywords'] as List<dynamic>).join('|'),
        ),
      );
    }
  }

  // ─── Helpers de mapeo dominio ↔ Drift ──────────────────────────────────────

  static domain.Transaction toDomainTransaction(TransactionRow row) {
    return domain.Transaction(
      id: row.id,
      amount: row.amount,
      merchant: row.merchant,
      date: row.date,
      source: domain.TransactionSource.values
          .firstWhere((e) => e.name == row.source),
      categoryId: row.categoryId,
      cardLast4: row.cardLast4,
      gmailMessageId: row.gmailMessageId,
      isManual: row.isManual,
    );
  }

  static domain_cat.Category toDomainCategory(CategoryRow row) {
    return domain_cat.Category(
      id: row.id,
      name: row.name,
      colorHex: row.colorHex,
      icon: row.icon,
      keywords: row.keywords.isEmpty ? [] : row.keywords.split('|'),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(name: 'control_gastos.db');
  });
}
