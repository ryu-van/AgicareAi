import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agricare_ai_mobile/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('primary navigation and large text remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(AgriCareApp());
    expect(find.text('AgriCare AI'), findsOneWidget);
    await tester.tap(find.text('Kiáº¿n thá»©c'));
    await tester.pump();
    expect(find.text('Kiáº¿n thá»©c'), findsOneWidget);
    await tester.tap(find.text('Há»“ sÆ¡'));
    await tester.pump();
    expect(find.text('Há»“ sÆ¡'), findsOneWidget);
  });
}
