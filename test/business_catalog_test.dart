import 'package:flutter_test/flutter_test.dart';
import 'package:zap_mexico/core/utils/business_category_images.dart';
import 'package:zap_mexico/core/utils/business_field_value.dart';
import 'package:zap_mexico/data/business_catalog.dart';
import 'package:zap_mexico/data/municipal_events.dart';
import 'package:zap_mexico/presentation/providers/business_provider.dart';

void main() {
  test('loads public business records without synthetic businesses', () {
    final businesses = createInitialBusinessCatalog();

    expect(regionMunicipalities, ['Ciudad Hidalgo', 'Senguio']);
    expect(businesses, isNotEmpty);
    expect(
      businesses.map((business) => business['id']).toSet().length,
      businesses.length,
    );
    expect(
      businesses.map((business) => business['id']),
      containsAll([
        'grocery-tiendas-3b-senguio',
        'restaurant-los-arcos-senguio',
        'repair-my-phone-senguio',
        'hardware-la-hormiga-senguio',
        'plaza-monarca-senguio',
        'producer-senguihongo-senguio',
        'grocery-la-bodeguita-senguio',
        'monarch-butterfly-parador-senguio',
        'restaurant-el-patio-ciudad-hidalgo',
        'pharmacy-openfarma-ciudad-hidalgo',
        'pharmacy-guadalajara-lerdo-ciudad-hidalgo',
        'mechanic-escobedo-automotive-ciudad-hidalgo',
        'mechanic-patino-ciudad-hidalgo',
        'hardware-taximaroa-ciudad-hidalgo',
        'hardware-ferreperfiles-ciudad-hidalgo',
        'grocery-dominguez-ciudad-hidalgo',
        'grocery-merza-ciudad-hidalgo',
        'grocery-maya-ciudad-hidalgo',
        'grocery-camacho-ciudad-hidalgo',
        'hotel-anoranza-ciudad-hidalgo',
      ]),
    );
    expect(
      businesses.where((business) => business['city'] == 'Senguio'),
      hasLength(8),
    );
    expect(
      businesses.map((business) => business['id']),
      isNot(contains('restaurant-chopstiks-senguio')),
    );
    for (final business in businesses) {
      expect(regionMunicipalities, contains(business['city']));
      expect(businessCategories, contains(business['category']));
      expect(business['status'], 'approved');
      expect(business['rating'], 0.0);
      expect(business['sourceUrl'], startsWith('https://'));
      for (final field in [
        'id',
        'name',
        'category',
        'description',
        'address',
        'phone',
        'schedule',
        'city',
        'location',
        'sourceUrl',
        'facebook',
        'instagram',
      ]) {
        expect(business, contains(field), reason: '${business['name']} $field');
      }
      for (final field in [
        'name',
        'category',
        'description',
        'city',
        'location',
      ]) {
        expect(
          business[field],
          isNotEmpty,
          reason: '${business['name']} should have a non-empty $field',
        );
        expect(
          business[field],
          isNot(matches(RegExp(r'Ã|Â|â€™|â€œ|â€|�'))),
          reason: '${business['name']} $field should not contain mojibake',
        );
      }
      for (final field in ['address', 'phone', 'schedule']) {
        expect(
          businessFieldValue(business, field),
          isNotEmpty,
          reason:
              '${business['name']} $field should show its value or source status',
        );
      }
      final publishedRequiredDetails = [
        'address',
        'phone',
        'schedule',
      ].where((field) => (business[field] ?? '').toString().trim().isNotEmpty);
      if (business['category'] == 'Turismo' ||
          business['id'] == 'producer-senguihongo-senguio') {
        expect(business['address'], isNotEmpty);
        expect(business['sourceUrl'], isNotEmpty);
        if (business['category'] == 'Turismo') {
          expect(business['address'], contains('ubicación general'));
          expect(business['sourceUrl'], contains('sectur.michoacan.gob.mx'));
        }
      } else {
        expect(
          publishedRequiredDetails.length,
          greaterThan(1.5),
          reason:
              '${business['name']} should publish more than half of its required details',
        );
      }
      expect(
        business['sourceLicense'],
        anyOf('', 'Open Database License (ODbL) 1.0'),
      );
      expect(
        business['logoUrl'],
        businessCategoryImageAsset(business['category'] as String),
      );
      expect(business['imageIsIllustrative'], isTrue);
      expect(business['description'], contains('ilustrativa'));
    }
    final laEstancia = businesses.singleWhere(
      (business) => business['id'] == 'facebook-la-estancia-ciudad-hidalgo',
    );
    expect(
      laEstancia['facebook'],
      'https://www.facebook.com/people/Restaurante-La-Estancia/100057645241066/',
    );
    expect(laEstancia['instagram'], 'https://www.instagram.com/laestancia_mx/');
    final taximaroa = businesses.singleWhere(
      (business) => business['id'] == 'hardware-taximaroa-ciudad-hidalgo',
    );
    expect(
      taximaroa['facebook'],
      'https://www.facebook.com/taximaroaferreteria/?locale=es_LA',
    );
    final camacho = businesses.singleWhere(
      (business) => business['id'] == 'grocery-camacho-ciudad-hidalgo',
    );
    expect(camacho['facebook'], 'https://www.facebook.com/camachoabarrotes/');
    final anoranza = businesses.singleWhere(
      (business) => business['id'] == 'hotel-anoranza-ciudad-hidalgo',
    );
    expect(
      anoranza['instagram'],
      'https://www.instagram.com/anoranza_hotel_boutique/',
    );
    final threeB = businesses.singleWhere(
      (business) => business['id'] == 'grocery-tiendas-3b-senguio',
    );
    expect(threeB['city'], 'Senguio');
    expect(threeB['phone'], '55 4510 9999');
    expect(threeB['website'], 'https://www.tiendas3b.com/');
    final repairMyPhone = businesses.singleWhere(
      (business) => business['id'] == 'repair-my-phone-senguio',
    );
    expect(repairMyPhone['category'], 'Tecnología');
    expect(repairMyPhone['address'], 'Centro, 61290 Senguio, Michoacán');
    expect(repairMyPhone['phone'], '447 101 7691');
    expect(
      repairMyPhone['schedule'],
      'Lunes a viernes, 10:00 a 17:00; sábado cerrado',
    );
    expect(
      repairMyPhone['facebook'],
      'https://www.facebook.com/jovaniriosreyes/',
    );
    final ferreteriaLaHormiga = businesses.singleWhere(
      (business) => business['id'] == 'hardware-la-hormiga-senguio',
    );
    expect(ferreteriaLaHormiga['category'], 'Ferretería');
    expect(ferreteriaLaHormiga['address'], contains('Benito Juárez 57'));
    expect(ferreteriaLaHormiga['phone'], '786 155 5077');
    expect(ferreteriaLaHormiga['schedule'], contains('7:00'));
    expect(
      ferreteriaLaHormiga['facebook'],
      'https://www.facebook.com/people/Ferreter%C3%ADa-La-Hormiga-Refaccionar%C3%ADa-F%C3%A9nix/61582346903025/',
    );
    final laBodeguita = businesses.singleWhere(
      (business) => business['id'] == 'grocery-la-bodeguita-senguio',
    );
    expect(laBodeguita['category'], 'Abarrotes');
    expect(laBodeguita['address'], contains('Cda. de Hidalgo 49'));
    expect(laBodeguita['schedule'], 'Lunes a domingo, 8:30 a 21:00');
    expect(
      laBodeguita['facebook'],
      'https://www.facebook.com/labodeguitadesenguio/',
    );
    final plazaMonarca = businesses.singleWhere(
      (business) => business['id'] == 'plaza-monarca-senguio',
    );
    expect(plazaMonarca['category'], 'Comercio');
    expect(plazaMonarca['address'], 'Hidalgo, 61290 Senguio, Michoacán');
    expect(
      plazaMonarca['schedule'],
      'Lunes a domingo, 9:00 a 17:00; puede variar por establecimiento.',
    );
    expect(
      plazaMonarca['facebook'],
      'https://www.facebook.com/p/Plaza-Monarca-100063647378611/',
    );
    final senguihongo = businesses.singleWhere(
      (business) => business['id'] == 'producer-senguihongo-senguio',
    );
    expect(senguihongo['category'], 'Productores locales');
    expect(
      senguihongo['address'],
      'Benito Juárez 57, rumbo a la secundaria, 61290 Senguio, Michoacán',
    );
    expect(senguihongo['phone'], isEmpty);
    expect(senguihongo['schedule'], isEmpty);
    expect(
      senguihongo['facebook'],
      'https://www.facebook.com/hongosshiitake.senguio/',
    );
    final parador = businesses.singleWhere(
      (business) => business['id'] == 'monarch-butterfly-parador-senguio',
    );
    expect(parador['category'], 'Turismo');
    expect(
      parador['sourceUrl'],
      'https://sectur.michoacan.gob.mx/senguio-invita-a-visitar-santuario-de-las-mariposas-monarca-esta-temporada-sectur/',
    );
    expect(parador['phone'], isEmpty);
    expect(parador['schedule'], isEmpty);
    final losArcos = businesses.singleWhere(
      (business) => business['id'] == 'restaurant-los-arcos-senguio',
    );
    expect(losArcos['facebook'], 'https://www.facebook.com/LosArcosSenguio/');
    expect(BusinessProvider().businesses, hasLength(businesses.length));
  });

  test('keeps only populated categories for the focused municipalities', () {
    final categories = createInitialBusinessCatalog()
        .map((business) => business['category'])
        .toSet();

    expect(businessCategories, [
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
    ]);
    expect(categories, isNotEmpty);
    expect(categories, businessCategories.toSet());
    expect(businessCategories.toSet(), hasLength(categories.length));
  });

  test(
    'allows business requests to use the illustrative category image',
    () async {
      final provider = BusinessProvider();
      await provider.submitBusinessRequest(
        name: 'Negocio enviado por usuario',
        owner: '',
        email: '',
        phone: '786 123 4567',
        whatsapp: '',
        city: 'Ciudad Hidalgo',
        address: 'Avenida principal 1',
        schedule: 'Lunes a sábado, 9:00 a 18:00',
        category: 'Restaurantes',
        description: 'Servicio local de prueba.',
        facebook: '',
        instagram: '',
        website: '',
      );
      final businessId =
          provider.pendingBusinesses.singleWhere(
                (business) => business['id'] == 'local-0',
              )['id']
              as String;

      await provider.approveBusiness(businessId);

      final business = provider.businesses.singleWhere(
        (business) => business['id'] == businessId,
      );
      expect(business['logoUrl'], businessCategoryImageAsset('Restaurantes'));
      expect(business['imageIsIllustrative'], isTrue);
    },
  );

  test('rejects business requests with missing required information', () async {
    final provider = BusinessProvider();
    await expectLater(
      provider.submitBusinessRequest(
        name: 'Negocio incompleto',
        owner: '',
        email: '',
        phone: '',
        whatsapp: '',
        city: '',
        address: '',
        schedule: '',
        category: 'Restaurantes',
        description: '',
        facebook: '',
        instagram: '',
        website: '',
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(provider.pendingBusinesses, isEmpty);
  });

  test('provides an event or date card for each focused municipality', () {
    for (final municipality in regionMunicipalities) {
      expect(
        municipalEvents[municipality],
        isNotEmpty,
        reason: '$municipality should have an event or agenda card',
      );
    }
  });
}
