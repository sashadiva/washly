import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';

/// Result of a successful register/login: the JWT and the authenticated user.
class AuthResult {
  final String token;
  final User user;
  AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Thin wrapper that turns Dio errors into readable messages using the
/// backend's `{ error: string }` shape.
String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class AuthService {
  Future<AuthResult> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _register({
      'role': 'CUSTOMER',
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }

  Future<AuthResult> registerPartner({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String businessName,
    required String businessAddress,
    required double latitude,
    required double longitude,
    required String pricingModel, // 'PER_KG' or 'PER_ITEM'
    required List<String> specialties,
  }) async {
    return _register({
      'role': 'PARTNER',
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'latitude': latitude,
      'longitude': longitude,
      'pricingModel': pricingModel,
      'specialties': specialties,
    });
  }

  Future<AuthResult> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String plateNumber,
  }) async {
    return _register({
      'role': 'DRIVER',
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
    });
  }

  Future<AuthResult> _register(Map<String, dynamic> body) async {
    try {
      final response = await ApiClient.dio.post('/auth/register', data: body);
      return AuthResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Registration failed.'));
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Login failed.'));
    }
  }

  Future<User> me() async {
    try {
      final response = await ApiClient.dio.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load account.'));
    }
  }

  Future<User> updateProfile({String? name, String? phone}) async {
    try {
      final response = await ApiClient.dio.put(
        '/account/profile',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to update profile.'));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await ApiClient.dio.put(
        '/account/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to change password.'));
    }
  }
}
