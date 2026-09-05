import '../network/api_client.dart';
import '../../shared/widgets/chat_components.dart';

abstract class ChatRepository {
  Future<String> createSession(Domain domain);
  Future<ChatMessage> sendMessage(String sessionId, String text);
}

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<String> createSession(Domain domain) => apiClient.createChatSession(domain);

  @override
  Future<ChatMessage> sendMessage(String sessionId, String text) => apiClient.sendChatMessage(sessionId, text);
}
