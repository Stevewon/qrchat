import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

/// 로컬 알림 서비스 (포그라운드 및 백그라운드 알림)
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;
  
  /// ⭐ 현재 열려있는 채팅방 ID (알림 음소거용)
  static String? _activeChatRoomId;
  
  /// ⭐ 알림음 활성화 상태 (기본: true)
  static bool _soundEnabled = true;
  
  /// ⭐ 채팅방별 알림음 카운터 (2회당 1회 재생용)
  static final Map<String, int> _soundCountPerChatRoom = {};
  
  /// ⭐ 채팅방별 마지막 알림 시간 (동일 채팅방 연속 알림 방지)
  static final Map<String, DateTime> _lastNotificationTime = {};
  
  /// 현재 활성 채팅방 설정 (채팅방 진입 시 호출)
  static Future<void> setActiveChatRoom(String? chatRoomId) async {
    _activeChatRoomId = chatRoomId;
    
    // ⭐ 채팅방 진입 시 알림 전체 삭제 (배지 숫자 0으로)
    await cancelAll();
    
    // ⭐ 채팅방 진입 시 카운터 초기화 (다음 알림은 소리 나도록)
    if (chatRoomId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final counterKey = 'notification_counter_$chatRoomId';
        await prefs.remove(counterKey); // 카운터 삭제
        
        if (kDebugMode) {
          print('🔇 활성 채팅방 설정 + 카운터 초기화: $chatRoomId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ 카운터 초기화 실패: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('🔇 활성 채팅방 해제 (null)');
      }
    }
  }
  
  /// 현재 활성 채팅방 가져오기
  static String? getActiveChatRoom() => _activeChatRoomId;

  /// 로컬 알림 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android 알림 설정
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 알림 설정
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // ⭐ Android 알림 채널 2개 생성
      // 1. 소리 있는 채널 (백그라운드 홀수번째 알림용)
      const AndroidNotificationChannel soundChannel = AndroidNotificationChannel(
        'qrchat_messages_sound', // 채널 ID
        'QRChat 메시지 (소리)', // 채널 이름
        description: '새로운 채팅 메시지 알림 (소리 있음)',
        importance: Importance.high,
        playSound: true,  // ⭐ 알림음 켜기
        enableVibration: true,  // ⭐ 진동 켜기
        sound: RawResourceAndroidNotificationSound('notification'),  // ⭐ 커스텀 알림음
      );

      // 2. 소리 없는 채널 (백그라운드 짝수번째 알림용)
      const AndroidNotificationChannel silentChannel = AndroidNotificationChannel(
        'qrchat_messages_silent', // 채널 ID
        'QRChat 메시지 (무음)', // 채널 이름
        description: '새로운 채팅 메시지 알림 (소리 없음)',
        importance: Importance.high,
        playSound: false,  // ⭐ 알림음 끄기
        enableVibration: false,  // ⭐ 진동 끄기
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(soundChannel);
          
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(silentChannel);

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ 로컬 알림 서비스 초기화 완료 (2개 채널: 소리 O / 소리 X)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 알림 초기화 오류: $e');
      }
    }
  }

  /// 알림 탭 핸들러
  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('🔔 알림 탭: ${response.payload}');
    }
    // TODO: 채팅방으로 이동
  }

  /// ⭐ 통합 알림 표시 함수 (포그라운드 + 백그라운드 공용)
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // ⭐ 현재 열려있는 채팅방이면 알림 표시 안 함
      if (payload != null && payload == _activeChatRoomId) {
        if (kDebugMode) {
          print('🔇 알림 음소거: 현재 채팅방이 열려있음 (채팅방 ID: $payload)');
        }
        return; // 알림 표시하지 않음
      }
      
      // 자동 초기화 (백그라운드에서도 동작하도록)
      if (!_isInitialized) {
        await initialize();
      }

      // ⭐ payload가 없으면 기본값 사용 (전역 카운터)
      final chatRoomId = payload ?? 'global';
      
      if (kDebugMode) {
        print('📩 알림 수신: 채팅방=$chatRoomId, 제목=$title, 내용=$body');
      }

      // ⭐ SharedPreferences로 카운터 관리 (백그라운드 isolate 간 공유)
      final prefs = await SharedPreferences.getInstance();
      final counterKey = 'notification_counter_$chatRoomId';
      final lastTimeKey = 'notification_last_time_$chatRoomId';
      final lastMsgKey = 'notification_last_msg_$chatRoomId';
      
      // ⭐⭐ 중복 알림 방지: 1초 이내 동일 메시지 무시
      final lastTimeMs = prefs.getInt(lastTimeKey) ?? 0;
      final lastMsg = prefs.getString(lastMsgKey) ?? '';
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (lastTimeMs > 0 && (now - lastTimeMs) < 1000 && lastMsg == body) {
        if (kDebugMode) {
          print('🚫 중복 알림 무시: 1초 이내 동일 메시지 (${now - lastTimeMs}ms 전)');
        }
        return; // 중복 알림 차단
      }
      
      // 현재 카운터 읽기
      int counter = prefs.getInt(counterKey) ?? 0;
      
      if (kDebugMode) {
        print('📊 저장된 카운터 읽기: $counter (키: $counterKey)');
      }
      
      // 마지막 알림 시간 확인 (10분 경과 시 카운터 초기화)
      // ⭐ lastTimeMs가 0이면 첫 알림이므로 리셋하지 않음
      if (lastTimeMs > 0) {
        final lastTime = DateTime.fromMillisecondsSinceEpoch(lastTimeMs);
        final elapsed = DateTime.now().difference(lastTime);
        
        if (kDebugMode) {
          print('⏰ 마지막 알림 시간: $lastTime (${elapsed.inMinutes}분 전)');
        }
        
        if (elapsed.inMinutes >= 10) {
          counter = 0; // 카운터 초기화
          if (kDebugMode) {
            print('🔄 알림음 카운터 초기화 (10분 경과): $chatRoomId');
          }
        }
      }
      
      // 카운터 증가
      counter++;
      
      // 카운터 및 마지막 메시지 저장
      await prefs.setInt(counterKey, counter);
      await prefs.setInt(lastTimeKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(lastMsgKey, body); // 중복 방지용 메시지 저장
      
      if (kDebugMode) {
        print('💾 카운터 저장 완료: $counter (키: $counterKey)');
      }
      
      // ⭐ 2회당 1회 알림음 재생 여부 결정
      final shouldPlaySound = (counter % 2 == 1); // 홀수번째만 소리
      
      if (kDebugMode) {
        print('🔔 알림 #$counter: ${shouldPlaySound ? "🔊 소리 O" : "🔇 소리 X"} (채팅방: $chatRoomId)');
      }

      // ⭐ 알림 채널 선택 (소리 여부에 따라)
      final channelId = shouldPlaySound ? 'qrchat_messages_sound' : 'qrchat_messages_silent';
      final channelName = shouldPlaySound ? 'QRChat 메시지 (소리)' : 'QRChat 메시지 (무음)';

      // 1. 로컬 알림 표시
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // 고유 ID
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,  // ⭐ 동적 채널 선택
            channelName,
            channelDescription: '새로운 채팅 메시지 알림',
            importance: Importance.high,
            priority: Priority.high,
            playSound: shouldPlaySound,  // ⭐ 동적 소리 설정
            enableVibration: shouldPlaySound,  // ⭐ 동적 진동 설정
            sound: shouldPlaySound ? const RawResourceAndroidNotificationSound('notification') : null,
            icon: '@mipmap/ic_launcher',
            onlyAlertOnce: false,  // ⭐ 매번 알림 표시
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: shouldPlaySound,  // ⭐ 동적 소리 설정
            sound: shouldPlaySound ? 'notification.mp3' : null,
          ),
        ),
        payload: payload,
      );

      if (kDebugMode) {
        print('✅ 알림 표시 완료: $title - $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 알림 표시 오류: $e');
      }
    }
  }

  /// 새 메시지 알림 표시 (포그라운드 - 하위 호환성 유지)
  static Future<void> showMessageNotification({
    required String senderName,
    required String messageText,
    String? chatRoomId,
  }) async {
    await showNotification(
      title: senderName,
      body: messageText,
      payload: chatRoomId,
    );
  }

  /// 알림음 재생
  static Future<void> playNotificationSound() async {
    try {
      // 기본 알림음 재생 (asset 또는 URL)
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      
      if (kDebugMode) {
        print('🔔 알림음 재생');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 알림음 재생 오류: $e');
      }
      
      // 기본 알림음 실패 시 시스템 알림음 사용
      try {
        await _audioPlayer.play(AssetSource('sounds/default.mp3'));
      } catch (e2) {
        if (kDebugMode) {
          print('⚠️ 기본 알림음도 재생 실패');
        }
      }
    }
  }

  /// 모든 알림 취소
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// 특정 알림 취소
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
  
  /// ⭐ 알림음 활성화/비활성화 설정
  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (kDebugMode) {
      print('🔔 알림음 설정 변경: ${enabled ? "활성화" : "비활성화"}');
    }
  }
  
  /// ⭐ 알림음 활성화 여부 가져오기
  static bool isSoundEnabled() => _soundEnabled;
}
