import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agricare_ai_mobile/core/auth/auth_service.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';
import 'package:agricare_ai_mobile/core/theme/app_theme.dart';
import 'package:agricare_ai_mobile/features/auth/register_page.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

Widget _wrapTestWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RegisterPage renders all required inputs and farming domains', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test');
    final authService = AuthService(baseUrl: 'http://test');

    await tester.pumpWidget(
      _wrapTestWidget(
        RegisterPage(apiClient: apiClient, authService: authService),
      ),
    );

    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Họ và tên của bạn'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    expect(find.text('Cây trồng'), findsOneWidget);
    expect(find.text('Vật nuôi'), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsOneWidget);
  });

  testWidgets('validates required fields and password matching', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test');
    final authService = AuthService(baseUrl: 'http://test');

    await tester.pumpWidget(
      _wrapTestWidget(
        RegisterPage(apiClient: apiClient, authService: authService),
      ),
    );

    // Scroll to and tap register without inputs
    final createBtn = find.widgetWithText(FilledButton, 'Tạo tài khoản');
    await tester.ensureVisible(createBtn);
    await tester.pumpAndSettle();
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
  });

  testWidgets('switches farming domain preference', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test');
    final authService = AuthService(baseUrl: 'http://test');

    await tester.pumpWidget(
      _wrapTestWidget(
        RegisterPage(apiClient: apiClient, authService: authService),
      ),
    );

    final animalChoice = find.text('Vật nuôi');
    await tester.tap(animalChoice);
    await tester.pumpAndSettle();

    expect(animalChoice, findsOneWidget);
  });

  testWidgets('submits registration successfully and logs in', (tester) async {
    final fakeHttp = _FakeHttpClient((request) async {
      return http.Response(
        jsonEncode({
          'access_token': 'new-user-token',
          'refresh_token': 'new-refresh-token',
          'user': {
            'id': 'u-reg-1',
            'display_name': 'Nông Dân Tri Thức',
            'phone': '0987654321',
          },
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final authService = AuthService(client: fakeHttp, baseUrl: 'http://test');
    final apiClient = ApiClient(client: fakeHttp, baseUrl: 'http://test', authService: authService);

    var registerSuccess = false;
    await tester.pumpWidget(
      _wrapTestWidget(
        RegisterPage(
          apiClient: apiClient,
          authService: authService,
          onRegisterSuccess: () => registerSuccess = true,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Họ và tên của bạn'),
      'Nông Dân Tri Thức',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Số điện thoại'),
      '0987654321',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      'matkhau678',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Xác nhận mật khẩu'),
      'matkhau678',
    );

    // Scroll to and tap create account button
    final createBtn = find.widgetWithText(FilledButton, 'Tạo tài khoản');
    await tester.ensureVisible(createBtn);
    await tester.pumpAndSettle();
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    expect(registerSuccess, isTrue);
    expect(authService.isAuthenticated, isTrue);
    expect(authService.currentDisplayName, 'Nông Dân Tri Thức');
  });
}
