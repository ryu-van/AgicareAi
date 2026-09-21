import '../models/journal_entry_entity.dart';
import 'local_store_interface.dart';

class InMemoryJournalStore implements JournalLocalStore {
  InMemoryJournalStore({bool populateDefaultSeed = true}) {
    if (populateDefaultSeed) {
      _seedDefaultData();
    }
  }

  final Map<String, JournalEntryEntity> _storage = {};

  void _seedDefaultData() {
    final entry1 = JournalEntryEntity(
      localId: 'local-seed-001',
      serverId: 'srv-seed-001',
      clientEventId: 'client-event-seed-001',
      subjectId: 'rice',
      entryType: 'treatment',
      title: 'Bón phân đợt 1 cho lúa',
      notes: 'Bón lót NPK đầu vụ theo quy trình kỹ thuật.',
      observedAt: DateTime.parse('2026-09-02T08:00:00Z'),
      syncStatus: SyncStatus.synced,
      createdAt: DateTime.parse('2026-09-02T08:00:00Z'),
      updatedAt: DateTime.parse('2026-09-02T08:00:00Z'),
    );
    final entry2 = JournalEntryEntity(
      localId: 'local-seed-002',
      serverId: 'srv-seed-002',
      clientEventId: 'client-event-seed-002',
      subjectId: 'chicken',
      entryType: 'observation',
      title: 'Kiểm tra tình trạng đàn gà',
      notes: 'Gà khỏe mạnh, ăn uống bình thường, chuồng thông thoáng.',
      observedAt: DateTime.parse('2026-09-01T07:30:00Z'),
      syncStatus: SyncStatus.synced,
      createdAt: DateTime.parse('2026-09-01T07:30:00Z'),
      updatedAt: DateTime.parse('2026-09-01T07:30:00Z'),
    );
    _storage[entry1.localId] = entry1;
    _storage[entry2.localId] = entry2;
  }

  @override
  Future<List<JournalEntryEntity>> getAllEntries({
    String? subjectId,
    SyncStatus? status,
  }) async {
    var entries = _storage.values.where((e) => e.deletedAt == null).toList();
    if (subjectId != null) {
      entries = entries.where((e) => e.subjectId == subjectId).toList();
    }
    if (status != null) {
      entries = entries.where((e) => e.syncStatus == status).toList();
    }
    entries.sort((a, b) => b.observedAt.compareTo(a.observedAt));
    return List.unmodifiable(entries);
  }

  @override
  Future<JournalEntryEntity?> getEntryByLocalId(String localId) async {
    return _storage[localId];
  }

  @override
  Future<JournalEntryEntity?> getEntryByClientEventId(String clientEventId) async {
    for (final entry in _storage.values) {
      if (entry.clientEventId == clientEventId) return entry;
    }
    return null;
  }

  @override
  Future<void> saveEntry(JournalEntryEntity entry) async {
    _storage[entry.localId] = entry;
  }

  @override
  Future<void> updateSyncStatus(
    String clientEventId,
    SyncStatus status, {
    String? serverId,
    String? error,
  }) async {
    for (final entry in _storage.values) {
      if (entry.clientEventId == clientEventId) {
        _storage[entry.localId] = entry.copyWith(
          serverId: serverId,
          syncStatus: status,
          syncError: error,
          updatedAt: DateTime.now().toUtc(),
        );
        break;
      }
    }
  }

  @override
  Future<void> deleteEntry(String localId) async {
    final existing = _storage[localId];
    if (existing != null) {
      _storage[localId] = existing.copyWith(
        deletedAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
  }
}

class InMemoryOutboxStore implements OutboxQueueStore {
  final Map<String, OutboxEventEntity> _queue = {};

  @override
  Future<List<OutboxEventEntity>> getPendingEvents({int limit = 50}) async {
    final pending = _queue.values
        .where((e) => e.status != OutboxStatus.synced)
        .toList();
    pending.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pending.take(limit).toList();
  }

  @override
  Future<void> enqueue(OutboxEventEntity event) async {
    _queue[event.eventId] = event;
  }

  @override
  Future<void> markStatus(
    List<String> eventIds,
    OutboxStatus status, {
    String? error,
  }) async {
    for (final id in eventIds) {
      final existing = _queue[id];
      if (existing != null) {
        _queue[id] = OutboxEventEntity(
          eventId: existing.eventId,
          entity: existing.entity,
          operation: existing.operation,
          payload: existing.payload,
          status: status,
          retryCount: existing.retryCount + (status == OutboxStatus.failed ? 1 : 0),
          maxRetries: existing.maxRetries,
          lastAttemptAt: DateTime.now().toUtc(),
          errorMessage: error ?? existing.errorMessage,
          createdAt: existing.createdAt,
        );
      }
    }
  }

  @override
  Future<void> remove(String eventId) async {
    _queue.remove(eventId);
  }

  @override
  Future<int> getPendingCount() async {
    return _queue.values
        .where((e) => e.status != OutboxStatus.synced)
        .length;
  }


  @override
  Future<void> clearAll() async {
    _queue.clear();
  }
}
