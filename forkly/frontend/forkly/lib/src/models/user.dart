class User {
  final String id;
  final String username;
  final String email;
  final String? name;
  final UserRole role;
  final String? referralCode;
  final String? referredBy;
  final DateTime createdAt;
  final bool isActive;
  final String? profileImage;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    required this.role,
    this.referralCode,
    this.referredBy,
    required this.createdAt,
    this.isActive = true,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: UserRole.fromString(json['role'] as String),
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      profileImage: json['profile_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'role': role.toString(),
      'referral_code': referralCode,
      'referred_by': referredBy,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'profile_image': profileImage,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    UserRole? role,
    String? referralCode,
    String? referredBy,
    DateTime? createdAt,
    bool? isActive,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

enum UserRole {
  user,
  restaurantOwner,
  admin,
  superAdmin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'restaurant_owner':
        return UserRole.restaurantOwner;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }

  @override
  String toString() {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.restaurantOwner:
        return 'restaurant_owner';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'superadmin';
    }
  }

  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;
  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isRestaurantOwner => this == UserRole.restaurantOwner;
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  AuthState clearError() {
    return copyWith(error: null);
  }
}

class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? name;
  final String? referralCode;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.name,
    this.referralCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'name': name,
      'referral_code': referralCode,
    };
  }
}

class PasswordResetRequest {
  final String email;

  const PasswordResetRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class PasswordResetConfirm {
  final String token;
  final String newPassword;

  const PasswordResetConfirm({
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'new_password': newPassword,
    };
  }
}
