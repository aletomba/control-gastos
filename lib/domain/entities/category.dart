class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.icon,
    required this.keywords,
  });

  final int id;
  final String name;
  final String colorHex;
  final String icon;
  final List<String> keywords;

  Category copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? icon,
    List<String>? keywords,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      keywords: keywords ?? this.keywords,
    );
  }
}

/// Categorías por defecto precargadas en la app
abstract class DefaultCategories {
  static const List<Map<String, dynamic>> values = [
    {
      'name': 'Supermercados',
      'colorHex': '#4CAF50',
      'icon': 'shopping_cart',
      'keywords': ['DISCO', 'JUMBO', 'CARREFOUR', 'DIA', 'COTO', 'WALMART', 'LA ANONIMA', 'VEA', 'SUPER'],
    },
    {
      'name': 'Restaurantes',
      'colorHex': '#FF9800',
      'icon': 'restaurant',
      'keywords': ['MCDONALDS', 'BURGER', 'PIZZA', 'RESTO', 'RESTAURANT', 'BAR ', 'CAFE ', 'SUSHI', 'PARRILLA'],
    },
    {
      'name': 'Combustible',
      'colorHex': '#F44336',
      'icon': 'local_gas_station',
      'keywords': ['YPF', 'SHELL', 'AXION', 'PETROBRAS', 'PUMA', 'NAFTA'],
    },
    {
      'name': 'Transporte',
      'colorHex': '#2196F3',
      'icon': 'directions_bus',
      'keywords': ['UBER', 'CABIFY', 'TAXI', 'REMIS', 'SUBTE', 'METROBUS', 'TREN'],
    },
    {
      'name': 'Entretenimiento',
      'colorHex': '#9C27B0',
      'icon': 'movie',
      'keywords': ['NETFLIX', 'SPOTIFY', 'DISNEY', 'HBO', 'PRIME', 'CINE', 'TEATRO', 'STEAM'],
    },
    {
      'name': 'Salud',
      'colorHex': '#00BCD4',
      'icon': 'local_hospital',
      'keywords': ['FARMACIA', 'DROGUERIA', 'CLINICA', 'HOSPITAL', 'MEDICO', 'DR ', 'DRA '],
    },
    {
      'name': 'Otros',
      'colorHex': '#9E9E9E',
      'icon': 'category',
      'keywords': [],
    },
  ];
}
