import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:agricare_ai_mobile/data/api_client.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);
  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  test('maps profile and article models', () {
    final profile = Profile.fromJson({
      'display_name': 'Lan',
      'active_domain': 'animal',
    });
    final article = KnowledgeArticle.fromJson({
      'id': 'a1',
      'title': 'Chăm sóc lúa',
      'content': 'Nội dung',
      'source_name': 'AgriCare',
    });
    expect(profile.displayName, 'Lan');
    expect(profile.activeDomain, Domain.animal);
    expect(article.content, 'Nội dung');
    expect(article.sourceName, 'AgriCare');
  });

  test('keeps compatible auth header and maps profile response', () async {
    late http.BaseRequest request;
    final client = ApiClient(
      client: _FakeClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({'display_name': 'Demo', 'active_domain': 'plant'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'http://test',
      userId: 'user-1',
    );
    final profile = await client.getProfile();
    expect(profile.displayName, 'Demo');
    expect(request.headers['authorization'], 'Bearer dev:user-1');
    client.dispose();
  });

  test('maps API errors to an exception', () async {
    final client = ApiClient(
      client: _FakeClient(
        (_) async => http.Response('{"error":{"message":"Unauthorized"}}', 401),
      ),
      baseUrl: 'http://test',
    );
    expect(client.getProfile(), throwsException);
    client.dispose();
  });

  test('omits demo auth when production auth is selected', () async {
    late http.BaseRequest request;
    final client = ApiClient(
      client: _FakeClient((incoming) async {
        request = incoming;
        return http.Response('{"status":"ok"}', 200);
      }),
      baseUrl: 'http://test',
      devAuthEnabled: false,
    );

    await client.healthCheck();
    expect(request.headers.containsKey('authorization'), isFalse);
    client.dispose();
  });

  test('supports an injected production access token', () async {
    late http.BaseRequest request;
    final client = ApiClient(
      client: _FakeClient((incoming) async {
        request = incoming;
        return http.Response('{"status":"ok"}', 200);
      }),
      baseUrl: 'http://test',
      devAuthEnabled: false,
      authToken: 'access-token',
    );

    await client.healthCheck();
    expect(request.headers['authorization'], 'Bearer access-token');
    client.dispose();
  });

  test('retries a GET once after timeout', () async {
    var attempts = 0;
    final client = ApiClient(
      client: _FakeClient((_) async {
        attempts++;
        if (attempts == 1) throw TimeoutException('test timeout');
        return http.Response('{"status":"ok"}', 200);
      }),
      baseUrl: 'http://test',
    );

    expect(await client.healthCheck(), isTrue);
    expect(attempts, 2);
    client.dispose();
  });
}
