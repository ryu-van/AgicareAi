import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final List<Map<String, dynamic>> _reminders = [
    {
      'title': 'Tưới nước lúa vụ Đông Xuân',
      'time': '07:00 - 04/09/2026',
      'done': false,
    },
    {
      'title': 'Tiêm vắc xin phòng bệnh cho đàn gà',
      'time': '08:00 - 05/09/2026',
      'done': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc nhở Canh tác'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: () {},
            tooltip: 'Tạo nhắc nhở',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final item = _reminders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: CheckboxListTile(
              value: item['done'] as bool,
              title: Text(item['title'] as String),
              subtitle: Text(item['time'] as String),
              onChanged: (val) {
                setState(() => item['done'] = val);
              },
            ),
          );
        },
      ),
    );
  }
}
