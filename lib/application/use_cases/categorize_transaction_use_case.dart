import '../../domain/repositories/i_category_repository.dart';

/// Busca la categoría que mejor coincide con el nombre del comercio
/// usando keywords. Retorna el id de la categoría "Otros" si no hay match.
class CategorizeTransactionUseCase {
  CategorizeTransactionUseCase(this._categoryRepository);

  final ICategoryRepository _categoryRepository;

  Future<int?> execute(String merchant) async {
    final categories = await _categoryRepository.getAll();
    final upperMerchant = merchant.toUpperCase();

    for (final category in categories) {
      for (final keyword in category.keywords) {
        if (keyword.isNotEmpty && upperMerchant.contains(keyword.toUpperCase())) {
          return category.id;
        }
      }
    }

    // Buscar la categoría "Otros" como fallback
    final otros = categories.where((c) => c.name == 'Otros').firstOrNull;
    return otros?.id;
  }
}
