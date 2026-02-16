import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  /// 대화 추적 맵 (chatRoomId -> 마지막 메시지 시간)
  static final Map<String, DateTime> _chatActivity = {};

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

  /// 그룹 채팅에서 메시지가 전송될 때 호출
  /// 
  /// [chatRoomId] 채팅방 ID
  /// [participantCount] 참여자 수
  static Future<void> onMessageSent({
    required String chatRoomId,
    required int participantCount,
  }) async {
    try {
      // 1. 참여자 수 체크
      if (participantCount < minParticipants) {
        debugPrint('🎁 참여자 ${participantCount}명 (최소 ${minParticipants}명 필요)');
        return;
      }

      // 2. 대화 활동 기록
      final now = DateTime.now();
      final lastActivity = _chatActivity[chatRoomId];

      if (lastActivity == null) {
        // 첫 메시지
        _chatActivity[chatRoomId] = now;
        debugPrint('🎁 채팅방 $chatRoomId 대화 시작');
        return;
      }

      // 3. 대화 지속 시간 체크
      final duration = now.difference(lastActivity).inSeconds;
      _chatActivity[chatRoomId] = now;

      if (duration < conversationDuration) {
        debugPrint('🎁 대화 지속 ${duration}초 (${conversationDuration}초 필요)');
        return;
      }

      // 4. 쿨다운 체크
      final lastEvent = _eventCooldown[chatRoomId];
      if (lastEvent != null) {
        final cooldown = now.difference(lastEvent).inSeconds;
        if (cooldown < eventCooldownSeconds) {
          debugPrint('🎁 쿨다운 중 ${cooldown}초/${eventCooldownSeconds}초');
          return;
        }
      }

      // 5. 확률 체크
      if (_random.nextDouble() > eventProbability) {
        debugPrint('🎁 확률 미달 (${(eventProbability * 100).toInt()}%)');
        return;
      }

      // 6. 이벤트 생성
      await _createRewardEvent(chatRoomId);
      _eventCooldown[chatRoomId] = now;

    } catch (e) {
      debugPrint('❌ 보상 이벤트 처리 오류: $e');
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

      await _firestore.collection(_collectionName).add(event.toFirestore());
      
      debugPrint('🎉 보상 이벤트 생성! 채팅방: $chatRoomId, 보상: ${rewardAmount} QKEY');
    } catch (e) {
      debugPrint('❌ 보상 이벤트 생성 오류: $e');
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

      // QKEY 지급
      await QKeyService.addQKey(
        userId: user.id,
        amount: result,
        type: 'reward_event',
        description: '그룹 채팅 보상 이벤트',
      );

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
