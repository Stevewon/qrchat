import 'package:flutter/foundation.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 앱 아이콘 배지 관리 서비스
class AppBadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 앱 배지 지원 여부 확인
  static Future<bool> isSupported() async {
    try {
      return await AppBadgePlus.isSupported();
    } catch (e) {
      if (kDebugMode) {
        print('❌ 앱 배지 지원 확인 오류: $e');
      }
      return false;
    }
  }

  /// 배지 업데이트 (총 안 읽은 메시지 개수)
  static Future<void> updateBadge(String userId) async {
    try {
      // 배지 지원 여부 확인
      final isSupported = await AppBadgeService.isSupported();
      if (!isSupported) {
        if (kDebugMode) {
          print('⚠️ 이 기기는 앱 배지를 지원하지 않습니다');
        }
        return;
      }

      // 총 안 읽은 메시지 개수 계산
      final unreadCount = await _getTotalUnreadMessageCount(userId);

      if (kDebugMode) {
        print('📛 앱 배지 업데이트: $unreadCount');
      }

      if (unreadCount > 0) {
        // 배지 표시
        await AppBadgePlus.updateBadge(unreadCount);
      } else {
        // 배지 제거
        await AppBadgePlus.updateBadge(0);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 앱 배지 업데이트 오류: $e');
      }
    }
  }

  /// 총 안 읽은 메시지 개수 계산
  static Future<int> _getTotalUnreadMessageCount(String userId) async {
    try {
      // 1. 사용자가 참여한 모든 채팅방 가져오기
      final chatRoomsSnapshot = await _firestore
          .collection('ChatRooms')
          .where('participantIds', arrayContains: userId)
          .get();

      int totalUnreadCount = 0;

      // 2. 각 채팅방의 안 읽은 메시지 개수 계산
      for (var chatRoomDoc in chatRoomsSnapshot.docs) {
        final chatRoomId = chatRoomDoc.id;

        // 채팅방의 모든 메시지 가져오기
        final messagesSnapshot = await _firestore
            .collection('Messages')
            .where('chatRoomId', isEqualTo: chatRoomId)
            .get();

        // 안 읽은 메시지 카운트
        for (var messageDoc in messagesSnapshot.docs) {
          final data = messageDoc.data();
          final senderId = data['senderId'] as String?;
          final readBy = (data['readBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
              [];

          // 본인이 보낸 메시지가 아니고, readBy에 자신이 없으면 안 읽은 메시지
          if (senderId != userId && !readBy.contains(userId)) {
            totalUnreadCount++;
          }
        }
      }

      if (kDebugMode) {
        print('📊 총 안 읽은 메시지: $totalUnreadCount개');
      }

      return totalUnreadCount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 총 안 읽은 메시지 개수 계산 오류: $e');
      }
      return 0;
    }
  }

  /// 배지 제거
  static Future<void> removeBadge() async {
    try {
      await AppBadgePlus.updateBadge(0);
      if (kDebugMode) {
        print('✅ 앱 배지 제거 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 앱 배지 제거 오류: $e');
      }
    }
  }

  /// 배지 숫자 직접 설정
  static Future<void> setBadge(int count) async {
    try {
      final isSupported = await AppBadgeService.isSupported();
      if (!isSupported) return;

      await AppBadgePlus.updateBadge(count);
      if (kDebugMode) {
        print('📛 앱 배지 설정: $count');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 앱 배지 설정 오류: $e');
      }
    }
  }
}
