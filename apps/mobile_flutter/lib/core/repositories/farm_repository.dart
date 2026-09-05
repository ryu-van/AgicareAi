import '../network/api_client.dart';

abstract class FarmRepository {
  Future<Map<String, dynamic>> getFarmSummary();
}

class ApiFarmRepository implements FarmRepository {
  ApiFarmRepository({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<Map<String, dynamic>> getFarmSummary() async {
    return {
      'name': 'Trang trại AgriCare Demo',
      'totalAreaHa': 2.5,
      'activeCrops': 3,
      'activeLivestock': 2,
    };
  }
}
