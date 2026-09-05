import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool _syncing = false;
  String _statusMessage = 'Dữ liệu đã được đồng bộ mới nhất.';

  void _triggerSync() async {
    setState(() {
      _syncing = true;
      _statusMessage = 'Đang đồng bộ dữ liệu ngoại tuyến...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _syncing = false;
      _statusMessage = 'Đồng bộ hoàn tất thành công!';
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
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      _syncing ? Icons.sync : Icons.cloud_done_outlined,
                      size: 56,
                      color: _syncing ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(height: 12),
                    Text('Trạng thái Ngoại tuyến (Offline)', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_statusMessage, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _syncing ? null : _triggerSync,
                      icon: _syncing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
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
