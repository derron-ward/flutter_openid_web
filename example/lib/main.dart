import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterWebAuth.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthState authState;
  StreamSubscription<AuthState>? authSubscription;

  @override
  void initState() {
    super.initState();
    authState = FlutterWebAuth.instance.currentState;

    authSubscription = FlutterWebAuth.instance.authStateChanges.listen((state) {
      setState(() => authState = state);
    });
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  void login() async {
    final uri = Uri.base;
    final redirect = '${uri.scheme}://${uri.host}:${uri.port}/';

    final request = await AuthRequest.fromDiscoveryUrl(
      discoveryUrl: 'https://demo.duendesoftware.com/.well-known/openid-configuration',
      clientId: 'interactive.public',
      redirectUri: redirect,
      scopes: [
        'openid',
        'profile',
        'email',
        'offline_access',
        'api'
      ]
    );
    FlutterWebAuth.instance.authenticateAndExchangeCode(request);
  }

  void logout() async {
    final idToken = authState.tokens?.idToken;
    if (idToken == null) return;

    final uri = Uri.base;
    final redirect = '${uri.scheme}://${uri.host}:${uri.port}/';

    final request = await EndSessionRequest.fromDiscoveryUrl(
      discoveryUrl: 'https://demo.duendesoftware.com/.well-known/openid-configuration',
      idToken: idToken,
      clientId: 'interactive.public',
      redirectUri: redirect,
    );
    FlutterWebAuth.instance.endSession(request);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Web Auth Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 36,
            children: [
              Text(
                'Authenticated: ${authState.isAuthenticated}',
                style: TextStyle(
                  fontSize: 28
                ),
              ),
              TextButton(
                onPressed: authState.isAuthenticated ? logout : login,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    authState.isAuthenticated ? 'Logout' : 'Login',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}