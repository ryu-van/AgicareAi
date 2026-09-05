import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/repositories/journal_repository.dart';

class JournalPage extends StatefulWidget {
  JournalPage({super.key, ApiClient? apiClient, JournalRepository? repository})
      : repository = repository ?? ApiJournalRepository(apiClient: apiClient ?? ApiClient());
  final JournalRepository repository;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Map<String, String>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final data = await widget.repository.fetchJournalEntries();
    if (!mounted) return;
    setState(() {
      _entries = data;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký Sản xuất'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
            tooltip: 'Tạo nhật ký mới',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.edit_note),
              ),
              title: Text(entry['title']!),
              subtitle: Text('${entry['type']} • ${entry['date']}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
