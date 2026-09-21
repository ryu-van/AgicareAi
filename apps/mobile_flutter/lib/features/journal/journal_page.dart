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
  bool _isSyncing = false;

  String? _selectedSubjectFilter;
  String? _selectedTypeFilter;

  static const _subjects = [
    {'id': 'rice', 'label': 'Cây lúa'},
    {'id': 'chicken', 'label': 'Đàn gà'},
    {'id': 'pig', 'label': 'Đàn heo'},
    {'id': 'coffee', 'label': 'Cây cà phê'},
    {'id': 'durian', 'label': 'Cây sầu riêng'},
  ];

  static const _types = [
    {'id': 'treatment', 'label': 'Bón phân / Chăm sóc'},
    {'id': 'observation', 'label': 'Theo dõi sâu bệnh'},
    {'id': 'feeding', 'label': 'Cho ăn / Dinh dưỡng'},
    {'id': 'vaccination', 'label': 'Tiêm phòng'},
    {'id': 'harvest', 'label': 'Thu hoạch'},
  ];

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

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await widget.repository.syncPendingEvents();
      await _loadEntries();
      if (!mounted) return;
      final failed = result.processedCount - result.appliedCount - result.conflictCount;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Đồng bộ hoàn tất: ${result.appliedCount} thành công, ${result.conflictCount} xung đột, ${failed > 0 ? failed : 0} lỗi.',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không thể kết nối máy chủ để đồng bộ lúc này.'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  List<Map<String, String>> get _filteredEntries {
    return _entries.where((e) {
      if (_selectedSubjectFilter != null &&
          e['subject_id'] != _selectedSubjectFilter) {
        return false;
      }
      if (_selectedTypeFilter != null &&
          e['entry_type'] != _selectedTypeFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  String _getSubjectLabel(String? subjectId) {
    final found = _subjects.firstWhere(
      (s) => s['id'] == subjectId,
      orElse: () => {'label': subjectId ?? 'Chung'},
    );
    return found['label'] ?? subjectId ?? 'Chung';
  }

  IconData _getTypeIcon(String? type) {
    return switch (type) {
      'treatment' => LucideIcons.sprout,
      'observation' => LucideIcons.eye,
      'feeding' => LucideIcons.wheat,
      'vaccination' => LucideIcons.syringe,
      'harvest' => LucideIcons.packageCheck,
      _ => LucideIcons.notebookPen,
    };
  }

  void _showEntryFormModal({Map<String, String>? initialEntry}) {
    final isEditing = initialEntry != null;
    final titleController =
        TextEditingController(text: initialEntry?['title'] ?? '');
    final notesController =
        TextEditingController(text: initialEntry?['notes'] ?? '');
    var selectedSubject = initialEntry?['subject_id'] ?? 'rice';
    var selectedType = initialEntry?['entry_type'] ?? 'treatment';
    String? attachedPhoto = initialEntry?['photo_path'];
    if (attachedPhoto != null && attachedPhoto.isEmpty) {
      attachedPhoto = null;
    }

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
                          isEditing ? 'Chỉnh sửa Nhật ký' : 'Ghi Nhật ký Mùa vụ',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                      autofocus: !isEditing,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Đối tượng nông nghiệp',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.sprout),
                      ),
                      items: _subjects.map((s) {
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
                      items: _types.map((t) {
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
                        hintText:
                            'Liều lượng phân, thời tiết, biểu hiện bất thường...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.fileText),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Photo Attachment Area
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.camera,
                                  size: 18, color: Colors.black87),
                              const SizedBox(width: 8),
                              Text(
                                'Ảnh chụp thực địa / minh chứng',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (attachedPhoto != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.image,
                                      size: 18, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      attachedPhoto!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2,
                                        size: 16, color: Colors.red),
                                    onPressed: () {
                                      setModalState(() => attachedPhoto = null);
                                    },
                                    tooltip: 'Gỡ ảnh',
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              icon: const Icon(LucideIcons.camera, size: 16),
                              label: const Text('Chụp ảnh hoặc Chọn ảnh từ máy'),
                              onPressed: () {
                                final mockPath =
                                    'img_field_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                setModalState(() => attachedPhoto = mockPath);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(LucideIcons.save),
                      label: Text(isEditing
                          ? 'Cập nhật Nhật ký'
                          : 'Lưu vào Nhật ký (Ngoại tuyến)'),
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
                        if (isEditing) {
                          await widget.repository.editEntry(
                            localId: initialEntry['id']!,
                            title: title,
                            entryType: selectedType,
                            subjectId: selectedSubject,
                            notes: notesController.text,
                            photoPath: attachedPhoto,
                          );
                        } else {
                          await widget.repository.createEntry(
                            title: title,
                            entryType: selectedType,
                            subjectId: selectedSubject,
                            notes: notesController.text,
                            photoPath: attachedPhoto,
                          );
                        }
                        await _loadEntries();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Đã cập nhật nhật ký thành công.'
                                  : 'Đã lưu nhật ký vào máy an toàn (chờ đồng bộ)',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
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

  void _showEntryDetailBottomSheet(Map<String, String> entry) {
    final theme = Theme.of(context);
    final subjectLabel = _getSubjectLabel(entry['subject_id']);
    final isPending = entry['status'] == 'pendingSync';
    final isFailed = entry['status'] == 'syncFailed';
    final photoPath = entry['photo_path'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          _getTypeIcon(entry['entry_type']),
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry['type'] ?? 'Nhật ký',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                entry['title'] ?? '',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Meta chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(LucideIcons.sprout, size: 14),
                    label: Text(subjectLabel),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    avatar: const Icon(LucideIcons.calendar, size: 14),
                    label: Text(entry['date'] ?? ''),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    avatar: Icon(
                      isPending
                          ? LucideIcons.cloudUpload
                          : isFailed
                              ? LucideIcons.alertCircle
                              : LucideIcons.checkCircle2,
                      size: 14,
                      color: isPending
                          ? Colors.amber.shade900
                          : isFailed
                              ? Colors.red.shade800
                              : const Color(0xFF2E7D32),
                    ),
                    label: Text(
                      entry['status_label'] ??
                          (isPending ? 'Chờ gửi' : 'Đã đồng bộ'),
                      style: TextStyle(
                        color: isPending
                            ? Colors.amber.shade900
                            : isFailed
                                ? Colors.red.shade800
                                : const Color(0xFF2E7D32),
                      ),
                    ),
                    backgroundColor: isPending
                        ? Colors.amber.shade50
                        : isFailed
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (photoPath != null && photoPath.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.image,
                          color: Color(0xFF2E7D32), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ảnh minh chứng đính kèm',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              photoPath,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'Nội dung chi tiết & Ghi chú:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  entry['notes'] != null && entry['notes']!.isNotEmpty
                      ? entry['notes']!
                      : 'Không có ghi chú bổ sung nào.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: entry['notes'] != null && entry['notes']!.isNotEmpty
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.penLine, size: 16),
                      label: const Text('Chỉnh sửa'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showEntryFormModal(initialEntry: entry);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.trash2,
                          size: 16, color: Colors.red),
                      label: const Text('Xóa',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _confirmDelete(entry);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(Map<String, String> entry) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa nhật ký'),
          content: Text(
            'Bạn có chắc chắn muốn xóa "${entry['title']}"? '
            'Bản ghi này sẽ bị xóa trên thiết bị và đồng bộ xóa lên máy chủ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                final id = entry['id'];
                if (id != null) {
                  await widget.repository.deleteEntry(id);
                  await _loadEntries();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa bản ghi nhật ký.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedEntries = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký Sản xuất'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showEntryFormModal(),
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
                  // Pending Sync Banner
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
                              'Có $_pendingCount sự kiện ngoại tuyến đang chờ gửi.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _isSyncing ? null : _syncNow,
                            child: _isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Đồng bộ ngay'),
                          ),
                        ],
                      ),
                    ),

                  // Subject Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _selectedSubjectFilter == null,
                          label: const Text('Tất cả đối tượng'),
                          onSelected: (_) {
                            setState(() => _selectedSubjectFilter = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._subjects.map((s) {
                          final isSelected = _selectedSubjectFilter == s['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(s['label']!),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSubjectFilter =
                                      selected ? s['id'] : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Type Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _selectedTypeFilter == null,
                          label: const Text('Tất cả hoạt động'),
                          onSelected: (_) {
                            setState(() => _selectedTypeFilter = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._types.map((t) {
                          final isSelected = _selectedTypeFilter == t['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(t['label']!),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTypeFilter =
                                      selected ? t['id'] : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Entries List
                  Expanded(
                    child: displayedEntries.isEmpty
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
                                  _entries.isEmpty
                                      ? 'Chưa có nhật ký canh tác nào.'
                                      : 'Không tìm thấy nhật ký phù hợp với bộ lọc.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () => _showEntryFormModal(),
                                  icon: const Icon(LucideIcons.plus),
                                  label: const Text('Tạo nhật ký mới'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: displayedEntries.length,
                            itemBuilder: (context, index) {
                              final entry = displayedEntries[index];
                              final isPending =
                                  entry['status'] == 'pendingSync';
                              final isFailed = entry['status'] == 'syncFailed';
                              final hasPhoto = entry['photo_path'] != null &&
                                  entry['photo_path']!.isNotEmpty;
                              final subjectLabel =
                                  _getSubjectLabel(entry['subject_id']);

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
                                      _getTypeIcon(entry['entry_type']),
                                      size: 20,
                                      color: isPending
                                          ? Colors.amber.shade900
                                          : isFailed
                                              ? Colors.red.shade800
                                              : theme.colorScheme.primary,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry['title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (hasPhoto) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          LucideIcons.camera,
                                          size: 15,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        '${entry['type']} • $subjectLabel • ${entry['date']}',
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
                                              ?.copyWith(
                                                  color: Colors.black54),
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
                                  onTap: () =>
                                      _showEntryDetailBottomSheet(entry),
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
