/// Sent to POST /auth/login
class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Sent to POST /auth/register
class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
  });
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  /// Either "TRAVELER" or "HOST"
  final String role;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
  };
}

/// Access + refresh tokens returned by login / register / refresh
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
    accessToken:  json['accessToken']  as String,
    refreshToken: json['refreshToken'] as String,
  );

  final String accessToken;
  final String refreshToken;
}

/// Represents the currently logged-in user (from GET /users/me)
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:        json['id']        as String,
    email:     json['email']     as String,
    firstName: json['firstName'] as String,
    lastName:  json['lastName']  as String,
    role:      json['role']      as String,
  );

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  bool get isHost => role == 'HOST';

  String get fullName => '$firstName $lastName';
}
