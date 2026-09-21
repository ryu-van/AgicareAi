import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agricare_ai_mobile/app.dart';
import 'package:agricare_ai_mobile/core/auth/auth_service.dart';
import 'package:agricare_ai_mobile/core/auth/auth_state.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';
import 'package:agricare_ai_mobile/features/auth/login_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AgriCareApp shows LoginPage when unauthenticated with authService', (tester) async {
    final authService = AuthService(
      baseUrl: 'http://test',
      initialState: const AuthState.unauthenticated(),
    );
    final apiClient = ApiClient(baseUrl: 'http://test', authService: authService);

    await tester.pumpWidget(
      AgriCareApp(apiClient: apiClient, authService: authService),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Đăng nhập tài khoản'), findsOneWidget);
  });

  testWidgets('AgriCareApp shows HomeShell when user is guest', (tester) async {
    final authService = AuthService(
      baseUrl: 'http://test',
      initialState: const AuthState.guest(),
    );
    final apiClient = ApiClient(baseUrl: 'http://test', authService: authService);

    await tester.pumpWidget(
      AgriCareApp(apiClient: apiClient, authService: authService),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Bạn muốn làm gì hôm nay?'), findsOneWidget);
  });

  testWidgets('AgriCareApp shows HomeShell when user is authenticated', (tester) async {
    final authService = AuthService(
      baseUrl: 'http://test',
      initialState: const AuthState.authenticated(
        accessToken: 'tk',
        refreshToken: 'rf',
        userId: 'u1',
      ),
    );
    final apiClient = ApiClient(baseUrl: 'http://test', authService: authService);

    await tester.pumpWidget(
      AgriCareApp(apiClient: apiClient, authService: authService),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Bạn muốn làm gì hôm nay?'), findsOneWidget);
  });

  testWidgets('AgriCareApp respects requireAuth=false for testing backward compatibility', (tester) async {
    final authService = AuthService(
      baseUrl: 'http://test',
      initialState: const AuthState.unauthenticated(),
    );

    await tester.pumpWidget(
      AgriCareApp(authService: authService, requireAuth: false),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
