class TokenResponse {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime expiresAt;
  final List<String> scopes;

  const TokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    required this.expiresAt,
    this.scopes = const []
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int? ?? 300;
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      idToken: json['id_token'] as String?,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      scopes: (json['scope'] as String? ?? '').split(' ')
    );
  }
}