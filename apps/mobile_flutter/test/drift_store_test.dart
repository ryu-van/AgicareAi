import 'dart:io';

import 'package:agricare_ai_mobile/core/database/drift_store.dart';
import 'package:agricare_ai_mobile/core/models/journal_entry_entity.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'persists journal entries and outbox events across store instances',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'agricare-offline-store-',
      );
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}journal.sqlite',
      );
      final database = OfflineDatabase.forTesting(NativeDatabase(databaseFile));
      final now = DateTime.utc(2026, 9, 21, 9);
      final entry = JournalEntryEntity(
        localId: 'local-1',
        clientEventId: 'event-1',
        subjectId: 'rice',
        entryType: 'observation',
        title: 'Theo dõi lúa',
        observedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final event = OutboxEventEntity(
        eventId: 'event-1',
        payload: {'title': entry.title},
        createdAt: now,
      );

      await DriftJournalStore(database).saveEntry(entry);
      await DriftOutboxStore(database).enqueue(event);

      await database.close();

      final reopenedDatabase = OfflineDatabase.forTesting(
        NativeDatabase(databaseFile),
      );
      final reopenedJournalStore = DriftJournalStore(reopenedDatabase);
      final reopenedOutboxStore = DriftOutboxStore(reopenedDatabase);
      expect(
        (await reopenedJournalStore.getEntryByLocalId(entry.localId))?.title,
        entry.title,
      );
      expect(
        (await reopenedOutboxStore.getPendingEvents()).single.payload,
        event.payload,
      );

      await reopenedDatabase.close();
      await directory.delete(recursive: true);
    },
  );
}
