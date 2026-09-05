import '../network/api_client.dart';

abstract class JournalRepository {
  Future<List<Map<String, String>>> fetchJournalEntries();
}

class ApiJournalRepository implements JournalRepository {
  ApiJournalRepository({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<List<Map<String, String>>> fetchJournalEntries() async {
    return [
      {
        'title': 'Bón phân đợt 1 cho lúa',
        'date': '02/09/2026',
        'type': 'Bón phân',
      },
      {
        'title': 'Kiểm tra tình trạng đàn gà',
        'date': '01/09/2026',
        'type': 'Theo dõi',
      },
    ];
  }
}
