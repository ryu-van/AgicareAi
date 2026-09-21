import 'dart:convert';

enum SyncStatus { draft, pendingSync, syncing, synced, syncFailed }

extension SyncStatusLabel on SyncStatus {
  String get label => switch (this) {
    SyncStatus.draft => 'Bản nháp',
    SyncStatus.pendingSync => 'Chờ đồng bộ',
    SyncStatus.syncing => 'Đang đồng bộ',
    SyncStatus.synced => 'Đã đồng bộ',
    SyncStatus.syncFailed => 'Lỗi đồng bộ',
  };
}

class JournalEntryEntity {
  const JournalEntryEntity({
    required this.localId,
    this.serverId,
    required this.clientEventId,
    required this.subjectId,
    required this.entryType,
    required this.title,
    this.notes,
    this.photoPath,
    required this.observedAt,
    this.timezone = 'Asia/Ho_Chi_Minh',
    this.syncStatus = SyncStatus.pendingSync,
    this.syncError,
    this.isDraft = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String localId;
  final String? serverId;
  final String clientEventId;
  final String subjectId;
  final String entryType; // observation, treatment, harvest, vaccination, feeding
  final String title;
  final String? notes;
  final String? photoPath;
  final DateTime observedAt;
  final String timezone;
  final SyncStatus syncStatus;
  final String? syncError;
  final bool isDraft;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toMap() => {
    'local_id': localId,
    'server_id': serverId,
    'client_event_id': clientEventId,
    'subject_id': subjectId,
    'entry_type': entryType,
    'title': title,
    'notes': notes,
    'photo_path': photoPath,
    'observed_at': observedAt.toIso8601String(),
    'timezone': timezone,
    'sync_status': syncStatus.name,
    'sync_error': syncError,
    'is_draft': isDraft ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  factory JournalEntryEntity.fromMap(Map<String, dynamic> map) => JournalEntryEntity(
    localId: map['local_id'] as String,
    serverId: map['server_id'] as String?,
    clientEventId: map['client_event_id'] as String,
    subjectId: map['subject_id'] as String,
    entryType: map['entry_type'] as String,
    title: map['title'] as String,
    notes: map['notes'] as String?,
    photoPath: map['photo_path'] as String?,
    observedAt: DateTime.parse(map['observed_at'] as String),
    timezone: map['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
    syncStatus: SyncStatus.values.firstWhere(
      (e) => e.name == (map['sync_status'] as String? ?? 'pendingSync'),
      orElse: () => SyncStatus.pendingSync,
    ),
    syncError: map['sync_error'] as String?,
    isDraft: (map['is_draft'] as int? ?? 0) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
  );

  JournalEntryEntity copyWith({
    String? serverId,
    String? clientEventId,
    String? title,
    String? entryType,
    String? subjectId,
    String? notes,
    String? photoPath,
    DateTime? observedAt,
    SyncStatus? syncStatus,
    String? syncError,
    bool? isDraft,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return JournalEntryEntity(
      localId: localId,
      serverId: serverId ?? this.serverId,
      clientEventId: clientEventId ?? this.clientEventId,
      subjectId: subjectId ?? this.subjectId,
      entryType: entryType ?? this.entryType,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      observedAt: observedAt ?? this.observedAt,
      timezone: timezone,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

enum OutboxStatus { pending, inFlight, synced, failed, conflict }

class OutboxEventEntity {
  const OutboxEventEntity({
    required this.eventId,
    this.entity = 'journal_entry',
    this.operation = 'upsert',
    required this.payload,
    this.status = OutboxStatus.pending,
    this.retryCount = 0,
    this.maxRetries = 5,
    this.lastAttemptAt,
    this.errorMessage,
    required this.createdAt,
  });

  final String eventId;
  final String entity;
  final String operation;
  final Map<String, dynamic> payload;
  final OutboxStatus status;
  final int retryCount;
  final int maxRetries;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'event_id': eventId,
    'entity': entity,
    'operation': operation,
    'payload': jsonEncode(payload),
    'status': status.name,
    'retry_count': retryCount,
    'max_retries': maxRetries,
    'last_attempt_at': lastAttemptAt?.toIso8601String(),
    'error_message': errorMessage,
    'created_at': createdAt.toIso8601String(),
  };

  factory OutboxEventEntity.fromMap(Map<String, dynamic> map) => OutboxEventEntity(
    eventId: map['event_id'] as String,
    entity: map['entity'] as String? ?? 'journal_entry',
    operation: map['operation'] as String? ?? 'upsert',
    payload: map['payload'] is String
        ? jsonDecode(map['payload'] as String) as Map<String, dynamic>
        : map['payload'] as Map<String, dynamic>,
    status: OutboxStatus.values.firstWhere(
      (e) => e.name == (map['status'] as String? ?? 'pending'),
      orElse: () => OutboxStatus.pending,
    ),
    retryCount: map['retry_count'] as int? ?? 0,
    maxRetries: map['max_retries'] as int? ?? 5,
    lastAttemptAt: map['last_attempt_at'] != null ? DateTime.parse(map['last_attempt_at'] as String) : null,
    errorMessage: map['error_message'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
