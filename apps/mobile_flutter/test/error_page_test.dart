import 'package:agricare_ai_mobile/shared/widgets/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'not-found page exposes a semantic SVG illustration and return action',
    (tester) async {
      var returnedHome = false;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorPage.notFound(onPrimaryAction: () => returnedHome = true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy trang này'), findsOneWidget);
      expect(find.bySemanticsLabel('Minh họa lỗi 404'), findsOneWidget);
      await tester.tap(find.text('Về trang chủ'));
      expect(returnedHome, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'forbidden and offline states provide the intended recovery action',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ErrorPage.forbidden()));
      await tester.pumpAndSettle();
      expect(find.text('Bạn không có quyền truy cập'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: ErrorPage.offline()));
      await tester.pumpAndSettle();
      expect(find.text('Bạn đang ngoại tuyến'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );
}
