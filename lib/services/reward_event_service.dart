import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_event.dart';
import '../models/securet_user.dart';
import 'qkey_service.dart';

/// 그룹 채팅 보상 이벤트 서비스
/// 
/// 3인 이상 그룹 채팅에서 2분 이상 대화 시 랜덤으로 보상 이벤트 생성
class RewardEventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Firestore 컬렉션 이름
  static const String _collectionName = 'reward_events';

  /// 대화 시작 시간 추적 맵 (chatRoomId -> 대화 시작 시간)
  static final Map<String, DateTime> _chatStartTime = {};

  /// 마지막 메시지 시간 (chatRoomId -> 마지막 메시지 시간)
  static final Map<String, DateTime> _lastMessageTime = {};

  /// 이벤트 생성 쿨다운 (chatRoomId -> 마지막 이벤트 생성 시간)
  static final Map<String, DateTime> _eventCooldown = {};

  // ===== 설정 =====
  /// 최소 참여자 수
  static const int minParticipants = 3;

  /// 대화 지속 시간 (초)
  static const int conversationDuration = 120; // 2분

  /// 이벤트 생성 확률 (0.0 ~ 1.0)
  static const double eventProbability = 0.3; // 30%

  /// 이벤트 만료 시간 (초)
  static const int eventExpiration = 30; // 30초

  /// 이벤트 생성 쿨다운 (초)
  static const int eventCooldownSeconds = 300; // 5분

  /// 최소 보상 QKEY
  static const int minReward = 1;

  /// 최대 보상 QKEY
  static const int maxReward = 10;
  
  /// 출금 가능 최소 QKEY (로그인 보너스 등과 동일)
  static const int withdrawMinAmount = 1000; // 1,000 QKEY

  /// 그룹 채팅에서 메시지가 전송될 때 호출
  /// 
  /// [chatRoomId] 채팅방 ID
  /// [participantCount] 참여자 수
  static Future<void> onMessageSent({
    required String chatRoomId,
    required int participantCount,
  }) async {
    try {
      print('');
      print('========================================');
      print('🎁 [보상 시스템] 메시지 전송 감지');
      print('   채팅방 ID: $chatRoomId');
      print('   참여자 수: $participantCount명');
      print('========================================');
      debugPrint('');
      debugPrint('========================================');
      debugPrint('🎁 [보상 시스템] 메시지 전송 감지');
      debugPrint('   채팅방 ID: $chatRoomId');
      debugPrint('   참여자 수: $participantCount명');
      debugPrint('========================================');
      
      // 1. 참여자 수 체크
      if (participantCount < minParticipants) {
        debugPrint('❌ [조건 미달] 참여자 ${participantCount}명 (최소 ${minParticipants}명 필요)');
        debugPrint('========================================');
        return;
      }
      debugPrint('✅ [조건 충족] 참여자 수: ${participantCount}명 >= ${minParticipants}명');

      // 2. 대화 활동 기록 - SharedPreferences에서 복원!
      final now = DateTime.now();
      DateTime? startTime = _chatStartTime[chatRoomId];
      DateTime? lastMessage = _lastMessageTime[chatRoomId];
      
      debugPrint('🔍 [메모리 확인] startTime: ${startTime?.toString().substring(11, 19) ?? "없음"}');
      debugPrint('🔍 [메모리 확인] lastMessage: ${lastMessage?.toString().substring(11, 19) ?? "없음"}');
      
      // ✅ SharedPreferences에서 startTime 복원
      if (startTime == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedMs = prefs.getInt('chat_start_$chatRoomId');
          if (savedMs != null) {
            startTime = DateTime.fromMillisecondsSinceEpoch(savedMs);
            _chatStartTime[chatRoomId] = startTime;
            debugPrint('📂 [startTime 복원] ${startTime.toString().substring(11, 19)}');
          } else {
            debugPrint('📂 [startTime] 저장된 데이터 없음');
          }
        } catch (e) {
          debugPrint('❌ [startTime 복원 오류] $e');
        }
      }
      
      // ✅ SharedPreferences에서 lastMessage 복원
      if (lastMessage == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedMs = prefs.getInt('chat_last_$chatRoomId');
          if (savedMs != null) {
            lastMessage = DateTime.fromMillisecondsSinceEpoch(savedMs);
            _lastMessageTime[chatRoomId] = lastMessage;
            debugPrint('📂 [lastMessage 복원] ${lastMessage.toString().substring(11, 19)}');
          } else {
            debugPrint('📂 [lastMessage] 저장된 데이터 없음');
          }
        } catch (e) {
          debugPrint('❌ [lastMessage 복원 오류] $e');
        }
      }

      debugPrint('📊 [시간 정보]');
      debugPrint('   현재 시간: ${now.toString().substring(11, 19)}');
      debugPrint('   대화 시작 시간: ${startTime?.toString().substring(11, 19) ?? "없음"}');
      debugPrint('   마지막 메시지 시간: ${lastMessage?.toString().substring(11, 19) ?? "없음"}');

      // 첫 메시지이거나 10분 이상 대화가 끊긴 경우 새로운 대화 세션 시작
      if (startTime == null) {
        debugPrint('⚠️  [판단] startTime이 null → 새 세션 시작');
        _chatStartTime[chatRoomId] = now;
        _lastMessageTime[chatRoomId] = now;
        
        // ✅ SharedPreferences에 저장
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('chat_start_$chatRoomId', now.millisecondsSinceEpoch);
          await prefs.setInt('chat_last_$chatRoomId', now.millisecondsSinceEpoch);
          debugPrint('💾 [저장 성공] startTime & lastMessage 저장');
        } catch (e) {
          debugPrint('❌ [저장 오류] $e');
        }
        
        debugPrint('🆕 [새 세션] 첫 메시지 - 대화 시작 시간 기록: ${now.toString().substring(11, 19)}');
        debugPrint('   ℹ️  다음 메시지부터 지속 시간 카운트 시작');
        debugPrint('========================================');
        return;
      }

      // 10분 이상 대화가 끊긴 경우 세션 리셋
      if (lastMessage != null && now.difference(lastMessage).inMinutes >= 10) {
        debugPrint('🔄 [세션 리셋] 10분 이상 대화 중단 → 새 세션 시작');
        _chatStartTime[chatRoomId] = now;
        _lastMessageTime[chatRoomId] = now;
        
        // ✅ SharedPreferences에 새 시작 시간 저장
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('chat_start_$chatRoomId', now.millisecondsSinceEpoch);
          await prefs.setInt('chat_last_$chatRoomId', now.millisecondsSinceEpoch);
          debugPrint('💾 [저장] startTime & lastMessage 업데이트');
        } catch (e) {
          debugPrint('❌ [저장 오류] $e');
        }
        
        debugPrint('========================================');
        return;
      }

      // 마지막 메시지 시간 업데이트
      _lastMessageTime[chatRoomId] = now;
      
      // ✅ SharedPreferences에 lastMessage 저장
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('chat_last_$chatRoomId', now.millisecondsSinceEpoch);
        debugPrint('💾 [업데이트] lastMessage 저장: ${now.toString().substring(11, 19)}');
      } catch (e) {
        debugPrint('❌ [lastMessage 저장 오류] $e');
      }

      // 3. 대화 지속 시간 체크 (대화 시작 시간부터 현재까지)
      final totalDuration = now.difference(startTime).inSeconds;
      final remainingSeconds = conversationDuration - totalDuration;

      debugPrint('⏱️  [대화 지속 시간]');
      debugPrint('   경과 시간: ${totalDuration}초');
      debugPrint('   필요 시간: ${conversationDuration}초');
      debugPrint('   남은 시간: ${remainingSeconds > 0 ? remainingSeconds : 0}초');

      if (totalDuration < conversationDuration) {
        debugPrint('❌ [조건 미달] 아직 ${remainingSeconds}초 더 대화 필요');
        debugPrint('========================================');
        return;
      }

      debugPrint('✅ [조건 충족] 대화 ${totalDuration}초 지속! (${conversationDuration}초 이상)');

      // 4. 쿨다운 체크
      final lastEvent = _eventCooldown[chatRoomId];
      if (lastEvent != null) {
        final cooldown = now.difference(lastEvent).inSeconds;
        final remainingCooldown = eventCooldownSeconds - cooldown;
        debugPrint('⏳ [쿨다운 체크]');
        debugPrint('   마지막 이벤트: ${lastEvent.toString().substring(11, 19)}');
        debugPrint('   경과 시간: ${cooldown}초');
        debugPrint('   쿨다운: ${eventCooldownSeconds}초');
        
        if (cooldown < eventCooldownSeconds) {
          debugPrint('❌ [조건 미달] 쿨다운 중 (${remainingCooldown}초 남음)');
          debugPrint('========================================');
          return;
        }
        debugPrint('✅ [조건 충족] 쿨다운 완료');
      } else {
        debugPrint('✅ [쿨다운] 첫 이벤트 - 쿨다운 없음');
      }

      // 5. 모든 조건 충족! 확률 없이 무조건 이벤트 생성
      debugPrint('');
      debugPrint('🎉🎉🎉 [조건 완료] 모든 조건 충족! 확률 체크 없이 무조건 생성! 🎉🎉🎉');
      debugPrint('   ✅ 참여자 수: ${participantCount}명 >= ${minParticipants}명');
      debugPrint('   ✅ 대화 시간: ${totalDuration}초 >= ${conversationDuration}초');
      debugPrint('   ✅ 쿨다운: 완료');
      debugPrint('   🎁 보상 이벤트 생성 시작...');
      debugPrint('');

      // 6. 이벤트 생성
      await _createRewardEvent(chatRoomId);
      _eventCooldown[chatRoomId] = now;
      debugPrint('========================================');
      debugPrint('');

    } catch (e) {
      debugPrint('❌ 보상 이벤트 처리 오류: $e');
      debugPrint('========================================');
    }
  }

  /// 보상 이벤트 생성
  static Future<void> _createRewardEvent(String chatRoomId) async {
    try {
      final now = DateTime.now();
      final rewardAmount = _random.nextInt(maxReward - minReward + 1) + minReward;
      
      // 랜덤 위치 생성 (화면 중앙 부근)
      final positionX = 0.3 + _random.nextDouble() * 0.4; // 0.3 ~ 0.7
      final positionY = 0.3 + _random.nextDouble() * 0.4; // 0.3 ~ 0.7

      debugPrint('🎨 [이벤트 상세]');
      debugPrint('   보상 QKEY: ${rewardAmount}개');
      debugPrint('   위치: (${(positionX * 100).toInt()}%, ${(positionY * 100).toInt()}%)');
      debugPrint('   만료: ${eventExpiration}초 후');

      final event = RewardEvent(
        id: '', // Firestore에서 자동 생성
        chatRoomId: chatRoomId,
        rewardAmount: rewardAmount,
        createdAt: now,
        expiresAt: now.add(Duration(seconds: eventExpiration)),
        status: RewardEventStatus.active,
        positionX: positionX,
        positionY: positionY,
      );

      debugPrint('💾 [Firestore] 이벤트 저장 시도...');
      debugPrint('   컬렉션: $_collectionName');
      debugPrint('   채팅방 ID: $chatRoomId');
      debugPrint('   데이터: ${event.toFirestore()}');
      
      final docRef = await _firestore.collection(_collectionName).add(event.toFirestore());
      
      debugPrint('✅ [Firestore] 이벤트 저장 완료!');
      debugPrint('   문서 ID: ${docRef.id}');
      debugPrint('   컬렉션: $_collectionName');
      debugPrint('   경로: $_collectionName/${docRef.id}');
      debugPrint('🎉🎉🎉 보상 이벤트 생성 성공! 채팅방에서 황금 구슬이 나타납니다! 🎉🎉🎉');
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌❌❌ [치명적 오류] 보상 이벤트 생성 실패! ❌❌❌');
      debugPrint('   오류 타입: ${e.runtimeType}');
      debugPrint('   오류 메시지: $e');
      debugPrint('   스택 트레이스:');
      debugPrint('$stackTrace');
      debugPrint('');
      debugPrint('🔍 [가능한 원인]');
      debugPrint('   1. Firestore 권한 문제');
      debugPrint('   2. 네트워크 연결 문제');
      debugPrint('   3. 잘못된 데이터 형식');
      debugPrint('');
    }
  }

  /// 특정 채팅방의 활성 이벤트 스트림
  static Stream<List<RewardEvent>> getActiveEvents(String chatRoomId) {
    return _firestore
        .collection(_collectionName)
        .where('chatRoomId', isEqualTo: chatRoomId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(5) // 최대 5개
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RewardEvent.fromFirestore(doc))
            .where((event) => event.isActive) // 만료되지 않은 것만
            .toList());
  }

  /// 보상 이벤트 클릭 처리 (선착순)
  static Future<bool> claimReward({
    required String eventId,
    required SecuretUser user,
  }) async {
    try {
      final eventRef = _firestore.collection(_collectionName).doc(eventId);

      // Firestore Transaction으로 동시성 제어
      final result = await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          throw Exception('이벤트를 찾을 수 없습니다');
        }

        final event = RewardEvent.fromFirestore(eventDoc);

        // 이미 클릭됨
        if (event.isClaimed) {
          throw Exception('이미 다른 사용자가 획득했습니다');
        }

        // 만료됨
        if (event.isExpired) {
          // 상태 업데이트
          transaction.update(eventRef, {
            'status': RewardEventStatus.expired.toString(),
          });
          throw Exception('이벤트가 만료되었습니다');
        }

        // 클릭 성공! 이벤트 업데이트
        transaction.update(eventRef, {
          'claimedByUserId': user.id,
          'claimedByNickname': user.nickname,
          'claimedAt': Timestamp.now(),
          'status': RewardEventStatus.claimed.toString(),
        });

        return event.rewardAmount;
      });

      // QKEY 지급 (직접 Firestore에 기록)
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
      final transactionsRef = FirebaseFirestore.instance.collection('qkey_transactions');
      
      // 현재 잔액 조회
      final userDoc = await userRef.get();
      final currentBalance = (userDoc.data()?['qkeyBalance'] as int?) ?? 0;
      final newBalance = currentBalance + result;
      
      // 사용자 잔액 업데이트
      await userRef.update({
        'qkeyBalance': newBalance,
        'qkey_balance': newBalance, // 동기화
        'totalQKeyEarned': FieldValue.increment(result),
      });
      
      // 트랜잭션 기록 추가 (balanceAfter 포함!)
      await transactionsRef.add({
        'userId': user.id,
        'amount': result,
        'balanceAfter': newBalance, // ✅ 추가!
        'type': 'bonus',
        'description': '🎁 그룹 채팅 보상 이벤트',
        'timestamp': Timestamp.now(),
      });

      debugPrint('✅ ${user.nickname}님이 ${result} QKEY 획득!');
      return true;

    } on Exception catch (e) {
      debugPrint('⚠️ 보상 획득 실패: ${e.toString()}');
      return false;
    } catch (e) {
      debugPrint('❌ 보상 획득 오류: $e');
      return false;
    }
  }

  /// 만료된 이벤트 정리 (백그라운드에서 주기적으로 실행)
  static Future<void> cleanupExpiredEvents() async {
    try {
      final now = Timestamp.now();
      final expiredQuery = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'active')
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (var doc in expiredQuery.docs) {
        batch.update(doc.reference, {
          'status': RewardEventStatus.expired.toString(),
        });
      }

      await batch.commit();
      debugPrint('🧹 만료된 이벤트 ${expiredQuery.docs.length}개 정리');
    } catch (e) {
      debugPrint('❌ 이벤트 정리 오류: $e');
    }
  }

  /// 특정 사용자가 획득한 보상 히스토리
  static Future<List<RewardEvent>> getUserRewardHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('claimedByUserId', isEqualTo: userId)
          .orderBy('claimedAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) => RewardEvent.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ 보상 히스토리 조회 오류: $e');
      return [];
    }
  }

  /// 채팅방 통계
  static Future<Map<String, dynamic>> getChatRoomStats(String chatRoomId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      int totalEvents = snapshot.docs.length;
      int claimedEvents = 0;
      int totalRewards = 0;

      for (var doc in snapshot.docs) {
        final event = RewardEvent.fromFirestore(doc);
        if (event.isClaimed) {
          claimedEvents++;
          totalRewards += event.rewardAmount;
        }
      }

      return {
        'totalEvents': totalEvents,
        'claimedEvents': claimedEvents,
        'expiredEvents': totalEvents - claimedEvents,
        'totalRewards': totalRewards,
      };
    } catch (e) {
      debugPrint('❌ 채팅방 통계 조회 오류: $e');
      return {};
    }
  }
}
