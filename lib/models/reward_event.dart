import 'package:cloud_firestore/cloud_firestore.dart';

/// 그룹 채팅 보상 이벤트
/// 
/// 3인 이상 그룹 채팅에서 2분 이상 대화 시 랜덤으로 생성되는 보상 이벤트
class RewardEvent {
  /// 이벤트 ID
  final String id;
  
  /// 그룹 채팅방 ID
  final String chatRoomId;
  
  /// 보상 금액 (QKEY)
  final int rewardAmount;
  
  /// 이벤트 생성 시각
  final DateTime createdAt;
  
  /// 이벤트 만료 시각 (생성 후 30초)
  final DateTime expiresAt;
  
  /// 클릭한 사용자 ID (null = 아직 클릭 안 됨)
  final String? claimedByUserId;
  
  /// 클릭한 사용자 닉네임
  final String? claimedByNickname;
  
  /// 클릭 시각
  final DateTime? claimedAt;
  
  /// 이벤트 상태
  final RewardEventStatus status;
  
  /// 구체 화면 위치 X (0.0 ~ 1.0, 화면 비율)
  final double positionX;
  
  /// 구체 화면 위치 Y (0.0 ~ 1.0, 화면 비율)
  final double positionY;

  RewardEvent({
    required this.id,
    required this.chatRoomId,
    required this.rewardAmount,
    required this.createdAt,
    required this.expiresAt,
    this.claimedByUserId,
    this.claimedByNickname,
    this.claimedAt,
    required this.status,
    required this.positionX,
    required this.positionY,
  });

  /// Firestore 문서에서 생성
  factory RewardEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardEvent(
      id: doc.id,
      chatRoomId: data['chatRoomId'] as String,
      rewardAmount: data['rewardAmount'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      claimedByUserId: data['claimedByUserId'] as String?,
      claimedByNickname: data['claimedByNickname'] as String?,
      claimedAt: data['claimedAt'] != null 
          ? (data['claimedAt'] as Timestamp).toDate() 
          : null,
      status: RewardEventStatus.fromString(data['status'] as String),
      positionX: (data['positionX'] as num?)?.toDouble() ?? 0.5,
      positionY: (data['positionY'] as num?)?.toDouble() ?? 0.5,
    );
  }

  /// Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'chatRoomId': chatRoomId,
      'rewardAmount': rewardAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'claimedByUserId': claimedByUserId,
      'claimedByNickname': claimedByNickname,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'status': status.toString(),
      'positionX': positionX,
      'positionY': positionY,
    };
  }

  /// 이벤트가 아직 유효한지 (만료되지 않았는지)
  bool get isActive => 
      status == RewardEventStatus.active && 
      DateTime.now().isBefore(expiresAt);

  /// 이미 누군가 클릭했는지
  bool get isClaimed => status == RewardEventStatus.claimed;

  /// 만료되었는지
  bool get isExpired => 
      status == RewardEventStatus.expired || 
      DateTime.now().isAfter(expiresAt);

  /// 복사본 생성
  RewardEvent copyWith({
    String? id,
    String? chatRoomId,
    int? rewardAmount,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? claimedByUserId,
    String? claimedByNickname,
    DateTime? claimedAt,
    RewardEventStatus? status,
    double? positionX,
    double? positionY,
  }) {
    return RewardEvent(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      claimedByUserId: claimedByUserId ?? this.claimedByUserId,
      claimedByNickname: claimedByNickname ?? this.claimedByNickname,
      claimedAt: claimedAt ?? this.claimedAt,
      status: status ?? this.status,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
    );
  }
}

/// 보상 이벤트 상태
enum RewardEventStatus {
  /// 활성 상태 (클릭 가능)
  active,
  
  /// 누군가 클릭함
  claimed,
  
  /// 만료됨 (30초 경과)
  expired;

  @override
  String toString() {
    switch (this) {
      case RewardEventStatus.active:
        return 'active';
      case RewardEventStatus.claimed:
        return 'claimed';
      case RewardEventStatus.expired:
        return 'expired';
    }
  }

  static RewardEventStatus fromString(String value) {
    switch (value) {
      case 'active':
        return RewardEventStatus.active;
      case 'claimed':
        return RewardEventStatus.claimed;
      case 'expired':
        return RewardEventStatus.expired;
      default:
        return RewardEventStatus.expired;
    }
  }
}
