import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/app.dart';
import 'package:agricare_ai_mobile/shared/widgets/app_components.dart';

void main() {
  testWidgets('opens chat deep link', (tester) async {
    await tester.pumpWidget(AgriCareApp(initialRoute: '/chat'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hỏi AgriCare AI'), findsOneWidget);
  });

  testWidgets('opens article deep link with safe preview', (tester) async {
    await tester.pumpWidget(AgriCareApp(initialRoute: '/knowledge/article-1'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kiến thức AgriCare'), findsOneWidget);
    expect(
      find.text(
        'Thông tin chỉ mang tính tham khảo. Hãy hỏi chuyên gia khi tình huống nghiêm trọng.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('normalizes external chat scheme deep link', (tester) async {
    await tester.pumpWidget(AgriCareApp(initialRoute: 'agricare-ai://chat'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hỏi AgriCare AI'), findsOneWidget);
  });

  testWidgets('falls back to home for an invalid deep link', (tester) async {
    await tester.pumpWidget(AgriCareApp(initialRoute: '/not-a-route'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('AgriCare AI'), findsOneWidget);
    expect(find.byType(AppFloatingCenterNavShell), findsOneWidget);
  });
}
