enum AuthStatus {
  unauthenticated,
  authenticated,
  guest,
}

class AuthState {
  const AuthState({
    required this.status,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.displayName,
    this.phone,
  });

  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? displayName;
  final String? phone;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        accessToken = null,
        refreshToken = null,
        userId = null,
        displayName = null,
        phone = null;

  const AuthState.guest()
      : status = AuthStatus.guest,
        accessToken = null,
        refreshToken = null,
        userId = null,
        displayName = null,
        phone = null;

  const AuthState.authenticated({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.displayName,
    this.phone,
  }) : status = AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? displayName,
    String? phone,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          userId == other.userId &&
          displayName == other.displayName &&
          phone == other.phone;

  @override
  int get hashCode => Object.hash(
        status,
        accessToken,
        refreshToken,
        userId,
        displayName,
        phone,
      );

  @override
  String toString() =>
      'AuthState(status: $status, userId: $userId, displayName: $displayName, phone: $phone)';
}
