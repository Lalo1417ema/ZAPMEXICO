import 'package:flutter_test/flutter_test.dart';
import 'package:zap_mexico/data/michoacan_municipalities.dart';
import 'package:zap_mexico/presentation/providers/catalog_provider.dart';

void main() {
  test('contains the 113 unique municipalities of Michoacán', () {
    expect(michoacanMunicipalities, hasLength(113));
    expect(michoacanMunicipalities.toSet(), hasLength(113));
  });

  test(
    'makes every official municipality available without business records',
    () {
      expect(
        CatalogProvider().municipalities,
        containsAll(michoacanMunicipalities),
      );
    },
  );
}
