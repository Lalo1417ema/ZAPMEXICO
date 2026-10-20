import 'package:flutter_test/flutter_test.dart';
import 'package:zap_mexico/data/michoacan_municipalities.dart';

void main() {
  test('contains the 113 unique municipalities of Michoacán', () {
    expect(michoacanMunicipalities, hasLength(113));
    expect(michoacanMunicipalities.toSet(), hasLength(113));
  });
}
