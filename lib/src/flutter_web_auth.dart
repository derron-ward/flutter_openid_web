import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'helpers/helpers.dart';
import 'models/models.dart';

enum SessionStorageNames {
  codeVerifier('flutter_web_auth_code_verifier'),
  state('flutter_web_auth_oidc_state'),
  authRequest('flutter_web_auth_auth_request'),
  endSessionRequest('flutter_web_auth_end_session_request');

  final String key;
  const SessionStorageNames(this.key);
}

class FlutterWebAuth {
  static FlutterWebAuth? _instance;
  static FlutterWebAuth get instance {
    assert(_instance != null, 'FlutterWebAuth.initialize() must be called first.');
    return _instance!;
  }

  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  AuthState _currentState = AuthState.unauthenticated();
  AuthState get currentState => _currentState;

  FlutterWebAuth();

  /// Initializes `FlutterWebAuth` with the given configuration
  /// 
  /// Trys to handle an OIDC redirect if present
  static Future<void> initialize() async {
    final client = FlutterWebAuth();
    _instance = client;

    await client._boot();
  }

  Future<void> _boot() async {
    if (kIsWeb) {
      await _tryHandleRedirect();
    }
  }

  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<void> authenticateAndExchangeCode(AuthRequest request) async {
    final codeVerifier = _generateRandomString(128);
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateRandomString(32);

    WebUtils.setSessionValue(SessionStorageNames.codeVerifier.key, codeVerifier);
    WebUtils.setSessionValue(SessionStorageNames.state.key, state);
    WebUtils.setSessionValue(
      SessionStorageNames.authRequest.key,
      jsonEncode(request.toJson())
    );

    final authUri = Uri.parse(request.serviceConfiguration.authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': request.clientId,
        'redirect_uri': request.redirectUri,
        'scope': request.scopes.join(' '),
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256'
      }
    );

    WebUtils.redirect(authUri.toString());
  }

  Future<TokenResponse> refreshTokens(RefreshTokenRequest request) async {
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    final body = {
      'grant_type': 'refresh_token',
      'client_id': request.clientId,
      'refresh_token': request.refreshToken
    };

    try {
      final dio = Dio();
      final response = await dio.post(
        request.serviceConfiguration.tokenEndpoint,
        options: Options(
          headers: headers
        ),
        data: body
      );

      final tokenResponse = TokenResponse.fromJson(response.data);
      return tokenResponse;
    }
    catch (err) {
      rethrow;
    }
  }

  Future<void> endSession(EndSessionRequest request) async {
    assert(
      request.serviceConfiguration.endSessionEndpoint != null,
      'No End Session endpoint provided'
    );

    WebUtils.setSessionValue(
      SessionStorageNames.endSessionRequest.key, 
      jsonEncode(request.toJson())
    );

    final state = _generateRandomString(32);
    WebUtils.setSessionValue(SessionStorageNames.state.key, state);

    final endSessionUri = Uri.parse(request.serviceConfiguration.endSessionEndpoint!).replace(
      queryParameters: {
        'id_token_hint': request.idToken,
        'client_id': request.clientId,
        'post_logout_redirect_uri': request.postLogoutRedirectUri,
        'state': state
      },
    );

    WebUtils.redirect(endSessionUri.toString());
  }

  Future<bool> _tryHandleRedirect() async {
    final uri = WebUtils.currentUrl;

    // Handle post logout
    if (WebUtils.getSessionValue(SessionStorageNames.endSessionRequest.key) != null 
        && !uri.queryParameters.containsKey('code')) {

      // Validate state if provider returned it
      final returnedState = uri.queryParameters['state'];
      final storedState = WebUtils.getSessionValue(SessionStorageNames.state.key);

      if (returnedState != null && storedState != returnedState) {
        _emit(AuthState.error('Logout state mismatch'));
        WebUtils.removeSessionValue(SessionStorageNames.endSessionRequest.key);
        WebUtils.removeSessionValue(SessionStorageNames.state.key);
        return true;
      }

      WebUtils.replaceUrlState(WebUtils.currentPath);
      WebUtils.removeSessionValue(SessionStorageNames.endSessionRequest.key);
      WebUtils.removeSessionValue(SessionStorageNames.state.key);
      _emit(AuthState.unauthenticated());
      return true;
    }

    // No redirect if there is no "code" query param
    if (!uri.queryParameters.containsKey('code')) return false;

    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];

    // Grab request data from session storage
    final requestJsonString = WebUtils.getSessionValue(SessionStorageNames.authRequest.key);
    if (requestJsonString == null) {
      _emit(AuthState.error('No auth request found'));
      WebUtils.removeSessionValue(SessionStorageNames.authRequest.key);
      return true;
    }
    final request = AuthRequest.fromJson(jsonDecode(requestJsonString));

    // Clean the URL
    WebUtils.replaceUrlState(WebUtils.currentPath);

    if (error != null) {
      final description = uri.queryParameters['error_description'] ?? error;
      _emit(AuthState.error(description));
      WebUtils.removeSessionValue(SessionStorageNames.authRequest.key);
      return true;
    }

    // Validate state parameter
    final storedState = WebUtils.getSessionValue(SessionStorageNames.state.key);
    if (storedState == null || storedState != state) {
      _emit(AuthState.error('OIDC State mismatch'));
      WebUtils.removeSessionValue(SessionStorageNames.authRequest.key);
      return true;
    }

    final codeVerifier = WebUtils.getSessionValue(SessionStorageNames.codeVerifier.key);
    if (codeVerifier == null) {
      _emit(AuthState.error('Missing code verifier'));
      WebUtils.removeSessionValue(SessionStorageNames.authRequest.key);
      return true;
    }

    // Clean session storage
    WebUtils.removeSessionValue(SessionStorageNames.codeVerifier.key);
    WebUtils.removeSessionValue(SessionStorageNames.state.key);

    try {
      final tokens = await _exchangeCodeForTokens(code: code!, codeVerifier: codeVerifier, request: request);
      _emit(AuthState.authenticated(tokens));
    }
    catch (err) {
      _emit(AuthState.error('Token exchange failed: $err'));
    }

    return true;
  }

  Future<TokenResponse> _exchangeCodeForTokens({
    required String code,
    required String codeVerifier,
    required AuthRequest request
  }) async {
    final dio = Dio();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    final body = {
      'grant_type': 'authorization_code',
      'client_id': request.clientId,
      'code': code,
      'redirect_uri': request.redirectUri,
      'code_verifier': codeVerifier
    };

    try {
      final response = await dio.post(
        request.serviceConfiguration.tokenEndpoint,
        options: Options(
          headers: headers
        ),
        data: body
      );

      final tokenResponse = TokenResponse.fromJson(response.data);
      return tokenResponse;
    }
    catch (err) {
      rethrow;
    }
  }

  void _emit(AuthState state) {
    _currentState = state;
    _authStateController.add(state);
  }
}