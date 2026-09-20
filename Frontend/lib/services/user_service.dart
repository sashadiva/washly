import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class UserService {
  Future<List<User>> getUsers() async {
    try {
      final response = await ApiClient.dio.get('/users');
      final data = response.data as List;
      return data.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load users: ${e.response?.data ?? e.message}');
    }
  }

  Future<User> createUser(String email, String? name) async {
    try {
      final response = await ApiClient.dio.post(
        '/users',
        data: {
          'email': email,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create user: ${e.response?.data ?? e.message}');
    }
  }
}