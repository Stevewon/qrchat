import 'package:cloud_firestore/cloud_firestore.dart';

/// QKEY 거래 타입
enum QKeyTransactionType {
  earn,       // 적립 (채팅 활동)
  withdraw,   // 출금 신청
  bonus,      // 보너스 지급
  penalty,    // 패널티 차감
}

/// QKEY 출금 상태
enum WithdrawStatus {
  pending,    // 대기중
  approved,   // 승인됨
  rejected,   // 거부됨
  completed,  // 완료됨
}

/// QKEY 거래 내역 모델
class QKeyTransaction {
  final String id;
  final String userId;
  final QKeyTransactionType type;
  final int amount;           // QKEY 수량 (양수: 적립, 음수: 차감)
  final int balanceAfter;     // 거래 후 잔액
  final DateTime timestamp;
  final String? description;  // 거래 설명
  
  // 출금 관련 필드
  final WithdrawStatus? withdrawStatus;
  final String? walletAddress;  // 지갑 주소
  final String? adminNote;      // 관리자 메모
  final String? adminId;        // 처리한 관리자 ID
  final DateTime? processedAt;  // 처리 시간

  QKeyTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.timestamp,
    this.description,
    this.withdrawStatus,
    this.walletAddress,
    this.adminNote,
    this.adminId,
    this.processedAt,
  });

  /// Firestore에서 읽기
  factory QKeyTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QKeyTransaction.fromJson(data, doc.id);
  }

  /// JSON에서 생성
  factory QKeyTransaction.fromJson(Map<String, dynamic> json, String id) {
    return QKeyTransaction(
      id: id,
      userId: json['userId'] as String,
      type: QKeyTransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => QKeyTransactionType.earn,
      ),
      amount: json['amount'] as int,
      balanceAfter: json['balanceAfter'] as int,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      description: json['description'] as String?,
      withdrawStatus: json['withdrawStatus'] != null
          ? WithdrawStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['withdrawStatus'],
              orElse: () => WithdrawStatus.pending,
            )
          : null,
      walletAddress: json['walletAddress'] as String?,
      adminNote: json['adminNote'] as String?,
      adminId: json['adminId'] as String?,
      processedAt: json['processedAt'] != null 
          ? (json['processedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'withdrawStatus': withdrawStatus?.toString().split('.').last,
      'walletAddress': walletAddress,
      'adminNote': adminNote,
      'adminId': adminId,
      'processedAt': processedAt != null 
          ? Timestamp.fromDate(processedAt!) 
          : null,
    };
  }

  /// 복사본 생성
  QKeyTransaction copyWith({
    String? id,
    String? userId,
    QKeyTransactionType? type,
    int? amount,
    int? balanceAfter,
    DateTime? timestamp,
    String? description,
    WithdrawStatus? withdrawStatus,
    String? walletAddress,
    String? adminNote,
    String? adminId,
    DateTime? processedAt,
  }) {
    return QKeyTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      withdrawStatus: withdrawStatus ?? this.withdrawStatus,
      walletAddress: walletAddress ?? this.walletAddress,
      adminNote: adminNote ?? this.adminNote,
      adminId: adminId ?? this.adminId,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
