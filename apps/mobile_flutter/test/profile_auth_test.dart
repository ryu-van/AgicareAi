import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agricare_ai_mobile/core/auth/auth_service.dart';
import 'package:agricare_ai_mobile/core/auth/auth_state.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';
import 'package:agricare_ai_mobile/core/theme/app_theme.dart';
import 'package:agricare_ai_mobile/features/auth/login_page.dart';
import 'package:agricare_ai_mobile/features/profile/profile_page.dart';

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
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ProfilePage displays guest banner when in guest mode', (tester) async {
    final authService = AuthService(
      baseUrl: 'http://test',
      initialState: const AuthState.guest(),
    );
    final apiClient = ApiClient(baseUrl: 'http://test', authService: authService);

    await tester.pumpWidget(
      _wrapTestWidget(
        ProfilePage(apiClient: apiClient, authService: authService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chế độ dùng thử ngoại tuyến'), findsOneWidget);
    expect(find.text('Đăng nhập để đồng bộ dữ liệu nhật ký của bạn và nhận hỗ trợ từ chuyên gia AI.'), findsOneWidget);
    expect(find.text('Đăng nhập ngay'), findsOneWidget);

    // Scroll down to see logout button
    await tester.drag(find.byType(ProfilePage), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Thoát chế độ khách'), findsOneWidget);
  });

  testWidgets('ProfilePage displays phone and user info when authenticated', (tester) async {
    final fakeHttp = _FakeHttpClient((request) async {
      return http.Response('{"display_name": "Chú Tư Nông Nghiệp"}', 200);
    });

    final authService = AuthService(
      client: fakeHttp,
      baseUrl: 'http://test',
      initialState: const AuthState.authenticated(
        accessToken: 'tk',
        refreshToken: 'rf',
        userId: 'u4',
        displayName: 'Chú Tư Nông Nghiệp',
        phone: '0988776655',
      ),
    );
    final apiClient = ApiClient(client: fakeHttp, baseUrl: 'http://test', authService: authService);

    await tester.pumpWidget(
      _wrapTestWidget(
        ProfilePage(apiClient: apiClient, authService: authService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chú Tư Nông Nghiệp'), findsWidgets);
    expect(find.text('0988776655'), findsWidgets);

    await tester.drag(find.byType(ProfilePage), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất tài khoản'), findsOneWidget);
  });

  testWidgets('Logout shows friendly confirmation dialog and logs out on confirm', (tester) async {
    final authService = AuthService(
      baseUrl: 'http://test',
      initialState: const AuthState.authenticated(
        accessToken: 'valid-token',
        refreshToken: 'rt',
        userId: 'u1',
      ),
    );
    final apiClient = ApiClient(baseUrl: 'http://test', authService: authService);

    await tester.pumpWidget(
      _wrapTestWidget(
        ProfilePage(apiClient: apiClient, authService: authService),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to find logout button
    await tester.drag(find.byType(ProfilePage), const Offset(0, -400));
    await tester.pumpAndSettle();

    final logoutBtn = find.text('Đăng xuất tài khoản');
    expect(logoutBtn, findsOneWidget);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
    expect(find.text('Bạn có chắc chắn muốn đăng xuất khỏi AgriAn?'), findsOneWidget);
    expect(find.text('Ở lại'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);

    // Confirm logout
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(authService.isAuthenticated, isFalse);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
