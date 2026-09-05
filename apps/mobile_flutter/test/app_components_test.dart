import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/shared/widgets/app_components.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('feature card exposes title, status and tap semantics', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        FeatureCard(
          icon: Icons.eco_outlined,
          title: 'Chẩn đoán',
          subtitle: 'Phân tích hình ảnh',
          status: 'Sắp có',
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Chẩn đoán'), findsOneWidget);
    expect(find.text('Sắp có'), findsOneWidget);
    await tester.tap(find.text('Chẩn đoán'));
    expect(tapped, isTrue);
  });

  testWidgets('async state view renders retry for errors', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _host(
        AsyncStateView(
          state: AsyncState.error,
          errorMessage: 'Mất kết nối',
          onRetry: () => retried = true,
          child: const Text('content'),
        ),
      ),
    );

    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    expect(retried, isTrue);
  });

  testWidgets('search field exposes clear action', (tester) async {
    final controller = TextEditingController(text: 'lá vàng');
    var cleared = false;
    await tester.pumpWidget(
      _host(
        AppSearchField(
          controller: controller,
          onChanged: (_) {},
          onClear: () => cleared = true,
        ),
      ),
    );

    expect(find.byTooltip('Xóa tìm kiếm'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    expect(cleared, isTrue);
  });

  testWidgets('large text still renders component content', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _host(
          const AppCard(
            child: Text('Nội dung dài cần vẫn đọc được trên màn hình nhỏ.'),
          ),
        ),
      ),
    );

    expect(
      find.text('Nội dung dài cần vẫn đọc được trên màn hình nhỏ.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
