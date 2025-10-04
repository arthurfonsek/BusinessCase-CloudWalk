class Friend {
  final String id;
  final String username;
  final String name;
  final String email;
  final String? profileImage;
  final DateTime addedAt;
  final bool isReferred; // Se foi adicionado através de código de referência
  final String? referralCode; // Código de referência usado

  const Friend({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.profileImage,
    required this.addedAt,
    this.isReferred = false,
    this.referralCode,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'].toString(),
      username: json['friend_username'] ?? json['username'] ?? '',
      name: json['friend_name'] ?? json['name'] ?? json['friend_username'] ?? json['username'] ?? '',
      email: json['friend_email'] ?? json['email'] ?? '',
      profileImage: json['profile_image'],
      addedAt: DateTime.parse(json['created_at'] ?? json['added_at']),
      isReferred: json['is_referred'] ?? false,
      referralCode: json['referral_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'profile_image': profileImage,
      'added_at': addedAt.toIso8601String(),
      'is_referred': isReferred,
      'referral_code': referralCode,
    };
  }

  Friend copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? profileImage,
    DateTime? addedAt,
    bool? isReferred,
    String? referralCode,
  }) {
    return Friend(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      addedAt: addedAt ?? this.addedAt,
      isReferred: isReferred ?? this.isReferred,
      referralCode: referralCode ?? this.referralCode,
    );
  }
}
