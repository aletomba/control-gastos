import '../entities/category.dart';

abstract interface class ICategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(int id);
  Future<Category> insert(Category category);
  Future<void> update(Category category);
  Future<void> delete(int id);
  Future<void> seedDefaults();
}
