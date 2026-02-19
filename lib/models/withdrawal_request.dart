import 'package:cloud_firestore/cloud_firestore.dart';

/// 출금 신청 상태
enum WithdrawalStatus {
  pending,    // 대기 중
  approved,   // 승인됨
  rejected,   // 거절됨
  completed,  // 완료됨
}

/// 출금 신청 모델
class WithdrawalRequest {
  final String id;
  final String userId;
  final String userNickname;
  final String walletAddress;
  final int amount;              // 출금 금액 (QKEY)
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;   // 처리 완료 시간
  final String? adminNote;       // 관리자 메모
  final String? rejectionReason; // 거절 사유

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userNickname,
    required this.walletAddress,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.adminNote,
    this.rejectionReason,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userNickname': userNickname,
      'walletAddress': walletAddress,
      'amount': amount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'adminNote': adminNote,
      'rejectionReason': rejectionReason,
    };
  }

  /// JSON에서 생성
  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userNickname: json['userNickname'] as String,
      walletAddress: json['walletAddress'] as String,
      amount: json['amount'] as int,
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      processedAt: json['processedAt'] != null 
          ? (json['processedAt'] as Timestamp).toDate() 
          : null,
      adminNote: json['adminNote'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  /// Firestore에서 생성
  factory WithdrawalRequest.fromFirestore(Map<String, dynamic> data, String docId) {
    return WithdrawalRequest(
      id: docId,
      userId: data['userId'] as String,
      userNickname: data['userNickname'] as String,
      walletAddress: data['walletAddress'] as String,
      amount: data['amount'] as int,
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null 
          ? (data['processedAt'] as Timestamp).toDate() 
          : null,
      adminNote: data['adminNote'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  /// 복사본 생성
  WithdrawalRequest copyWith({
    String? id,
    String? userId,
    String? userNickname,
    String? walletAddress,
    int? amount,
    WithdrawalStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? adminNote,
    String? rejectionReason,
  }) {
    return WithdrawalRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userNickname: userNickname ?? this.userNickname,
      walletAddress: walletAddress ?? this.walletAddress,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      adminNote: adminNote ?? this.adminNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// 상태 텍스트
  String get statusText {
    switch (status) {
      case WithdrawalStatus.pending:
        return '대기 중';
      case WithdrawalStatus.approved:
        return '승인됨';
      case WithdrawalStatus.rejected:
        return '거절됨';
      case WithdrawalStatus.completed:
        return '완료됨';
    }
  }
}
