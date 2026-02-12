import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'securet_auth_service.dart';
import 'local_notification_service.dart';
import 'chat_state_service.dart';

// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화 필요 (백그라운드에서 동작 시)
  await Firebase.initializeApp();
  
  if (kDebugMode) {
    print('📱 백그라운드 메시지 수신: ${message.messageId}');
    print('   제목: ${message.notification?.title}');
    print('   내용: ${message.notification?.body}');
  }

  // ⭐ 핵심: 백그라운드에서도 로컬 알림 표시!
  final title = message.notification?.title ?? '새 메시지';
  final body = message.notification?.body ?? '';
  final chatRoomId = message.data['chat_room_id'] as String?;
  
  await LocalNotificationService.showNotification(
    title: title,
    body: body,
    payload: chatRoomId,
  );
  
  if (kDebugMode) {
    print('🔔 백그라운드 로컬 알림 표시 완료');
  }
}

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// FCM 초기화 및 권한 요청
  static Future<void> initialize() async {
    try {
      // 알림 권한 요청 (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('✅ FCM 권한 상태: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 백그라운드 메시지 핸들러 등록
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // FCM 토큰 가져오기 및 저장
        await _saveFCMToken();

        // 포그라운드 메시지 리스너
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // 백그라운드에서 알림 클릭 리스너
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // 앱 종료 상태에서 알림으로 실행된 경우
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }

        if (kDebugMode) {
          print('✅ FCM 초기화 완료');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ FCM 권한이 거부되었습니다');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM 초기화 오류: $e');
      }
    }
  }

  /// FCM 토큰을 Firestore에 저장
  static Future<void> _saveFCMToken() async {
    try {
      final user = await SecuretAuthService.getCurrentUser();
      if (user == null) return;

      String? token = await _messaging.getToken();
      if (token == null) return;

      if (kDebugMode) {
        print('📱 FCM 토큰: ${token.substring(0, 20)}...');
      }

      // Firestore에 토큰 저장
      await _firestore.collection('users').doc(user.id).update({
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ FCM 토큰 저장 완료');
      }

      // 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('users').doc(user.id).update({
          'fcm_token': newToken,
          'fcm_token_updated_at': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          print('🔄 FCM 토큰 갱신: ${newToken.substring(0, 20)}...');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM 토큰 저장 오류: $e');
      }
    }
  }

  /// 포그라운드 메시지 핸들러 (앱이 열려있을 때)
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📱 포그라운드 메시지 수신: ${message.messageId}');
      print('   제목: ${message.notification?.title}');
      print('   내용: ${message.notification?.body}');
      print('   데이터: ${message.data}');
    }

    // ⭐ 현재 채팅방 안에 있으면 알림 표시 안 함
    final chatRoomId = message.data['chat_room_id'] as String?;
    if (chatRoomId != null && ChatStateService().isInChatRoom(chatRoomId)) {
      if (kDebugMode) {
        print('🔕 채팅방 안에 있어서 알림 표시 안 함: $chatRoomId');
      }
      return; // 알림 차단!
    }

    // ⭐ chat_room_id가 없는 경우에도 현재 채팅방이 열려있으면 차단
    if (ChatStateService().currentChatRoomId != null) {
      if (kDebugMode) {
        print('🔕 채팅방 사용 중이므로 알림 표시 안 함 (현재: ${ChatStateService().currentChatRoomId})');
      }
      return; // 알림 차단!
    }

    // ⭐ 채팅방 밖에 있을 때만 로컬 알림 표시
    final title = message.notification?.title ?? '새 메시지';
    final body = message.notification?.body ?? '';
    
    LocalNotificationService.showNotification(
      title: title,
      body: body,
      payload: chatRoomId,
    );
    
    if (kDebugMode) {
      print('🔔 포그라운드 로컬 알림 표시 완료');
    }
  }

  /// 백그라운드/종료 상태에서 알림 클릭 시 핸들러
  static void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 알림 클릭으로 앱 실행: ${message.messageId}');
      print('   데이터: ${message.data}');
    }

    // 알림 클릭 시 특정 화면으로 이동
    // 예: 채팅방 ID가 있으면 해당 채팅방으로 이동
    final chatRoomId = message.data['chat_room_id'];
    if (chatRoomId != null) {
      // 채팅방으로 이동하는 로직
      if (kDebugMode) {
        print('💬 채팅방으로 이동: $chatRoomId');
      }
      // TODO: Navigator를 사용해 채팅방으로 이동
    }
  }

  /// 로그아웃 시 FCM 토큰 제거
  static Future<void> clearFCMToken() async {
    try {
      final user = await SecuretAuthService.getCurrentUser();
      if (user == null) return;

      await _firestore.collection('users').doc(user.id).update({
        'fcm_token': FieldValue.delete(),
      });

      // FCM 토큰 삭제
      await _messaging.deleteToken();

      if (kDebugMode) {
        print('✅ FCM 토큰 제거 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM 토큰 제거 오류: $e');
      }
    }
  }

  /// 채팅 메시지 알림 보내기 (직접 로컬 알림 트리거)
  static Future<void> sendMessageNotification({
    required String receiverUserId,
    required String senderName,
    required String messageText,
    required String chatRoomId,
  }) async {
    try {
      // 수신자의 FCM 토큰 가져오기
      final receiverDoc = await _firestore.collection('users').doc(receiverUserId).get();
      final fcmToken = receiverDoc.data()?['fcm_token'] as String?;

      if (fcmToken == null) {
        if (kDebugMode) {
          print('⚠️ 수신자의 FCM 토큰이 없습니다');
        }
        return;
      }

      if (kDebugMode) {
        print('📤 알림 전송: $senderName -> $receiverUserId');
      }

      // ⭐ 핵심: Firestore에 알림 트리거 저장
      // 수신자가 실시간으로 감지하여 로컬 알림 표시
      await _firestore.collection('notification_triggers').add({
        'receiver_user_id': receiverUserId,
        'sender_name': senderName,
        'message_text': messageText,
        'chat_room_id': chatRoomId,
        'created_at': FieldValue.serverTimestamp(),
        'processed': false,
      });

      if (kDebugMode) {
        print('✅ 알림 트리거 저장 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 알림 전송 오류: $e');
      }
    }
  }

  /// ⭐ 실시간 알림 트리거 감지 및 로컬 알림 표시
  static void listenToNotificationTriggers(String userId) {
    _firestore
        .collection('notification_triggers')
        .where('receiver_user_id', isEqualTo: userId)
        .where('processed', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final data = docChange.doc.data();
          if (data != null) {
            final senderName = data['sender_name'] as String? ?? '새 메시지';
            final messageText = data['message_text'] as String? ?? '';
            final chatRoomId = data['chat_room_id'] as String?;

            if (kDebugMode) {
              print('🔔 새 알림 트리거 감지: $senderName - $messageText');
            }

            // 로컬 알림 표시
            await LocalNotificationService.showNotification(
              title: senderName,
              body: messageText,
              payload: chatRoomId,
            );

            // 처리 완료 표시
            await docChange.doc.reference.update({'processed': true});
          }
        }
      }
    });
  }
}
