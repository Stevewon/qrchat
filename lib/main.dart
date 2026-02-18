import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/firebase_notification_service.dart';
import 'services/local_notification_service.dart';

/// ⭐ 백그라운드 메시지 핸들러 (최상위 함수)
/// 앱이 백그라운드/종료 상태일 때 FCM 메시지 수신 시 호출됨
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화 (백그라운드 isolate에서 필요)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('📱📱📱 [백그라운드 핸들러 시작] ===================================');
  print('📱 메시지 ID: ${message.messageId}');
  print('📱 제목: ${message.notification?.title}');
  print('📱 내용: ${message.notification?.body}');
  print('📱 데이터: ${message.data}');
  
  // ⭐ 로컬 알림 + 알림음 표시
  final title = message.notification?.title ?? '새 메시지';
  final body = message.notification?.body ?? '';
  final chatRoomId = message.data['chat_room_id'] as String?;
  
  print('📱 로컬 알림 호출 시작...');
  print('   → 제목: $title');
  print('   → 내용: $body');
  print('   → 채팅방 ID: $chatRoomId');
  
  await LocalNotificationService.showNotification(
    title: title,
    body: body,
    payload: chatRoomId,
  );
  
  print('✅✅✅ [백그라운드 핸들러 완료] ===================================');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 Firebase 초기화 (멀티플랫폼 지원)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ⭐ 백그라운드 메시지 핸들러 등록 (필수!)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // 🔔 알림음 서비스 초기화
  await NotificationService().initialize();
  
  // 📱 FCM 푸시 알림 초기화
  await FirebaseNotificationService.initialize();
  
  // 🔔 로컬 알림 서비스 초기화 (포그라운드 알림)
  await LocalNotificationService.initialize();
  
  runApp(const QRChatApp());
}

class QRChatApp extends StatelessWidget {
  const QRChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
