import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zap_mexico/core/utils/business_category_images.dart';
import 'package:zap_mexico/data/business_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundles a reusable illustration for every business category', () async {
    expect(
      businessCategoryImageAssets.keys.toSet(),
      businessCategories.toSet(),
    );

    for (final asset in businessCategoryImageAssets.values.toSet()) {
      final image = await rootBundle.load(asset);
      expect(image.lengthInBytes, greaterThan(5000), reason: asset);
    }
  });

  testWidgets('decodes every category illustration', (tester) async {
    for (final asset in businessCategoryImageAssets.values.toSet()) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Image.asset(asset))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: asset);
    }
  });
}
