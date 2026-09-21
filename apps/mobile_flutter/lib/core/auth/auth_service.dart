import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_logger.dart';
import '../config/app_config.dart';
import 'auth_state.dart';

class AuthService extends ChangeNotifier {
  AuthService({
    http.Client? client,
    String? baseUrl,
    SharedPreferences? prefs,
    AuthState? initialState,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceFirst(
          RegExp(r'/$'),
          '',
        ),
        _state = initialState ?? const AuthState.unauthenticated() {
    _prefs = prefs;
  }

  final http.Client _client;
  final String _baseUrl;
  SharedPreferences? _prefs;
  AuthState _state;

  static const String keyAccessToken = 'agrian_auth_access_token';
  static const String keyRefreshToken = 'agrian_auth_refresh_token';
  static const String keyUserId = 'agrian_auth_user_id';
  static const String keyDisplayName = 'agrian_auth_display_name';
  static const String keyPhone = 'agrian_auth_phone';
  static const String keyIsGuest = 'agrian_auth_is_guest';

  AuthState get state => _state;
  String? get currentAccessToken => _state.accessToken;
  String? get currentRefreshToken => _state.refreshToken;
  String? get currentUserId => _state.userId;
  String? get currentDisplayName => _state.displayName;
  String? get currentPhone => _state.phone;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isGuest => _state.isGuest;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> initialize() async {
    final prefs = await _getPrefs();
    final isGuest = prefs.getBool(keyIsGuest) ?? false;
    if (isGuest) {
      _state = const AuthState.guest();
      notifyListeners();
      return;
    }

    final accessToken = prefs.getString(keyAccessToken);
    final userId = prefs.getString(keyUserId);

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty) {
      final refreshToken = prefs.getString(keyRefreshToken) ?? '';
      final displayName = prefs.getString(keyDisplayName);
      final phone = prefs.getString(keyPhone);

      _state = AuthState.authenticated(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        displayName: displayName,
        phone: phone,
      );
    } else {
      _state = const AuthState.unauthenticated();
    }
    notifyListeners();
  }

  Future<AuthState> login({
    required String identifier,
    required String password,
  }) async {
    final trimmedIdentifier = identifier.trim();
    final uri = Uri.parse('$_baseUrl/v1/auth/login');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'identifier': trimmedIdentifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      AppLogger.event('auth.login.network_error', fields: {'error': '$e'});
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.');
    }

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final String? rawAccessToken = (body['access_token'] ??
          body['accessToken'] ??
          body['token'])?.toString();
      final String refreshToken = (body['refresh_token'] ??
          body['refreshToken'] ??
          '')
          .toString();

      if (rawAccessToken == null || rawAccessToken.isEmpty) {
        throw Exception('Phản hồi đăng nhập không hợp lệ từ máy chủ.');
      }
      final String accessToken = rawAccessToken;

      final userObj = body['user'] is Map<String, dynamic>
          ? body['user'] as Map<String, dynamic>
          : body;

      final String userId = (userObj['id'] ??
          userObj['user_id'] ??
          trimmedIdentifier)
          .toString();
      final String? displayName = (userObj['display_name'] ??
          userObj['displayName'] ??
          userObj['name'])
          ?.toString();
      final String? phone = (userObj['phone'] ??
          (trimmedIdentifier.startsWith('0') || trimmedIdentifier.startsWith('+')
              ? trimmedIdentifier
              : null))
          ?.toString();

      final prefs = await _getPrefs();
      await prefs.setString(keyAccessToken, accessToken);
      await prefs.setString(keyRefreshToken, refreshToken);
      await prefs.setString(keyUserId, userId);
      if (displayName != null) {
        await prefs.setString(keyDisplayName, displayName);
      } else {
        await prefs.remove(keyDisplayName);
      }
      if (phone != null) {
        await prefs.setString(keyPhone, phone);
      } else {
        await prefs.remove(keyPhone);
      }
      await prefs.remove(keyIsGuest);

      _state = AuthState.authenticated(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        displayName: displayName,
        phone: phone,
      );
      notifyListeners();
      return _state;
    }

    final errorMsg = _extractErrorMessage(
      body,
      fallback: 'Đăng nhập không thành công. Vui lòng kiểm tra lại tài khoản hoặc mật khẩu.',
    );
    throw Exception(errorMsg);
  }

  Future<AuthState> register({
    required String identifier,
    required String password,
    String? displayName,
    String? phone,
  }) async {
    final trimmedIdentifier = identifier.trim();
    final trimmedDisplayName = displayName?.trim();
    final trimmedPhone = phone?.trim();

    final payload = <String, dynamic>{
      'identifier': trimmedIdentifier,
      'password': password,
      if (trimmedDisplayName != null && trimmedDisplayName.isNotEmpty)
        'display_name': trimmedDisplayName,
      if (trimmedPhone != null && trimmedPhone.isNotEmpty)
        'phone': trimmedPhone,
    };

    final uri = Uri.parse('$_baseUrl/v1/auth/register');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      AppLogger.event('auth.register.network_error', fields: {'error': '$e'});
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.');
    }

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final String? rawAccessToken = (body['access_token'] ??
          body['accessToken'] ??
          body['token'])?.toString();

      if (rawAccessToken != null && rawAccessToken.isNotEmpty) {
        final String accessToken = rawAccessToken;
        final String refreshToken = (body['refresh_token'] ??
            body['refreshToken'] ??
            '')
            .toString();
        final userObj = body['user'] is Map<String, dynamic>
            ? body['user'] as Map<String, dynamic>
            : body;

        final String userId = (userObj['id'] ??
            userObj['user_id'] ??
            trimmedIdentifier)
            .toString();
        final String? resDisplayName = (userObj['display_name'] ??
            userObj['displayName'] ??
            trimmedDisplayName)
            ?.toString();
        final String? resPhone = (userObj['phone'] ?? trimmedPhone)?.toString();

        final prefs = await _getPrefs();
        await prefs.setString(keyAccessToken, accessToken);
        await prefs.setString(keyRefreshToken, refreshToken);
        await prefs.setString(keyUserId, userId);
        if (resDisplayName != null) {
          await prefs.setString(keyDisplayName, resDisplayName);
        }
        if (resPhone != null) {
          await prefs.setString(keyPhone, resPhone);
        }
        await prefs.remove(keyIsGuest);

        _state = AuthState.authenticated(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: userId,
          displayName: resDisplayName,
          phone: resPhone,
        );
        notifyListeners();
        return _state;
      }

      // If register endpoint does not return tokens directly, perform login automatically
      return login(identifier: trimmedIdentifier, password: password);
    }

    final errorMsg = _extractErrorMessage(
      body,
      fallback: 'Đăng ký tài khoản không thành công. Vui lòng thử lại.',
    );
    throw Exception(errorMsg);
  }

  Future<String?> refreshToken() async {
    final token = _state.refreshToken ??
        (await _getPrefs()).getString(keyRefreshToken);

    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    final uri = Uri.parse('$_baseUrl/v1/auth/refresh');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh_token': token}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body) as Map<String, dynamic>;

        final newAccessToken = (body['access_token'] ??
            body['accessToken'] ??
            body['token']) as String?;
        final newRefreshToken = (body['refresh_token'] ??
            body['refreshToken'] ??
            token) as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          final prefs = await _getPrefs();
          await prefs.setString(keyAccessToken, newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await prefs.setString(keyRefreshToken, newRefreshToken);
          }

          _state = _state.copyWith(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          notifyListeners();
          return newAccessToken;
        }
      }
    } catch (e) {
      AppLogger.event('auth.refresh.error', fields: {'error': '$e'});
    }

    await logout();
    return null;
  }

  Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyAccessToken);
    await prefs.remove(keyRefreshToken);
    await prefs.remove(keyUserId);
    await prefs.remove(keyDisplayName);
    await prefs.remove(keyPhone);
    await prefs.remove(keyIsGuest);

    _state = const AuthState.unauthenticated();
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyAccessToken);
    await prefs.remove(keyRefreshToken);
    await prefs.remove(keyUserId);
    await prefs.remove(keyDisplayName);
    await prefs.remove(keyPhone);
    await prefs.setBool(keyIsGuest, true);

    _state = const AuthState.guest();
    notifyListeners();
  }

  Future<void> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    final prefs = await _getPrefs();
    await prefs.setString(keyDisplayName, trimmed);

    if (_state.isAuthenticated) {
      _state = _state.copyWith(displayName: trimmed);
      notifyListeners();
    }
  }

  String _extractErrorMessage(Map<String, dynamic> body, {required String fallback}) {
    if (body['error'] is Map<String, dynamic>) {
      final err = body['error'] as Map<String, dynamic>;
      if (err['message'] is String && (err['message'] as String).isNotEmpty) {
        return err['message'] as String;
      }
    }
    if (body['message'] is String && (body['message'] as String).isNotEmpty) {
      return body['message'] as String;
    }
    if (body['detail'] is String && (body['detail'] as String).isNotEmpty) {
      return body['detail'] as String;
    }
    return fallback;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
