import 'token_response.dart';

enum AuthStatus { unauthenticated, authenticated, error }

class AuthState {
  final AuthStatus status;
  final TokenResponse? tokens;
  final String? errorMessage;

  const AuthState._({
    required this.status,
    this.tokens,
    this.errorMessage
  });

  factory AuthState.unauthenticated() =>
    AuthState._(status: AuthStatus.unauthenticated);
  
  factory AuthState.authenticated(TokenResponse tokens) =>
    AuthState._(status: AuthStatus.authenticated, tokens: tokens);

  factory AuthState.error(String message) =>
    AuthState._(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}