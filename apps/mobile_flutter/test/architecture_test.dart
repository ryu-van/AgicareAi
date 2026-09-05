import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/app.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';
import 'package:agricare_ai_mobile/features/diagnosis/diagnosis_page.dart';
import 'package:agricare_ai_mobile/features/farm/farm_page.dart';
import 'package:agricare_ai_mobile/features/journal/journal_page.dart';
import 'package:agricare_ai_mobile/features/reminders/reminders_page.dart';
import 'package:agricare_ai_mobile/features/sync/sync_page.dart';

void main() {
  testWidgets('renders farm feature page', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test', userId: 'user-1');
    await tester.pumpWidget(MaterialApp(home: FarmPage(apiClient: apiClient)));
    await tester.pumpAndSettle();

    expect(find.text('Quản lý Trang trại'), findsOneWidget);
    expect(find.text('Trang trại AgriCare Demo'), findsOneWidget);
  });

  testWidgets('renders diagnosis feature page and performs analysis flow', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test', userId: 'user-1');
    await tester.pumpWidget(MaterialApp(home: DiagnosisPage(apiClient: apiClient)));
    await tester.pumpAndSettle();

    expect(find.text('Chẩn đoán Sâu bệnh'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Lá lúa bị cháy vi khuẩn');
    await tester.tap(find.text('Phân tích chẩn đoán'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Kết quả chẩn đoán sơ bộ'), findsOneWidget);
  });

  testWidgets('renders journal feature page', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test', userId: 'user-1');
    await tester.pumpWidget(MaterialApp(home: JournalPage(apiClient: apiClient)));
    await tester.pumpAndSettle();

    expect(find.text('Nhật ký Sản xuất'), findsOneWidget);
    expect(find.text('Bón phân đợt 1 cho lúa'), findsOneWidget);
  });

  testWidgets('renders reminders feature page', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test', userId: 'user-1');
    await tester.pumpWidget(MaterialApp(home: RemindersPage(apiClient: apiClient)));
    await tester.pumpAndSettle();

    expect(find.text('Nhắc nhở Canh tác'), findsOneWidget);
    expect(find.text('Tưới nước lúa vụ Đông Xuân'), findsOneWidget);
  });

  testWidgets('renders sync feature page and triggers sync', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test', userId: 'user-1');
    await tester.pumpWidget(MaterialApp(home: SyncPage(apiClient: apiClient)));
    await tester.pumpAndSettle();

    expect(find.text('Đồng bộ Dữ liệu'), findsOneWidget);
    await tester.tap(find.text('Đồng bộ ngay'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Đồng bộ hoàn tất thành công!'), findsOneWidget);
  });

  testWidgets('supports navigation deep-links for new feature routes', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test', userId: 'user-1');
    await tester.pumpWidget(AgriCareApp(apiClient: apiClient, initialRoute: 'agricare-ai://diagnosis'));
    await tester.pumpAndSettle();

    expect(find.text('Chẩn đoán Sâu bệnh'), findsOneWidget);
  });
}
