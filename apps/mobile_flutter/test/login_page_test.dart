import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agricare_ai_mobile/core/auth/auth_service.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';
import 'package:agricare_ai_mobile/core/theme/app_theme.dart';
import 'package:agricare_ai_mobile/features/auth/login_page.dart';
import 'package:agricare_ai_mobile/features/auth/register_page.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this.handler);

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

  testWidgets('LoginPage renders branding elements correctly', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test');
    final authService = AuthService(baseUrl: 'http://test');

    await tester.pumpWidget(
      _wrapTestWidget(
        LoginPage(apiClient: apiClient, authService: authService),
      ),
    );

    expect(find.text('AgriAn'), findsWidgets);
    expect(find.text('Vụ mùa an tâm, nông gia thịnh vượng'), findsOneWidget);
    expect(find.text('Đăng nhập tài khoản'), findsOneWidget);
    expect(find.text('Số điện thoại hoặc tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Dùng thử ngoại tuyến (Không cần mạng)'), findsOneWidget);
    expect(find.text('Đăng ký tài khoản mới'), findsOneWidget);
  });

  testWidgets('validates required fields on submit', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test');
    final authService = AuthService(baseUrl: 'http://test');

    await tester.pumpWidget(
      _wrapTestWidget(
        LoginPage(apiClient: apiClient, authService: authService),
      ),
    );

    // Tap login button without filling inputs
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập số điện thoại hoặc tài khoản'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test');
    final authService = AuthService(baseUrl: 'http://test');

    await tester.pumpWidget(
      _wrapTestWidget(
        LoginPage(apiClient: apiClient, authService: authService),
      ),
    );

    final eyeFinder = find.byTooltip('Hiện mật khẩu');
    expect(eyeFinder, findsOneWidget);

    await tester.tap(eyeFinder);
    await tester.pump();

    expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
  });

  testWidgets('tapping guest button activates guest mode', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test');
    final authService = AuthService(baseUrl: 'http://test');

    var successCalled = false;
    await tester.pumpWidget(
      _wrapTestWidget(
        LoginPage(
          apiClient: apiClient,
          authService: authService,
          onLoginSuccess: () => successCalled = true,
        ),
      ),
    );

    final guestButton = find.text('Dùng thử ngoại tuyến (Không cần mạng)');
    await tester.ensureVisible(guestButton);
    await tester.pumpAndSettle();
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    expect(authService.isGuest, isTrue);
    expect(successCalled, isTrue);
  });

  testWidgets('tapping register navigation navigates to RegisterPage', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://test');
    final authService = AuthService(baseUrl: 'http://test');

    await tester.pumpWidget(
      _wrapTestWidget(
        LoginPage(apiClient: apiClient, authService: authService),
      ),
    );

    final registerBtn = find.text('Đăng ký tài khoản mới');
    await tester.ensureVisible(registerBtn);
    await tester.pumpAndSettle();
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Lĩnh vực canh tác quan tâm chính:'), findsOneWidget);
  });

  testWidgets('submitting credentials logs in successfully', (tester) async {
    final fakeHttp = _FakeHttpClient((request) async {
      return http.Response(
        jsonEncode({
          'access_token': 'test-access-token',
          'refresh_token': 'test-refresh-token',
          'user': {
            'id': 'user-100',
            'display_name': 'Nông Dân Việt',
            'phone': '0912345678',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final authService = AuthService(client: fakeHttp, baseUrl: 'http://test');
    final apiClient = ApiClient(client: fakeHttp, baseUrl: 'http://test', authService: authService);

    var loginSuccess = false;
    await tester.pumpWidget(
      _wrapTestWidget(
        LoginPage(
          apiClient: apiClient,
          authService: authService,
          onLoginSuccess: () => loginSuccess = true,
        ),
      ),
    );

    // Enter phone
    final identifierInput = find.widgetWithText(TextFormField, 'Số điện thoại hoặc tên đăng nhập');
    await tester.enterText(identifierInput, '0912345678');

    // Enter password
    final passwordInput = find.widgetWithText(TextFormField, 'Mật khẩu');
    await tester.enterText(passwordInput, 'matkhau123');

    // Tap login button
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(loginSuccess, isTrue);
    expect(authService.isAuthenticated, isTrue);
    expect(authService.currentDisplayName, 'Nông Dân Việt');
  });

  testWidgets('displays error banner when login fails', (tester) async {
    final fakeHttp = _FakeHttpClient((request) async {
      return http.Response(
        jsonEncode({
          'error': {'message': 'Mật khẩu không chính xác.'},
        }),
        400,
        headers: {'content-type': 'application/json'},
      );
    });

    final authService = AuthService(client: fakeHttp, baseUrl: 'http://test');
    final apiClient = ApiClient(client: fakeHttp, baseUrl: 'http://test', authService: authService);

    await tester.pumpWidget(
      _wrapTestWidget(
        LoginPage(apiClient: apiClient, authService: authService),
      ),
    );

    final identifierInput = find.widgetWithText(TextFormField, 'Số điện thoại hoặc tên đăng nhập');
    await tester.enterText(identifierInput, '0912345678');

    final passwordInput = find.widgetWithText(TextFormField, 'Mật khẩu');
    await tester.enterText(passwordInput, 'wrongpassword');

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu không chính xác.'), findsOneWidget);
    expect(authService.isAuthenticated, isFalse);
  });
}
