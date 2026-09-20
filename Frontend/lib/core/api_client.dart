import 'dart:io';
import 'package:dio/dio.dart';

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

  static String _getBaseUrl() {
    // Android Emulator uses 10.0.2.2 to map back to host PC localhost
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    // iOS Simulator uses localhost
    else if (Platform.isIOS) {
      return 'http://127.0.0.1:5000/api';
    }
    // Desktop (Windows/macOS/Linux) or Web
    return 'http://localhost:5000/api';
  }
}