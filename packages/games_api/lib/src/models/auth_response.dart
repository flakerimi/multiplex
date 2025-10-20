import 'user.dart';

class AuthResponse {
  final String token;
  final User user;
  final Map<String, dynamic>? extend;

  AuthResponse({
    required this.token,
    required this.user,
    this.extend,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    print('[AuthResponse.fromJson] Parsing auth response from JSON');
    print('[AuthResponse.fromJson] JSON keys: ${json.keys}');

    try {
      // Base Framework returns a flat structure with user data at top level
      // and the token as "accessToken"
      final token = json['accessToken'] as String;
      print('[AuthResponse.fromJson] Token found: ${token.substring(0, 20)}...');

      // Create user from the top-level fields
      final user = User.fromJson(json);
      print('[AuthResponse.fromJson] User parsed: ${user.email}');

      final authResponse = AuthResponse(
        token: token,
        user: user,
        extend: json['extend'] as Map<String, dynamic>?,
      );
      print('[AuthResponse.fromJson] Auth response parsed successfully');
      return authResponse;
    } catch (e, stackTrace) {
      print('[AuthResponse.fromJson] ERROR: $e');
      print('[AuthResponse.fromJson] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'extend': extend,
    };
  }

  int? get achievementCount {
    return extend?['achievement_count'] as int?;
  }

  Map<String, dynamic>? get role {
    return extend?['role'] as Map<String, dynamic>?;
  }
}
