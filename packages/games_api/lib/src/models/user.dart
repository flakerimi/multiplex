class User {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final int roleId;
  final String? roleName;
  final String? avatarUrl;
  final String? lastLogin;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.roleId,
    this.roleName,
    this.avatarUrl,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('[User.fromJson] Parsing user from JSON: $json');
    try {
      final user = User(
        id: json['id'] as int,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        roleId: json['role_id'] as int,
        roleName: json['role_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        lastLogin: json['last_login'] as String?,
      );
      print('[User.fromJson] User parsed successfully: ${user.email}');
      return user;
    } catch (e, stackTrace) {
      print('[User.fromJson] ERROR parsing user: $e');
      print('[User.fromJson] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'role_id': roleId,
      'role_name': roleName,
      'avatar_url': avatarUrl,
      'last_login': lastLogin,
    };
  }

  String get fullName => '$firstName $lastName';
}
