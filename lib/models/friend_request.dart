/// 친구 요청 상태
enum FriendRequestStatus {
  pending,   // 대기 중
  accepted,  // 수락됨
  rejected,  // 거절됨
}

/// 친구 요청 모델
class FriendRequest {
  final String id;                    // 요청 ID
  final String fromUserId;            // 요청 보낸 사람 ID
  final String fromUserNickname;      // 요청 보낸 사람 닉네임
  final String toUserId;              // 요청 받은 사람 ID
  final String toUserNickname;        // 요청 받은 사람 닉네임
  final FriendRequestStatus status;   // 요청 상태
  final DateTime createdAt;           // 요청 날짜
  final DateTime? respondedAt;        // 응답 날짜

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserNickname,
    required this.toUserId,
    required this.toUserNickname,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// JSON to FriendRequest
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserNickname: json['fromUserNickname'] as String,
      toUserId: json['toUserId'] as String,
      toUserNickname: json['toUserNickname'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  /// FriendRequest to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserNickname': fromUserNickname,
      'toUserId': toUserId,
      'toUserNickname': toUserNickname,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }
}
