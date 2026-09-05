import '../network/api_client.dart';

abstract class DiagnosisRepository {
  Future<String> analyzeSymptoms(String symptoms);
}

class ApiDiagnosisRepository implements DiagnosisRepository {
  ApiDiagnosisRepository({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<String> analyzeSymptoms(String symptoms) async {
    return 'Kết quả chẩn đoán sơ bộ:\n'
        '• Bệnh: Đốm lá vi khuẩn (Xanthomonas)\n'
        '• Độ tin cậy: 88%\n'
        '• Khuyến nghị: Sử dụng chế phẩm sinh học chứa Bacillus subtilis và tỉa bớt lá bệnh.';
  }
}
