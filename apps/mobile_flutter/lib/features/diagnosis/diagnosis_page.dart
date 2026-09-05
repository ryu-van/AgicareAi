import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/repositories/diagnosis_repository.dart';

class DiagnosisPage extends StatefulWidget {
  DiagnosisPage({super.key, ApiClient? apiClient, DiagnosisRepository? repository})
      : repository = repository ?? ApiDiagnosisRepository(apiClient: apiClient ?? ApiClient());
  final DiagnosisRepository repository;

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  final _symptomsController = TextEditingController();
  bool _analyzing = false;
  String? _result;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _runDiagnosis() async {
    final symptoms = _symptomsController.text.trim();
    if (symptoms.isEmpty) return;
    setState(() {
      _analyzing = true;
      _result = null;
    });

    final res = await widget.repository.analyzeSymptoms(symptoms);
    if (!mounted) return;

    setState(() {
      _analyzing = false;
      _result = res;
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chẩn đoán Sâu bệnh'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.teal),
                    const SizedBox(height: 8),
                    Text('Chụp hoặc tải ảnh cây trồng / vật nuôi', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Chọn hình ảnh'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả triệu chứng наблюда quan sát được',
                hintText: 'Ví dụ: Lá cây bị thâm đen, xoắn lá, v.v.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _analyzing ? null : _runDiagnosis,
              icon: _analyzing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: Text(_analyzing ? 'Đang phân tích...' : 'Phân tích chẩn đoán'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_result!, style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
