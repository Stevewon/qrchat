/// 친구 모델 (Firebase Firestore 호환)
class Friend {
  final String userId;          // 나의 사용자 ID
  final String friendId;        // 친구 ID
  final String friendNickname;  // 친구 닉네임
  final String? profilePhoto;   // 프로필 사진
  final String? statusMessage;  // 상태 메시지
  final DateTime addedAt;       // 친구 추가 날짜
  final bool isOnline;          // 온라인 상태

  Friend({
    required this.userId,
    required this.friendId,
    required this.friendNickname,
    this.profilePhoto,
    this.statusMessage,
    required this.addedAt,
    this.isOnline = false,
  });

  /// JSON to Friend
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userId: json['userId'] as String,
      friendId: json['friendId'] as String,
      friendNickname: json['friendNickname'] as String,
      profilePhoto: json['profilePhoto'] as String?,
      statusMessage: json['statusMessage'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  /// Friend to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'friendId': friendId,
      'friendNickname': friendNickname,
      'profilePhoto': profilePhoto,
      'statusMessage': statusMessage,
      'addedAt': addedAt.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  /// 복사본 생성
  Friend copyWith({
    String? userId,
    String? friendId,
    String? friendNickname,
    String? profilePhoto,
    String? statusMessage,
    DateTime? addedAt,
    bool? isOnline,
  }) {
    return Friend(
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendNickname: friendNickname ?? this.friendNickname,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      statusMessage: statusMessage ?? this.statusMessage,
      addedAt: addedAt ?? this.addedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
  
  // 하위 호환성을 위한 getter
  String get id => friendId;
  String get nickname => friendNickname;
}
