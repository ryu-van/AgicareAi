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
    String? photoPath,
    DateTime? observedAt,
  });
  Future<JournalEntryEntity?> editEntry({
    required String localId,
    String? title,
    String? entryType,
    String? subjectId,
    String? notes,
    String? photoPath,
    DateTime? observedAt,
  });
  Future<bool> deleteEntry(String localId);
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
        'entry_type': entry.entryType,
        'subject_id': entry.subjectId,
        'status': entry.syncStatus.name,
        'status_label': entry.syncStatus.label,
        'notes': entry.notes ?? '',
        'photo_path': entry.photoPath ?? '',
        'observed_at': entry.observedAt.toIso8601String(),
      };
    }).toList();
  }

  @override
  Future<List<JournalEntryEntity>> getEntries({String? subjectId}) {
    return localStore.getAllEntries(subjectId: subjectId);
  }

  static int _idCounter = 0;

  @override
  Future<JournalEntryEntity> createEntry({
    required String title,
    required String entryType,
    required String subjectId,
    String? notes,
    String? photoPath,
    DateTime? observedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final time = observedAt?.toUtc() ?? now;
    final timestamp = now.microsecondsSinceEpoch;
    final count = ++_idCounter;
    final localId = 'loc-$timestamp-$count';
    final clientEventId = 'evt-$timestamp-$count';

    final entry = JournalEntryEntity(
      localId: localId,
      clientEventId: clientEventId,
      subjectId: subjectId,
      entryType: entryType,
      title: title.trim(),
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      photoPath: photoPath,
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
        'photo_url': photoPath,
        'client_event_id': clientEventId,
      },
      status: OutboxStatus.pending,
      createdAt: now,
    );
    await outboxStore.enqueue(outboxEvent);

    return entry;
  }

  @override
  Future<JournalEntryEntity?> editEntry({
    required String localId,
    String? title,
    String? entryType,
    String? subjectId,
    String? notes,
    String? photoPath,
    DateTime? observedAt,
  }) async {
    final existing = await localStore.getEntryByLocalId(localId);
    if (existing == null) return null;

    final now = DateTime.now().toUtc();
    final updated = existing.copyWith(
      title: title?.trim().isNotEmpty == true ? title!.trim() : existing.title,
      entryType: entryType ?? existing.entryType,
      subjectId: subjectId ?? existing.subjectId,
      notes: notes,
      photoPath: photoPath ?? existing.photoPath,
      observedAt: observedAt?.toUtc() ?? existing.observedAt,
      syncStatus: SyncStatus.pendingSync,
      updatedAt: now,
    );

    await localStore.saveEntry(updated);

    final outboxEvent = OutboxEventEntity(
      eventId: 'evt-${now.microsecondsSinceEpoch}-${++_idCounter}',
      entity: 'journal_entry',
      operation: 'upsert',
      payload: {
        'subject_id': updated.subjectId,
        'entry_type': updated.entryType,
        'observed_at': updated.observedAt.toIso8601String(),
        'timezone': 'Asia/Ho_Chi_Minh',
        'title': updated.title,
        'notes': updated.notes,
        'photo_url': updated.photoPath,
        'client_event_id': updated.clientEventId,
      },
      status: OutboxStatus.pending,
      createdAt: now,
    );
    await outboxStore.enqueue(outboxEvent);

    return updated;
  }

  @override
  Future<bool> deleteEntry(String localId) async {
    final existing = await localStore.getEntryByLocalId(localId);
    if (existing == null) return false;

    await localStore.deleteEntry(localId);

    final now = DateTime.now().toUtc();
    final outboxEvent = OutboxEventEntity(
      eventId: 'evt-del-${now.microsecondsSinceEpoch}-${++_idCounter}',
      entity: 'journal_entry',
      operation: 'delete',
      payload: {
        'entry_id': existing.serverId,
        'client_event_id': existing.clientEventId,
      },
      status: OutboxStatus.pending,
      createdAt: now,
    );
    await outboxStore.enqueue(outboxEvent);

    return true;
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

