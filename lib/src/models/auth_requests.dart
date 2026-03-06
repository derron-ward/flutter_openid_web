import 'package:dio/dio.dart';

class AuthServiceConfiguration {
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String? endSessionEndpoint;

  const AuthServiceConfiguration({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.endSessionEndpoint
  });
}

class AuthRequest {
  final String issuer;
  final String clientId;
  final String redirectUri;
  final List<String> scopes;
  final AuthServiceConfiguration serviceConfiguration;

  AuthRequest({
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    this.scopes = const [],
    required this.serviceConfiguration,
  });

  static Future<AuthRequest> fromDiscoveryUrl({
    required String discoveryUrl,
    required String clientId,
    required String redirectUri,
    List<String> scopes = const []
  }) async {
    final dio = Dio();
    final response = await dio.get(discoveryUrl);
    final json = response.data as Map<String, dynamic>;

    return AuthRequest(
      issuer: json['issuer'] as String,
      clientId: clientId,
      redirectUri: redirectUri,
      scopes: scopes,
      serviceConfiguration: AuthServiceConfiguration(
        authorizationEndpoint: json['authorization_endpoint'] as String,
        tokenEndpoint: json['token_endpoint'] as String,
        endSessionEndpoint: json['end_session_endpoint'] as String?
      )
    );
  }

  factory AuthRequest.fromJson(Map<String, dynamic> json) {
    return AuthRequest(
      issuer: json['issuer'] as String,
      clientId: json['clientId'] as String,
      redirectUri: json['redirectUri'] as String,
      scopes: (json['scopes'] as String).split(' '),
      serviceConfiguration: AuthServiceConfiguration(
        authorizationEndpoint: json['authorizationEndpoint'] as String,
        tokenEndpoint: json['tokenEndpoint'] as String,
        endSessionEndpoint: json['endSessionEndpoint'] as String?
      )
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issuer': issuer,
      'clientId': clientId,
      'redirectUri': redirectUri,
      'scopes': scopes.join(' '),
      'authorizationEndpoint': serviceConfiguration.authorizationEndpoint,
      'tokenEndpoint': serviceConfiguration.tokenEndpoint,
      'endSessionEndpoint': serviceConfiguration.endSessionEndpoint
    };
  }
}

class EndSessionRequest {
  final String idToken;
  final String issuer;
  final String clientId;
  final String postLogoutRedirectUri;
  final AuthServiceConfiguration serviceConfiguration;

  EndSessionRequest({
    required this.idToken,
    required this.issuer,
    required this.clientId,
    required this.postLogoutRedirectUri,
    required this.serviceConfiguration,
  });

  static Future<EndSessionRequest> fromDiscoveryUrl({
    required String discoveryUrl,
    required String idToken,
    required String clientId,
    required String redirectUri,
  }) async {
    final dio = Dio();
    final response = await dio.get(discoveryUrl);
    final json = response.data as Map<String, dynamic>;

    return EndSessionRequest(
      idToken: idToken,
      issuer: json['issuer'] as String,
      clientId: clientId,
      postLogoutRedirectUri: redirectUri,
      serviceConfiguration: AuthServiceConfiguration(
        authorizationEndpoint: json['authorization_endpoint'] as String,
        tokenEndpoint: json['token_endpoint'] as String,
        endSessionEndpoint: json['end_session_endpoint'] as String?
      )
    );
  }

  factory EndSessionRequest.fromJson(Map<String, dynamic> json) {
    return EndSessionRequest(
      idToken: json['idToken'] as String,
      issuer: json['issuer'] as String,
      clientId: json['clientId'] as String,
      postLogoutRedirectUri: json['postLogoutRedirectUri'] as String,
      serviceConfiguration: AuthServiceConfiguration(
        authorizationEndpoint: json['authorizationEndpoint'] as String,
        tokenEndpoint: json['tokenEndpoint'] as String,
        endSessionEndpoint: json['endSessionEndpoint'] as String?
      )
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'issuer': issuer,
      'clientId': clientId,
      'postLogoutRedirectUri': postLogoutRedirectUri,
      'authorizationEndpoint': serviceConfiguration.authorizationEndpoint,
      'tokenEndpoint': serviceConfiguration.tokenEndpoint,
      'endSessionEndpoint': serviceConfiguration.endSessionEndpoint
    };
  }
}

class RefreshTokenRequest {
  final String idToken;
  final String clientId;
  final String refreshToken;
  final AuthServiceConfiguration serviceConfiguration;

  RefreshTokenRequest({
    required this.idToken,
    required this.clientId,
    required this.refreshToken,
    required this.serviceConfiguration,
  });

  static Future<RefreshTokenRequest> fromDiscoveryUrl({
    required String discoveryUrl,
    required String idToken,
    required String clientId,
    required String refreshToken
  }) async {
    final dio = Dio();
    final response = await dio.get(discoveryUrl);
    final json = response.data as Map<String, dynamic>;

    return RefreshTokenRequest(
      idToken: idToken,
      clientId: clientId,
      refreshToken: refreshToken,
      serviceConfiguration: AuthServiceConfiguration(
        authorizationEndpoint: json['authorization_endpoint'] as String,
        tokenEndpoint: json['token_endpoint'] as String,
        endSessionEndpoint: json['end_session_endpoint'] as String?
      )
    );
  }
}