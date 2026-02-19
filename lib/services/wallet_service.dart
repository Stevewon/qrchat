import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/withdrawal_request.dart';

class WalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _usersCollection = 'users';
  static const String _withdrawalRequestsCollection = 'withdrawal_requests';
  
  /// 사용자의 지갑 주소 조회
  static Future<String?> getWalletAddress(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      return userDoc.data()?['walletAddress'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 지갑 주소 조회 실패: $e');
      }
      return null;
    }
  }
  
  /// 지갑 주소 설정 (1회만 가능)
  static Future<bool> setWalletAddress(String userId, String walletAddress) async {
    try {
      // 기존 지갑 주소 확인
      final existingAddress = await getWalletAddress(userId);
      
      if (existingAddress != null && existingAddress.isNotEmpty) {
        if (kDebugMode) {
          print('❌ 이미 지갑 주소가 설정되어 있습니다');
        }
        return false; // 이미 설정됨
      }
      
      // 지갑 주소 저장
      await _firestore.collection(_usersCollection).doc(userId).update({
        'walletAddress': walletAddress,
        'walletAddressSetAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ 지갑 주소 설정 완료: ${walletAddress.substring(0, 10)}...');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 지갑 주소 설정 실패: $e');
      }
      return false;
    }
  }
  
  /// 출금 신청
  static Future<bool> requestWithdrawal({
    required String userId,
    required String userNickname,
    required String walletAddress,
    required int amount,
  }) async {
    try {
      // 최소 출금 금액 확인 (1,000 QKEY)
      if (amount < 1000) {
        if (kDebugMode) {
          print('❌ 최소 출금 금액은 1,000 QKEY입니다');
        }
        return false;
      }
      
      // 1,000 단위 확인
      if (amount % 1000 != 0) {
        if (kDebugMode) {
          print('❌ 출금 금액은 1,000 QKEY 단위여야 합니다');
        }
        return false;
      }
      
      // 사용자 잔액 확인
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      final currentBalance = (userDoc.data()?['qkeyBalance'] as int?) ?? 0;
      
      if (currentBalance < amount) {
        if (kDebugMode) {
          print('❌ 잔액이 부족합니다 (현재: $currentBalance, 요청: $amount)');
        }
        return false;
      }
      
      // 대기 중인 출금 신청 확인
      final pendingRequests = await _firestore
          .collection(_withdrawalRequestsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: WithdrawalStatus.pending.name)
          .get();
      
      if (pendingRequests.docs.isNotEmpty) {
        if (kDebugMode) {
          print('❌ 이미 대기 중인 출금 신청이 있습니다');
        }
        return false;
      }
      
      // 트랜잭션으로 처리
      final batch = _firestore.batch();
      
      // 1. 출금 신청 생성
      final requestRef = _firestore.collection(_withdrawalRequestsCollection).doc();
      final request = WithdrawalRequest(
        id: requestRef.id,
        userId: userId,
        userNickname: userNickname,
        walletAddress: walletAddress,
        amount: amount,
        status: WithdrawalStatus.pending,
        createdAt: DateTime.now(),
      );
      batch.set(requestRef, request.toJson());
      
      // 2. 사용자 잔액 차감
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'qkeyBalance': currentBalance - amount,
        'qkey_balance': currentBalance - amount, // 동기화
        'totalQKeyWithdrawn': FieldValue.increment(amount),
      });
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ 출금 신청 완료: $amount QKEY');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 출금 신청 실패: $e');
      }
      return false;
    }
  }
  
  /// 사용자의 출금 신청 내역 조회
  static Future<List<WithdrawalRequest>> getUserWithdrawalRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_withdrawalRequestsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ 출금 신청 내역 조회 실패: $e');
      }
      return [];
    }
  }
  
  /// 모든 출금 신청 조회 (관리자용)
  static Stream<List<WithdrawalRequest>> getAllWithdrawalRequests() {
    return _firestore
        .collection(_withdrawalRequestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
  
  /// 출금 신청 승인 (관리자용)
  static Future<bool> approveWithdrawal(String requestId, {String? adminNote}) async {
    try {
      await _firestore.collection(_withdrawalRequestsCollection).doc(requestId).update({
        'status': WithdrawalStatus.approved.name,
        'processedAt': FieldValue.serverTimestamp(),
        'adminNote': adminNote,
      });
      
      if (kDebugMode) {
        print('✅ 출금 신청 승인 완료: $requestId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 출금 신청 승인 실패: $e');
      }
      return false;
    }
  }
  
  /// 출금 완료 처리 (관리자용)
  static Future<bool> completeWithdrawal(String requestId, {String? adminNote}) async {
    try {
      await _firestore.collection(_withdrawalRequestsCollection).doc(requestId).update({
        'status': WithdrawalStatus.completed.name,
        'processedAt': FieldValue.serverTimestamp(),
        'adminNote': adminNote,
      });
      
      if (kDebugMode) {
        print('✅ 출금 완료 처리: $requestId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 출금 완료 처리 실패: $e');
      }
      return false;
    }
  }
  
  /// 출금 신청 거절 (관리자용)
  static Future<bool> rejectWithdrawal(
    String requestId,
    String userId,
    int amount, {
    String? rejectionReason,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // 1. 출금 신청 상태 변경
      final requestRef = _firestore.collection(_withdrawalRequestsCollection).doc(requestId);
      batch.update(requestRef, {
        'status': WithdrawalStatus.rejected.name,
        'processedAt': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
      });
      
      // 2. 사용자 잔액 복구
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'qkeyBalance': FieldValue.increment(amount),
        'qkey_balance': FieldValue.increment(amount), // 동기화
        'totalQKeyWithdrawn': FieldValue.increment(-amount),
      });
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ 출금 신청 거절 및 잔액 복구 완료: $requestId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 출금 신청 거절 실패: $e');
      }
      return false;
    }
  }
}
