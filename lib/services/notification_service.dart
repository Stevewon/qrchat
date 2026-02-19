import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림음 관리 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // SharedPreferences 키
  static const String _soundEnabledKey = 'notification_sound_enabled';
  
  // 알림음 활성화 상태
  bool _isSoundEnabled = true;
  
  /// 알림음 활성화 여부 초기화
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      
      if (kDebugMode) {
        debugPrint('🔔 [알림음] 초기화 완료 - 활성화: $_isSoundEnabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [알림음] 초기화 실패: $e');
      }
    }
  }
  
  /// 알림음 활성화 여부 가져오기
  bool get isSoundEnabled => _isSoundEnabled;
  
  /// 알림음 활성화/비활성화 설정
  Future<void> setSoundEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, enabled);
      _isSoundEnabled = enabled;
      
      if (kDebugMode) {
        debugPrint('🔔 [알림음] 설정 변경 - 활성화: $_isSoundEnabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [알림음] 설정 저장 실패: $e');
      }
    }
  }
  
  /// 새 메시지 알림음 재생
  Future<void> playNotificationSound() async {
    if (!_isSoundEnabled) {
      if (kDebugMode) {
        debugPrint('🔕 [알림음] 소리 꺼짐 - 재생 안 함');
      }
      return;
    }
    
    try {
      // 이전 재생 중지
      await _audioPlayer.stop();
      
      // 알림음 재생
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      
      if (kDebugMode) {
        debugPrint('🔔 [알림음] 재생 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [알림음] 재생 실패: $e');
      }
    }
  }
  
  /// 리소스 정리
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
