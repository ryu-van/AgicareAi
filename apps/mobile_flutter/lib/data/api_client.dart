import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/app_logger.dart';

enum Domain { plant, animal }

extension DomainLabel on Domain {
  String get value => name;
  String get label => this == Domain.plant ? 'Cây trồng' : 'Vật nuôi';
}

class Profile {
  const Profile({this.displayName, this.activeDomain});
  final String? displayName;
  final Domain? activeDomain;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    displayName: json['display_name'] as String?,
    activeDomain: _domainFromJson(json['active_domain']),
  );
}

class KnowledgeArticle {
  const KnowledgeArticle({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    this.sourceName,
  });
  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String? sourceName;

  factory KnowledgeArticle.fromJson(Map<String, dynamic> json) =>
      KnowledgeArticle(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Bài viết AgriCare',
        summary: json['summary'] as String?,
        content: json['content'] as String?,
        sourceName: json['source_name'] as String?,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.safetyLevel,
    this.status = 'completed',
    this.citations = const [],
  });
  final String text;
  final bool isUser;
  final String? safetyLevel;
  final String status;
  final List<String> citations;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    String? userId,
    bool? devAuthEnabled,
    this.authToken,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceFirst(
         RegExp(r'/$'),
         '',
       ),
       _userId = userId ?? AppConfig.devUserId,
       _devAuthEnabled = devAuthEnabled ?? AppConfig.useDevAuth;

  final http.Client _client;
  final String _baseUrl;
  final String _userId;
  final bool _devAuthEnabled;
  final String? authToken;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
    if (authToken == null && _devAuthEnabled)
      'Authorization': 'Bearer dev:$_userId',
  };

  Future<dynamic> _get(String path) async {
    final response = await _getWithRetry(path);
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map && body['error'] is Map<String, dynamic>
          ? (body['error'] as Map<String, dynamic>)['message'] as String?
          : null;
      throw Exception(message ?? 'Không thể kết nối máy chủ.');
    }
    return body;
  }

  Future<http.Response> _getWithRetry(String path) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _client
            .get(Uri.parse('$_baseUrl$path'), headers: _headers)
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        AppLogger.event(
          'api.get.timeout',
          fields: {'path': path, 'attempt': attempt + 1},
        );
        if (attempt == 1) rethrow;
      }
    }
    throw StateError('GET request retry exhausted');
  }

  Future<Profile> getProfile() async =>
      Profile.fromJson(await _get('/v1/me') as Map<String, dynamic>);

  Future<Profile> updateProfile(
    String displayName, {
    Domain? activeDomain,
  }) async => Profile.fromJson(
    await _patch('/v1/me', {
      'display_name': displayName,
      if (activeDomain != null) 'active_domain': activeDomain.value,
    }),
  );

  Future<bool> healthCheck() async {
    final body = await _get('/health') as Map<String, dynamic>;
    return body['status'] == 'ok' || body['status'] == 'healthy';
  }

  Future<List<KnowledgeArticle>> getArticles(
    Domain domain, {
    String? query,
  }) async {
    final encodedQuery = query == null || query.trim().isEmpty
        ? ''
        : '&q=${Uri.encodeQueryComponent(query.trim())}';
    final body =
        await _get(
              '/v1/knowledge/articles?domain=${domain.value}&limit=3$encodedQuery',
            )
            as Map<String, dynamic>;
    return ((body['items'] as List<dynamic>? ?? const []))
        .map((item) => KnowledgeArticle.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<KnowledgeArticle> getArticle(String articleId) async =>
      KnowledgeArticle.fromJson(
        await _get('/v1/knowledge/articles/$articleId') as Map<String, dynamic>,
      );

  Future<List<String>> getSubjects(Domain domain) async {
    final body =
        await _get('/v1/subjects?domain=${domain.value}') as List<dynamic>;
    return body
        .map((item) => (item as Map<String, dynamic>)['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<String> createChatSession(Domain domain) async {
    final response = await _post('/v1/chat/sessions', {'domain': domain.value});
    return response['id'] as String;
  }

  Future<ChatMessage> sendChatMessage(String sessionId, String content) async {
    final response = await _post('/v1/chat/sessions/$sessionId/messages', {
      'content': content,
    });
    final citations = (response['citations'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              (item as Map<String, dynamic>)['section'] as String? ??
              'Nguồn kiến thức',
        )
        .toList();
    return ChatMessage(
      text: response['answer'] as String? ?? 'Mình đang xử lý câu hỏi của bạn.',
      isUser: false,
      status: response['status'] as String? ?? 'completed',
      safetyLevel: response['safety_level'] as String?,
      citations: citations,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: {
            ..._headers,
            'Idempotency-Key':
                'flutter-${DateTime.now().microsecondsSinceEpoch}',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể thực hiện yêu cầu lúc này.');
    }
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client
        .patch(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể lưu thông tin lúc này.');
    }
    return body as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}

Domain? _domainFromJson(Object? value) => switch (value) {
  'plant' => Domain.plant,
  'animal' => Domain.animal,
  _ => null,
};
