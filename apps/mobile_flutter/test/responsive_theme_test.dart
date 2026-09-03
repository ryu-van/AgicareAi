import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/app.dart';
import 'package:agricare_ai_mobile/widgets/app_components.dart';

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
      ..clearTextScaleFactorTestValue()
      ..clearPlatformBrightnessTestValue();
  });

  testWidgets('home remains usable on a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(AgriCareApp());
    expect(find.text('AgriCare AI'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
  });

  testWidgets('home remains usable in landscape dark mode', (tester) async {
    tester.view.physicalSize = const ui.Size(800, 400);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(AgriCareApp());
    expect(find.text('AgriCare AI'), findsOneWidget);
    expect(find.byType(AppFloatingCenterNavShell), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });
}
