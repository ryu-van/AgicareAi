import '../database/in_memory_store.dart';
import '../database/local_store_interface.dart';
import '../models/journal_entry_entity.dart';
import '../network/api_client.dart';
import '../sync/sync_engine.dart';

abstract class JournalRepository {
  Future<List<Map<String, String>>> fetchJournalEntries();
  Future<List<JournalEntryEntity>> getEntries({String? subjectId});
  Future<JournalEntryEntity> createEntry({
    required String title,
    required String entryType,
    required String subjectId,
    String? notes,
    DateTime? observedAt,
  });
  Future<int> getPendingSyncCount();
  Future<SyncResultSummary> syncPendingEvents();
  SyncEngine get syncEngine;
}

class ApiJournalRepository implements JournalRepository {
  ApiJournalRepository({
    required this.apiClient,
    JournalLocalStore? localStore,
    OutboxQueueStore? outboxStore,
  })  : localStore = localStore ?? InMemoryJournalStore(),
        outboxStore = outboxStore ?? InMemoryOutboxStore() {
    syncEngine = SyncEngine(
      apiClient: apiClient,
      localStore: this.localStore,
      outboxStore: this.outboxStore,
    );
  }

  final ApiClient apiClient;
  final JournalLocalStore localStore;
  final OutboxQueueStore outboxStore;
  @override
  late final SyncEngine syncEngine;

  @override
  Future<List<Map<String, String>>> fetchJournalEntries() async {
    final entries = await localStore.getAllEntries();
    return entries.map((entry) {
      final dt = entry.observedAt.toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final formattedDate = '$day/$month/$year';

      final displayType = switch (entry.entryType) {
        'treatment' => 'Bón phân',
        'observation' => 'Theo dõi',
        'feeding' => 'Cho ăn',
        'vaccination' => 'Tiêm phòng',
        'harvest' => 'Thu hoạch',
        _ => entry.entryType,
      };

      return {
        'id': entry.localId,
        'title': entry.title,
        'date': formattedDate,
        'type': displayType,
        'status': entry.syncStatus.name,
        'status_label': entry.syncStatus.label,
        'notes': entry.notes ?? '',
      };
    }).toList();
  }

  @override
  Future<List<JournalEntryEntity>> getEntries({String? subjectId}) {
    return localStore.getAllEntries(subjectId: subjectId);
  }

  @override
  Future<JournalEntryEntity> createEntry({
    required String title,
    required String entryType,
    required String subjectId,
    String? notes,
    DateTime? observedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final time = observedAt?.toUtc() ?? now;
    final timestamp = now.microsecondsSinceEpoch;
    final localId = 'loc-$timestamp';
    final clientEventId = 'evt-$timestamp';

    final entry = JournalEntryEntity(
      localId: localId,
      clientEventId: clientEventId,
      subjectId: subjectId,
      entryType: entryType,
      title: title.trim(),
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      observedAt: time,
      syncStatus: SyncStatus.pendingSync,
      createdAt: now,
      updatedAt: now,
    );

    // Save to local storage
    await localStore.saveEntry(entry);

    // Enqueue into offline outbox
    final outboxEvent = OutboxEventEntity(
      eventId: clientEventId,
      entity: 'journal_entry',
      operation: 'upsert',
      payload: {
        'subject_id': subjectId,
        'entry_type': entryType,
        'observed_at': time.toIso8601String(),
        'timezone': 'Asia/Ho_Chi_Minh',
        'title': title.trim(),
        'notes': notes?.trim().isNotEmpty == true ? notes!.trim() : null,
        'client_event_id': clientEventId,
      },
      status: OutboxStatus.pending,
      createdAt: now,
    );
    await outboxStore.enqueue(outboxEvent);

    return entry;
  }

  @override
  Future<int> getPendingSyncCount() {
    return outboxStore.getPendingCount();
  }

  @override
  Future<SyncResultSummary> syncPendingEvents() {
    return syncEngine.syncNow();
  }
}
