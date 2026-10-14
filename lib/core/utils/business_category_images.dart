const businessCategoryImageAssets = <String, String>{
  'Mecánica': 'assets/images/business_categories/mecanica.jpg',
  'Salud': 'assets/images/business_categories/salud.jpg',
  'Restaurantes': 'assets/images/business_categories/restaurantes.jpg',
  'Hoteles': 'assets/images/business_categories/hoteles.jpg',
  'Ferretería': 'assets/images/business_categories/ferreteria.jpg',
  'Abarrotes': 'assets/images/business_categories/otro.jpg',
  'Tecnología': 'assets/images/business_categories/tecnologia.jpg',
  'Turismo': 'assets/images/business_categories/transporte.webp',
  'Comercio': 'assets/images/business_categories/otro.jpg',
  'Productores locales': 'assets/images/business_categories/otro.jpg',
};

String businessCategoryImageAsset(String category) =>
    businessCategoryImageAssets[category] ??
    businessCategoryImageAssets['Restaurantes']!;
