import '../models/journal_entry_entity.dart';

abstract class JournalLocalStore {
  Future<List<JournalEntryEntity>> getAllEntries({String? subjectId, SyncStatus? status});
  Future<JournalEntryEntity?> getEntryByLocalId(String localId);
  Future<JournalEntryEntity?> getEntryByClientEventId(String clientEventId);
  Future<void> saveEntry(JournalEntryEntity entry);
  Future<void> updateSyncStatus(
    String clientEventId,
    SyncStatus status, {
    String? serverId,
    String? error,
  });
  Future<void> deleteEntry(String localId);
  Future<void> clearAll();
}

abstract class OutboxQueueStore {
  Future<List<OutboxEventEntity>> getPendingEvents({int limit = 50});
  Future<void> enqueue(OutboxEventEntity event);
  Future<void> markStatus(
    List<String> eventIds,
    OutboxStatus status, {
    String? error,
  });
  Future<void> remove(String eventId);
  Future<int> getPendingCount();
  Future<void> clearAll();
}
