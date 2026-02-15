import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'local_notification_service.dart';

/// 현재 열려있는 채팅방 추적 서비스
/// 
/// 알림 표시 여부를 결정하기 위해 사용자가 현재 어떤 채팅방을 보고 있는지 추적합니다.
class ChatStateService with WidgetsBindingObserver {
  static final ChatStateService _instance = ChatStateService._internal();
  factory ChatStateService() => _instance;
  ChatStateService._internal() {
    // ⭐ 앱 생명주기 감지 시작
    WidgetsBinding.instance.addObserver(this);
  }

  /// 현재 열려있는 채팅방 ID (null이면 채팅방 밖)
  String? _currentChatRoomId;
  
  /// 앱이 포그라운드에 있는지 여부
  bool _isAppInForeground = true;

  /// 현재 열려있는 채팅방 ID 가져오기
  String? get currentChatRoomId => _currentChatRoomId;

  /// ⭐ 앱 생명주기 변경 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      debugPrint('📍 [ChatStateService] 앱 상태 변경: $state');
    }

    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아옴
        _isAppInForeground = true;
        if (kDebugMode) {
          debugPrint('📍 [ChatStateService] 앱이 포그라운드로 복귀');
        }
        break;
        
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 앱이 백그라운드로 전환됨
        _isAppInForeground = false;
        
        // ⭐ 핵심: 백그라운드로 가면 채팅방 상태 해제 (알림 활성화)
        if (_currentChatRoomId != null) {
          if (kDebugMode) {
            debugPrint('📍 [ChatStateService] 앱이 백그라운드로 전환 → 채팅방 상태 해제 (알림 활성화)');
          }
          
          // 채팅방 상태 임시 해제 (알림 받을 수 있도록)
          LocalNotificationService.setActiveChatRoom(null);
        }
        break;
        
      default:
        break;
    }
  }

  /// 채팅방 진입 (채팅방 열 때 호출)
  void enterChatRoom(String chatRoomId) {
    _currentChatRoomId = chatRoomId;
    
    // ⭐ 앱이 포그라운드에 있을 때만 알림 차단
    if (_isAppInForeground) {
      LocalNotificationService.setActiveChatRoom(chatRoomId);
    }
    
    if (kDebugMode) {
      debugPrint('📍 [ChatStateService] 채팅방 진입: $chatRoomId (포그라운드: $_isAppInForeground)');
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
    // ⭐ 앱이 백그라운드에 있으면 채팅방에 없는 것으로 간주
    if (!_isAppInForeground) {
      return false;
    }
    return _currentChatRoomId == chatRoomId;
  }
  
  /// 리소스 정리
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
