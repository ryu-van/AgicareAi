import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:agricare_ai_mobile/app.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';
import 'package:agricare_ai_mobile/features/profile/profile_page.dart';

class _FlowClient extends http.BaseClient {
  bool patchCalled = false;
  bool failPatch = false;
  bool failNextMessage = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    if (request.method == 'PATCH') patchCalled = true;
    if (request.method == 'PATCH' && failPatch) {
      final response = http.Response('{"error":{}}', 500);
      return http.StreamedResponse(
        Stream.value(utf8.encode(response.body)),
        response.statusCode,
        headers: response.headers,
      );
    }
    if (request.method == 'POST' &&
        path.endsWith('/messages') &&
        failNextMessage) {
      failNextMessage = false;
      final response = http.Response('{"error":{}}', 500);
      return http.StreamedResponse(
        Stream.value(utf8.encode(response.body)),
        response.statusCode,
        headers: response.headers,
      );
    }
    final response = switch ((request.method, path)) {
      ('GET', '/v1/me') => _json({
        'display_name': 'Nông hộ demo',
        'active_domain': 'plant',
      }),
      ('PATCH', '/v1/me') => _json({
        'display_name': 'Tên mới',
        'active_domain': 'animal',
      }),
      ('GET', '/v1/knowledge/articles') => _json({
        'items': [
          {
            'id': 'a1',
            'title': 'Bài viết kiểm thử',
            'summary': 'Tóm tắt kiểm thử',
          },
        ],
      }),
      ('GET', '/v1/knowledge/articles/a1') => _json({
        'id': 'a1',
        'title': 'Bài viết kiểm thử',
        'content': 'Nội dung bài viết kiểm thử',
        'source_name': 'Fixture',
      }),
      ('POST', '/v1/chat/sessions') => _json({'id': 'session-1'}, 201),
      ('POST', '/v1/chat/sessions/session-1/messages') => _json({
        'answer': 'Câu trả lời kiểm thử',
        'status': 'completed',
        'citations': [
          {'section': 'Fixture'},
        ],
      }, 201),
      _ => http.Response('{}', 404),
    };
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }

  static http.Response _json(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
}

ApiClient _apiClient() => ApiClient(
  client: _FlowClient(),
  baseUrl: 'http://test',
  userId: 'flow-user',
);

void main() {
  testWidgets('home knowledge card opens article detail', (tester) async {
    final apiClient = _apiClient();
    addTearDown(apiClient.dispose);
    await tester.pumpWidget(AgriCareApp(apiClient: apiClient));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pump();
    await tester.tap(find.text('Bài viết kiểm thử').first);
    await tester.pumpAndSettle();

    expect(find.text('Nội dung bài viết kiểm thử'), findsOneWidget);
  });

  testWidgets('home to knowledge to article flow', (tester) async {
    final apiClient = _apiClient();
    addTearDown(apiClient.dispose);
    await tester.pumpWidget(AgriCareApp(apiClient: apiClient));
    await tester.pump();

    await tester.tap(find.text('Kiến thức').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bài viết kiểm thử'));
    await tester.pumpAndSettle();

    expect(find.text('Nội dung bài viết kiểm thử'), findsOneWidget);
    expect(find.text('Nguồn: Fixture'), findsOneWidget);
  });

  testWidgets('chat create session and send response flow', (tester) async {
    final apiClient = _apiClient();
    addTearDown(apiClient.dispose);
    await tester.pumpWidget(
      AgriCareApp(apiClient: apiClient, initialRoute: '/chat'),
    );
    await tester.pump();
    await tester.tap(find.byType(ActionChip).first);
    await tester.tap(find.byTooltip('Gửi câu hỏi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Câu trả lời kiểm thử'), findsOneWidget);
    expect(find.text('Nguồn: Fixture'), findsOneWidget);
  });

  testWidgets('profile load edit and save flow', (tester) async {
    final transport = _FlowClient();
    final apiClient = ApiClient(
      client: transport,
      baseUrl: 'http://test',
      userId: 'flow-user',
    );
    addTearDown(apiClient.dispose);
    await tester.pumpWidget(
      MaterialApp(home: ProfilePage(apiClient: apiClient)),
    );
    await tester.pump();

    final profilePage = find.byType(ProfilePage);
    final field = find.descendant(
      of: profilePage,
      matching: find.byType(TextField),
    );
    expect(
      find.descendant(of: profilePage, matching: find.text('Nông hộ demo')),
      findsWidgets,
    );
    await tester.enterText(field, 'Tên mới');
    final saveButton = find.descendant(
      of: profilePage,
      matching: find.byType(FilledButton),
    );
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(transport.patchCalled, isTrue);
    expect(find.text('Tên mới'), findsWidgets);
  });

  testWidgets('profile save failure keeps entered data', (tester) async {
    final transport = _FlowClient()..failPatch = true;
    final apiClient = ApiClient(
      client: transport,
      baseUrl: 'http://test',
      userId: 'flow-user',
    );
    addTearDown(apiClient.dispose);
    await tester.pumpWidget(
      MaterialApp(home: ProfilePage(apiClient: apiClient)),
    );
    await tester.pump();

    final profilePage = find.byType(ProfilePage);
    final field = find.descendant(
      of: profilePage,
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'Tên chưa mất');
    final saveButton = find.descendant(
      of: profilePage,
      matching: find.byType(FilledButton),
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(transport.patchCalled, isTrue);
    expect(tester.widget<TextField>(field).controller?.text, 'Tên chưa mất');
    expect(find.text('Không thể lưu hồ sơ. Hãy thử lại.'), findsOneWidget);
  });

  testWidgets('chat request failure can be retried', (tester) async {
    final transport = _FlowClient()..failNextMessage = true;
    final apiClient = ApiClient(
      client: transport,
      baseUrl: 'http://test',
      userId: 'flow-user',
    );
    addTearDown(apiClient.dispose);
    await tester.pumpWidget(
      AgriCareApp(apiClient: apiClient, initialRoute: '/chat'),
    );
    await tester.pump();
    await tester.tap(find.byType(ActionChip).first);
    await tester.tap(find.byTooltip('Gửi câu hỏi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final retry = find.byType(TextButton);
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Câu trả lời kiểm thử'), findsOneWidget);
  });
}
