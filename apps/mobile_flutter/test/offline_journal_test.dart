import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agricare_ai_mobile/core/database/in_memory_store.dart';
import 'package:agricare_ai_mobile/core/models/journal_entry_entity.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';
import 'package:agricare_ai_mobile/core/repositories/journal_repository.dart';


void main() {
  group('Local Store & Outbox Tests', () {
    late InMemoryJournalStore localStore;
    late InMemoryOutboxStore outboxStore;

    setUp(() {
      localStore = InMemoryJournalStore(populateDefaultSeed: false);
      outboxStore = InMemoryOutboxStore();
    });

    test('saves journal entry locally with pendingSync status', () async {
      final entry = JournalEntryEntity(
        localId: 'loc-1',
        clientEventId: 'evt-1',
        subjectId: 'rice',
        entryType: 'treatment',
        title: 'Bón phân kali',
        observedAt: DateTime.parse('2026-09-21T08:00:00Z'),
        syncStatus: SyncStatus.pendingSync,
        createdAt: DateTime.parse('2026-09-21T08:00:00Z'),
        updatedAt: DateTime.parse('2026-09-21T08:00:00Z'),
      );

      await localStore.saveEntry(entry);
      final fetched = await localStore.getEntryByLocalId('loc-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Bón phân kali');
      expect(fetched.syncStatus, SyncStatus.pendingSync);

      final byEvent = await localStore.getEntryByClientEventId('evt-1');
      expect(byEvent, isNotNull);
      expect(byEvent!.localId, 'loc-1');
    });

    test('outbox queues events and tracks pending count', () async {
      final event1 = OutboxEventEntity(
        eventId: 'evt-1',
        entity: 'journal_entry',
        operation: 'upsert',
        payload: {'title': 'Sự kiện 1'},
        createdAt: DateTime.now().toUtc(),
      );
      final event2 = OutboxEventEntity(
        eventId: 'evt-2',
        entity: 'journal_entry',
        operation: 'upsert',
        payload: {'title': 'Sự kiện 2'},
        createdAt: DateTime.now().toUtc(),
      );

      await outboxStore.enqueue(event1);
      await outboxStore.enqueue(event2);

      expect(await outboxStore.getPendingCount(), 2);

      final pending = await outboxStore.getPendingEvents(limit: 10);
      expect(pending.length, 2);
      expect(pending.first.eventId, 'evt-1');

      await outboxStore.remove('evt-1');
      expect(await outboxStore.getPendingCount(), 1);
    });

    test('JournalRepository creates entry locally and enqueues to outbox', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });
      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test');
      final repository = ApiJournalRepository(
        apiClient: apiClient,
        localStore: localStore,
        outboxStore: outboxStore,
      );

      final created = await repository.createEntry(
        title: 'Phun thuốc rầy nâu',
        entryType: 'treatment',
        subjectId: 'rice',
        notes: 'Dùng thuốc sinh học theo liều khuyến cáo',
      );

      expect(created.title, 'Phun thuốc rầy nâu');
      expect(created.syncStatus, SyncStatus.pendingSync);

      // Verify stored locally
      final entries = await repository.getEntries();
      expect(entries.length, 1);
      expect(entries.first.title, 'Phun thuốc rầy nâu');

      // Verify outbox queue
      expect(await repository.getPendingSyncCount(), 1);

      // Verify fetchJournalEntries formatting
      final formattedList = await repository.fetchJournalEntries();
      expect(formattedList.length, 1);
      expect(formattedList.first['title'], 'Phun thuốc rầy nâu');
      expect(formattedList.first['type'], 'Bón phân');
    });

    test('SyncEngine synchronizes pending outbox events with batch API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/v1/sync/batch')) {
          final reqBody = jsonDecode(request.body) as Map<String, dynamic>;
          final events = reqBody['events'] as List<dynamic>;
          final results = events.map((e) {
            final ev = e as Map<String, dynamic>;
            return {
              'event_id': ev['event_id'],
              'status': 'applied',
              'entity_id': 'srv-generated-${ev['event_id']}',
            };
          }).toList();
          return http.Response(jsonEncode({'results': results}), 200);
        }
        return http.Response('{}', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test');
      final repository = ApiJournalRepository(
        apiClient: apiClient,
        localStore: localStore,
        outboxStore: outboxStore,
      );

      // Create an offline entry
      final entry = await repository.createEntry(
        title: 'Thu hoạch lúa OM5451',
        entryType: 'harvest',
        subjectId: 'rice',
      );
      expect(await repository.getPendingSyncCount(), 1);

      // Trigger sync
      final syncResult = await repository.syncPendingEvents();
      expect(syncResult.success, isTrue);
      expect(syncResult.appliedCount, 1);

      // Verify outbox is cleared
      expect(await repository.getPendingSyncCount(), 0);

      // Verify local entry updated to synced
      final localEntry = await localStore.getEntryByClientEventId(entry.clientEventId);
      expect(localEntry, isNotNull);
      expect(localEntry!.syncStatus, SyncStatus.synced);
      expect(localEntry.serverId, startsWith('srv-generated-'));
    });

    test('SyncEngine handles network failure gracefully without data loss', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Mạng không khả dụng');
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test');
      final repository = ApiJournalRepository(
        apiClient: apiClient,
        localStore: localStore,
        outboxStore: outboxStore,
      );

      // Create an entry
      final entry = await repository.createEntry(
        title: 'Tiêm phòng dịch tả lợn',
        entryType: 'vaccination',
        subjectId: 'pig',
      );

      // Trigger sync with network down
      final syncResult = await repository.syncPendingEvents();
      expect(syncResult.success, isFalse);

      // Outbox item is preserved
      expect(await repository.getPendingSyncCount(), 1);

      // Local entry still exists with local data preserved
      final localEntry = await localStore.getEntryByClientEventId(entry.clientEventId);
      expect(localEntry, isNotNull);
      expect(localEntry!.title, 'Tiêm phòng dịch tả lợn');
    });
  });
}
