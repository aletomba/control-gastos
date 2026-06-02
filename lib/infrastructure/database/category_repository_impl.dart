import 'package:drift/drift.dart';

import '../../domain/entities/category.dart' as domain;
import '../../domain/repositories/i_category_repository.dart';
import 'app_database.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  CategoryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<domain.Category>> getAll() async {
    final rows = await _db.select(_db.categories).get();
    return rows.map<domain.Category>(AppDatabase.toDomainCategory).toList();
  }

  @override
  Future<domain.Category?> getById(int id) async {
    final row = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row != null ? AppDatabase.toDomainCategory(row) : null;
  }

  @override
  Future<domain.Category> insert(domain.Category category) async {
    final id = await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            name: category.name,
            colorHex: category.colorHex,
            icon: category.icon,
            keywords: category.keywords.join('|'),
          ),
        );
    return category.copyWith(id: id);
  }

  @override
  Future<void> update(domain.Category category) async {
    await (_db.update(_db.categories)
          ..where((c) => c.id.equals(category.id)))
        .write(CategoriesCompanion(
      name: Value(category.name),
      colorHex: Value(category.colorHex),
      icon: Value(category.icon),
      keywords: Value(category.keywords.join('|')),
    ));
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  @override
  Future<void> seedDefaults() async {
    final existing = await _db.select(_db.categories).get();
    if (existing.isNotEmpty) return;
    for (final data in domain.DefaultCategories.values) {
      await _db.into(_db.categories).insert(
            CategoriesCompanion.insert(
              name: data['name'] as String,
              colorHex: data['colorHex'] as String,
              icon: data['icon'] as String,
              keywords: (data['keywords'] as List<dynamic>).join('|'),
            ),
          );
    }
  }
}
