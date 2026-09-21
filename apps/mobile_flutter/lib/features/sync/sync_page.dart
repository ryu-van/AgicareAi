import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/database/in_memory_store.dart';
import '../../core/network/api_client.dart';
import '../../core/repositories/journal_repository.dart';
import '../../core/sync/sync_engine.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({
    super.key,
    required this.apiClient,
    this.syncEngine,
    this.repository,
  });


  final ApiClient apiClient;
  final SyncEngine? syncEngine;
  final JournalRepository? repository;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final SyncEngine _engine;
  bool _syncing = false;
  int _pendingCount = 0;
  String _statusMessage = 'Dữ liệu đã được đồng bộ mới nhất.';

  @override
  void initState() {
    super.initState();
    _engine = widget.syncEngine ??
        (widget.repository?.syncEngine) ??
        SyncEngine(
          apiClient: widget.apiClient,
          localStore: InMemoryJournalStore(populateDefaultSeed: false),
          outboxStore: InMemoryOutboxStore(),
        );
    _checkPendingCount();
  }

  Future<void> _checkPendingCount() async {
    final count = await _engine.outboxStore.getPendingCount();
    if (!mounted) return;
    setState(() {
      _pendingCount = count;
      if (count > 0) {
        _statusMessage = 'Có $count sự kiện ngoại tuyến đang chờ gửi lên máy chủ.';
      }
    });
  }

  void _triggerSync() async {
    setState(() {
      _syncing = true;
      _statusMessage = 'Đang đồng bộ dữ liệu ngoại tuyến...';
    });

    final result = await _engine.syncNow();
    if (!mounted) return;

    final remaining = await _engine.outboxStore.getPendingCount();
    setState(() {
      _syncing = false;
      _pendingCount = remaining;
      _statusMessage = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đồng bộ Dữ liệu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: _syncing
                          ? Colors.orange.shade50
                          : (_pendingCount > 0
                              ? Colors.amber.shade50
                              : const Color(0xFFE8F5E9)),
                      child: Icon(
                        _syncing
                            ? LucideIcons.refreshCw
                            : (_pendingCount > 0
                                ? LucideIcons.cloudUpload
                                : LucideIcons.cloudCheck),
                        size: 38,
                        color: _syncing
                            ? Colors.orange
                            : (_pendingCount > 0
                                ? Colors.amber.shade800
                                : const Color(0xFF2E7D32)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trạng thái Ngoại tuyến (Offline)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    if (_pendingCount > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Hàng đợi: $_pendingCount mục',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _syncing ? null : _triggerSync,
                      icon: _syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.refreshCw),
                      label: Text(_syncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
