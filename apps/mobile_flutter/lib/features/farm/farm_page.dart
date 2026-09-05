import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/repositories/farm_repository.dart';

class FarmPage extends StatefulWidget {
  FarmPage({super.key, ApiClient? apiClient, FarmRepository? repository})
      : repository = repository ?? ApiFarmRepository(apiClient: apiClient ?? ApiClient());
  final FarmRepository repository;

  @override
  State<FarmPage> createState() => _FarmPageState();
}


class _FarmPageState extends State<FarmPage> {
  bool _loading = true;
  String _farmName = 'Trang trại AgriCare Demo';
  double _areaHa = 2.5;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  Future<void> _loadFarmData() async {
    final summary = await widget.repository.getFarmSummary();
    if (!mounted) return;
    setState(() {
      _farmName = summary['name'] as String? ?? _farmName;
      _areaHa = (summary['totalAreaHa'] as num?)?.toDouble() ?? _areaHa;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Trang trại'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            onPressed: () {},
            tooltip: 'Thêm khu nuôi trồng',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.landscape, color: Colors.green, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_farmName, style: theme.textTheme.titleMedium),
                                  Text('Diện tích: $_areaHa ha', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem(context, '3', 'Khu trồng trọt', Icons.grass),
                            _statItem(context, '2', 'Khu chăn nuôi', Icons.pets),
                            _statItem(context, 'Tốt', 'Trạng thái', Icons.check_circle_outline),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
