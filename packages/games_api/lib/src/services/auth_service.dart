import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user.dart';

class AuthService {
  final String baseUrl;
  final String apiKey;
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'games_api_token';
  static const String _userKey = 'games_api_user';

  AuthService({
    required this.baseUrl,
    required this.apiKey,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  /// Get headers with API key and optional bearer token
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Register a new user
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      // Save token and user
      await _saveAuthData(authResponse);

      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Registration failed');
    }
  }

  /// Login user
  Future<AuthResponse> login(LoginRequest request) async {
    print('[AuthService] Login request starting...');
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    print('[AuthService] Login response status: ${response.statusCode}');
    print('[AuthService] Login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('[AuthService] Decoded JSON: $data');

      final authResponse = AuthResponse.fromJson(data);
      print('[AuthService] AuthResponse created - token: ${authResponse.token.substring(0, 20)}...');
      print('[AuthService] User: ${authResponse.user.email}');

      // Save token and user
      await _saveAuthData(authResponse);
      print('[AuthService] Auth data saved');

      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: _getHeaders(token: token),
        );
      }
    } catch (e) {
      // Ignore logout errors, clear local data anyway
    }

    await clearAuthData();
  }

  /// Save authentication data
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _storage.write(key: _tokenKey, value: authResponse.token);
    await _storage.write(key: _userKey, value: jsonEncode(authResponse.user.toJson()));
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Get stored user
  Future<User?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  /// Clear authentication data
  Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Get authorization headers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    return _getHeaders(token: token);
  }
}
