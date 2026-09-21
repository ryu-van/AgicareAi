import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/journal_entry_entity.dart';
import 'local_store_interface.dart';

part 'drift_store.g.dart';

class JournalEntries extends Table {
  TextColumn get localId => text().named('local_id')();
  TextColumn get serverId => text().named('server_id').nullable()();
  TextColumn get clientEventId => text().named('client_event_id').unique()();
  TextColumn get subjectId => text().named('subject_id')();
  TextColumn get entryType => text().named('entry_type')();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().named('photo_path').nullable()();
  TextColumn get observedAt => text().named('observed_at')();
  TextColumn get timezone =>
      text().withDefault(const Constant('Asia/Ho_Chi_Minh'))();
  TextColumn get syncStatus => text().named('sync_status')();
  TextColumn get syncError => text().named('sync_error').nullable()();
  IntColumn get isDraft =>
      integer().named('is_draft').withDefault(const Constant(0))();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at')();
  TextColumn get deletedAt => text().named('deleted_at').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class OutboxEvents extends Table {
  TextColumn get eventId => text().named('event_id')();
  TextColumn get entity =>
      text().withDefault(const Constant('journal_entry'))();
  TextColumn get operation => text().withDefault(const Constant('upsert'))();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();
  IntColumn get maxRetries =>
      integer().named('max_retries').withDefault(const Constant(5))();
  TextColumn get lastAttemptAt => text().named('last_attempt_at').nullable()();
  TextColumn get errorMessage => text().named('error_message').nullable()();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column<Object>> get primaryKey => {eventId};
}

@DriftDatabase(tables: [JournalEntries, OutboxEvents])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase(super.executor);

  OfflineDatabase.defaults() : super(driftDatabase(name: 'agricare_offline'));

  factory OfflineDatabase.forTesting(QueryExecutor executor) =>
      OfflineDatabase(executor);

  @override
  int get schemaVersion => 1;
}

class OfflineDatabaseProvider {
  OfflineDatabaseProvider._();

  static final OfflineDatabase instance = OfflineDatabase.defaults();
}

class DriftJournalStore implements JournalLocalStore {
  DriftJournalStore(this._database);

  final OfflineDatabase _database;

  @override
  Future<List<JournalEntryEntity>> getAllEntries({
    String? subjectId,
    SyncStatus? status,
  }) async {
    final filters = <String>['deleted_at IS NULL'];
    final variables = <Variable<Object>>[];
    if (subjectId != null) {
      filters.add('subject_id = ?');
      variables.add(Variable.withString(subjectId));
    }
    if (status != null) {
      filters.add('sync_status = ?');
      variables.add(Variable.withString(status.name));
    }
    final rows = await _database
        .customSelect(
          'SELECT * FROM journal_entries WHERE ${filters.join(' AND ')} ORDER BY observed_at DESC',
          variables: variables,
        )
        .get();
    return rows
        .map((row) => JournalEntryEntity.fromMap(row.data))
        .toList(growable: false);
  }

  @override
  Future<JournalEntryEntity?> getEntryByLocalId(String localId) =>
      _singleEntry('local_id = ?', localId);

  @override
  Future<JournalEntryEntity?> getEntryByClientEventId(String clientEventId) =>
      _singleEntry('client_event_id = ?', clientEventId);

  Future<JournalEntryEntity?> _singleEntry(String clause, String value) async {
    final row = await _database
        .customSelect(
          'SELECT * FROM journal_entries WHERE $clause LIMIT 1',
          variables: [Variable.withString(value)],
        )
        .getSingleOrNull();
    return row == null ? null : JournalEntryEntity.fromMap(row.data);
  }

  @override
  Future<void> saveEntry(JournalEntryEntity entry) => _database.customStatement(
    '''INSERT INTO journal_entries (
          local_id, server_id, client_event_id, subject_id, entry_type, title, notes, photo_path,
          observed_at, timezone, sync_status, sync_error, is_draft, created_at, updated_at, deleted_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(local_id) DO UPDATE SET
          server_id = excluded.server_id, client_event_id = excluded.client_event_id,
          subject_id = excluded.subject_id, entry_type = excluded.entry_type, title = excluded.title,
          notes = excluded.notes, photo_path = excluded.photo_path, observed_at = excluded.observed_at,
          timezone = excluded.timezone, sync_status = excluded.sync_status, sync_error = excluded.sync_error,
          is_draft = excluded.is_draft, updated_at = excluded.updated_at, deleted_at = excluded.deleted_at''',
    [
      entry.localId,
      entry.serverId,
      entry.clientEventId,
      entry.subjectId,
      entry.entryType,
      entry.title,
      entry.notes,
      entry.photoPath,
      entry.observedAt.toIso8601String(),
      entry.timezone,
      entry.syncStatus.name,
      entry.syncError,
      entry.isDraft ? 1 : 0,
      entry.createdAt.toIso8601String(),
      entry.updatedAt.toIso8601String(),
      entry.deletedAt?.toIso8601String(),
    ],
  );

  @override
  Future<void> updateSyncStatus(
    String clientEventId,
    SyncStatus status, {
    String? serverId,
    String? error,
  }) => _database.customStatement(
    'UPDATE journal_entries SET sync_status = ?, server_id = COALESCE(?, server_id), sync_error = ?, updated_at = ? WHERE client_event_id = ?',
    [
      status.name,
      serverId,
      error,
      DateTime.now().toUtc().toIso8601String(),
      clientEventId,
    ],
  );

  @override
  Future<void> deleteEntry(String localId) => _database.customStatement(
    'UPDATE journal_entries SET deleted_at = ?, updated_at = ? WHERE local_id = ?',
    [
      DateTime.now().toUtc().toIso8601String(),
      DateTime.now().toUtc().toIso8601String(),
      localId,
    ],
  );

  @override
  Future<void> clearAll() =>
      _database.customStatement('DELETE FROM journal_entries');
}

class DriftOutboxStore implements OutboxQueueStore {
  DriftOutboxStore(this._database);

  final OfflineDatabase _database;

  @override
  Future<List<OutboxEventEntity>> getPendingEvents({int limit = 50}) async {
    final rows = await _database
        .customSelect(
          'SELECT * FROM outbox_events WHERE status != ? ORDER BY created_at ASC LIMIT ?',
          variables: [
            Variable.withString(OutboxStatus.synced.name),
            Variable.withInt(limit),
          ],
        )
        .get();
    return rows
        .map((row) => OutboxEventEntity.fromMap(row.data))
        .toList(growable: false);
  }

  @override
  Future<void> enqueue(OutboxEventEntity event) => _database.customStatement(
    '''INSERT INTO outbox_events (
          event_id, entity, operation, payload, status, retry_count, max_retries, last_attempt_at, error_message, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(event_id) DO UPDATE SET
          entity = excluded.entity, operation = excluded.operation, payload = excluded.payload,
          status = excluded.status, retry_count = excluded.retry_count, max_retries = excluded.max_retries,
          last_attempt_at = excluded.last_attempt_at, error_message = excluded.error_message''',
    [
      event.eventId,
      event.entity,
      event.operation,
      event.toMap()['payload'],
      event.status.name,
      event.retryCount,
      event.maxRetries,
      event.lastAttemptAt?.toIso8601String(),
      event.errorMessage,
      event.createdAt.toIso8601String(),
    ],
  );

  @override
  Future<void> markStatus(
    List<String> eventIds,
    OutboxStatus status, {
    String? error,
  }) async {
    for (final eventId in eventIds) {
      await _database.customStatement(
        '''UPDATE outbox_events SET status = ?, error_message = COALESCE(?, error_message),
          last_attempt_at = ?, retry_count = retry_count + CASE WHEN ? = 'failed' THEN 1 ELSE 0 END
          WHERE event_id = ?''',
        [
          status.name,
          error,
          DateTime.now().toUtc().toIso8601String(),
          status.name,
          eventId,
        ],
      );
    }
  }

  @override
  Future<void> remove(String eventId) => _database.customStatement(
    'DELETE FROM outbox_events WHERE event_id = ?',
    [eventId],
  );

  @override
  Future<int> getPendingCount() async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS count FROM outbox_events WHERE status != ?',
          variables: [Variable.withString(OutboxStatus.synced.name)],
        )
        .getSingle();
    return row.read<int>('count');
  }

  @override
  Future<void> clearAll() =>
      _database.customStatement('DELETE FROM outbox_events');
}
