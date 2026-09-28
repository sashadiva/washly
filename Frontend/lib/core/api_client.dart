import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'auth_store.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Global navigator key so the interceptor can route to login on 401
  // without needing a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static AuthStore? _authStore;

  /// Wire the interceptor to the app's AuthStore. Call once at startup after
  /// creating the AuthStore instance.
  static void attachAuth(AuthStore store) {
    _authStore = store;

    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authStore?.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Session is no longer valid: clear it and return to login.
            await _authStore?.clear();
            final nav = navigatorKey.currentState;
            if (nav != null) {
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static String _getBaseUrl() {
    // On web, dart:io's Platform is unavailable (it throws
    // "Unsupported operation: Platform._operatingSystem"), so check kIsWeb
    // first. The browser reaches the backend directly on localhost.
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    // Android emulator maps host localhost to 10.0.2.2.
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    // iOS simulator uses localhost.
    else if (Platform.isIOS) {
      return 'http://127.0.0.1:5000/api';
    }
    // Desktop (Windows/macOS/Linux).
    return 'http://localhost:5000/api';
  }
}
