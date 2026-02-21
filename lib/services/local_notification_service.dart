import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io' show Platform;

/// 로컬 알림 서비스 (포그라운드 및 백그라운드 알림)
/// 
/// ⭐⭐ 주요 기능:
/// 1. 2회당 1회 알림음 재생 (배터리 절약)
/// 2. 현재 열린 채팅방에서는 알림 음소거
/// 3. 채팅방별 독립적인 카운터 관리
/// 
/// ⭐⭐ 동작 방식:
/// - 1번째 메시지: 🔇 알림음 없음 (카운터 = 1)
/// - 2번째 메시지: 🔊 알림음 재생 (카운터 = 2)
/// - 3번째 메시지: 🔇 알림음 없음 (카운터 = 3)
/// - 4번째 메시지: 🔊 알림음 재생 (카운터 = 4)
/// - 반복...
/// 
/// ⭐⭐ 카운터 초기화:
/// - 채팅방 진입 시 자동 초기화
/// - 앱 재시작 시 자동 초기화
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop); // 재생 완료 후 멈춤
  static bool _isInitialized = false;
  
  /// ⭐ 현재 열려있는 채팅방 ID (알림 음소거용)
  static String? _activeChatRoomId;
  
  /// ⭐ 알림음 활성화 상태 (기본: true)
  static bool _soundEnabled = true;
  
  /// ⭐⭐ 2회당 1회 알림음 로직을 위한 카운터 맵 (채팅방별)
  static final Map<String, int> _notificationCounters = {};
  
  /// 현재 활성 채팅방 설정 (채팅방 진입 시 호출)
  static void setActiveChatRoom(String? chatRoomId) {
    _activeChatRoomId = chatRoomId;
    
    // ⭐⭐ 채팅방 진입 시 해당 채팅방의 알림음 카운터 초기화
    if (chatRoomId != null) {
      _notificationCounters[chatRoomId] = 0;
      if (kDebugMode) {
        print('🔇 활성 채팅방 설정 및 카운터 초기화: $chatRoomId');
      }
    } else {
      if (kDebugMode) {
        print('🔇 활성 채팅방 해제');
      }
    }
  }
  
  /// 현재 활성 채팅방 가져오기
  static String? getActiveChatRoom() => _activeChatRoomId;

  /// 로컬 알림 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // AudioPlayer 초기화
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      if (kDebugMode) {
        print('🔊 AudioPlayer 초기화 완료');
      }
      
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

      // Android 알림 채널 생성 (조용한 알림 - 소리 없음)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'qrchat_messages', // 채널 ID
        'QRChat 메시지', // 채널 이름
        description: '새로운 채팅 메시지 알림 (조용한 알림)',
        importance: Importance.high,
        playSound: false,  // ⭐ 알림음 끄기
        enableVibration: false,  // ⭐ 진동 끄기
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ 로컬 알림 서비스 초기화 완료');
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

      // ⭐ 알림음 활성화 여부 체크
      if (kDebugMode) {
        print('🔔 알림 표시: ${_soundEnabled ? "🔊 소리 O" : "🔇 소리 X"}');
      }

      // ⭐⭐ 2회당 1회 알림음 로직 구현
      bool shouldPlaySound = false;
      
      if (_soundEnabled && payload != null) {
        // 채팅방별 카운터 증가
        _notificationCounters[payload] = (_notificationCounters[payload] ?? 0) + 1;
        
        // 2회마다 알림음 재생 (홀수번째는 음소거)
        if (_notificationCounters[payload]! % 2 == 0) {
          shouldPlaySound = true;
          if (kDebugMode) {
            print('🔊 알림음 재생: ${_notificationCounters[payload]}번째 알림 (2회당 1회)');
          }
        } else {
          if (kDebugMode) {
            print('🔇 알림음 건너뜀: ${_notificationCounters[payload]}번째 알림 (다음 알림에서 재생)');
          }
        }
      }

      // 1. 로컬 알림 표시 (음소거 모드 - 소리 없이 배지만)
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // 고유 ID
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'qrchat_messages',
            'QRChat 메시지',
            channelDescription: '새로운 채팅 메시지 알림',
            importance: Importance.high,
            priority: Priority.high,
            playSound: false,  // ⭐ 알림음 끄기 (수동으로 재생)
            enableVibration: false,  // ⭐ 진동 끄기
            icon: '@mipmap/ic_launcher',
            onlyAlertOnce: true,  // ⭐ 한 번만 알림
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,  // ⭐ 알림음 끄기 (수동으로 재생)
          ),
        ),
        payload: payload,
      );

      // ⭐⭐ 2회당 1회 알림음 재생
      if (shouldPlaySound) {
        await playNotificationSound();
        if (kDebugMode) {
          print('🔊 알림음 재생 완료');
        }
      } else {
        if (kDebugMode) {
          print('🔇 알림음 꺼짐 (2회당 1회 로직 또는 사용자 설정)');
        }
      }

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
      if (kDebugMode) {
        print('🔊 [알림음] 재생 시작...');
      }
      
      // 볼륨 최대로 설정
      await _audioPlayer.setVolume(1.0);
      
      // PlayerMode를 LOW_LATENCY로 설정 (빠른 재생)
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      // 먼저 이전 재생 중지
      await _audioPlayer.stop();
      
      if (kDebugMode) {
        print('🔊 [알림음] AudioPlayer 준비 완료, 재생 중...');
      }
      
      // 기본 알림음 재생
      await _audioPlayer.play(
        AssetSource('sounds/notification.mp3'),
        volume: 1.0,
      );
      
      if (kDebugMode) {
        print('🔔 [알림음] 재생 완료 - assets/sounds/notification.mp3');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [알림음] 재생 오류: $e');
        print('📝 [알림음] 스택 트레이스: ${StackTrace.current}');
      }
      
      // 기본 알림음 실패 시 coin_earn.mp3 사용해보기
      try {
        if (kDebugMode) {
          print('🔄 [알림음] 대체 음원 시도: coin_earn.mp3');
        }
        await _audioPlayer.stop();
        await _audioPlayer.play(
          AssetSource('sounds/coin_earn.mp3'),
          volume: 1.0,
        );
        if (kDebugMode) {
          print('✅ [알림음] 대체 음원 재생 성공');
        }
      } catch (e2) {
        if (kDebugMode) {
          print('⚠️ [알림음] 대체 음원도 재생 실패: $e2');
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
  
  /// ⭐⭐ 특정 채팅방의 알림음 카운터 초기화
  static void resetNotificationCounter(String chatRoomId) {
    _notificationCounters[chatRoomId] = 0;
    if (kDebugMode) {
      print('🔄 알림음 카운터 초기화: $chatRoomId');
    }
  }
  
  /// ⭐⭐ 모든 채팅방의 알림음 카운터 초기화
  static void resetAllNotificationCounters() {
    _notificationCounters.clear();
    if (kDebugMode) {
      print('🔄 모든 알림음 카운터 초기화');
    }
  }
  
  /// ⭐⭐ 특정 채팅방의 현재 카운터 값 가져오기 (디버깅용)
  static int getNotificationCount(String chatRoomId) {
    return _notificationCounters[chatRoomId] ?? 0;
  }
}
