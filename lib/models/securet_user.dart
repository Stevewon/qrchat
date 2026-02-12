class SecuretUser {
  final String id;              // User ID
  final String qrUrl;
  final String securetQR;       // 별칭 추가
  final String securetQrUrl;    // 별칭 추가 2
  final String nickname;
  final String password;
  final String token;
  final String? voip;
  final String os;
  final DateTime registeredAt;
  final String? profilePhoto;   // 프로필 사진

  SecuretUser({
    String? id,
    required this.qrUrl,
    required this.nickname,
    required this.password,
    required this.token,
    this.voip,
    required this.os,
    required this.registeredAt,
    this.profilePhoto,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       securetQR = qrUrl,        // 별칭 초기화
       securetQrUrl = qrUrl;     // 별칭 초기화 2

  // Parse Securet QR URL
  static SecuretUser? fromQRUrl(String url, String nickname, String password) {
    try {
      final uri = Uri.parse(url);
      
      // Validate Securet domain
      if (!uri.host.contains('securet.kr')) {
        return null;
      }

      // Extract parameters from QR URL
      final token = uri.queryParameters['token'] ?? '';
      final voip = uri.queryParameters['voip'];
      final os = uri.queryParameters['os'] ?? 'unknown';
      
      // Extract nickname from QR URL if not provided (for QR scan)
      String finalNickname = nickname;
      if (nickname.isEmpty) {
        finalNickname = uri.queryParameters['nick'] ?? '';
      }

      // For QR scan, password is not required (will be empty)
      // For registration, both nickname and password are required
      if (token.isEmpty) {
        return null;
      }

      return SecuretUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        qrUrl: url,
        nickname: finalNickname,
        password: password, // Can be empty for QR scan
        token: token,
        voip: voip,
        os: os,
        registeredAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qrUrl': qrUrl,
      'nickname': nickname,
      'password': password,
      'token': token,
      'voip': voip,
      'os': os,
      'registeredAt': registeredAt.toIso8601String(),
      'profilePhoto': profilePhoto,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory SecuretUser.fromMap(Map<String, dynamic> map) {
    return SecuretUser(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      qrUrl: map['qrUrl'] ?? '',
      nickname: map['nickname'] ?? '',
      password: map['password'] ?? '',
      token: map['token'] ?? '',
      voip: map['voip'],
      os: map['os'] ?? 'unknown',
      registeredAt: DateTime.parse(map['registeredAt'] ?? DateTime.now().toIso8601String()),
      profilePhoto: map['profilePhoto'],
    );
  }

  factory SecuretUser.fromJson(Map<String, dynamic> json) => SecuretUser.fromMap(json);

  /// copyWith 메서드 (프로필 사진 업데이트용)
  SecuretUser copyWith({
    String? id,
    String? qrUrl,
    String? nickname,
    String? password,
    String? token,
    String? voip,
    String? os,
    DateTime? registeredAt,
    String? profilePhoto,
  }) {
    return SecuretUser(
      id: id ?? this.id,
      qrUrl: qrUrl ?? this.qrUrl,
      nickname: nickname ?? this.nickname,
      password: password ?? this.password,
      token: token ?? this.token,
      voip: voip ?? this.voip,
      os: os ?? this.os,
      registeredAt: registeredAt ?? this.registeredAt,
      profilePhoto: profilePhoto ?? this.profilePhoto,
    );
  }
}
