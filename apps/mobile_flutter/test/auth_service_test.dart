import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agricare_ai_mobile/core/auth/auth_service.dart';
import 'package:agricare_ai_mobile/core/auth/auth_state.dart';
import 'package:agricare_ai_mobile/core/network/api_client.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Tests', () {
    test('initializes with unauthenticated state when storage is empty', () async {
      final service = AuthService(baseUrl: 'http://test');
      await service.initialize();

      expect(service.state.status, AuthStatus.unauthenticated);
      expect(service.isAuthenticated, isFalse);
      expect(service.isGuest, isFalse);
      expect(service.currentAccessToken, isNull);
    });

    test('initializes with authenticated state when storage has credentials', () async {
      SharedPreferences.setMockInitialValues({
        AuthService.keyAccessToken: 'valid-access-token',
        AuthService.keyRefreshToken: 'valid-refresh-token',
        AuthService.keyUserId: 'user-123',
        AuthService.keyDisplayName: 'Bác Ba Nông Dân',
        AuthService.keyPhone: '0987654321',
      });

      final service = AuthService(baseUrl: 'http://test');
      await service.initialize();

      expect(service.state.status, AuthStatus.authenticated);
      expect(service.isAuthenticated, isTrue);
      expect(service.currentAccessToken, 'valid-access-token');
      expect(service.currentUserId, 'user-123');
      expect(service.currentDisplayName, 'Bác Ba Nông Dân');
      expect(service.currentPhone, '0987654321');
    });

    test('initializes with guest state when storage has guest flag', () async {
      SharedPreferences.setMockInitialValues({
        AuthService.keyIsGuest: true,
      });

      final service = AuthService(baseUrl: 'http://test');
      await service.initialize();

      expect(service.state.status, AuthStatus.guest);
      expect(service.isGuest, isTrue);
      expect(service.isAuthenticated, isFalse);
    });

    test('login successfully stores tokens and updates state', () async {
      late http.BaseRequest sentRequest;
      final client = _FakeHttpClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'access_token': 'token-abc',
            'refresh_token': 'refresh-xyz',
            'user': {
              'id': 'user-999',
              'display_name': 'Anh Bảy',
              'phone': '0901234567',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: client, baseUrl: 'http://test');
      final state = await service.login(
        identifier: '0901234567',
        password: 'secretPassword',
      );

      expect(sentRequest.url.path, '/v1/auth/login');
      expect(state.status, AuthStatus.authenticated);
      expect(state.accessToken, 'token-abc');
      expect(state.userId, 'user-999');
      expect(state.displayName, 'Anh Bảy');
      expect(state.phone, '0901234567');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AuthService.keyAccessToken), 'token-abc');
      expect(prefs.getString(AuthService.keyRefreshToken), 'refresh-xyz');
      expect(prefs.getString(AuthService.keyUserId), 'user-999');
    });

    test('login throws exception when server returns 401 error', () async {
      final client = _FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'UNAUTHENTICATED',
              'message': 'Số điện thoại hoặc mật khẩu không chính xác.',
            },
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: client, baseUrl: 'http://test');

      expect(
        () => service.login(identifier: '0901234567', password: 'wrong'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Số điện thoại hoặc mật khẩu không chính xác.'),
        )),
      );
      expect(service.isAuthenticated, isFalse);
    });

    test('register successfully creates account and updates state', () async {
      late http.BaseRequest sentRequest;
      final client = _FakeHttpClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'access_token': 'new-reg-token',
            'refresh_token': 'new-refresh-token',
            'user': {
              'id': 'user-created',
              'display_name': 'Chị Chín',
              'phone': '0911223344',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: client, baseUrl: 'http://test');
      final state = await service.register(
        identifier: '0911223344',
        password: 'pass123456',
        displayName: 'Chị Chín',
        phone: '0911223344',
      );

      expect(sentRequest.url.path, '/v1/auth/register');
      expect(state.status, AuthStatus.authenticated);
      expect(state.accessToken, 'new-reg-token');
      expect(state.displayName, 'Chị Chín');
    });

    test('refreshToken updates token on success', () async {
      SharedPreferences.setMockInitialValues({
        AuthService.keyAccessToken: 'old-access-token',
        AuthService.keyRefreshToken: 'old-refresh-token',
        AuthService.keyUserId: 'u1',
      });

      final client = _FakeHttpClient((request) async {
        expect(request.url.path, '/v1/auth/refresh');
        return http.Response(
          jsonEncode({
            'access_token': 'refreshed-access-token',
            'refresh_token': 'refreshed-refresh-token',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: client, baseUrl: 'http://test');
      await service.initialize();

      final newToken = await service.refreshToken();
      expect(newToken, 'refreshed-access-token');
      expect(service.currentAccessToken, 'refreshed-access-token');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AuthService.keyAccessToken), 'refreshed-access-token');
      expect(prefs.getString(AuthService.keyRefreshToken), 'refreshed-refresh-token');
    });

    test('refreshToken logs out when refresh request fails', () async {
      SharedPreferences.setMockInitialValues({
        AuthService.keyAccessToken: 'expired-access-token',
        AuthService.keyRefreshToken: 'invalid-refresh-token',
        AuthService.keyUserId: 'u1',
      });

      final client = _FakeHttpClient((request) async {
        return http.Response('{"error":"invalid_token"}', 401);
      });

      final service = AuthService(client: client, baseUrl: 'http://test');
      await service.initialize();

      final result = await service.refreshToken();
      expect(result, isNull);
      expect(service.state.status, AuthStatus.unauthenticated);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AuthService.keyAccessToken), isNull);
    });

    test('logout clears storage and resets state', () async {
      SharedPreferences.setMockInitialValues({
        AuthService.keyAccessToken: 'token',
        AuthService.keyRefreshToken: 'refresh',
        AuthService.keyUserId: 'u1',
        AuthService.keyDisplayName: 'Demo',
      });

      final service = AuthService(baseUrl: 'http://test');
      await service.initialize();
      expect(service.isAuthenticated, isTrue);

      await service.logout();

      expect(service.state.status, AuthStatus.unauthenticated);
      expect(service.isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AuthService.keyAccessToken), isNull);
      expect(prefs.getString(AuthService.keyUserId), isNull);
    });

    test('continueAsGuest sets guest mode in storage and state', () async {
      final service = AuthService(baseUrl: 'http://test');
      await service.continueAsGuest();

      expect(service.state.status, AuthStatus.guest);
      expect(service.isGuest, isTrue);
      expect(service.isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AuthService.keyIsGuest), isTrue);
    });
  });

  group('ApiClient with AuthService integration', () {
    test('attaches Bearer token from AuthService automatically', () async {
      SharedPreferences.setMockInitialValues({
        AuthService.keyAccessToken: 'auth-service-access-token',
        AuthService.keyRefreshToken: 'rt-1',
        AuthService.keyUserId: 'u123',
      });

      final authService = AuthService(baseUrl: 'http://test');
      await authService.initialize();

      late http.BaseRequest sentRequest;
      final fakeHttp = _FakeHttpClient((request) async {
        sentRequest = request;
        return http.Response('{"display_name": "Test User"}', 200);
      });

      final apiClient = ApiClient(
        client: fakeHttp,
        baseUrl: 'http://test',
        authService: authService,
      );

      final profile = await apiClient.getProfile();
      expect(profile.displayName, 'Test User');
      expect(sentRequest.headers['authorization'], 'Bearer auth-service-access-token');
      apiClient.dispose();
    });

    test('retries request once on 401 with refreshed token', () async {
      var requestCount = 0;
      var refreshCount = 0;

      final fakeHttp = _FakeHttpClient((request) async {
        if (request.url.path == '/v1/auth/refresh') {
          refreshCount++;
          return http.Response(
            jsonEncode({
              'access_token': 'new-retried-token',
              'refresh_token': 'new-rt',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/v1/me') {
          requestCount++;
          if (requestCount == 1) {
            // First call fails with 401
            return http.Response(
              jsonEncode({'error': {'message': 'UNAUTHENTICATED'}}),
              401,
              headers: {'content-type': 'application/json'},
            );
          } else {
            // Second call succeeds with new token
            expect(request.headers['authorization'], 'Bearer new-retried-token');
            return http.Response(
              jsonEncode({'display_name': 'Recovered User'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }

        return http.Response('Not Found', 404);
      });

      final authService = AuthService(
        client: fakeHttp,
        baseUrl: 'http://test',
        initialState: const AuthState.authenticated(
          accessToken: 'expired-token',
          refreshToken: 'valid-refresh-token',
          userId: 'u1',
        ),
      );

      final apiClient = ApiClient(
        client: fakeHttp,
        baseUrl: 'http://test',
        authService: authService,
      );

      final profile = await apiClient.getProfile();
      expect(profile.displayName, 'Recovered User');
      expect(requestCount, 2);
      expect(refreshCount, 1);
      expect(authService.currentAccessToken, 'new-retried-token');
      apiClient.dispose();
    });
  });
}
