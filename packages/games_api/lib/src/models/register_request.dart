class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String username;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
    };
  }
}
