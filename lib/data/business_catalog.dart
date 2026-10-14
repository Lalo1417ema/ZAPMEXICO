import '../core/utils/business_category_images.dart';
import 'openstreetmap_businesses.dart';

const businessCategories = [
  'Mecánica',
  'Salud',
  'Restaurantes',
  'Hoteles',
  'Ferretería',
  'Abarrotes',
  'Tecnología',
  'Turismo',
  'Comercio',
  'Productores locales',
];

const regionMunicipalities = ['Ciudad Hidalgo', 'Senguio'];

List<Map<String, dynamic>> createInitialBusinessCatalog() => [
  for (final business in [
    ...createOpenStreetMapBusinesses(),
    ..._additionalPublicBusinesses,
  ])
    if (businessCategories.contains(business['category']) &&
        regionMunicipalities.contains(business['city']) &&
        _hasMoreThanHalfOfRequiredDetails(business))
      business,
];

bool _hasMoreThanHalfOfRequiredDetails(Map<String, dynamic> business) {
  if (business['category'] == 'Turismo' ||
      business['id'] == 'producer-senguihongo-senguio') {
    return (business['address'] ?? '').toString().trim().isNotEmpty &&
        (business['sourceUrl'] ?? '').toString().trim().isNotEmpty;
  }

  const requiredDetails = ['address', 'phone', 'schedule'];
  final publishedDetails = requiredDetails
      .where((field) => (business[field] ?? '').toString().trim().isNotEmpty)
      .length;

  return publishedDetails > requiredDetails.length / 2;
}

final _additionalPublicBusinesses = <Map<String, dynamic>>[
  _publicBusiness(
    id: 'osm-way-444992030',
    name: 'Hacienda Cantalagua Hotel & Country Club',
    category: 'Hoteles',
    municipality: 'Contepec',
    sourceUrl: 'https://www.openstreetmap.org/way/444992030',
    sourceLicense: 'Open Database License (ODbL) 1.0',
  ),
  _publicBusiness(
    id: 'osm-node-7004219153',
    name: 'El Llano',
    category: 'Restaurantes',
    municipality: 'Senguio',
    sourceUrl: 'https://www.openstreetmap.org/node/7004219153',
    sourceLicense: 'Open Database License (ODbL) 1.0',
  ),
  _publicBusiness(
    id: 'facebook-la-estancia-ciudad-hidalgo',
    name: 'Restaurante La Estancia',
    category: 'Restaurantes',
    municipality: 'Ciudad Hidalgo',
    address: 'Vidal Solís 52',
    phone: '786 154 1211',
    facebook:
        'https://www.facebook.com/people/Restaurante-La-Estancia/100057645241066/',
    instagram: 'https://www.instagram.com/laestancia_mx/',
    sourceUrl:
        'https://www.facebook.com/people/Restaurante-La-Estancia/100057645241066/',
    sourceLicense: '',
  ),
  _publicBusiness(
    id: 'facebook-geugaz-jan-ciudad-hidalgo',
    name: 'Geugaz Jan',
    category: 'Restaurantes',
    municipality: 'Ciudad Hidalgo',
    sourceUrl:
        'https://www.facebook.com/search/top?q=Geugaz%20Jan%20Ciudad%20Hidalgo',
    sourceLicense: '',
  ),
  _publicBusiness(
    id: 'facebook-la-casona-ciudad-hidalgo',
    name: 'La Casona Restaurante',
    category: 'Restaurantes',
    municipality: 'Ciudad Hidalgo',
    sourceUrl:
        'https://www.facebook.com/search/top?q=La%20Casona%20Restaurante%20Ciudad%20Hidalgo',
    sourceLicense: '',
  ),
  _publicBusiness(
    id: 'facebook-taboo-ciudad-hidalgo',
    name: 'Taboo Bar & Grill',
    category: 'Restaurantes',
    municipality: 'Ciudad Hidalgo',
    sourceUrl:
        'https://www.facebook.com/search/top?q=Taboo%20Bar%20Grill%20Ciudad%20Hidalgo',
    sourceLicense: '',
  ),
  _publicBusiness(
    id: 'facebook-el-molino-ciudad-hidalgo',
    name: 'El Molino Restaurante',
    category: 'Restaurantes',
    municipality: 'Ciudad Hidalgo',
    sourceUrl: 'https://www.facebook.com/ElMolinoRestauranteCdHgo/',
    sourceLicense: '',
  ),
  _publicBusiness(
    id: 'web-cd-hacienda',
    name: 'Restaurante La Hacienda',
    category: 'Restaurantes',
    municipality: 'Ciudad Hidalgo',
    address: 'Av. Juárez 13A',
    phone: '786 154 3735',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Restaurante+La+Hacienda+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'web-ferreteria-marin',
    name: 'Ferretería Marín',
    category: 'Ferretería',
    municipality: 'Ciudad Hidalgo',
    phone: '786 139 2530',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Ferreteria+Marin+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'web-plomeria-casa-tello',
    name: 'Plomería Casa Tello',
    category: 'Ferretería',
    municipality: 'Ciudad Hidalgo',
    address: 'Melchor Ocampo Poniente 76',
    phone: '786 154 4984',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Plomeria+Casa+Tello+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'web-abarrotes-perez',
    name: 'Abarrotes, Vinos y Forrajes Pérez',
    category: 'Abarrotes',
    municipality: 'Ciudad Hidalgo',
    description:
        'Comercio de abarrotes, vinos, forrajes y productos para animales, '
        'según su ficha en el directorio local. Imagen ilustrativa de la '
        'categoría; no es una fotografía del establecimiento.',
    sourceUrl: 'https://www.cdhidalgo.com/servicios',
    sourceLicense: '',
  ),
  _publicBusiness(
    id: 'web-camelinas-tuxpan',
    name: 'Camelinas Tuxpan Mich',
    category: 'Restaurantes',
    municipality: 'Tuxpan',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=CAMELINAS+TUXPAN+MICH+Michoacan',
  ),
  _publicBusiness(
    id: 'web-el-tasajo-tuxpan',
    name: 'Restaurante El Tasajo',
    category: 'Restaurantes',
    municipality: 'Tuxpan',
    address: 'Km. 134.5, carretera Toluca-Morelia',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Restaurante+El+Tasajo+Tuxpan+Michoacan',
  ),
  _publicBusiness(
    id: 'web-la-santa-tuxpan',
    name: 'La Santa',
    category: 'Restaurantes',
    municipality: 'Tuxpan',
    address: 'Benedicto López Tejada 5',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=La+Santa+Tuxpan+Michoacan',
  ),
  _publicBusiness(
    id: 'web-mail-zitacuaro',
    name: 'M@il Fábrica de Asados y Azúcar',
    category: 'Restaurantes',
    municipality: 'Zitácuaro',
    address: 'Andrés Landa y Piña Norte 93',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Mail+Fabrica+de+Asados+y+Azucar+Zitacuaro',
  ),
  _publicBusiness(
    id: 'web-habanero-zitacuaro',
    name: 'Habanero Cocina Mar y Tierra',
    category: 'Restaurantes',
    municipality: 'Zitácuaro',
    address: 'Cuauhtémoc Oriente 65',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Habanero+Cocina+Mar+y+Tierra+Zitacuaro',
  ),
  _publicBusiness(
    id: 'web-cabana-zitacuaro',
    name: 'La Cabaña de Don Bar-Bar',
    category: 'Restaurantes',
    municipality: 'Zitácuaro',
    address: 'Libramiento J. Francisco Mújica 350',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=La+Cabana+de+Don+Bar+Bar+Zitacuaro',
  ),
  _publicBusiness(
    id: 'web-los-de-asada-irimbo',
    name: 'Los de Asada - Irimbo',
    category: 'Restaurantes',
    municipality: 'Irimbo',
    address: 'Melchor Ocampo Poniente 32, Col. Nueva España',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Los+de+Asada+Irimbo+Michoacan',
  ),
  _publicBusiness(
    id: 'web-mariscos-mirador-tuzantla',
    name: 'Mariscos El Mirador de Tuzantla',
    category: 'Restaurantes',
    municipality: 'Tuzantla',
    address: 'Av. Curindal s/n, Col. Mesa de Morelos 1',
    phone: '786 107 7239',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Mariscos+El+Mirador+de+Tuzantla',
  ),
  _publicBusiness(
    id: 'web-posada-colorines-zinapecuaro',
    name: 'Hotel Posada Los Colorines',
    category: 'Hoteles',
    municipality: 'Zinapécuaro',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Hotel+Posada+Los+Colorines+Zinapecuaro',
  ),
  _publicBusiness(
    id: 'web-meson-puente-zinapecuaro',
    name: 'Hotel Mesón del Puente',
    category: 'Hoteles',
    municipality: 'Zinapécuaro',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Hotel+Meson+del+Puente+Zinapecuaro',
  ),
  _publicBusiness(
    id: 'web-quinta-azufres-zinapecuaro',
    name: 'Quinta Los Azufres',
    category: 'Hoteles',
    municipality: 'Zinapécuaro',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Quinta+Los+Azufres+Zinapecuaro',
  ),
  _publicBusiness(
    id: 'web-casa-rayita-aporo',
    name: 'Casa Rayita',
    category: 'Hoteles',
    municipality: 'Áporo',
    address: 'Reforma 2, Centro',
    phone: '786 100 0549',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Casa+Rayita+Aporo+Michoacan',
  ),
  _publicBusiness(
    id: 'web-hotel-el-paraiso-epitacio-huerta',
    name: 'Hotel El Paraíso',
    category: 'Hoteles',
    municipality: 'Epitacio Huerta',
    address: 'Hidalgo, Centro',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Hotel+El+Paraiso+Epitacio+Huerta+Michoacan',
  ),
  _publicBusiness(
    id: 'web-hotel-ocampo-maravatio',
    name: 'Hotel Ocampo',
    category: 'Hoteles',
    municipality: 'Maravatío',
    address: 'Portal 5 de Mayo 46, Centro',
    phone: '447 478 2174',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Hotel+Ocampo+Maravatio+Michoacan',
  ),
  _publicBusiness(
    id: 'grocery-tiendas-3b-senguio',
    name: 'Tiendas 3B',
    category: 'Abarrotes',
    municipality: 'Senguio',
    address: 'Benito Juárez, Juárez, 61290 Senguio, Michoacán',
    phone: '55 4510 9999',
    schedule: 'Cierra a las 21:00',
    website: 'https://www.tiendas3b.com/',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Tiendas+3B+Senguio+Michoacan',
  ),
  _publicBusiness(
    id: 'restaurant-los-arcos-senguio',
    name: 'Restaurante y Cafetería Los Arcos',
    category: 'Restaurantes',
    municipality: 'Senguio',
    address: 'Portal Victoria 3, El Dólar, 61290 Senguio, Michoacán',
    phone: '55 3191 8539',
    facebook: 'https://www.facebook.com/LosArcosSenguio/',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Restaurante+y+Cafeteria+Los+Arcos+Senguio+Michoacan',
  ),
  _publicBusiness(
    id: 'repair-my-phone-senguio',
    name: 'Repair My Phone',
    category: 'Tecnología',
    municipality: 'Senguio',
    address: 'Centro, 61290 Senguio, Michoacán',
    phone: '447 101 7691',
    schedule: 'Lunes a viernes, 10:00 a 17:00; sábado cerrado',
    facebook: 'https://www.facebook.com/jovaniriosreyes/',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Repair+My+Phone+Senguio+Michoacan',
  ),
  _publicBusiness(
    id: 'hardware-la-hormiga-senguio',
    name: 'Ferretería La Hormiga - Refaccionaría Fénix',
    category: 'Ferretería',
    municipality: 'Senguio',
    address:
        'Benito Juárez 57, rumbo a la secundaria, 61290 Senguio, Michoacán',
    phone: '786 155 5077',
    schedule:
        'La ficha consultada indica apertura a las 7:00; no publica el horario completo.',
    facebook:
        'https://www.facebook.com/people/Ferreter%C3%ADa-La-Hormiga-Refaccionar%C3%ADa-F%C3%A9nix/61582346903025/',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Materiales+La+Hormiga+Senguio+Michoacan',
  ),
  _publicBusiness(
    id: 'plaza-monarca-senguio',
    name: 'Plaza Monarca',
    category: 'Comercio',
    municipality: 'Senguio',
    address: 'Hidalgo, 61290 Senguio, Michoacán',
    schedule:
        'Lunes a domingo, 9:00 a 17:00; puede variar por establecimiento.',
    facebook: 'https://www.facebook.com/p/Plaza-Monarca-100063647378611/',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Plaza+Monarca+Senguio+Michoacan',
  ),
  _publicBusiness(
    id: 'producer-senguihongo-senguio',
    name: 'Senguihongo',
    category: 'Productores locales',
    municipality: 'Senguio',
    address:
        'Benito Juárez 57, rumbo a la secundaria, 61290 Senguio, Michoacán',
    facebook: 'https://www.facebook.com/hongosshiitake.senguio/',
    sourceUrl: 'https://www.facebook.com/hongosshiitake.senguio/',
  ),
  _publicBusiness(
    id: 'grocery-la-bodeguita-senguio',
    name: 'La Bodeguita de Senguio',
    category: 'Abarrotes',
    municipality: 'Senguio',
    address: 'Cda. de Hidalgo 49, Melchor Ocampo, 61290 Senguio, Michoacán',
    schedule: 'Lunes a domingo, 8:30 a 21:00',
    facebook: 'https://www.facebook.com/labodeguitadesenguio/',
    sourceUrl:
        'https://www.facebook.com/labodeguitadesenguio/posts/la-bodeguita-el-mejor-negocio-para-tu-negocio/511560111232920/',
  ),
  _publicBusiness(
    id: 'monarch-butterfly-parador-senguio',
    name: 'Parador Turístico del Santuario de la Mariposa Monarca',
    category: 'Turismo',
    municipality: 'Senguio',
    address: 'Municipio de Senguio, Michoacán (ubicación general)',
    description:
        'Parador de acceso al santuario de la mariposa monarca en Senguio. '
        'La Secretaría de Turismo de Michoacán reporta transporte local desde '
        'el parador hasta las zonas de avistamiento y actividades de naturaleza. '
        'Consulta la fuente oficial para información vigente de temporada, '
        'acceso y servicios. Imagen ilustrativa; no es una fotografía del lugar.',
    sourceUrl:
        'https://sectur.michoacan.gob.mx/senguio-invita-a-visitar-santuario-de-las-mariposas-monarca-esta-temporada-sectur/',
  ),
  _publicBusiness(
    id: 'restaurant-el-patio-ciudad-hidalgo',
    name: 'Restaurante El Patio',
    category: 'Restaurantes',
    municipality: 'Ciudad Hidalgo',
    address: 'Vicente Guerrero 32 Bis, Centro, 61100 Ciudad Hidalgo',
    phone: '786 112 4766',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Restaurante+El+Patio+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'pharmacy-openfarma-ciudad-hidalgo',
    name: 'OPENFARMA Cd. Hidalgo Centro',
    category: 'Salud',
    municipality: 'Ciudad Hidalgo',
    address: 'Av. Juárez 1, Centro, 61100 Ciudad Hidalgo',
    phone: '786 156 3719',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=OPENFARMA+Cd+Hidalgo+Centro+Michoacan',
  ),
  _publicBusiness(
    id: 'pharmacy-guadalajara-lerdo-ciudad-hidalgo',
    name: 'Farmacia Guadalajara',
    category: 'Salud',
    municipality: 'Ciudad Hidalgo',
    address: 'C. Lerdo de Tejada 32, Centro, 61100 Ciudad Hidalgo',
    phone: '786 154 8982',
    schedule: 'Abierto las 24 horas',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Farmacia+Guadalajara+Lerdo+de+Tejada+32+Ciudad+Hidalgo',
  ),
  _publicBusiness(
    id: 'mechanic-escobedo-automotive-ciudad-hidalgo',
    name: 'Servicio Mecánico Escobedo Automotive',
    category: 'Mecánica',
    municipality: 'Ciudad Hidalgo',
    address:
        'Segunda Privada de Leona Vicario 2, 61149 Ciudad Hidalgo, Michoacán',
    phone: '786 105 2335',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Servicio+Mecanico+Escobedo+Automotive+Ciudad+Hidalgo',
  ),
  _publicBusiness(
    id: 'mechanic-patino-ciudad-hidalgo',
    name: 'Taller Mecánico Automotriz Patiño',
    category: 'Mecánica',
    municipality: 'Ciudad Hidalgo',
    address: 'Reforma 92, La Mangana, 61100 Ciudad Hidalgo, Michoacán',
    phone: '786 113 3386',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Taller+Mecanico+Automotriz+Patino+Ciudad+Hidalgo',
  ),
  _publicBusiness(
    id: 'hardware-taximaroa-ciudad-hidalgo',
    name: 'Ferretería Taximaroa',
    category: 'Ferretería',
    municipality: 'Ciudad Hidalgo',
    address: 'Plaza Hidalgo 12, Centro, 61100 Ciudad Hidalgo, Michoacán',
    phone: '786 154 4596',
    facebook: 'https://www.facebook.com/taximaroaferreteria/?locale=es_LA',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Ferreteria+Taximaroa+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'hardware-ferreperfiles-ciudad-hidalgo',
    name: 'FerrePerfiles Unión Hidalgo',
    category: 'Ferretería',
    municipality: 'Ciudad Hidalgo',
    address: 'Calle Corregidora, Ciudad Hidalgo, Michoacán',
    phone: '786 141 4301',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=FerrePerfiles+Union+Hidalgo+Ciudad+Hidalgo',
  ),
  _publicBusiness(
    id: 'grocery-dominguez-ciudad-hidalgo',
    name: 'Abarrotera Domínguez y Cía.',
    category: 'Abarrotes',
    municipality: 'Ciudad Hidalgo',
    address: 'Av. Juárez 3, Centro, 61100 Ciudad Hidalgo, Michoacán',
    phone: '786 154 0118',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Abarrotera+Dominguez+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'grocery-merza-ciudad-hidalgo',
    name: 'Tienda Merza Sucursal Ciudad Hidalgo I',
    category: 'Abarrotes',
    municipality: 'Ciudad Hidalgo',
    address: 'Mariano Abasolo 41 Bis, Ciudad Hidalgo, Michoacán',
    phone: '786 154 8302',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Tienda+Merza+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'grocery-maya-ciudad-hidalgo',
    name: 'Abarrotes Maya',
    category: 'Abarrotes',
    municipality: 'Ciudad Hidalgo',
    address: 'Emilio Carranza Oriente 75, Centro, 61100 Ciudad Hidalgo',
    phone: '786 154 2370',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Abarrotes+Maya+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'grocery-camacho-ciudad-hidalgo',
    name: 'Abarrotes Camacho',
    category: 'Abarrotes',
    municipality: 'Ciudad Hidalgo',
    address: '8 de Mayo 46, La Mangana, 61120 Ciudad Hidalgo, Michoacán',
    phone: '786 145 0980',
    facebook: 'https://www.facebook.com/camachoabarrotes/',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Abarrotes+Camacho+Ciudad+Hidalgo+Michoacan',
  ),
  _publicBusiness(
    id: 'hotel-anoranza-ciudad-hidalgo',
    name: 'Añoranza Hotel Boutique',
    category: 'Hoteles',
    municipality: 'Ciudad Hidalgo',
    address: 'Nicolás Bravo 46, Centro, 61100 Ciudad Hidalgo, Michoacán',
    phone: '786 244 1375',
    instagram: 'https://www.instagram.com/anoranza_hotel_boutique/',
    sourceUrl:
        'https://www.google.com/maps/search/?api=1&query=Anoranza+Hotel+Boutique+Ciudad+Hidalgo+Michoacan',
  ),
];

Map<String, dynamic> _publicBusiness({
  required String id,
  required String name,
  required String category,
  required String municipality,
  String address = '',
  String phone = '',
  String schedule = '',
  String facebook = '',
  String instagram = '',
  String website = '',
  String description = '',
  required String sourceUrl,
  String sourceLicense = '',
}) => {
  'id': id,
  'name': name,
  'category': category,
  'description': description.isNotEmpty
      ? description
      : '$category en $municipality, Michoacán. Imagen ilustrativa de la '
            'categoría; no es una fotografía del establecimiento.',
  'address': address,
  'phone': phone,
  'whatsapp': '',
  'email': '',
  'city': municipality,
  'location': '$municipality, Michoacán, México',
  'schedule': schedule,
  'facebook': facebook,
  'instagram': instagram,
  'website': website,
  'logoUrl': businessCategoryImageAsset(category),
  'imageIsIllustrative': true,
  'gallery': <String>[],
  'rating': 0.0,
  'reviewCount': 0,
  'status': 'approved',
  'adminComment': '',
  'createdBy': 'public-directory-research',
  'sourceUrl': sourceUrl,
  'sourceLicense': sourceLicense,
};
