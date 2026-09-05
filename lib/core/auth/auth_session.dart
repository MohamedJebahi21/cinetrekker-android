class CineTrekkerAuthUser {
  const CineTrekkerAuthUser({
    required this.id,
    this.email,
    this.phone,
    this.appMetadata = const <String, dynamic>{},
    this.userMetadata = const <String, dynamic>{},
    this.createdAt,
    this.lastSignInAt,
  });

  final String id;
  final String? email;
  final String? phone;
  final Map<String, dynamic> appMetadata;
  final Map<String, dynamic> userMetadata;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  factory CineTrekkerAuthUser.fromJson(Map<String, dynamic> json) {
    return CineTrekkerAuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      appMetadata:
          (json['app_metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      userMetadata:
          (json['user_metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      lastSignInAt: json['last_sign_in_at'] == null
          ? null
          : DateTime.tryParse(json['last_sign_in_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'phone': phone,
      'app_metadata': appMetadata,
      'user_metadata': userMetadata,
      'created_at': createdAt?.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
    };
  }

  String get displayName {
    final metadataName = userMetadata['full_name'] ?? userMetadata['name'];
    if (metadataName is String && metadataName.trim().isNotEmpty) {
      return metadataName.trim();
    }

    if (email != null && email!.contains('@')) {
      return email!.split('@').first;
    }

    return 'CineTrekker user';
  }

  String? get avatarUrl {
    final value = userMetadata['avatar_url'] ?? userMetadata['picture'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is CineTrekkerAuthUser &&
        other.id == id &&
        other.email == email &&
        other.phone == phone &&
        _mapEquals(other.appMetadata, appMetadata) &&
        _mapEquals(other.userMetadata, userMetadata) &&
        other.createdAt == createdAt &&
        other.lastSignInAt == lastSignInAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    phone,
    _mapHash(appMetadata),
    _mapHash(userMetadata),
    createdAt,
    lastSignInAt,
  );

  @override
  String toString() {
    return 'CineTrekkerAuthUser(id: $id, email: $email, phone: $phone)';
  }
}

class CineTrekkerAuthSession {
  const CineTrekkerAuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    required this.expiresIn,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final int expiresAt;
  final CineTrekkerAuthUser user;

  factory CineTrekkerAuthSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Missing auth user payload.');
    }

    return CineTrekkerAuthSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      expiresAt:
          (json['expires_at'] as num?)?.toInt() ??
          ((DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) +
              ((json['expires_in'] as num?)?.toInt() ?? 0)),
      user: CineTrekkerAuthUser.fromJson(userJson),
    );
  }

  factory CineTrekkerAuthSession.fromApiJson(Map<String, dynamic> json) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 0;
    final computedExpiresAt =
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + expiresIn;
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Missing auth user payload.');
    }

    return CineTrekkerAuthSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: expiresIn,
      expiresAt: (json['expires_at'] as num?)?.toInt() ?? computedExpiresAt,
      user: CineTrekkerAuthUser.fromJson(userJson),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'expires_at': expiresAt,
      'user': user.toJson(),
    };
  }

  Map<String, dynamic> toStorageJson() => toJson();

  bool get isExpired {
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds >= (expiresAt - 60);
  }

  @override
  bool operator ==(Object other) {
    return other is CineTrekkerAuthSession &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.tokenType == tokenType &&
        other.expiresIn == expiresIn &&
        other.expiresAt == expiresAt &&
        other.user == user;
  }

  @override
  int get hashCode => Object.hash(
    accessToken,
    refreshToken,
    tokenType,
    expiresIn,
    expiresAt,
    user,
  );

  @override
  String toString() {
    return 'CineTrekkerAuthSession(accessToken: [hidden], user: ${user.id})';
  }
}

bool _mapEquals(Map<String, dynamic> left, Map<String, dynamic> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash(Map<String, dynamic> value) {
  return Object.hashAll(
    value.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
