# Flutter OpenId Web

A Flutter package for web-based OpenID Connect (OIDC) authentication using the Authorization Code Flow with PKCE. Built for Flutter Web, it handles the full auth lifecycle — redirects, token exchange, token refresh, and session termination.

---

## Features

- Authorization Code Flow with **PKCE** (S256)
- Automatic redirect handling on page load
- **State parameter** validation to prevent CSRF attacks
- Token refresh via refresh token
- End session / logout with post-logout redirect
- Broadcast stream for reactive auth state changes

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_openid_web: ^1.0.0
```

Then run:

```sh
flutter pub get
```

---

## Getting Started

### 1. Initialize

Call `FlutterOpenidWeb.initialize()` once at app startup, **before** `runApp()`. This sets up the singleton and automatically handles any OIDC redirect that may be present in the URL.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterOpenidWeb.initialize();
  runApp(const MyApp());
}
```

### 2. Access the Instance

After initialization, access the singleton anywhere in your app:

```dart
final auth = FlutterOpenidWeb.instance;
```

---

## Usage

### Listen to Auth State Changes

Subscribe to the `authStateChanges` stream to reactively respond to login, logout, and error events:

```dart
FlutterOpenidWeb.instance.authStateChanges.listen((state) {
  if (state.isAuthenticated) {
    print('Authenticated: ${state.tokens}');
  } else if (state.isError) {
    print('Auth error: ${state.error}');
  } else {
    print('Unauthenticated');
  }
});
```

You can also read the current state synchronously:

```dart
final currentState = FlutterOpenidWeb.instance.currentState;
```

### Sign In

Build an `AuthRequest` with your OIDC provider's configuration and call `authenticateAndExchangeCode`. This redirects the user to the provider's login page. When they return, the redirect is handled automatically during `initialize()`.

```dart
final request = AuthRequest(
  clientId: 'your-client-id',
  redirectUri: 'https://your-app.com/callback',
  scopes: ['openid', 'profile', 'email'],
  serviceConfiguration: ServiceConfiguration(
    authorizationEndpoint: 'https://your-provider.com/oauth2/authorize',
    tokenEndpoint: 'https://your-provider.com/oauth2/token',
  ),
);

await FlutterOpenidWeb.instance.authenticateAndExchangeCode(request);
// User is redirected to the provider — no code needed after this line.
```

### Refresh Tokens

Use `refreshTokens` to silently obtain new tokens using a stored refresh token:

```dart
final refreshed = await FlutterOpenidWeb.instance.refreshTokens(
  RefreshTokenRequest(
    clientId: 'your-client-id',
    refreshToken: storedRefreshToken,
    serviceConfiguration: ServiceConfiguration(
      authorizationEndpoint: 'https://your-provider.com/oauth2/authorize',
      tokenEndpoint: 'https://your-provider.com/oauth2/token',
    ),
  ),
);

print('New access token: ${refreshed.accessToken}');
```

### Sign Out

Call `endSession` to redirect the user to the provider's end session endpoint. The auth state is automatically set to `unauthenticated` when the user returns.

```dart
await FlutterOpenidWeb.instance.endSession(
  EndSessionRequest(
    clientId: 'your-client-id',
    idToken: storedIdToken,
    postLogoutRedirectUri: 'https://your-app.com/',
    serviceConfiguration: ServiceConfiguration(
      authorizationEndpoint: 'https://your-provider.com/oauth2/authorize',
      tokenEndpoint: 'https://your-provider.com/oauth2/token',
      endSessionEndpoint: 'https://your-provider.com/oauth2/logout',
    ),
  ),
);
```

### Persisting Auth State
By default, Auth state is persisted across sessions using local storage. If you do not want the package to persist automatically, initialize the instance with the `persistState` config value set to `false`
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterOpenidWeb.initialize(FlutterOpenidWebConfig(
    persistState: false
  ));

  runApp(MyApp());
}
```

---

## Auth State

The `AuthState` emitted on the stream has three possible states:

| State | Description |
|---|---|
| `AuthState.authenticated(tokens)` | The user has successfully signed in |
| `AuthState.unauthenticated()` | No active session |
| `AuthState.error(message)` | An error occurred during auth or logout |

---

## Models

### `ServiceConfiguration`

| Field | Type | Required | Description |
|---|---|---|---|
| `authorizationEndpoint` | `String` | ✅ | Provider's authorization URL |
| `tokenEndpoint` | `String` | ✅ | Provider's token exchange URL |
| `endSessionEndpoint` | `String?` | ❌ | Provider's logout URL (required for `endSession`) |

### `AuthRequest`

| Field | Type | Description |
|---|---|---|
| `clientId` | `String` | Your app's OAuth client ID |
| `redirectUri` | `String` | The URI to return to after login |
| `scopes` | `List<String>` | OAuth scopes to request |
| `serviceConfiguration` | `ServiceConfiguration` | OIDC provider endpoints |

### `RefreshTokenRequest`

| Field | Type | Description |
|---|---|---|
| `clientId` | `String` | Your app's OAuth client ID |
| `refreshToken` | `String` | The refresh token from a previous `TokenResponse` |
| `serviceConfiguration` | `ServiceConfiguration` | OIDC provider endpoints |

### `EndSessionRequest`

| Field | Type | Description |
|---|---|---|
| `clientId` | `String` | Your app's OAuth client ID |
| `idToken` | `String` | The ID token from the current session |
| `postLogoutRedirectUri` | `String` | The URI to return to after logout |
| `serviceConfiguration` | `ServiceConfiguration` | OIDC provider endpoints (must include `endSessionEndpoint`) |

---

## Platform Support

| Platform | Supported |
|---|---|
| Web | ✅ |
| Android | ❌ |
| iOS | ❌ |
| macOS | ❌ |
| Windows | ❌ |
| Linux | ❌ |

This package is designed exclusively for **Flutter Web**. Redirect-based OIDC flows require browser session storage and URL manipulation, which are web-only capabilities.

---

## Security

- PKCE is enforced using the **S256** code challenge method — plain PKCE is not supported.
- The `state` parameter is validated on every redirect to protect against CSRF.
- Code verifiers and state values are stored in **session storage**, which is scoped to the browser tab and cleared when the tab is closed.

---

## Dependencies

- [`crypto`](https://pub.dev/packages/crypto) — SHA-256 for PKCE code challenge generation
- [`dio`](https://pub.dev/packages/dio) — HTTP client for token requests