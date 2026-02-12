import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';

/// 현재 열려있는 채팅방 추적 서비스
/// 
/// 알림 표시 여부를 결정하기 위해 사용자가 현재 어떤 채팅방을 보고 있는지 추적합니다.
class ChatStateService {
  static final ChatStateService _instance = ChatStateService._internal();
  factory ChatStateService() => _instance;
  ChatStateService._internal();

  /// 현재 열려있는 채팅방 ID (null이면 채팅방 밖)
  String? _currentChatRoomId;

  /// 현재 열려있는 채팅방 ID 가져오기
  String? get currentChatRoomId => _currentChatRoomId;

  /// 채팅방 진입 (채팅방 열 때 호출)
  void enterChatRoom(String chatRoomId) {
    _currentChatRoomId = chatRoomId;
    
    // ⭐ LocalNotificationService에도 알림 (알림 차단용)
    LocalNotificationService.setActiveChatRoom(chatRoomId);
    
    if (kDebugMode) {
      debugPrint('📍 [ChatStateService] 채팅방 진입: $chatRoomId');
    }
  }

  /// 채팅방 나가기 (채팅방 닫을 때 호출)
  void exitChatRoom() {
    if (kDebugMode) {
      debugPrint('📍 [ChatStateService] 채팅방 나가기: $_currentChatRoomId');
    }
    
    _currentChatRoomId = null;
    
    // ⭐ LocalNotificationService에도 알림 (알림 재개용)
    LocalNotificationService.setActiveChatRoom(null);
  }

  /// 특정 채팅방이 현재 열려있는지 확인
  bool isInChatRoom(String chatRoomId) {
    return _currentChatRoomId == chatRoomId;
  }
}
