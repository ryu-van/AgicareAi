import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agricare_ai_mobile/core/database/in_memory_store.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';
import 'package:agricare_ai_mobile/core/repositories/journal_repository.dart';
import 'package:agricare_ai_mobile/features/journal/journal_page.dart';

void main() {
  group('JournalPage Widget Tests', () {
    late InMemoryJournalStore localStore;
    late InMemoryOutboxStore outboxStore;
    late JournalRepository repository;

    setUp(() async {
      localStore = InMemoryJournalStore(populateDefaultSeed: false);
      outboxStore = InMemoryOutboxStore();
      repository = ApiJournalRepository(
        apiClient: ApiClient(baseUrl: 'http://test'),
        localStore: localStore,
        outboxStore: outboxStore,
      );

      // Seed 2 entries: 1 rice treatment with photo, 1 chicken observation
      await repository.createEntry(
        title: 'Bón phân đợt 1',
        entryType: 'treatment',
        subjectId: 'rice',
        notes: 'Bón NPK 16-16-8 đợt đầu',
        photoPath: 'file:///photos/rice_field.jpg',
      );
      await repository.createEntry(
        title: 'Kiểm tra chuồng gà',
        entryType: 'observation',
        subjectId: 'chicken',
        notes: 'Đàn gà khỏe mạnh, ăn tốt',
      );
    });

    testWidgets('renders entries and filters by subject', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JournalPage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Verify both entries are visible
      expect(find.text('Bón phân đợt 1'), findsOneWidget);
      expect(find.text('Kiểm tra chuồng gà'), findsOneWidget);

      // Verify filter chips exist
      expect(find.text('Tất cả đối tượng'), findsOneWidget);
      expect(find.text('Cây lúa'), findsWidgets);
      expect(find.text('Đàn gà'), findsWidgets);

      // Filter by "Cây lúa"
      final riceChip = find.widgetWithText(FilterChip, 'Cây lúa');
      await tester.tap(riceChip);
      await tester.pumpAndSettle();

      // Only rice entry should be visible
      expect(find.text('Bón phân đợt 1'), findsOneWidget);
      expect(find.text('Kiểm tra chuồng gà'), findsNothing);

      // Filter back to "Tất cả đối tượng"
      await tester.tap(find.text('Tất cả đối tượng'));
      await tester.pumpAndSettle();
      expect(find.text('Bón phân đợt 1'), findsOneWidget);
      expect(find.text('Kiểm tra chuồng gà'), findsOneWidget);
    });

    testWidgets('tap entry opens details bottom sheet with notes and photo', (tester) async {
      tester.view.physicalSize = const ui.Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: JournalPage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the rice entry
      await tester.tap(find.text('Bón phân đợt 1'));
      await tester.pumpAndSettle();

      // Verify detail bottom sheet is displayed
      expect(find.text('Nội dung chi tiết & Ghi chú:'), findsOneWidget);
      expect(find.text('Bón NPK 16-16-8 đợt đầu'), findsNWidgets(2));
      expect(find.text('Ảnh minh chứng đính kèm'), findsOneWidget);
      expect(find.text('file:///photos/rice_field.jpg'), findsOneWidget);
      expect(find.text('Chỉnh sửa'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
    });

    testWidgets('delete entry removes it from list and local store', (tester) async {
      tester.view.physicalSize = const ui.Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: JournalPage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Open detail
      await tester.tap(find.text('Kiểm tra chuồng gà'));
      await tester.pumpAndSettle();

      // Tap delete in bottom sheet
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Verify alert dialog appears
      expect(find.text('Xác nhận xóa nhật ký'), findsOneWidget);

      // Confirm delete
      final deleteConfirmButton = find.widgetWithText(FilledButton, 'Xóa');
      await tester.tap(deleteConfirmButton);
      await tester.pumpAndSettle();

      // Verify entry is gone
      expect(find.text('Kiểm tra chuồng gà'), findsNothing);
      expect(find.text('Bón phân đợt 1'), findsOneWidget);
    });
  });
}
