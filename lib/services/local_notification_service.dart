import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
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
  static void setActiveChatRoom(String? chatRoomId) {
    _activeChatRoomId = chatRoomId;
    if (kDebugMode) {
      print('🔇 활성 채팅방 설정: $_activeChatRoomId');
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

      // ⭐ 알림음 재생 (2회당 1회 제한)
      if (_soundEnabled && payload != null) {
        // 채팅방별 카운터 초기화
        _soundCountPerChatRoom[payload] ??= 0;
        
        // 카운터 증가
        _soundCountPerChatRoom[payload] = _soundCountPerChatRoom[payload]! + 1;
        
        // 2회당 1회 알림음 재생
        if (_soundCountPerChatRoom[payload]! % 2 == 1) {
          // 홀수번째 (1, 3, 5, ...) 알림에만 소리
          await playNotificationSound();
          if (kDebugMode) {
            print('🔊 알림음 재생 (${_soundCountPerChatRoom[payload]}번째 알림, 2회당 1회)');
          }
        } else {
          // 짝수번째 (2, 4, 6, ...) 알림은 소리 없음
          if (kDebugMode) {
            print('🔇 알림음 생략 (${_soundCountPerChatRoom[payload]}번째 알림, 2회당 1회 제한)');
          }
        }
        
        // 마지막 알림 시간 기록
        _lastNotificationTime[payload] = DateTime.now();
        
        // 10분 경과 시 카운터 초기화 (새로운 대화로 간주)
        Future.delayed(const Duration(minutes: 10), () {
          if (_lastNotificationTime[payload] != null) {
            final elapsed = DateTime.now().difference(_lastNotificationTime[payload]!);
            if (elapsed >= const Duration(minutes: 10)) {
              _soundCountPerChatRoom[payload] = 0;
              if (kDebugMode) {
                print('🔄 알림음 카운터 초기화 (10분 경과): $payload');
              }
            }
          }
        });
      } else if (_soundEnabled && payload == null) {
        // payload 없는 경우 (시스템 알림 등) 항상 소리
        await playNotificationSound();
        if (kDebugMode) {
          print('🔊 알림음 재생 (시스템 알림)');
        }
      } else {
        if (kDebugMode) {
          print('🔇 알림음 꺼짐 (사용자 설정)');
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
