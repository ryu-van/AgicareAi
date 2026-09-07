import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/shared/widgets/app_brand_logo.dart';

void main() {
  testWidgets('AppBrandLogo renders with correct dimensions and semantic label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBrandLogo(size: BrandLogoSize.medium),
        ),
      ),
    );

    final logoFinder = find.byType(AppBrandLogo);
    expect(logoFinder, findsOneWidget);

    final container = tester.widget<Container>(
      find.descendant(of: logoFinder, matching: find.byType(Container)).first,
    );
    expect(container.constraints?.maxWidth, BrandLogoSize.medium.dimension);
    expect(container.constraints?.maxHeight, BrandLogoSize.medium.dimension);
  });

  testWidgets('AgriAnBrandHeader renders logo, brand name and tagline', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AgriAnBrandHeader(),
        ),
      ),
    );

    expect(find.text('AgriAn'), findsOneWidget);
    expect(find.text('Vụ mùa an tâm, nông gia thịnh vượng'), findsOneWidget);
    expect(find.byType(AppBrandLogo), findsOneWidget);
  });
}

