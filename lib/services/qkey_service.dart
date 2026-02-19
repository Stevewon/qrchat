import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/qkey_transaction.dart';

class QKeyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 컬렉션 이름
  static const String _usersCollection = 'users';
  static const String _transactionsCollection = 'qkey_transactions';
  
  // QKEY 적립 설정
  static const int earnAmountPerInterval = 2;       // 5분당 적립량 (10 → 2로 감소)
  static const int earnIntervalMinutes = 5;         // 적립 간격 (분)
  static const int withdrawMinAmount = 1000;        // 최소 출금 가능 금액
  static const int withdrawUnit = 1000;             // 출금 단위
  
  // 첫 로그인 보너스 설정
  static const int loginBonusAmount = 1;            // 로그인 당 지급량
  static const int loginBonusMaxPerDay = 5;         // 하루 최대 로그인 보너스 횟수
  
  // 채팅방 채굴 설정
  static const int chatMiningMaxPerDay = 3;         // 하루 최대 채팅 채굴 횟수
  
  /// 사용자의 현재 QKEY 잔액 조회
  static Future<int> getUserBalance(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return 0;
      }
      
      final data = userDoc.data();
      return (data?['qkeyBalance'] as int?) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ QKEY 잔액 조회 실패: $e');
      }
      return 0;
    }
  }
  
  /// 사용자의 마지막 QKEY 적립 시간 조회
  static Future<DateTime?> getLastEarnTime(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      final data = userDoc.data();
      final timestamp = data?['lastQKeyEarnTime'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      if (kDebugMode) {
        print('❌ 마지막 적립 시간 조회 실패: $e');
      }
      return null;
    }
  }
  
  /// 첫 로그인 보너스 지급
  /// 하루 5회까지 지급 가능
  static Future<bool> giveLoginBonus(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 사용자 문서 조회
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          print('❌ 사용자를 찾을 수 없습니다');
        }
        return false;
      }
      
      final userData = userDoc.data()!;
      
      // 오늘 로그인 보너스 받은 횟수 확인
      final lastLoginBonusDate = (userData['lastLoginBonusDate'] as Timestamp?)?.toDate();
      int todayLoginBonusCount = 0;
      
      if (lastLoginBonusDate != null) {
        final lastLoginDay = DateTime(lastLoginBonusDate.year, lastLoginBonusDate.month, lastLoginBonusDate.day);
        if (lastLoginDay.isAtSameMomentAs(today)) {
          // 오늘 이미 받았음
          todayLoginBonusCount = (userData['todayLoginBonusCount'] as int?) ?? 0;
          
          if (todayLoginBonusCount >= loginBonusMaxPerDay) {
            if (kDebugMode) {
              print('⏳ 오늘 로그인 보너스를 모두 받았습니다 ($todayLoginBonusCount/$loginBonusMaxPerDay)');
            }
            return false;
          }
        }
      }
      
      // 현재 잔액 조회
      final currentBalance = (userData['qkeyBalance'] as int?) ?? 0;
      final newBalance = currentBalance + loginBonusAmount;
      
      // 트랜잭션으로 처리
      final batch = _firestore.batch();
      
      // 1. 사용자 잔액 업데이트
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'qkeyBalance': newBalance,
        'qkey_balance': newBalance, // 동기화
        'lastLoginBonusDate': Timestamp.fromDate(now),
        'todayLoginBonusCount': todayLoginBonusCount + 1,
        'totalQKeyEarned': FieldValue.increment(loginBonusAmount),
      });
      
      // 2. 거래 내역 추가
      final transactionRef = _firestore.collection(_transactionsCollection).doc();
      final transaction = QKeyTransaction(
        id: transactionRef.id,
        userId: userId,
        type: QKeyTransactionType.earn,
        amount: loginBonusAmount,
        balanceAfter: newBalance,
        timestamp: now,
        description: '로그인 보너스 (${todayLoginBonusCount + 1}/$loginBonusMaxPerDay)',
      );
      batch.set(transactionRef, transaction.toJson());
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ 로그인 보너스 지급 완료: +$loginBonusAmount QKEY (${todayLoginBonusCount + 1}/$loginBonusMaxPerDay) (잔액: $newBalance)');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로그인 보너스 지급 실패: $e');
      }
      return false;
    }
  }
  
  /// QKEY 채굴 (채팅방 활동 - 방장만)
  /// chatRoomId: 채팅방 ID
  /// creatorId: 방을 만든 사람 (방장) ID
  /// userId: 현재 사용자 ID
  /// messageTimestamp: 메시지 전송 시간
  static Future<bool> earnQKeyFromChat({
    required String chatRoomId,
    required String creatorId,
    required String userId,
    required DateTime messageTimestamp,
  }) async {
    try {
      // 방장이 아니면 지급하지 않음
      if (userId != creatorId) {
        if (kDebugMode) {
          print('⏳ 방장이 아니므로 QKEY를 지급하지 않습니다');
        }
        return false;
      }
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 사용자 문서 조회
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          print('❌ 사용자를 찾을 수 없습니다');
        }
        return false;
      }
      
      final userData = userDoc.data()!;
      
      // 채팅방별 마지막 채굴 시간 확인
      final chatMiningData = userData['chatMiningData'] as Map<String, dynamic>? ?? {};
      final roomMiningData = chatMiningData[chatRoomId] as Map<String, dynamic>? ?? {};
      
      // 마지막 메시지 시간과 마지막 채굴 시간 확인
      final lastMessageTime = (roomMiningData['lastMessageTime'] as Timestamp?)?.toDate();
      final lastMiningTime = (roomMiningData['lastMiningTime'] as Timestamp?)?.toDate();
      
      // 첫 메시지이거나 5분 이상 대화가 없었으면 타이머 시작
      if (lastMessageTime == null || messageTimestamp.difference(lastMessageTime).inMinutes >= earnIntervalMinutes) {
        // 타이머 시작: 메시지 시간 기록
        final batch = _firestore.batch();
        final userRef = _firestore.collection(_usersCollection).doc(userId);
        
        chatMiningData[chatRoomId] = {
          'lastMessageTime': Timestamp.fromDate(messageTimestamp),
          'lastMiningTime': lastMiningTime != null ? Timestamp.fromDate(lastMiningTime) : null,
          'todayCount': roomMiningData['todayCount'] ?? 0,
          'lastCountResetDate': roomMiningData['lastCountResetDate'],
        };
        
        batch.update(userRef, {
          'chatMiningData': chatMiningData,
        });
        
        await batch.commit();
        
        if (kDebugMode) {
          print('⏰ 채굴 타이머 시작: 5분 후 지급 예정');
        }
        return false;
      }
      
      // 5분이 지났는지 확인
      if (now.difference(lastMessageTime!).inMinutes < earnIntervalMinutes) {
        if (kDebugMode) {
          final remaining = earnIntervalMinutes - now.difference(lastMessageTime).inMinutes;
          print('⏳ 아직 채굴 시간이 안됨: $remaining분 남음');
        }
        return false;
      }
      
      // 오늘 채굴 횟수 확인
      final lastCountResetDate = (roomMiningData['lastCountResetDate'] as Timestamp?)?.toDate();
      int todayCount = 0;
      
      if (lastCountResetDate != null) {
        final lastResetDay = DateTime(lastCountResetDate.year, lastCountResetDate.month, lastCountResetDate.day);
        if (lastResetDay.isAtSameMomentAs(today)) {
          todayCount = (roomMiningData['todayCount'] as int?) ?? 0;
        }
      }
      
      // 하루 3회 제한
      if (todayCount >= chatMiningMaxPerDay) {
        if (kDebugMode) {
          print('⏳ 오늘 채굴 횟수를 모두 사용했습니다 ($todayCount/$chatMiningMaxPerDay)');
        }
        return false;
      }
      
      // 현재 잔액 조회
      final currentBalance = (userData['qkeyBalance'] as int?) ?? 0;
      final newBalance = currentBalance + earnAmountPerInterval;
      
      // 트랜잭션으로 처리
      final batch = _firestore.batch();
      
      // 1. 사용자 잔액 및 채굴 데이터 업데이트
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      chatMiningData[chatRoomId] = {
        'lastMessageTime': Timestamp.fromDate(messageTimestamp),
        'lastMiningTime': Timestamp.fromDate(now),
        'todayCount': todayCount + 1,
        'lastCountResetDate': Timestamp.fromDate(now),
      };
      
      batch.update(userRef, {
        'qkeyBalance': newBalance,
        'qkey_balance': newBalance, // 동기화
        'chatMiningData': chatMiningData,
        'totalQKeyEarned': FieldValue.increment(earnAmountPerInterval),
      });
      
      // 2. 거래 내역 추가
      final transactionRef = _firestore.collection(_transactionsCollection).doc();
      final transaction = QKeyTransaction(
        id: transactionRef.id,
        userId: userId,
        type: QKeyTransactionType.earn,
        amount: earnAmountPerInterval,
        balanceAfter: newBalance,
        timestamp: now,
        description: '채팅 채굴 (${todayCount + 1}/$chatMiningMaxPerDay)',
      );
      batch.set(transactionRef, transaction.toJson());
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ 채팅 채굴 완료: +$earnAmountPerInterval QKEY (${todayCount + 1}/$chatMiningMaxPerDay) (잔액: $newBalance)');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 채팅 채굴 실패: $e');
      }
      return false;
    }
  }
  
  /// QKEY 적립 (채팅 활동) - 레거시 메서드 (하위 호환성 유지)
  static Future<bool> earnQKey(String userId, {String? description}) async {
    try {
      final now = DateTime.now();
      final lastEarnTime = await getLastEarnTime(userId);
      
      // 마지막 적립 시간 체크 (5분 간격)
      if (lastEarnTime != null) {
        final difference = now.difference(lastEarnTime);
        if (difference.inMinutes < earnIntervalMinutes) {
          if (kDebugMode) {
            print('⏳ 아직 적립 시간이 안됨: ${earnIntervalMinutes - difference.inMinutes}분 남음');
          }
          return false;
        }
      }
      
      // 현재 잔액 조회
      final currentBalance = await getUserBalance(userId);
      final newBalance = currentBalance + earnAmountPerInterval;
      
      // 트랜잭션으로 처리
      final batch = _firestore.batch();
      
      // 1. 사용자 잔액 업데이트
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'qkeyBalance': newBalance,
        'lastQKeyEarnTime': Timestamp.fromDate(now),
        'totalQKeyEarned': FieldValue.increment(earnAmountPerInterval),
      });
      
      // 2. 거래 내역 추가
      final transactionRef = _firestore.collection(_transactionsCollection).doc();
      final transaction = QKeyTransaction(
        id: transactionRef.id,
        userId: userId,
        type: QKeyTransactionType.earn,
        amount: earnAmountPerInterval,
        balanceAfter: newBalance,
        timestamp: now,
        description: description ?? '채팅 활동 적립',
      );
      batch.set(transactionRef, transaction.toJson());
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ QKEY 적립 완료: +$earnAmountPerInterval QKEY (잔액: $newBalance)');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ QKEY 적립 실패: $e');
      }
      return false;
    }
  }
  
  /// 출금 신청
  static Future<Map<String, dynamic>> requestWithdraw({
    required String userId,
    required int amount,
    required String walletAddress,
  }) async {
    try {
      // 1. 출금 가능 검증
      if (amount < withdrawMinAmount) {
        return {
          'success': false,
          'message': '최소 출금 가능 금액은 $withdrawMinAmount QKEY입니다.',
        };
      }
      
      if (amount % withdrawUnit != 0) {
        return {
          'success': false,
          'message': '출금은 $withdrawUnit QKEY 단위로만 가능합니다.',
        };
      }
      
      // 2. 잔액 확인
      final currentBalance = await getUserBalance(userId);
      if (currentBalance < amount) {
        return {
          'success': false,
          'message': '잔액이 부족합니다. (현재: $currentBalance QKEY)',
        };
      }
      
      // 3. 지갑 주소 검증 (간단한 검증)
      if (walletAddress.trim().isEmpty) {
        return {
          'success': false,
          'message': '지갑 주소를 입력해주세요.',
        };
      }
      
      // 4. 트랜잭션 처리
      final now = DateTime.now();
      final newBalance = currentBalance - amount;
      final batch = _firestore.batch();
      
      // 4-1. 사용자 잔액 차감
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'qkeyBalance': newBalance,
        'walletAddress': walletAddress, // 지갑 주소 저장
      });
      
      // 4-2. 출금 신청 거래 내역 추가
      final transactionRef = _firestore.collection(_transactionsCollection).doc();
      final transaction = QKeyTransaction(
        id: transactionRef.id,
        userId: userId,
        type: QKeyTransactionType.withdraw,
        amount: -amount, // 차감이므로 음수
        balanceAfter: newBalance,
        timestamp: now,
        description: '출금 신청',
        withdrawStatus: WithdrawStatus.pending,
        walletAddress: walletAddress,
      );
      batch.set(transactionRef, transaction.toJson());
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ 출금 신청 완료: -$amount QKEY → $walletAddress (잔액: $newBalance)');
      }
      
      return {
        'success': true,
        'message': '출금 신청이 완료되었습니다. 관리자 승인 후 처리됩니다.',
        'transactionId': transactionRef.id,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ 출금 신청 실패: $e');
      }
      return {
        'success': false,
        'message': '출금 신청 중 오류가 발생했습니다: $e',
      };
    }
  }
  
  /// 출금 신청 내역 조회 (사용자)
  static Stream<List<QKeyTransaction>> getUserWithdrawals(String userId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'withdraw')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QKeyTransaction.fromFirestore(doc))
            .toList());
  }
  
  /// 모든 출금 신청 내역 조회 (관리자)
  static Stream<List<QKeyTransaction>> getAllWithdrawals({
    WithdrawStatus? status,
  }) {
    Query query = _firestore
        .collection(_transactionsCollection)
        .where('type', isEqualTo: 'withdraw');
    
    if (status != null) {
      query = query.where(
        'withdrawStatus',
        isEqualTo: status.toString().split('.').last,
      );
    }
    
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QKeyTransaction.fromFirestore(doc))
            .toList());
  }
  
  /// 출금 신청 승인/거부 (관리자)
  static Future<bool> processWithdraw({
    required String transactionId,
    required String adminId,
    required bool approve,
    String? adminNote,
  }) async {
    try {
      final transactionRef = _firestore
          .collection(_transactionsCollection)
          .doc(transactionId);
      
      final transactionDoc = await transactionRef.get();
      if (!transactionDoc.exists) {
        if (kDebugMode) {
          print('❌ 거래 내역을 찾을 수 없습니다.');
        }
        return false;
      }
      
      final transaction = QKeyTransaction.fromFirestore(transactionDoc);
      
      // 이미 처리된 경우
      if (transaction.withdrawStatus != WithdrawStatus.pending) {
        if (kDebugMode) {
          print('⚠️ 이미 처리된 출금 신청입니다.');
        }
        return false;
      }
      
      final now = DateTime.now();
      final newStatus = approve ? WithdrawStatus.completed : WithdrawStatus.rejected;
      
      final batch = _firestore.batch();
      
      // 1. 거래 상태 업데이트
      batch.update(transactionRef, {
        'withdrawStatus': newStatus.toString().split('.').last,
        'adminId': adminId,
        'adminNote': adminNote,
        'processedAt': Timestamp.fromDate(now),
      });
      
      // 2. 거부된 경우 잔액 복구
      if (!approve) {
        final userRef = _firestore
            .collection(_usersCollection)
            .doc(transaction.userId);
        
        batch.update(userRef, {
          'qkeyBalance': FieldValue.increment(transaction.amount.abs()),
        });
        
        // 복구 거래 내역 추가
        final refundRef = _firestore.collection(_transactionsCollection).doc();
        final refundTransaction = QKeyTransaction(
          id: refundRef.id,
          userId: transaction.userId,
          type: QKeyTransactionType.bonus,
          amount: transaction.amount.abs(),
          balanceAfter: transaction.balanceAfter + transaction.amount.abs(),
          timestamp: now,
          description: '출금 거부로 인한 반환',
        );
        batch.set(refundRef, refundTransaction.toJson());
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ 출금 ${approve ? '승인' : '거부'} 완료: $transactionId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 출금 처리 실패: $e');
      }
      return false;
    }
  }
  
  /// 사용자 거래 내역 조회
  static Stream<List<QKeyTransaction>> getUserTransactions(String userId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QKeyTransaction.fromFirestore(doc))
            .toList());
  }
  
  /// 보너스 지급 (관리자)
  static Future<bool> giveBonus({
    required String userId,
    required int amount,
    required String adminId,
    String? description,
  }) async {
    try {
      final currentBalance = await getUserBalance(userId);
      final newBalance = currentBalance + amount;
      final now = DateTime.now();
      
      final batch = _firestore.batch();
      
      // 1. 사용자 잔액 업데이트
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'qkeyBalance': newBalance,
      });
      
      // 2. 거래 내역 추가
      final transactionRef = _firestore.collection(_transactionsCollection).doc();
      final transaction = QKeyTransaction(
        id: transactionRef.id,
        userId: userId,
        type: QKeyTransactionType.bonus,
        amount: amount,
        balanceAfter: newBalance,
        timestamp: now,
        description: description ?? '관리자 보너스 지급',
        adminId: adminId,
      );
      batch.set(transactionRef, transaction.toJson());
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ 보너스 지급 완료: +$amount QKEY (잔액: $newBalance)');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 보너스 지급 실패: $e');
      }
      return false;
    }
  }
}
