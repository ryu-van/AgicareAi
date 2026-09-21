import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_client.dart';
import '../../core/repositories/journal_repository.dart';

class JournalPage extends StatefulWidget {
  JournalPage({super.key, ApiClient? apiClient, JournalRepository? repository})
      : repository = repository ??
            ApiJournalRepository(apiClient: apiClient ?? ApiClient());
  final JournalRepository repository;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Map<String, String>> _entries = [];
  int _pendingCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final data = await widget.repository.fetchJournalEntries();
    final count = await widget.repository.getPendingSyncCount();
    if (!mounted) return;
    setState(() {
      _entries = data;
      _pendingCount = count;
      _loading = false;
    });
  }

  void _showCreateEntryDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    var selectedSubject = 'rice';
    var selectedType = 'treatment';

    final subjects = [
      {'id': 'rice', 'label': 'Cây lúa'},
      {'id': 'chicken', 'label': 'Đàn gà'},
      {'id': 'pig', 'label': 'Đàn heo'},
      {'id': 'coffee', 'label': 'Cây cà phê'},
      {'id': 'durian', 'label': 'Cây sầu riêng'},
    ];

    final types = [
      {'id': 'treatment', 'label': 'Bón phân / Chăm sóc'},
      {'id': 'observation', 'label': 'Theo dõi sâu bệnh'},
      {'id': 'feeding', 'label': 'Cho ăn / Dinh dưỡng'},
      {'id': 'vaccination', 'label': 'Tiêm phòng'},
      {'id': 'harvest', 'label': 'Thu hoạch'},
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ghi Nhật ký Mùa vụ',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung thực hiện *',
                        hintText: 'Ví dụ: Bón phân đợt 2, phun thuốc trừ sâu...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.penLine),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Đối tượng nông nghiệp',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.sprout),
                      ),
                      items: subjects.map((s) {
                        return DropdownMenuItem(
                          value: s['id'],
                          child: Text(s['label']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedSubject = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại hoạt động',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.tag),
                      ),
                      items: types.map((t) {
                        return DropdownMenuItem(
                          value: t['id'],
                          child: Text(t['label']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú bổ sung (nếu có)',
                        hintText: 'Liều lượng phân, thời tiết, biểu hiện bất thường...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.fileText),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(LucideIcons.save),
                      label: const Text('Lưu vào Nhật ký (Ngoại tuyến)'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập nội dung thực hiện.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(sheetContext);
                        await widget.repository.createEntry(
                          title: title,
                          entryType: selectedType,
                          subjectId: selectedSubject,
                          notes: notesController.text,
                        );
                        await _loadEntries();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã lưu nhật ký vào máy an toàn (chờ đồng bộ)',
                            ),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký Sản xuất'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _showCreateEntryDialog,
            tooltip: 'Tạo nhật ký mới',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: Column(
                children: [
                  if (_pendingCount > 0)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.cloudUpload,
                            size: 20,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Có $_pendingCount sự kiện ngoại tuyến đang chờ gửi lên máy chủ.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.notebookPen,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Chưa có nhật ký canh tác nào.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _showCreateEntryDialog,
                                  icon: const Icon(LucideIcons.plus),
                                  label: const Text('Tạo nhật ký đầu tiên'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              final isPending =
                                  entry['status'] == 'pendingSync';
                              final isFailed =
                                  entry['status'] == 'syncFailed';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                elevation: 0.8,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isPending
                                        ? Colors.amber.shade100
                                        : isFailed
                                            ? Colors.red.shade100
                                            : theme.colorScheme.primaryContainer,
                                    child: Icon(
                                      isPending
                                          ? LucideIcons.cloudUpload
                                          : isFailed
                                              ? LucideIcons.alertCircle
                                              : LucideIcons.notebookPen,
                                      size: 20,
                                      color: isPending
                                          ? Colors.amber.shade900
                                          : isFailed
                                              ? Colors.red.shade800
                                              : theme.colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    entry['title'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        '${entry['type']} • ${entry['date']}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      if (entry['notes'] != null &&
                                          entry['notes']!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          entry['notes']!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.black54),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: isPending
                                      ? Chip(
                                          label: const Text(
                                            'Chờ gửi',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          backgroundColor:
                                              Colors.amber.shade100,
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        )
                                      : const Icon(
                                          LucideIcons.chevronRight,
                                          size: 18,
                                        ),
                                  onTap: () {},
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
