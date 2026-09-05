import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/app.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';

void main() {
  testWidgets('renders AgriCare home shell', (tester) async {
    await tester.pumpWidget(AgriCareApp());
    expect(find.text('AgriCare AI'), findsOneWidget);
    expect(find.text('Bạn muốn làm gì hôm nay?'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
  });

  testWidgets('home presents one farm dashboard without a domain switcher', (
    tester,
  ) async {
    await tester.pumpWidget(AgriCareApp());

    expect(find.text('Nông trại của bạn'), findsOneWidget);
    expect(find.byType(SegmentedButton<Domain>), findsNothing);
  });

  testWidgets('chat suggestions populate the multiline composer', (
    tester,
  ) async {
    await tester.pumpWidget(AgriCareApp(initialRoute: '/chat'));

    final suggestion = find.byType(ActionChip).first;
    expect(suggestion, findsOneWidget);
    await tester.tap(suggestion);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Lá cây bị vàng phải làm sao?');
    expect(field.maxLines, 4);
  });
}
