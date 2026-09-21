import '../database/local_store_interface.dart';
import '../models/journal_entry_entity.dart';
import '../network/api_client.dart';

class SyncResultSummary {
  const SyncResultSummary({
    required this.success,
    required this.message,
    this.processedCount = 0,
    this.appliedCount = 0,
    this.conflictCount = 0,
  });

  final bool success;
  final String message;
  final int processedCount;
  final int appliedCount;
  final int conflictCount;
}

class SyncEngine {
  SyncEngine({
    required this.apiClient,
    required this.localStore,
    required this.outboxStore,
  });

  final ApiClient apiClient;
  final JournalLocalStore localStore;
  final OutboxQueueStore outboxStore;

  Future<SyncResultSummary> syncNow({bool pullFromServer = false}) async {
    final pendingEvents = await outboxStore.getPendingEvents(limit: 50);

    if (pendingEvents.isEmpty) {
      if (pullFromServer) {
        try {
          final serverEntries = await apiClient.getJournalEntries();
          for (final raw in serverEntries) {
            final clientEventId = raw['client_event_id'] as String? ?? raw['id'] as String;
            final existing = await localStore.getEntryByClientEventId(clientEventId);
            if (existing == null) {
              await localStore.saveEntry(
                JournalEntryEntity(
                  localId: 'srv-${raw['id']}',
                  serverId: raw['id'] as String?,
                  clientEventId: clientEventId,
                  subjectId: raw['subject_id'] as String? ?? 'rice',
                  entryType: raw['entry_type'] as String? ?? 'observation',
                  title: raw['title'] as String? ?? '',
                  notes: raw['notes'] as String?,
                  observedAt: DateTime.tryParse(raw['observed_at'] as String? ?? '') ?? DateTime.now().toUtc(),
                  timezone: raw['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
                  syncStatus: SyncStatus.synced,
                  createdAt: DateTime.tryParse(raw['created_at'] as String? ?? '') ?? DateTime.now().toUtc(),
                  updatedAt: DateTime.now().toUtc(),
                ),
              );
            }
          }
        } catch (_) {
          // Offline or backend unavailable, ignore read sync failure
        }
      }
      return const SyncResultSummary(
        success: true,
        message: 'Đồng bộ hoàn tất thành công!',
        processedCount: 0,
      );
    }


    final eventIds = pendingEvents.map((e) => e.eventId).toList();
    await outboxStore.markStatus(eventIds, OutboxStatus.inFlight);

    try {
      final payloadList = pendingEvents.map((e) => {
        'event_id': e.eventId,
        'entity': e.entity,
        'operation': e.operation,
        'payload': e.payload,
      }).toList();

      final response = await apiClient.syncBatch(payloadList);
      final rawResults = (response['results'] as List<dynamic>? ?? const []);

      var applied = 0;
      var conflict = 0;

      for (final item in rawResults) {
        final map = item as Map<String, dynamic>;
        final eventId = map['event_id'] as String;
        final status = map['status'] as String;
        final entityId = map['entity_id'] as String?;

        if (status == 'applied' || status == 'duplicate') {
          applied++;
          await localStore.updateSyncStatus(
            eventId,
            SyncStatus.synced,
            serverId: entityId,
          );
          await outboxStore.remove(eventId);
        } else {
          conflict++;
          await localStore.updateSyncStatus(
            eventId,
            SyncStatus.syncFailed,
            error: 'Trạng thái: $status',
          );
          await outboxStore.markStatus(
            [eventId],
            OutboxStatus.failed,
            error: 'Trạng thái đồng bộ: $status',
          );
        }
      }

      return SyncResultSummary(
        success: true,
        message: 'Đồng bộ hoàn tất thành công!',
        processedCount: pendingEvents.length,
        appliedCount: applied,
        conflictCount: conflict,
      );
    } catch (e) {
      await outboxStore.markStatus(
        eventIds,
        OutboxStatus.failed,
        error: e.toString(),
      );
      for (final id in eventIds) {
        await localStore.updateSyncStatus(
          id,
          SyncStatus.syncFailed,
          error: 'Mất kết nối máy chủ',
        );
      }
      return SyncResultSummary(
        success: false,
        message: 'Không thể kết nối máy chủ lúc này. Dữ liệu đã được lưu an toàn trên máy.',
        processedCount: pendingEvents.length,
      );
    }
  }
}
