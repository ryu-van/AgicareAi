import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/app.dart';
import 'package:agricare_ai_mobile/shared/widgets/app_components.dart';

void main() {
  testWidgets('opens chat deep link', (tester) async {
    await tester.pumpWidget(AgriCareApp(initialRoute: '/chat'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hỏi AgriAn AI'), findsOneWidget);
  });

  testWidgets('opens article deep link with safe preview', (tester) async {
    await tester.pumpWidget(AgriCareApp(initialRoute: '/knowledge/article-1'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kiến thức AgriAn'), findsOneWidget);
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
    expect(find.text('Hỏi AgriAn AI'), findsOneWidget);
  });

  testWidgets('shows 404 then returns home for an invalid deep link', (
    tester,
  ) async {
    await tester.pumpWidget(AgriCareApp(initialRoute: '/not-a-route'));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy trang này'), findsOneWidget);

    await tester.tap(find.text('Về trang chủ'));
    await tester.pumpAndSettle();
    expect(find.text('AgriAn'), findsOneWidget);
    expect(find.byType(AppFloatingCenterNavShell), findsOneWidget);
  });
}
